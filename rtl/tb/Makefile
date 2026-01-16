tb_sram: 
	iverilog -o dsn sram_tb.v ../sram.v
	vvp dsn
# 	gtkwave sram_tb.vcd &

tb_sram_dp: 
	iverilog -o dsn sram_dp_tb.v ../sram_dp.v 
	vvp dsn
# 	gtkwave sram_dp_tb.vcd &

tb_matrix_arithmetic: 
	iverilog -o dsn matrix_arithmetic_tb.v ../matrix_arithmetic.v ../mul.v  ../sram.v ../common/param.v ../csa_add.v ../csa_three_input.v
	vvp dsn
	# gtkwave matrix_arithmetic_tb.vcd &

tb_matrix_arithmetic_mode_2: 
	iverilog -o dsn matrix_arithmetic_mode_2_tb.v ../matrix_arithmetic.v ../mul.v  ../sram.v ../common/param.v ../csa_add.v ../csa_three_input.v
	vvp dsn
	# gtkwave matrix_arithmetic_mode_2_tb.vcd &


tb_sample:
	iverilog -o dsn sample_tb.v ../sample.v ../common/param.v
	vvp dsn
	# gtkwave sample_tb.vcd &

tb_encode:
	iverilog -o dsn  encode_tb.v ../encode.v ../common/param.v
	vvp dsn
# 	gtkwave encode_tb.vcd &

tb_decode:
	iverilog -o dsn  decode_tb.v ../decode.v ../encode.v ../common/param.v ../sram.v
	vvp dsn
	# gtkwave decode_tb.vcd &

tb_mem_copy:
	iverilog -o dsn mem_copy_tb.v ../common/param.v ../sram.v ../mem_copy.v
	vvp dsn
	# gtkwave mem_copy_tb.vcd &

tb_mem_compare:
	iverilog -o dsn mem_compare_tb.v ../common/param.v ../sram.v ../mem_compare.v
	vvp dsn
	# gtkwave mem_compare_tb.vcd &

tb_csa_add:
	iverilog -o dsn csa_add_tb.v ../common/param.v ../csa_add.v ../csa_three_input.v ../tree_add.v ../add.v
	vvp dsn
# 	gtkwave csa_add_tb.vcd &

tb_variable_shift:
	iverilog -o dsn variable_shift_tb.v ../common/param.v ../variable_shift.v 
	vvp dsn
	# gtkwave variable_shift_tb.vcd &

tb_frodo_kem_top: 
	iverilog -o dsn frodo_kem_top_tb.v ../frodo_kem_top.v ../matrix_arithmetic.v ../csa_add.v ../csa_three_input.v ../mul.v ../sram.v ../add.v ../sub.v ../common/param.v ../decode.v ../encode.v ../sample.v ../mem_copy.v ../mem_compare.v ../tree_add.v ../variable_shift.v 
	vvp dsn
	# vcd2fst -v frodo_kem_top_tb.vcd -f frodo_kem_top_tb.fst
	# gtkwave frodo_kem_top_tb.vcd &

format_files:
	grep -v // S.out > S_out.txt
	grep -v // E.out > E_out.txt
	grep -v // EPP.out > EPP_out.txt
	grep -v // B.out > B_out.txt
	grep -v // Bprime.out > Bprime_out.txt
	grep -v // A.out > A_out.txt
	grep -v // Mat_mul_out.mem > Mat_mul_out.txt

clean: 
	rm -r dsn *.vcd *.txt *.mem *.out

