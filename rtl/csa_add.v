/**
Carry Save Adder Module for adding T elements 

i_sec_lev = 1, 3, 5 (i_sec_lev = 1 MSB is zeroized from the output)

i_mode = 0 -> o_element = i_array[0] + i_array[1] + .. i_array[T-1] outputs one element

i_mode = 1 -> 
    o_array[0] = i_a[0] + i_b[0]; 
    o_array[1] = i_a[1] + i_b[1];  ... 
    o_array[T-1] =  i_a[T-1] + i_b[T-1] 
**/


module csa_add
#(
    parameter T                    = 16,
    parameter WIDTH                = 16
)
(
    input                   i_clk,
    input   [2:0]           i_sec_lev,      
    input                   i_mode,         
                                            

    input   [T*WIDTH-1:0]   i_a,
    input   [T*WIDTH-1:0]   i_b,
    
    input   [T*WIDTH-1:0]   i_array,
    input   [WIDTH-1:0]     i_element,

    output  [T*WIDTH-1:0]   o_array,
    output  [WIDTH-1:0]     o_element
);


genvar i;
// genvar i, level;
// integer j, k;

// Extract individual elements from input arrays
wire [WIDTH-1:0] array_elements [0:T-1];
wire [WIDTH-1:0] a_elements [0:T-1];
wire [WIDTH-1:0] b_elements [0:T-1];

wire [WIDTH-1:0] sum [0:T];
wire [WIDTH-1:0] carry [0:T];

generate
    for (i = 0; i < T; i = i + 1) begin : extract_elements
        assign array_elements[i] = i_array[i*WIDTH +: WIDTH];
        assign a_elements[i] = i_a[i*WIDTH +: WIDTH];
        assign b_elements[i] = i_b[i*WIDTH +: WIDTH];
    end
endgenerate


generate
    if (T==16) begin : csa_tree_16
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_0
            (
                .i_mode(0),
                .i_a(array_elements[0]),
                .i_b(array_elements[1]),
                .i_c(array_elements[2]),
                .o_sum(sum[0]),
                .o_carry(carry[0])
            );


        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_1
            (
                .i_mode(0),
                .i_a(array_elements[3]),
                .i_b(array_elements[4]),
                .i_c(array_elements[5]),
                .o_sum(sum[1]),
                .o_carry(carry[1])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_2
            (
                .i_mode(0),
                .i_a(array_elements[6]),
                .i_b(array_elements[7]),
                .i_c(array_elements[8]),
                .o_sum(sum[2]),
                .o_carry(carry[2])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_3
            (
                .i_mode(0),
                .i_a(array_elements[9]),
                .i_b(array_elements[10]),
                .i_c(array_elements[11]),
                .o_sum(sum[3]),
                .o_carry(carry[3])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_4
            (
                .i_mode(0),
                .i_a(array_elements[12]),
                .i_b(array_elements[13]),
                .i_c(array_elements[14]),
                .o_sum(sum[4]),
                .o_carry(carry[4])
            );
        // Level 2

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_5
            (
                .i_mode(0),
                .i_a(sum[0]),
                .i_b(carry[0]),
                .i_c(sum[1]),
                .o_sum(sum[5]),
                .o_carry(carry[5])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_6
            (
                .i_mode(0),
                .i_a(carry[1]),
                .i_b(sum[2]),
                .i_c(carry[2]),
                .o_sum(sum[6]),
                .o_carry(carry[6])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_7
            (
                .i_mode(0),
                .i_a(sum[3]),
                .i_b(carry[3]),
                .i_c(sum[4]),
                .o_sum(sum[7]),
                .o_carry(carry[7])
            );

        // Level 3

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_8
            (
                .i_mode(0),
                .i_a(sum[5]),
                .i_b(carry[5]),
                .i_c(sum[6]),
                .o_sum(sum[8]),
                .o_carry(carry[8])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_9
            (
                .i_mode(0),
                .i_a(carry[6]),
                .i_b(sum[7]),
                .i_c(carry[7]),
                .o_sum(sum[9]),
                .o_carry(carry[9])
            );


        // Level 4
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_10
            (
                .i_mode(0),
                .i_a(sum[8]),
                .i_b(carry[8]),
                .i_c(sum[9]),
                .o_sum(sum[10]),
                .o_carry(carry[10])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_11
            (
                .i_mode(0),
                .i_a(carry[9]),
                .i_b(carry[4]),
                .i_c(array_elements[15]),
                .o_sum(sum[11]),
                .o_carry(carry[11])
            );

        // Level 5
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_12
            (
                .i_mode(0),
                .i_a(sum[10]),
                .i_b(carry[10]),
                .i_c(sum[11]),
                .o_sum(sum[12]),
                .o_carry(carry[12])
            );


        // Level 6
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_13
            (
                .i_mode(0),
                .i_a(sum[12]),
                .i_b(carry[12]),
                .i_c(carry[11]),
                .o_sum(sum[13]),
                .o_carry(carry[13])
            );

        // Level 7
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_14
            (
                .i_mode(0),
                .i_a(sum[13]),
                .i_b(carry[13]),
                .i_c(i_element),
                .o_sum(sum[14]),
                .o_carry(carry[14])
            );
    end

    else if (T==32) begin : csa_tree_32
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_0
            (
                .i_mode(0),
                .i_a(array_elements[0]),
                .i_b(array_elements[1]),
                .i_c(array_elements[2]),
                .o_sum(sum[0]),
                .o_carry(carry[0])
            );


        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_1
            (
                .i_mode(0),
                .i_a(array_elements[3]),
                .i_b(array_elements[4]),
                .i_c(array_elements[5]),
                .o_sum(sum[1]),
                .o_carry(carry[1])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_2
            (
                .i_mode(0),
                .i_a(array_elements[6]),
                .i_b(array_elements[7]),
                .i_c(array_elements[8]),
                .o_sum(sum[2]),
                .o_carry(carry[2])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_3
            (
                .i_mode(0),
                .i_a(array_elements[9]),
                .i_b(array_elements[10]),
                .i_c(array_elements[11]),
                .o_sum(sum[3]),
                .o_carry(carry[3])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_4
            (
                .i_mode(0),
                .i_a(array_elements[12]),
                .i_b(array_elements[13]),
                .i_c(array_elements[14]),
                .o_sum(sum[4]),
                .o_carry(carry[4])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_5
            (
                .i_mode(0),
                .i_a(array_elements[15]),
                .i_b(array_elements[16]),
                .i_c(array_elements[17]),
                .o_sum(sum[5]),
                .o_carry(carry[5])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_6
            (
                .i_mode(0),
                .i_a(array_elements[18]),
                .i_b(array_elements[19]),
                .i_c(array_elements[20]),
                .o_sum(sum[6]),
                .o_carry(carry[6])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_7
            (
                .i_mode(0),
                .i_a(array_elements[21]),
                .i_b(array_elements[22]),
                .i_c(array_elements[23]),
                .o_sum(sum[7]),
                .o_carry(carry[7])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_8
            (
                .i_mode(0),
                .i_a(array_elements[24]),
                .i_b(array_elements[25]),
                .i_c(array_elements[26]),
                .o_sum(sum[8]),
                .o_carry(carry[8])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_9
            (
                .i_mode(0),
                .i_a(array_elements[27]),
                .i_b(array_elements[28]),
                .i_c(array_elements[29]),
                .o_sum(sum[9]),
                .o_carry(carry[9])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_10
            (
                .i_mode(0),
                .i_a(array_elements[30]),
                .i_b(array_elements[31]),
                .i_c(i_element),
                .o_sum(sum[10]),
                .o_carry(carry[10])
            );
        
        
        // Level 2

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_11
            (
                .i_mode(0),
                .i_a(sum[0]),   //0
                .i_b(carry[0]), //1
                .i_c(sum[1]),   //2
                .o_sum(sum[11]),
                .o_carry(carry[11])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_12
            (
                .i_mode(0),
                .i_a(carry[1]), //3
                .i_b(sum[2]),   //4
                .i_c(carry[2]), //5
                .o_sum(sum[12]),
                .o_carry(carry[12])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_13
            (
                .i_mode(0),
                .i_a(sum[3]),   //6
                .i_b(carry[3]), //7
                .i_c(sum[4]), //8
                .o_sum(sum[13]),
                .o_carry(carry[13])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_14
            (
                .i_mode(0),
                .i_a(carry[4]),  //9
                .i_b(sum[5]),   //10
                .i_c(carry[5]), //11
                .o_sum(sum[14]),
                .o_carry(carry[14])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_15
            (
                .i_mode(0),
                .i_a(sum[6]),   //12
                .i_b(carry[6]), //13
                .i_c(sum[7]),   //14
                .o_sum(sum[15]),
                .o_carry(carry[15])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_16
            (
                .i_mode(0),
                .i_a(carry[7]), //15
                .i_b(sum[8]),   //16
                .i_c(carry[8]), //17
                .o_sum(sum[16]),
                .o_carry(carry[16])
            );
        
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_17
            (
                .i_mode(0),
                .i_a(sum[9]), //18
                .i_b(carry[9]), //19
                .i_c(sum[10]), //20
                .o_sum(sum[17]),
                .o_carry(carry[17])
            );

        
        // Level 3
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_18
            (
                .i_mode(0),
                .i_a(sum[11]),
                .i_b(carry[11]),
                .i_c(sum[12]),
                .o_sum(sum[18]),
                .o_carry(carry[18])
            );

       
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_19
            (
                .i_mode(0),
                .i_a(carry[12]),
                .i_b(sum[13]),
                .i_c(carry[13]),
                .o_sum(sum[19]),
                .o_carry(carry[19])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_20
            (
                .i_mode(0),
                .i_a(sum[14]),
                .i_b(carry[14]),
                .i_c(sum[15]),
                .o_sum(sum[20]),
                .o_carry(carry[20])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_21
            (
                .i_mode(0),
                .i_a(carry[15]),
                .i_b(sum[16]),
                .i_c(carry[16]),
                .o_sum(sum[21]),
                .o_carry(carry[21])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_22
            (
                .i_mode(0),
                .i_a(sum[17]),
                .i_b(carry[17]),
                .i_c(carry[10]),
                .o_sum(sum[22]),
                .o_carry(carry[22])
            );
        

        // Level 4
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_23
            (
                .i_mode(0),
                .i_a(sum[18]),
                .i_b(carry[18]),
                .i_c(sum[19]),
                .o_sum(sum[23]),
                .o_carry(carry[23])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_24
            (
                .i_mode(0),
                .i_a(carry[19]),
                .i_b(sum[20]),
                .i_c(carry[20]),
                .o_sum(sum[24]),
                .o_carry(carry[24])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_25
            (
                .i_mode(0),
                .i_a(sum[21]),
                .i_b(carry[21]),
                .i_c(sum[22]),
                .o_sum(sum[25]),
                .o_carry(carry[25])
            );

        // Level 5
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_26
            (
                .i_mode(0),
                .i_a(sum[23]),
                .i_b(carry[23]),
                .i_c(sum[24]),
                .o_sum(sum[26]),
                .o_carry(carry[26])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_27
            (
                .i_mode(0),
                .i_a(carry[24]),
                .i_b(sum[25]),
                .i_c(carry[25]),
                .o_sum(sum[27]),
                .o_carry(carry[27])
            );

        // Level 6
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_28
            (
                .i_mode(0),
                .i_a(sum[26]),
                .i_b(carry[26]),
                .i_c(sum[27]),
                .o_sum(sum[28]),
                .o_carry(carry[28])
            );

        // Level 7
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_29
            (
                .i_mode(0),
                .i_a(carry[27]),
                .i_b(sum[28]),
                .i_c(carry[28]),
                .o_sum(sum[29]),
                .o_carry(carry[29])
            );

        // Level 8
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_30
            (
                .i_mode(0),
                .i_a(sum[29]),
                .i_b(carry[29]),
                .i_c(carry[22]),
                .o_sum(sum[30]),
                .o_carry(carry[30])
            );
  
    end

    else if (T==64) begin : csa_tree_64
    // Level 1
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_0
            (
                .i_mode(0),
                .i_a(array_elements[0]),
                .i_b(array_elements[1]),
                .i_c(array_elements[2]),
                .o_sum(sum[0]),
                .o_carry(carry[0])
            );


        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_1
            (
                .i_mode(0),
                .i_a(array_elements[3]),
                .i_b(array_elements[4]),
                .i_c(array_elements[5]),
                .o_sum(sum[1]),
                .o_carry(carry[1])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_2
            (
                .i_mode(0),
                .i_a(array_elements[6]),
                .i_b(array_elements[7]),
                .i_c(array_elements[8]),
                .o_sum(sum[2]),
                .o_carry(carry[2])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_3
            (
                .i_mode(0),
                .i_a(array_elements[9]),
                .i_b(array_elements[10]),
                .i_c(array_elements[11]),
                .o_sum(sum[3]),
                .o_carry(carry[3])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_4
            (
                .i_mode(0),
                .i_a(array_elements[12]),
                .i_b(array_elements[13]),
                .i_c(array_elements[14]),
                .o_sum(sum[4]),
                .o_carry(carry[4])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_5
            (
                .i_mode(0),
                .i_a(array_elements[15]),
                .i_b(array_elements[16]),
                .i_c(array_elements[17]),
                .o_sum(sum[5]),
                .o_carry(carry[5])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_6
            (
                .i_mode(0),
                .i_a(array_elements[18]),
                .i_b(array_elements[19]),
                .i_c(array_elements[20]),
                .o_sum(sum[6]),
                .o_carry(carry[6])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_7
            (
                .i_mode(0),
                .i_a(array_elements[21]),
                .i_b(array_elements[22]),
                .i_c(array_elements[23]),
                .o_sum(sum[7]),
                .o_carry(carry[7])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_8
            (
                .i_mode(0),
                .i_a(array_elements[24]),
                .i_b(array_elements[25]),
                .i_c(array_elements[26]),
                .o_sum(sum[8]),
                .o_carry(carry[8])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_9
            (
                .i_mode(0),
                .i_a(array_elements[27]),
                .i_b(array_elements[28]),
                .i_c(array_elements[29]),
                .o_sum(sum[9]),
                .o_carry(carry[9])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_10
            (
                .i_mode(0),
                .i_a(array_elements[30]),
                .i_b(array_elements[31]),
                .i_c(array_elements[32]),
                .o_sum(sum[10]),
                .o_carry(carry[10])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_11
            (
                .i_mode(0),
                .i_a(array_elements[33]),
                .i_b(array_elements[34]),
                .i_c(array_elements[35]),
                .o_sum(sum[11]),
                .o_carry(carry[11])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_12
            (
                .i_mode(0),
                .i_a(array_elements[36]),
                .i_b(array_elements[37]),
                .i_c(array_elements[38]),
                .o_sum(sum[12]),
                .o_carry(carry[12])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_13
            (
                .i_mode(0),
                .i_a(array_elements[39]),
                .i_b(array_elements[40]),
                .i_c(array_elements[41]),
                .o_sum(sum[13]),
                .o_carry(carry[13])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_14
            (
                .i_mode(0),
                .i_a(array_elements[42]),
                .i_b(array_elements[43]),
                .i_c(array_elements[44]),
                .o_sum(sum[14]),
                .o_carry(carry[14])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_15
            (
                .i_mode(0),
                .i_a(array_elements[45]),
                .i_b(array_elements[46]),
                .i_c(array_elements[47]),
                .o_sum(sum[15]),
                .o_carry(carry[15])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_16
            (
                .i_mode(0),
                .i_a(array_elements[48]),
                .i_b(array_elements[49]),
                .i_c(array_elements[50]),
                .o_sum(sum[16]),
                .o_carry(carry[16])
            );
        
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_17
            (
                .i_mode(0),
                .i_a(array_elements[51]),
                .i_b(array_elements[52]),
                .i_c(array_elements[53]),
                .o_sum(sum[17]),
                .o_carry(carry[17])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_18
            (
                .i_mode(0),
                .i_a(array_elements[54]),
                .i_b(array_elements[55]),
                .i_c(array_elements[56]),
                .o_sum(sum[18]),
                .o_carry(carry[18])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_19
            (
                .i_mode(0),
                .i_a(array_elements[57]),
                .i_b(array_elements[58]),
                .i_c(array_elements[59]),
                .o_sum(sum[19]),
                .o_carry(carry[19])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_20
            (
                .i_mode(0),
                .i_a(array_elements[60]),
                .i_b(array_elements[61]),
                .i_c(array_elements[62]),
                .o_sum(sum[20]),
                .o_carry(carry[20])
            );
        
        // Level 2

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_21
            (
                .i_mode(0),
                .i_a(sum[0]),   
                .i_b(carry[0]), 
                .i_c(sum[1]),   
                .o_sum(sum[21]),
                .o_carry(carry[21])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_22
            (
                .i_mode(0),
                .i_a(carry[1]), 
                .i_b(sum[2]),   
                .i_c(carry[2]), 
                .o_sum(sum[22]),
                .o_carry(carry[22])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_23
            (
                .i_mode(0),
                .i_a(sum[3]),   
                .i_b(carry[3]), 
                .i_c(sum[4]), 
                .o_sum(sum[23]),
                .o_carry(carry[23])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_24
            (
                .i_mode(0),
                .i_a(carry[4]),  
                .i_b(sum[5]),   
                .i_c(carry[5]), 
                .o_sum(sum[24]),
                .o_carry(carry[24])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_25
            (
                .i_mode(0),
                .i_a(sum[6]),   
                .i_b(carry[6]), 
                .i_c(sum[7]),   
                .o_sum(sum[25]),
                .o_carry(carry[25])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_26
            (
                .i_mode(0),
                .i_a(carry[7]), 
                .i_b(sum[8]),   
                .i_c(carry[8]), 
                .o_sum(sum[26]),
                .o_carry(carry[26])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_27
            (
                .i_mode(0),
                .i_a(sum[9]), 
                .i_b(carry[9]), 
                .i_c(sum[10]), 
                .o_sum(sum[27]),
                .o_carry(carry[27])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_28
            (
                .i_mode(0),
                .i_a(carry[10]),
                .i_b(sum[11]),
                .i_c(carry[11]),
                .o_sum(sum[28]),
                .o_carry(carry[28])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_29
            (
                .i_mode(0),
                .i_a(sum[12]),
                .i_b(carry[12]),
                .i_c(sum[13]),
                .o_sum(sum[29]),
                .o_carry(carry[29])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_30
            (
                .i_mode(0),
                .i_a(carry[13]),
                .i_b(sum[14]),
                .i_c(carry[14]),
                .o_sum(sum[30]),
                .o_carry(carry[30])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_31
            (
                .i_mode(0),
                .i_a(sum[15]),
                .i_b(carry[15]),
                .i_c(sum[16]),
                .o_sum(sum[31]),
                .o_carry(carry[31])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_32
            (
                .i_mode(0),
                .i_a(carry[16]),
                .i_b(sum[17]),
                .i_c(carry[17]),
                .o_sum(sum[32]),
                .o_carry(carry[32])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_33
            (
                .i_mode(0),
                .i_a(sum[18]),
                .i_b(carry[18]),
                .i_c(sum[19]),
                .o_sum(sum[33]),
                .o_carry(carry[33])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_34
            (
                .i_mode(0),
                .i_a(carry[19]),
                .i_b(sum[20]),
                .i_c(carry[20]),
                .o_sum(sum[34]),
                .o_carry(carry[34])
            );

        // Level 3
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_35
            (
                .i_mode(0),
                .i_a(sum[21]),
                .i_b(carry[21]),
                .i_c(sum[22]),
                .o_sum(sum[35]),
                .o_carry(carry[35])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_36
            (
                .i_mode(0),
                .i_a(carry[22]),
                .i_b(sum[23]),
                .i_c(carry[23]),
                .o_sum(sum[36]),
                .o_carry(carry[36])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_37
            (
                .i_mode(0),
                .i_a(sum[24]),
                .i_b(carry[24]),
                .i_c(sum[25]),
                .o_sum(sum[37]),
                .o_carry(carry[37])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_38
            (
                .i_mode(0),
                .i_a(carry[25]),
                .i_b(sum[26]),
                .i_c(carry[26]),
                .o_sum(sum[38]),
                .o_carry(carry[38])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_39
            (
                .i_mode(0),
                .i_a(sum[27]),
                .i_b(carry[27]),
                .i_c(sum[28]),
                .o_sum(sum[39]),
                .o_carry(carry[39])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_40
            (
                .i_mode(0),
                .i_a(carry[28]),
                .i_b(sum[29]),
                .i_c(carry[29]),
                .o_sum(sum[40]),
                .o_carry(carry[40])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_41
            (
                .i_mode(0),
                .i_a(sum[30]),
                .i_b(carry[30]),
                .i_c(sum[31]),
                .o_sum(sum[41]),
                .o_carry(carry[41])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_42
            (
                .i_mode(0),
                .i_a(carry[31]),
                .i_b(sum[32]),
                .i_c(carry[32]),
                .o_sum(sum[42]),
                .o_carry(carry[42])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_43
            (
                .i_mode(0),
                .i_a(sum[33]),
                .i_b(carry[33]),
                .i_c(sum[34]),
                .o_sum(sum[43]),
                .o_carry(carry[43])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_44
            (
                .i_mode(0),
                .i_a(carry[34]),
                .i_b(array_elements[63]),
                .i_c(i_element),
                .o_sum(sum[44]),
                .o_carry(carry[44])
            );

        // Level 4
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_45
            (
                .i_mode(0),
                .i_a(sum[35]),
                .i_b(carry[35]),
                .i_c(sum[36]),
                .o_sum(sum[45]),
                .o_carry(carry[45])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_46
            (
                .i_mode(0),
                .i_a(carry[36]),
                .i_b(sum[37]),
                .i_c(carry[37]),
                .o_sum(sum[46]),
                .o_carry(carry[46])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_47
            (
                .i_mode(0),
                .i_a(sum[38]),
                .i_b(carry[38]),
                .i_c(sum[39]),
                .o_sum(sum[47]),
                .o_carry(carry[47])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_48
            (
                .i_mode(0),
                .i_a(carry[39]),
                .i_b(sum[40]),
                .i_c(carry[40]),
                .o_sum(sum[48]),
                .o_carry(carry[48])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_49
            (
                .i_mode(0),
                .i_a(sum[41]),
                .i_b(carry[41]),
                .i_c(sum[42]),
                .o_sum(sum[49]),
                .o_carry(carry[49])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_50
            (
                .i_mode(0),
                .i_a(carry[42]),
                .i_b(sum[43]),
                .i_c(carry[43]),
                .o_sum(sum[50]),
                .o_carry(carry[50])
            );

            // Level 5
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_51
            (
                .i_mode(0),
                .i_a(sum[45]),
                .i_b(carry[45]),
                .i_c(sum[46]),
                .o_sum(sum[51]),
                .o_carry(carry[51])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_52
            (
                .i_mode(0),
                .i_a(carry[46]),
                .i_b(sum[47]),
                .i_c(carry[47]),
                .o_sum(sum[52]),
                .o_carry(carry[52])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_53
            (
                .i_mode(0),
                .i_a(sum[48]),
                .i_b(carry[48]),
                .i_c(sum[49]),
                .o_sum(sum[53]),
                .o_carry(carry[53])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_54
            (
                .i_mode(0),
                .i_a(carry[49]),
                .i_b(sum[50]),
                .i_c(carry[50]),
                .o_sum(sum[54]),
                .o_carry(carry[54])
            );

        // Level 6
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_55
            (
                .i_mode(0),
                .i_a(sum[51]),
                .i_b(carry[51]),
                .i_c(sum[52]),
                .o_sum(sum[55]),
                .o_carry(carry[55])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_56
            (
                .i_mode(0),
                .i_a(carry[52]),
                .i_b(sum[53]),
                .i_c(carry[53]),
                .o_sum(sum[56]),
                .o_carry(carry[56])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_57
            (
                .i_mode(0),
                .i_a(sum[54]),
                .i_b(carry[54]),
                .i_c(sum[44]),
                .o_sum(sum[57]),
                .o_carry(carry[57])
            );

        // Level 7
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_58
            (
                .i_mode(0),
                .i_a(sum[55]),
                .i_b(carry[55]),
                .i_c(sum[56]),
                .o_sum(sum[58]),
                .o_carry(carry[58])
            );

        csa_three_input
            #(
                .WIDTH(WIDTH)
            )   
        CSA_59
            (
                .i_mode(0),
                .i_a(carry[56]),
                .i_b(sum[57]),
                .i_c(carry[57]),
                .o_sum(sum[59]),
                .o_carry(carry[59])
            );

        // Level 8
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_60
            (
                .i_mode(0),
                .i_a(sum[58]),
                .i_b(carry[58]),
                .i_c(sum[59]),
                .o_sum(sum[60]),
                .o_carry(carry[60])
            );


        // Level 9
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_61
            (
                .i_mode(0),
                .i_a(sum[60]),
                .i_b(carry[60]),
                .i_c(carry[44]),
                .o_sum(sum[61]),
                .o_carry(carry[61])
            );

            // Level 10
        csa_three_input
            #(
                .WIDTH(WIDTH)
            )
        CSA_62
            (
                .i_mode(0),
                .i_a(sum[61]),
                .i_b(carry[61]),
                .i_c(carry[59]),
                .o_sum(sum[62]),
                .o_carry(carry[62])
            );
            
    end
endgenerate

// Final addition to get the result for Mode 0
wire [WIDTH-1:0] final_sum;

assign final_sum = sum[T-2] + carry[T-2];
assign o_element = i_sec_lev == 1? {1'b0, final_sum[WIDTH-2:0]} : final_sum;

//// Mode selection and output assignment
//reg [WIDTH-1:0] element_result;

wire  [T*WIDTH-1:0]  array;

genvar k;
generate
    for (k = 0; k < T; k = k+1) begin : array_output_loop
        assign array[k*WIDTH +: WIDTH] = a_elements[k] + b_elements[k];
        assign o_array[k*WIDTH +: WIDTH] = i_sec_lev == 1? {1'b0, array[(k+1)*WIDTH-2:k*WIDTH]} : array[(k+1)*WIDTH-1:k*WIDTH];
    end
endgenerate



endmodule