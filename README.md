# MIPS32_Singlecycle_VHDL
A single cycled version of the 32-bit MIPS ISA

The top_level.vhd entity is the top hierarchy entity. The top_level_tb.vhd entity is the test bench for this hierarchy. 
The instruction.mif file is the memory intialization for the instruction memory. The data_memory.mif file is the memory initialization file for the data_memory. I usually do not initialize the data_memory.mif file with values, I load them using instructions during runtime.
