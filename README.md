# 5-Stage-Pipelined-Processor-with-Complete-FPU-Unit

## Overview
This project implements a **5-stage pipelined processor** with an **IEEE-754 compliant Floating-Point Unit (FPU)**. The processor supports both **integer and floating-point arithmetic** and is fully pipelined for efficient execution.

### Key Features:
- **Pipeline Stages:** Instruction Fetch, Decode, Execute, Memory Access, Write-back
- **FPU Operations:** Addition (FADD), Subtraction (FSUB), Multiplication (FMUL), Division (FDIV)
- **Hazard Handling:** Implements data forwarding and hazard detection to reduce stalls
- **Instruction Set:** Supports a mix of integer and floating-point operations
- **Implemented in Verilog**, tested using ModelSim/Vivado

## System Architecture
The processor follows a **5-stage pipeline**:
1. **Instruction Fetch (IF):** Fetches instruction from memory
2. **Instruction Decode (ID):** Decodes instruction and reads registers
3. **Execution (EX):** Executes ALU or FPU operation
4. **Memory Access (MEM):** Reads/writes data to memory
5. **Write-back (WB):** Writes results back to registers

The FPU unit operates within the **Execute (EX) stage**, performing floating-point arithmetic following **IEEE-754 single-precision format**.
