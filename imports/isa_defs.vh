`ifndef ISA_DEFS_VH
`define ISA_DEFS_VH

// Opcodes
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_BRANCH   7'b1100011
`define OP_LOAD     7'b0000011
`define OP_STORE    7'b0100011
`define OP_IMM      7'b0010011
`define OP_REG      7'b0110011
`define OP_SYSTEM   7'b1110011

// Branch funct3
`define BEQ   3'b000
`define BNE   3'b001
`define BLT   3'b100
`define BGE   3'b101
`define BLTU  3'b110
`define BGEU  3'b111

// Load funct3
`define LB  3'b000
`define LH  3'b001
`define LW  3'b010
`define LBU 3'b100
`define LHU 3'b101

// Store funct3
`define SB  3'b000
`define SH  3'b001
`define SW  3'b010

// ALU funct3
`define ADD_SUB 3'b000
`define SLL     3'b001
`define SLT     3'b010
`define SLTU    3'b011
`define XOR_OP  3'b100
`define SRL_SRA 3'b101
`define OR_OP   3'b110
`define AND_OP  3'b111

// funct7
`define F7_ADD 7'b0000000
`define F7_SUB 7'b0100000
`define F7_SRA 7'b0100000

`endif
