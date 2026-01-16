/**
Matrix Multiplication Module 
**/

`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif


module matrix_arithmetic
#(
    parameter A_ROWS                = `L5_N,        // MAX A ROWS  
    parameter A_COLS                = `L5_N,        // MAX A COLS  
    parameter B_ROWS                = `L5_NBAR,     // MAX A ROWS
    parameter B_COLS                = `L5_N,        // MAX B COLS  

    parameter ELEMENT_WIDTH         = `L5_WIDTH_Q,
    parameter T                     = `T, // Number of Multipliers
    
    parameter WORD_SIZE             = ELEMENT_WIDTH*T,
    parameter C_ROWS                = B_ROWS,
    parameter C_COLS                = A_COLS,
    parameter A_SIZE                = A_ROWS*A_COLS*ELEMENT_WIDTH,
    parameter B_SIZE                = B_ROWS*B_COLS*ELEMENT_WIDTH,
    parameter C_SIZE                = C_ROWS*C_COLS*ELEMENT_WIDTH
)
(
    input                                       i_clk,
    input                                       i_rst_n,

    input                                       i_start,

    // i_mode = 0 => AB + E // A is generated on-the-fly row-wise
    // i_mode = 1 => BA + E // A is generated on-the-fly row-wise
    // i_mode = 2 => BA + E // full matrices are available in advance 

    input  [1:0]                                i_mode,

    input  [2:0]                                i_sec_lev,

    input  [`CLOG2(A_ROWS)-1:0]                 i_a_rows,
    input  [`CLOG2(A_ROWS)-1:0]                 i_b_rows,
    input  [`CLOG2(B_ROWS/T)-1:0]                 i_b_rows_div_t,
    input  [`CLOG2(B_COLS/T)-1:0]                 i_b_cols_div_t,
    input  [`CLOG2(A_ROWS/T)-1:0]                 i_a_rows_div_t,
    input  [`CLOG2(A_COLS/T)-1:0]                 i_a_cols_div_t,
    input  [`CLOG2(A_SIZE/WORD_SIZE)-1:0]       i_a_size_div_word_size,
    input  [`CLOG2(B_SIZE/WORD_SIZE)-1:0]       i_b_size_div_word_size,
    input  [`CLOG2(C_SIZE/WORD_SIZE)-1:0]       i_e_size_div_word_size,
    
    input                                       i_a_ready,

    output reg                                  o_mul_ready,
    
    input [WORD_SIZE-1:0]                       i_a,
    input [WORD_SIZE-1:0]                       i_b,

    output reg [`CLOG2(A_COLS)-1:0]             o_a_addr,
    output reg [`CLOG2(B_SIZE/WORD_SIZE)-1:0]   o_b_addr,
    
    input [`CLOG2(C_SIZE/WORD_SIZE)-1:0]        i_c_addr,
    input                                       i_c_en,
    output [WORD_SIZE-1:0]                      o_c,
    
    input [WORD_SIZE-1:0]                       i_e,
    input [`CLOG2(C_SIZE/WORD_SIZE)-1:0]        i_e_addr,
    input                                       i_e_wen,
    
    output                                      o_mem_sel,
    output  reg                                 o_mem_en,
    output  reg                                 o_done

);


parameter E_MEM_DEPTH = C_ROWS*C_COLS*ELEMENT_WIDTH/T;
parameter T_WIDTH = T > A_COLS/T? `CLOG2(T): `CLOG2(A_COLS/T);

wire [`CLOG2(B_COLS/T)-1:0] B_OFFSET;
wire [`CLOG2(A_COLS/T)-1:0] A_OFFSET;

reg [3:0] state = 0;

// BA + E states
localparam S_WAIT_START          =   0; 
localparam S1_WAIT_FOR_READY_A   =   1;
localparam S1_LOAD_SA            =   2;

// AB + E states
localparam S2_WAIT_START         =  3; 
localparam S2_WAIT_FOR_READY_A   =  4;
localparam S2_LOAD_SA            =  5;
localparam S2_DONE               =  6;

// BA + E states when full matrix is available
localparam S3_WAIT_FOR_READY_A   =  7;
localparam S3_LOAD_SA            =  8;
localparam S3_FINAL_WRITE        =  9;
localparam S3_DONE               =  10;

localparam S_DONE                =  11;


// ================== BA + E signals ==================
reg [`CLOG2(A_ROWS)-1:0]                count_a_rows;
reg [`CLOG2(A_ROWS)-1:0]                count_a_rows_reg;
reg [`CLOG2(A_ROWS)-1:0]                count_a_rows_reg_reg;
reg [`CLOG2(A_ROWS)-1:0]                count_a_rows_reg_reg_reg;
reg [`CLOG2(B_SIZE/WORD_SIZE)-1:0]      count_b_col_blocks;
reg [T_WIDTH-1:0]                       count_t;
reg [T_WIDTH-1:0]                       count_t_reg;
reg [T_WIDTH-1:0]                       count_t_reg_reg;
wire [T_WIDTH-1:0]                       count_t_mux;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      e_addr_int;
reg                                     wen_ram, wen_ram_reg;//, wen_ram_reg_reg;
reg [`CLOG2(B_ROWS*B_COLS/T)-1:0]       count_b;
reg                                     init_flag;


wire [ELEMENT_WIDTH-1:0]                b_array [0:T-1];
wire [ELEMENT_WIDTH-1:0]                b_selected;
reg [ELEMENT_WIDTH-1:0]                 b_selected_reg;

wire [WORD_SIZE-1:0]                    a_mul_b;
reg  [WORD_SIZE-1:0]                    a_mul_b_reg;
wire  [WORD_SIZE-1:0]                   acc_mem_in;
wire  [WORD_SIZE-1:0]                   acc_mem_out;

wire [WORD_SIZE-1:0]                    add_in;
wire [WORD_SIZE-1:0]                    add_out;

reg [WORD_SIZE-1:0]                     zeroth_loc_data;
wire [WORD_SIZE-1:0]                    e_acc;

wire [`CLOG2(C_SIZE/WORD_SIZE)-1:0]     i_addr_0;
wire [WORD_SIZE-1:0]                    i_data_0;
wire [WORD_SIZE-1:0]                    o_data_0;
wire                                    i_rdwr_n_0;

wire [`CLOG2(C_SIZE/WORD_SIZE)-1:0]     i_addr_1;
wire [WORD_SIZE-1:0]                    i_data_1;
wire [WORD_SIZE-1:0]                    o_data_1;
wire                                    i_rdwr_n_1;

reg                                     mem_sel_reg;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      e_addr_int_reg;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      e_addr_int_reg_reg;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      e_addr_int_reg_reg_reg;
// ===========================================

// ================== AB + E signals ==================
wire [`CLOG2(C_SIZE/WORD_SIZE)-1:0]     ab_i_addr_0;
wire [WORD_SIZE-1:0]                    ab_i_data_0;
wire [WORD_SIZE-1:0]                    ab_o_data_0;
wire                                    ab_i_rdwr_n_0;

reg                                     en_load_e;
reg                                     en_shift_e;
reg [WORD_SIZE-1:0]                     shifter_e;

wire [ELEMENT_WIDTH-1:0]                acc_ab_e;
wire [ELEMENT_WIDTH-1:0]                ab_add_in [0:T]; 
wire [(T+1)*ELEMENT_WIDTH-1:0]          add_in_vector;
reg [ELEMENT_WIDTH-1:0]                 ab_add_in_reg;

reg                                     en_shift;
reg                                     en_shift_reg;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      e_out_addr;
reg [WORD_SIZE-1:0]                     shifter;
reg [`CLOG2(T)-1:0]                     count_shifter;
reg                                     result_wen;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      c_addr;
// ==================================================
reg load;

reg [WORD_SIZE-1:0]                      a_reg;
reg [WORD_SIZE-1:0]                      b_reg;

reg en_load_e_reg;
reg en_shift_e_reg;

always@(posedge i_clk)
begin
    a_reg <= i_a;
    b_reg <= i_b;
end

genvar k;
generate
    for (k=0; k<T; k=k+1)    begin
        assign b_array[T-k-1] = b_reg[(k+1)*ELEMENT_WIDTH-1:k*ELEMENT_WIDTH];
    end
endgenerate

assign count_t_mux = (i_mode == 2'b10)? count_t_reg_reg: count_t_reg;

assign b_selected = (state == S3_WAIT_FOR_READY_A && i_mode == 2)? 0 : b_array[count_t_mux[`CLOG2(T)-1:0]];

always@(posedge i_clk)
begin
    b_selected_reg <= b_selected;
end


assign o_mem_sel = (i_mode == 2'b01 || i_mode == 2'b10)? count_a_rows[0]: mem_sel_reg;

genvar i;
generate
    for (i = 0; i < T; i=i+1) begin
        mul 
        #(
            .WIDTH(ELEMENT_WIDTH)
        ) EW_MUL
        (
            .i_a(a_reg[(i+1)*ELEMENT_WIDTH-1:i*ELEMENT_WIDTH]),
            .i_b((i_mode == 2'b01 || i_mode == 2'b10)? b_selected: b_reg[(i+1)*ELEMENT_WIDTH-1:i*ELEMENT_WIDTH]),
            .o_c(a_mul_b[(i+1)*ELEMENT_WIDTH-1:i*ELEMENT_WIDTH])
        );
    end
endgenerate


always@(posedge i_clk)
begin
    a_mul_b_reg <= a_mul_b;
end


// tree_add
//     #(
//         .T(T),
//         .WIDTH(ELEMENT_WIDTH)
//     )
// TREE_ADD
//     (
//         .i_clk(i_clk),
//         .i_sec_lev(i_sec_lev),
//         .i_mode((i_mode == 2'b01 || i_mode == 2'b10)? 1: 0),
//         .i_a(e_acc),
//         .i_b(a_mul_b_reg),
//         .i_array(a_mul_b_reg),
//         .i_element(ab_add_in[0]),
//         .o_array(add_out),
//         .o_element(ab_add_in[T])
//     );

csa_add
   #(
       .T(T),
       .WIDTH(ELEMENT_WIDTH)
   )
CSA_ADDER
   (
       .i_clk(i_clk),
       .i_sec_lev(i_sec_lev),
       .i_mode((i_mode == 2'b01 || i_mode == 2'b10)? 1: 0),
       .i_a(e_acc),
       .i_b(a_mul_b_reg),
       .i_array(a_mul_b_reg),
       .i_element(ab_add_in[0]),
       .o_array(add_out),
       .o_element(ab_add_in[T])
   );


reg [`CLOG2(A_COLS/T):0] a_count;
reg [`CLOG2(B_ROWS):0] b_count;
reg [`CLOG2(A_ROWS*A_COLS/T)-1:0] a_addr_start;
reg mul_in_proc;

assign B_OFFSET = (i_mode == 2'b10)? i_b_cols_div_t: i_a_rows_div_t;
assign A_OFFSET = i_a_cols_div_t[`CLOG2(A_COLS/T)-1:0];



always@(posedge i_clk)
begin
    if (~i_rst_n) begin
        state <= S_WAIT_START;
        e_addr_int <= 0;
        count_b_col_blocks <= 0;
        o_a_addr <= 0;
        o_b_addr <= 0;
        count_t <= 0;
        o_done <= 0;
        count_a_rows <= 0;
        wen_ram <= 0;
        init_flag <= 1;
        count_b <= 0;
        o_mul_ready <= 1;
        a_addr_start <= 0;
        a_count <= 0;
        b_count <= 0;
    end
    else begin
        if (state == S_WAIT_START) begin
            e_addr_int <= 0;
            count_b_col_blocks <= 0;
            o_a_addr <= 0;
            o_b_addr <= 0;
            count_t <= 0;
            o_done <= 0;
            count_a_rows <= 0;
            wen_ram <= 0;
            init_flag <= 1;
            count_b <= 0;
            o_mul_ready <= 1;
            a_addr_start <= 0;
            a_count <= 0;
            b_count <= 0;
            if (i_start) begin
                if (i_mode == 2'b01) begin
                    state <= S1_WAIT_FOR_READY_A;
                end
                else if (i_mode == 2'b10) begin
                    state <= S3_WAIT_FOR_READY_A;
                    o_b_addr <= o_b_addr + B_OFFSET;
                    b_count <= b_count + 1;
                end
                else begin
                    state <= S2_WAIT_FOR_READY_A;
                end
            end
        end

        else if (state == S_DONE) begin
            state <= S_WAIT_START;
            o_done <= 1;
            o_mul_ready <= 1;
        end
        
        else if (state == S1_WAIT_FOR_READY_A) begin
            if (count_a_rows == i_a_rows) begin
                wen_ram <= 0;    
                state <= S_DONE;
                o_done <= 0;   
                o_mul_ready <= 0;        
            end  
            else if (i_a_ready) begin
                state <= S1_LOAD_SA;
                o_a_addr <= o_a_addr + 1;
                o_mul_ready <= 0;
                if (init_flag == 0) begin
                    e_addr_int <= e_addr_int+1;
                end
            end
            else begin
                wen_ram <= 0;
            end
        end

        else if (state == S1_LOAD_SA) begin
            if (e_addr_int == i_b_size_div_word_size-1) begin
                e_addr_int <= 0;
                count_b <= 0;
                state <= S1_WAIT_FOR_READY_A;
                o_mul_ready <= 1;
                count_a_rows <= count_a_rows + 1;
                if (count_t == T-1) begin
                    count_b_col_blocks <=  count_b_col_blocks + 1;
                    count_t <= 0;
                end
                else begin
                    count_t <= count_t+1;
                end 

                if (i_a_ready) begin
                    if (count_a_rows == i_a_rows) begin
                        if (o_a_addr == i_a_rows_div_t-1) begin
                            o_a_addr <= 0;
                        end
                    end 
                    else begin
                        o_a_addr <= o_a_addr + 1;
                    end
                end
                else begin
                    o_a_addr <= 0;
                end

                init_flag <= 0;
            end
            else begin
                e_addr_int <= e_addr_int+1;
                wen_ram <= 1;
                if (o_a_addr == i_a_rows_div_t-1) begin
                    o_a_addr <= 0;
                end
                else begin
                    o_a_addr <= o_a_addr + 1;    
                end

                if (o_a_addr == i_a_rows_div_t-1) begin
                    if (count_b == i_b_rows - 1) begin
                        if (count_t == T-1) begin
                            o_b_addr <= count_b_col_blocks + 1;
                        end
                        else begin
                            o_b_addr <= count_b_col_blocks;
                        end
                        count_b <= 0;
                    end
                    else begin
                        o_b_addr <= o_b_addr + B_OFFSET;
                        count_b <= count_b + 1;
                    end 
                end
            end
        end
// ============ full matrix avilable ========

        else if (state == S3_WAIT_FOR_READY_A) begin
            o_mul_ready <= 0;  
            state <= S3_LOAD_SA;
            count_t <= 0;
            if (i_a_cols_div_t[`CLOG2(A_COLS/T)-1:0] == 1) begin
                b_count <= b_count + 1;
                o_b_addr <= o_b_addr + B_OFFSET;
                a_count <= 0;
                o_a_addr <= a_addr_start;                    
            end
            else begin
                a_count <= a_count + 1;
                o_a_addr <= o_a_addr + 1;
            end
            wen_ram <= 1;
            e_addr_int <= e_addr_int+1;
        end

        else if (state == S3_LOAD_SA) begin
            wen_ram <= 1;
            init_flag <= 0;
            if (e_addr_int == i_e_size_div_word_size-1) begin
                    e_addr_int <= 0;
            end
            else begin
                e_addr_int <= e_addr_int+1;
            end
            if (o_b_addr == i_b_size_div_word_size-1 && count_t == T-1 && b_count == i_b_rows-1 && a_count == i_a_cols_div_t[`CLOG2(A_COLS/T)-1:0]-1 ) begin
                state <= S3_FINAL_WRITE;
                o_done <= 0;
                init_flag <= 0;
                b_count <= 0;
                a_count <= 0;
                count_t <= 0;
                o_b_addr <= 0;
                o_a_addr <= 0;
            end
            else begin
                if (b_count == i_b_rows-1 && count_t == T-1 && a_count == i_a_cols_div_t-1) begin
                     count_b_col_blocks <= count_b_col_blocks + 1;
                     o_b_addr <= count_b_col_blocks + 1;
                     b_count <= 0;
                     a_count <= 0;
                     count_t <= 0;
                     o_a_addr <= a_addr_start+A_OFFSET;
                     a_addr_start <= a_addr_start + A_OFFSET;
                     count_a_rows <= count_a_rows + 1;
                end

                else if (b_count == i_b_rows-1 && a_count == i_a_cols_div_t-1) begin
                    o_b_addr <= count_b_col_blocks;
                    o_a_addr <= a_addr_start + A_OFFSET;
                    a_addr_start <= a_addr_start + A_OFFSET;
                    b_count <= 0;
                    a_count <= 0;
                    count_a_rows <= count_a_rows + 1;
                    if (count_t == T-1) begin
                        count_t <= 0;
                    end
                    else begin
                        count_t <= count_t+1;
                    end
                end

                else begin
                    if (a_count == i_a_cols_div_t-1) begin
                        b_count <= b_count + 1;
                        o_b_addr <= o_b_addr + B_OFFSET;
                        a_count <= 0;
                        o_a_addr <= a_addr_start;
                    end
                    else begin
                        a_count <= a_count + 1;
                        o_a_addr <= o_a_addr + 1;
                    end
                end
            
            end
        end

        else if (state == S3_FINAL_WRITE) begin
            wen_ram <= 1;
            state <= S3_DONE;
        end

        else if (state == S3_DONE) begin
            wen_ram <= 0;
            o_done <= 0;
            o_mul_ready <= 0;
            state <= S_DONE;
        end


// ==========================================

// ============ AS + E states ===============

         else if (state == S2_WAIT_FOR_READY_A) begin
            if (count_a_rows == i_a_rows) begin
                state <= S2_DONE;
                o_mul_ready <= 1;
            end
            else begin
                if (i_a_ready) begin
                    state <= S2_LOAD_SA;
                    o_a_addr <= o_a_addr + 1;
                    o_b_addr <= o_b_addr + 1;
                    o_mul_ready <= 0;
                end
            end
            count_t <= 0;
        end

        else if (state == S2_LOAD_SA) begin
            if (o_b_addr == i_b_size_div_word_size-1) begin
                state <= S2_WAIT_FOR_READY_A;
                o_mul_ready <= 1;
                o_b_addr <= 0;
                o_a_addr <= 0;
                count_a_rows <= count_a_rows+1;
            end
            else begin
                o_b_addr <= o_b_addr + 1;
                if (o_a_addr == i_a_cols_div_t - 1) begin
                    o_a_addr <= 0;
                end
                else begin
                    o_a_addr <= o_a_addr + 1;
                end         
            end

            if (count_t == i_a_cols_div_t-1) begin
                count_t <= 0;
            end
            else begin
                count_t <= count_t + 1;
            end

        end

        else if (state == S2_DONE) begin
            o_done <= 0;
            state <= S_DONE;
        end
        
 // ==========================================   
    end
    if (mul_in_proc) begin
        en_shift <= count_t == i_a_cols_div_t-1;
    end
    else begin
        en_shift <= 0;
    end
    en_shift_reg <= en_shift;
    count_t_reg <= count_t;
    count_t_reg_reg <= count_t_reg;
    count_a_rows_reg <= count_a_rows;
    count_a_rows_reg_reg <= count_a_rows_reg;
    count_a_rows_reg_reg_reg <= count_a_rows_reg_reg;
end

always@(*)
begin
    case(state)
    S_WAIT_START: begin
        if (i_start) begin
            o_mem_en <= 1'b1;
            en_load_e   <= 1'b1;
            load <= 1;
            mul_in_proc <= 1'b1;
        end
        else begin
            o_mem_en <= 1'b0;
            en_load_e   <= 1'b0;
            load <= 0;
            mul_in_proc <= 1'b0;
        end
        en_shift_e  <= 1'b0;
    end

    S1_WAIT_FOR_READY_A: begin
        if (i_a_ready) begin
            o_mem_en <= 1'b1;
        end
        else begin
            o_mem_en <= 1'b0;
        end
        mul_in_proc <= 1'b1;
        en_load_e   <= 1'b0;
        en_shift_e  <= 1'b0;
        load <= 0;
    end

    S1_LOAD_SA: begin
        o_mem_en    <= 1'b1;
        en_load_e   <= 1'b0;
        en_shift_e  <= 1'b0;
        load <= 0;
        mul_in_proc <= 1'b1;
    end

    S3_WAIT_FOR_READY_A: begin
        o_mem_en <= 1'b1;  
        en_load_e   <= 1'b0;
        en_shift_e  <= 1'b0;
        load <= 1;
        mul_in_proc <= 1'b1;
    end

    S3_LOAD_SA: begin
        o_mem_en    <= 1'b1;
        en_load_e   <= 1'b0;
        en_shift_e  <= 1'b0;
        load <= 0;
        mul_in_proc <= 1'b1;
    end

 // ========================= AS + E states =========================
    S2_WAIT_FOR_READY_A:begin
        load <= 0;
        if (i_a_ready) begin
            o_mem_en <= 1'b1;
            mul_in_proc <= 1'b1;
        end
        else begin
            o_mem_en <= 1'b0;
            mul_in_proc <= 1'b1;
        end
        if(en_shift == 1 && count_shifter == T-1) begin
            en_load_e <= 1'b1;
        end
        else begin
            en_load_e <= 1'b0;
        end
        en_shift_e  <= 1'b0;
    end

    S2_LOAD_SA:begin
        o_mem_en <= 1'b1;
        en_shift_e <= 0;
        load <= 0;
        mul_in_proc <= 1'b1;
        if (count_t == 1) begin
            en_shift_e <= 1'b1;
        end
        else begin
            en_shift_e <= 1'b0;
        end
        
        if(en_shift == 1 && count_shifter == T-1) begin
            en_load_e <= 1'b1;
        end
        else begin
            en_load_e <= 1'b0;
        end
    end

    S2_DONE:begin
        o_mem_en    <= 1'b1;
        en_load_e   <= 1'b0;
        en_shift_e  <= 1'b0;
        load <= 0;
        mul_in_proc <= 1'b0;
    end
  // ================================================== 

    default:begin
        o_mem_en    <= 1'b0;
        en_load_e   <= 1'b0;
        en_shift_e  <= 1'b0;
        load <= 0;
    end

    endcase
end

always@(posedge i_clk)
begin
    if (e_addr_int_reg_reg == 0 && wen_ram_reg) begin
        zeroth_loc_data <= add_out;
    end
end

reg mem_sel_reg_reg;
reg init_flag_reg;
always@(posedge i_clk)
begin
    if (i_mode == 2'b10) begin
        mem_sel_reg <= count_a_rows_reg[0];
    end
    else begin
         mem_sel_reg <= count_a_rows[0];
    end
    mem_sel_reg_reg <= mem_sel_reg;
    init_flag_reg <= init_flag;
end

assign e_acc =  ~init_flag_reg && e_addr_int_reg_reg == 0?   zeroth_loc_data:
                mem_sel_reg_reg?                                    o_data_1 : 
                                                                o_data_0;

assign o_c = o_data_0; 

assign i_data_0 =   i_e_wen?            i_e: 
                    (i_mode == 2'b00)?    shifter:
                                        add_out;

assign i_addr_0 =   i_e_wen?                    i_e_addr:
                    i_c_en?                     i_c_addr:
                    (i_mode == 2'b00)?            ab_i_addr_0:
                    (mem_sel_reg_reg)?              e_addr_int_reg_reg:
                                                e_addr_int_reg;


assign i_rdwr_n_0 =     ~((i_e_wen) | (mem_sel_reg_reg & wen_ram_sel) | result_wen);


    sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(C_SIZE/WORD_SIZE)))
        RESULT_RAM_0
            (
                .i_clk(i_clk),
                .i_ce_N(1'b0),
                .i_rdWr_N(i_rdwr_n_0),
                .i_ramAddr(i_addr_0),
                .i_ramData(i_data_0),
                .o_ramData(o_data_0)
            );



always@(posedge i_clk) begin
    e_addr_int_reg <= e_addr_int;
    e_addr_int_reg_reg <= e_addr_int_reg;
    e_addr_int_reg_reg_reg <= e_addr_int_reg_reg;
    wen_ram_reg <= wen_ram;
end
wire wen_ram_sel;
assign wen_ram_sel =  wen_ram_reg;

assign i_addr_1 =   (~mem_sel_reg_reg && wen_ram_sel)?  e_addr_int_reg_reg: 
                                                e_addr_int_reg;
assign i_rdwr_n_1 = ~((~mem_sel_reg_reg) & wen_ram_sel);
assign i_data_1 = add_out;

    sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(C_SIZE/WORD_SIZE)))
    RESULT_RAM_1
        (
            .i_clk(i_clk),
            .i_ce_N(1'b0),
            .i_rdWr_N(i_rdwr_n_1),
            .i_ramAddr(i_addr_1),
            .i_ramData(i_data_1),
            .o_ramData(o_data_1)
        );



// ========================= AS + E =========================


assign ab_o_data_0 = o_data_0;

always@(posedge i_clk)
begin
    en_load_e_reg <= en_load_e;
    en_shift_e_reg <= en_shift_e;

    if (en_load_e_reg) begin
        shifter_e <= ab_o_data_0;
    end
    else if (en_shift_e_reg) begin
        shifter_e <= {shifter_e[WORD_SIZE-ELEMENT_WIDTH-1:0],{(ELEMENT_WIDTH){1'b0}}};
    end

end

genvar m;
generate
    for (m=0; m<T+1; m=m+1) begin
        assign add_in_vector[ELEMENT_WIDTH*(m+1)-1:ELEMENT_WIDTH*m] = ab_add_in[T-m];
    end
endgenerate


assign ab_add_in[0] = (count_t_reg == 1)?   shifter_e[WORD_SIZE-1:WORD_SIZE-ELEMENT_WIDTH]:
                                        ab_add_in_reg ;



always@(posedge i_clk)
begin
    ab_add_in_reg <= ab_add_in[T];
    en_shift_reg <= en_shift;

    if (en_shift_reg) begin
        shifter <= {shifter[WORD_SIZE-ELEMENT_WIDTH-1:0], ab_add_in[T]};
    end

    // if (i_start) begin
    if (load) begin
        count_shifter <= 0;
        result_wen <= 1'b0;
    end
    else if (en_shift_reg && count_shifter == T-1) begin
            result_wen <= 1'b1;
            count_shifter <= 0;
    end
    else if (en_shift_reg) begin
            result_wen <= 1'b0;
            count_shifter <= count_shifter + 1;
    end
    else begin
        result_wen <= 1'b0;
    end
    
    if (i_start) begin
        c_addr <= 0;
    end
    else if (result_wen) begin
        c_addr <=  c_addr+1;
    end

end

always@(posedge i_clk)
begin
    if (~i_rst_n || i_start) begin
        e_out_addr <= 0;
    end
    else if (count_shifter== T-1 && en_shift_e_reg) begin
        e_out_addr <= e_out_addr+1;
    end
end

assign ab_i_addr_0 =    result_wen?     c_addr:
                                            e_out_addr;

endmodule