# Makefile for shake256_tb simulation

# Compiler
IVERILOG = iverilog
VVP = vvp

# Source files
SRC = shake256_top_fw_tb.v ../shake256_top_fw.v ../keccak_top.v ../keccak_round.v ../keccak_round_constants_gen.v 

# Output executable
OUT = output

# Default target
all: run

# Compile the testbench
$(OUT): $(SRC)
	$(IVERILOG) -o output shake256_top_fw_tb.v ../shake256_top_fw.v ../keccak_top.v ../keccak_round.v ../keccak_round_constants_gen.v 
	# $(IVERILOG) -o $(OUT) $(SRC)

# Run the simulation
run: $(OUT)
	$(VVP) $(OUT)

view: $(OUT)
	gtkwave shake256_top_fw_tb.vcd

# Clean up
clean:
	rm -f $(OUT) *.vcd

.PHONY: all run clean