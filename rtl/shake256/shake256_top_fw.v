

// `timescale 1 ns / 10 ps
module shake_top_fw
#(
  parameter KECCAK_UNROLL = 3, //Unroll factor for Keccak, 1, 2 or 3
  parameter DW = 1344,
  parameter REG_INPUT = 1'b0
)
(
  input                     clk_i,              //system clock
  input                     rst_ni,             //system reset, active low
  input                     start_i,            //start of SHAKE process, 1 clock pulse, assert before putting input data
  
  `ifndef SHAKE256
    input                     sel_shake128_i,     //start of SHAKE process, 1 clock pulse, assert before putting input data
  `endif
  input   [DW-1:0]          din_i,              //data input
  input                     din_valid_i,        //data input valid signal, transaction happens when both din_valid_i and din_ready_o HIGH
  input                     last_din_i,         //last data input, also used as first data output squeeze
  input   [7:0]             last_din_byte_i,    //byte length of last data input, 0 to 8 for DW=64
  
  input                     dout_ready_i,       //signal to request output data, transaction happens when both dout_ready_i and dout_valid_o HIGH
  output  reg               din_ready_o,        //signal showing shake module ready to receive input data, transaction happens when both din_valid_i and din_ready_o HIGH
  output  [DW-1:0]          dout_o,             //data output
  output  reg               dout_valid_o        //data output valid signal, transaction happens when both dout_ready_i and dout_valid_o HIGH
);

localparam  DELIMITER = 8'h1F; //SHAKE128/256 Delimiter
localparam  DOMAIN_SEPERATOR = 8'h80; //SHAKE128/256 DOMAIN_SEPERATOR

reg                keccak_start;
reg                keccak_squeeze;
wire                keccak_ready;
wire    [1599:0]    keccak_state_in;
wire    [1599:0]    keccak_state_out;

`ifdef SHAKE256
    wire                     sel_shake128_i;    
    assign sel_shake128_i = 0;
`endif

parameter DW_MASK = DW;
wire [DW_MASK-1:0] delimiter_mask;
wire [DW_MASK-1:0] mask;

wire [7:0] domain_seperator_shake256;
wire [7:0] domain_seperator_shake128;

wire [7:0] last_din_byte_mux;

assign last_din_byte_mux = (last_din_i) ?     last_din_byte_i : 
                           (last_full_block_reg)? 0 :
                                              168;
reg [DW-1:0] din_reg;
reg keccak_start_reg;
reg last_full_block_reg;

generate 
  if (REG_INPUT) begin
  always@(posedge clk_i)
  begin
    din_reg <= din_i;
    keccak_start_reg <= keccak_start;
    last_full_block_reg <= last_full_block;
  end
  end
  else begin
    always@(*)
    begin
      din_reg <= din_i;
      keccak_start_reg <= keccak_start;
      last_full_block_reg <= last_full_block;
    end
  end
endgenerate

genvar i;
generate
  for (i=0; i<DW_MASK/8; i=i+1) begin
    assign mask[DW_MASK-i*8-1: DW_MASK-(i+1)*8] = (i == last_din_byte_mux) ? DELIMITER : 8'h00;
  end
endgenerate

assign domain_seperator_shake128 =  ~sel_shake128? 8'h00 :
                                    squeeze_more || (last_din_i && last_din_byte_i == full_block) ? 8'h00 : 
                                                                                  (last_din_reg)  ? DOMAIN_SEPERATOR : 
                                                                                      ~last_din_i ? 8'h00 :
                                                                                                    DOMAIN_SEPERATOR;

assign domain_seperator_shake256 =  sel_shake128? 8'h00 :
                                    squeeze_more || (last_din_i && last_din_byte_i == full_block)   ? 8'h00 : 
                                                                                    (last_din_reg)  ? DOMAIN_SEPERATOR : 
                                                                                        ~last_din_i ? 8'h00 :
                                                                                                      DOMAIN_SEPERATOR;

assign delimiter_mask[1343:264] = {mask[1343:264]};
assign delimiter_mask[263:256] = mask[263:256] ^ domain_seperator_shake256;
assign delimiter_mask[255:8] = {mask[255:8]}; 
assign delimiter_mask[7:0] = {mask[7:0] ^ domain_seperator_shake128};


wire [DW-1:0] shake_data_in;





reg [2:0] state;
parameter S_WAIT_START              = 3'b000;
parameter S_WAIT_VALID_DATA         = 3'b001;
parameter S_WAIT_KECCAK_READY       = 3'b010;
parameter S_LAST_FULL_BLOCK         = 3'b011;
parameter S_SQUEEZE_MORE            = 3'b101;
parameter S_STALL                   = 3'b110;
parameter S_DONE                    = 3'b111;

reg [7:0] last_din_bytes;
reg last_din_reg;
reg sel_shake128;
reg last_full_block;
wire[7:0] full_block;
reg squeeze_more;

assign full_block = sel_shake128 ? 168 : 136; 

always@(posedge clk_i)
begin
  if (~rst_ni) begin
    state <= S_WAIT_START;
    dout_valid_o = 1'b0;
    last_din_bytes <= 8'h00;
    last_din_reg <= 1'b0;
    din_ready_o <= 1'b0;
    squeeze_more <= 1'b0;
    sel_shake128 = 0;
  end
  else begin
    if (state == S_WAIT_START) begin
      last_din_reg <= 1'b0;
      if (start_i) begin
        state <= S_WAIT_VALID_DATA;
        sel_shake128 <= sel_shake128_i;
        din_ready_o <= 1'b1;
        squeeze_more <= 1'b0;
      end
      else if (dout_ready_i && squeeze_more) begin
        if (REG_INPUT) begin
          state <= S_STALL;
        end
        else begin
          state <= S_WAIT_KECCAK_READY;
        end
        din_ready_o <= 1'b0;
      end

      if (dout_ready_i || start_i) begin
        dout_valid_o <= 1'b0;
      end
    end

    else if (state == S_STALL) begin
      state <= S_WAIT_KECCAK_READY;
    end

    else if (state == S_WAIT_VALID_DATA) begin
      if (din_valid_i) begin
        if (REG_INPUT) begin
          state <= S_STALL;
        end
        else begin
          state <= S_WAIT_KECCAK_READY;
        end

        din_ready_o <= 1'b0;
      end
      last_din_reg <= last_din_i;
      if (last_din_i) begin
        last_din_bytes <= last_din_byte_i;
      end
      else begin
        last_din_bytes <= 8'h00;
      end
    end

    else if (state == S_WAIT_KECCAK_READY) begin
      if (keccak_ready) begin
        if (last_din_reg) begin
          if (last_din_bytes == full_block) begin
            state <= S_LAST_FULL_BLOCK;
          end
          else begin
            state <= S_WAIT_START;
            dout_valid_o = 1'b1;
            squeeze_more <= 1'b1;
            din_ready_o <= 1'b1;
          end
        end
        else if (squeeze_more) begin
          state <= S_WAIT_START;
          din_ready_o <= 1'b1;
          dout_valid_o = 1'b1;
        end
        else begin
          state <= S_WAIT_VALID_DATA;
          din_ready_o <= 1'b1;
        end
      end
    end

    else if (state == S_LAST_FULL_BLOCK) begin
        // state <= S_WAIT_KECCAK_READY;
        if (REG_INPUT) begin
          state <= S_STALL;
        end
        else begin
          state <= S_WAIT_KECCAK_READY;
        end
        last_din_bytes <= 8'h00;
    end

  end
end

always@(*)
begin
  case(state)
    S_WAIT_START: begin
        keccak_squeeze <= 1'b0;
        last_full_block <= 1'b0;
        if (dout_ready_i && squeeze_more) begin
          keccak_start <= 1'b1;
        end
        else begin
          keccak_start <= 1'b0;
        end
    end

    S_WAIT_VALID_DATA: begin
      keccak_squeeze <= 1'b0;
      last_full_block <= 1'b0;
      if (din_valid_i) begin
        keccak_start <= 1'b1;
      end
      else begin
        keccak_start <= 1'b0;

      end
    end

    S_STALL: begin
      keccak_start <= 1'b0;
      keccak_squeeze <= 1'b0;
      last_full_block <= 1'b0;
    end

    S_WAIT_KECCAK_READY: begin
      keccak_start <= 1'b0;
      keccak_squeeze <= 1'b0;
      last_full_block <= 1'b0;
    end
    
    S_LAST_FULL_BLOCK: begin
      keccak_start <= 1'b1;
      keccak_squeeze <= 1'b0;
      last_full_block <= 1'b1;
    end
    
    S_DONE: begin
      keccak_start <= 1'b0;
      keccak_squeeze <= 1'b0;
      last_full_block <= 1'b0;
    end

    default: begin
      keccak_start <= 1'b0;
      keccak_squeeze <= 1'b0;
      last_full_block <= 1'b0;
    end

  endcase
end

assign shake_data_in = last_full_block_reg||squeeze_more? delimiter_mask : din_reg ^ delimiter_mask;
assign keccak_state_in[1599:512]  = shake_data_in[1343:256] ^ keccak_state_out[1599:512];
assign keccak_state_in[511:256]   = sel_shake128? shake_data_in[255:0] ^ keccak_state_out[511:256]:  keccak_state_out[511:256] ;
assign keccak_state_in[255:0]     = keccak_state_out[255:0];


    keccak_top
    #(.KECCAK_UNROLL(KECCAK_UNROLL))
    keccak_top (
        .Clock    (clk_i            ),      //System clock
        .Reset    (~rst_ni | start_i),      //Active HIGH reset signal
        .Start    (keccak_start_reg     ),      //Start signal, valid on Ready
        .Din      (keccak_state_in  ),      //Data input byte stream, 200 bytes length. Valid during Start AND Ready
        .Req_more (keccak_squeeze   ),      //Request more data output, valid on Ready
        .Ready    (keccak_ready     ),      //keccak's ready signal
        .Dout     (keccak_state_out )
      );     //Data output byte stream, 200 bytes length


assign dout_o[1343:256] = keccak_state_out[1599:1600-1088];
assign dout_o[255:0] = sel_shake128? keccak_state_out[1087:1600-1344] :{(256){1'b0}};

//printing values for debug
// reg print_once;
// always @(posedge clk_i)
// begin
  // if (keccak_start_reg) begin
  //   $display("shake data in = %h", shake_data_in);
  //   $display("mask = %h", mask);
  //   $display("delimiter_mask = %h", delimiter_mask);
  //   $display("keccak_state_in = %h", keccak_state_in);
  // end
  // if (state == S_WAIT_KECCAK_READY && keccak_ready) begin
  //   $display("Keccak output = %h", dout_o);
  //   $display("=====================");
  // end
  
  // if (keccak_start_reg) begin
  //   print_once <= 1'b1; 
  // end
  // else if (dout_valid_o && print_once) begin
  //   $display("final dout_o = %h", dout_o);
  //   print_once <= 1'b0;
  // end
// end

endmodule 

