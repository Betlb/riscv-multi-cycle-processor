# riscv-multi-cycle-processor

This repository contains the design of a multi-cycle RISC-V processor based on the RV32I instruction set architecture. The processor is capable of executing 13 basic instructions from the RISC-V ISA.

## Overview

The design consists of a Verilog module:
- **islemci.v**: The processor module that supports 13 RISC-V instructions, as detailed in the assignment.

## Features
- **Multi-Cycle Execution**: The processor uses a multi-cycle architecture with stages like Fetch, Decode, and Execute.
- **RISC-V RV32I**: The processor supports the RV32I instruction set with optimizations for specific instructions.
- **Verilog Implementation**: The design is written in Verilog, and it is intended to be synthesized for FPGA or other hardware platforms.

## Instructions Supported
The processor supports the following 13 RISC-V instructions:
1. **LUI** (Load Upper Immediate)
2. **AUIPC** (Add Upper Immediate to PC)
3. **JAL** (Jump and Link)
4. **JALR** (Jump and Link Register)
5. **BEQ** (Branch if Equal)
6. **BNE** (Branch if Not Equal)
7. **BLT** (Branch if Less Than)
8. **BGE** (Branch if Greater Than or Equal)
9. **LB** (Load Byte)
10. **LH** (Load Halfword)
11. **LW** (Load Word)
12. **SB** (Store Byte)
13. **SH** (Store Halfword)
