# FrodoKEM RTL Implementation

This directory contains the verilog implementation of the FrodoKEM post-quantum cryptographic algorithm.

## Directory Structure

### `/rtl/aes128`
AES-128 encryption implementation including key expansion, S-box operations, and encryption rounds.

### `/rtl/common`
Shared parameters and utilities used across the design, including system-wide parameter definitions.

### `/rtl/shake256`
SHAKE-256 cryptographic hash function implementation with Keccak round functions and top-level modules.

### `/rtl/tb`
Testbench directory containing verification files and simulation scripts for all modules.

## Core Modules

- `frodo_kem_top.v` - Top-level FrodoKEM module
- `matrix_arithmetic.v` - Matrix operations
- `encode.v` / `decode.v` - encode and decode modules
- `sample.v` - Random sampling operations
- `sram.v` / `sram_dp.v` - Memory modules (single and dual-port)

## Makefile Usage

The main Makefile is located in the `tb/` directory and provides targets for:

- **Individual module testing**: `tb_<module_name>` (e.g., `tb_sram`, `tb_encode`)
- **Full system test**: `tb_frodo_kem_top`
- **Cleanup**: `clean` - removes generated files

### Running Tests
```bash
cd rtl/tb/
make tb_frodo_kem_top    # Run full system testbench
make tb_matrix_arithmetic # Test matrix operations
make clean               # Clean generated files
```

All testbenches use Icarus Verilog for simulation. 
