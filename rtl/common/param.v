/*
package for FrodoKEM
*/


`ifndef PARAM_PKG
`define PARAM_PKG

`define T                                   16 // Number of Multipliers
`define T_ENCODE                            1 // Possible values 1,2,4,8,16,32
`define T_DECODE                            8 // Possible values 1,2,4,8,16,32

`define     L1_B                            2
`define     L3_B                            3
`define     L5_B                            4

`define     L1_Q                            32768
`define     L3_Q                            65536
`define     L5_Q                            65536

`define     L1_WIDTH_Q                      `CLOG2(`L1_Q)           
`define     L3_WIDTH_Q                      `CLOG2(`L3_Q)           
`define     L5_WIDTH_Q                      `CLOG2(`L5_Q)           

`define     L1_LEN_MU                       128          
`define     L3_LEN_MU                       192          
`define     L5_LEN_MU                       256

`define     L1_LEN_A                        128          
`define     L3_LEN_A                        128          
`define     L5_LEN_A                        128

`define     L1_LEN_SEC                      128          
`define     L3_LEN_SEC                      192          
`define     L5_LEN_SEC                      256

`define     L1_LEN_SE                       256          
`define     L3_LEN_SE                       384          
`define     L5_LEN_SE                       512

`define     L1_LEN_SALT                     256          
`define     L3_LEN_SALT                     384          
`define     L5_LEN_SALT                     512

`define     L1_N                            640
`define     L3_N                            976
`define     L5_N                            1344

`define     L1_NBAR                         8
`define     L3_NBAR                         8
`define     L5_NBAR                         8

`define     L1_MBAR                         8
`define     L3_MBAR                         8
`define     L5_MBAR                         8

`define     WORD_SIZE                       `T*`L5_WIDTH_Q
`define     WORD_SIZE_ENCODE                `T_ENCODE*`L5_WIDTH_Q
`define     WORD_SIZE_DECODE                `T_DECODE*`L5_WIDTH_Q


// Error Sampling Parameters
`define     SAMPLE_IN_SIZE                  16          
`define     L1_T_CHI_SIZE                   13          
`define     L3_T_CHI_SIZE                   11          
`define     L5_T_CHI_SIZE                   7



// PRNG Parameters
`define     SHAKE128_OUTPUT_SIZE               1344 //bits
// `define     T_SHAKE128_OUTPUT_SIZE             `SHAKE128_OUTPUT_SIZE + ((`WORD_SIZE - (`SHAKE128_OUTPUT_SIZE%`WORD_SIZE))%`WORD_SIZE) //bits
`define     SHAKE256_OUTPUT_SIZE               1088 //bits


// Different matrix sizes

`define     L1_SAMP_MAT_DEPTH               (`L1_N*`L1_NBAR)/`T
`define     L3_SAMP_MAT_DEPTH               (`L3_N*`L3_NBAR)/`T
`define     L5_SAMP_MAT_DEPTH               (`L5_N*`L5_NBAR)/`T

`define     L1_B_MAT_DEPTH                  (`L1_N*`L1_NBAR)/`T
`define     L3_B_MAT_DEPTH                  (`L3_N*`L3_NBAR)/`T
`define     L5_B_MAT_DEPTH                  (`L5_N*`L5_NBAR)/`T

`define     L1_A_MAT_DEPTH                  (`L1_N*`L1_N)/`T
`define     L3_A_MAT_DEPTH                  (`L3_N*`L3_N)/`T
`define     L5_A_MAT_DEPTH                  (`L5_N*`L5_N)/`T



`define CLOG2(x) ( \
    (x <= 2) ? 1 : \
    (x <= 4) ? 2 : \
    (x <= 8) ? 3 : \
    (x <= 16) ? 4 : \
    (x <= 32) ? 5 : \
    (x <= 64) ? 6 : \
    (x <= 128) ? 7 : \
    (x <= 256) ? 8 : \
    (x <= 512) ? 9 : \
    (x <= 1024) ? 10 : \
    (x <= 2048) ? 11 : \
    (x <= 4096) ? 12 : \
    (x <= 8192) ? 13 : \
    (x <= 16384) ? 14 : \
    (x <= 32768) ? 15 : \
    (x <= 65536) ? 16 : \
    (x <= 131072) ? 17 : \
    (x <= 262144) ? 18 : \
    (x <= 524288) ? 19 : \
    (x <= 1048576) ? 20 : \
    (x <= 2097152) ? 21 : \
    (x <= 4194304) ? 22 : \
    (x <= 8388608) ? 23 : \
    (x <= 16777216) ? 24 : \
    (x <= 33554432) ? 25 : \
    (x <= 67108864) ? 26 : \
    (x <= 134217728) ? 27 : \
    (x <= 268435456) ? 28 : \
    (x <= 536870912) ? 29 : \
    (x <= 1073741824) ? 30 : \
    -1)




`endif








