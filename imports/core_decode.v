`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 14:48:20
// Design Name: 
// Module Name: core_decode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module core_decode (
    input  wire [31:0] instr,

    output wire [6:0]  opcode,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,

    output reg  [31:0] imm,

    output reg         reg_we,
    output reg         mem_read,
    output reg         mem_write,
    output reg         branch,
    output reg         jump,

    output reg  [3:0]  alu_op,
    output reg         alu_src_imm,   

    output reg  [1:0]  wb_sel         
);

`include "isa_defs.vh"

assign opcode = instr[6:0];
assign rd     = instr[11:7];
assign funct3 = instr[14:12];
assign rs1    = instr[19:15];
assign rs2    = instr[24:20];
assign funct7 = instr[31:25];

always @(*) begin

    imm         = 32'b0;
    reg_we      = 1'b0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    branch      = 1'b0;
    jump        = 1'b0;
    alu_op      = 4'b0000; // ADD
    alu_src_imm = 1'b0;
    wb_sel      = 2'b00;   // ALU result

    case (opcode)

       
        `OP_REG: begin
            reg_we = 1'b1;
            alu_src_imm = 1'b0;

            case (funct3)
                `ADD_SUB: alu_op = (funct7 == `F7_SUB) ? 4'b0001 : 4'b0000;
                `SLL:     alu_op = 4'b0010;
                `SLT:     alu_op = 4'b0011;
                `SLTU:    alu_op = 4'b0100;
                `XOR_OP:  alu_op = 4'b0101;
                `SRL_SRA: alu_op = (funct7 == `F7_SRA) ? 4'b0111 : 4'b0110;
                `OR_OP:   alu_op = 4'b1000;
                `AND_OP:  alu_op = 4'b1001;
            endcase
        end

      
        `OP_IMM: begin
            reg_we      = 1'b1;
            alu_src_imm = 1'b1;
            imm         = {{20{instr[31]}}, instr[31:20]};

            case (funct3)
                `ADD_SUB: alu_op = 4'b0000; // ADDI
                `SLL:     alu_op = 4'b0010; // SLLI
                `SLT:     alu_op = 4'b0011;
                `SLTU:    alu_op = 4'b0100;
                `XOR_OP:  alu_op = 4'b0101;
                `SRL_SRA: alu_op = (funct7 == `F7_SRA) ? 4'b0111 : 4'b0110;
                `OR_OP:   alu_op = 4'b1000;
                `AND_OP:  alu_op = 4'b1001;
            endcase
        end

       
        `OP_LOAD: begin
            reg_we      = 1'b1;
            mem_read   = 1'b1;
            alu_src_imm = 1'b1;
            wb_sel      = 2'b01;
            alu_op      = 4'b0000; // address calc
            imm         = {{20{instr[31]}}, instr[31:20]};
        end

        
        `OP_STORE: begin
            mem_write  = 1'b1;
            alu_src_imm = 1'b1;
            alu_op      = 4'b0000;
            imm         = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        end

        // -----------------------
        // BRANCH
        // -----------------------
        `OP_BRANCH: begin
            branch = 1'b1;
            alu_op = 4'b0001; // subtraction for compare
            imm    = {{19{instr[31]}}, instr[31], instr[7],
                      instr[30:25], instr[11:8], 1'b0};
        end

       
        `OP_JAL: begin
            jump   = 1'b1;
            reg_we = 1'b1;
            wb_sel = 2'b10; // PC+4
            imm    = {{11{instr[31]}}, instr[31], instr[19:12],
                      instr[20], instr[30:21], 1'b0};
        end

       
        `OP_JALR: begin
            jump        = 1'b1;
            reg_we      = 1'b1;
            alu_src_imm = 1'b1;
            wb_sel      = 2'b10;
            imm         = {{20{instr[31]}}, instr[31:20]};
        end

        `OP_LUI: begin
            reg_we = 1'b1;
            alu_src_imm = 1'b1;
            alu_op = 4'b0000;
            imm = {instr[31:12], 12'b0};
        end

    
        `OP_AUIPC: begin
            reg_we = 1'b1;
            alu_src_imm = 1'b1;
            alu_op = 4'b0000;
            imm = {instr[31:12], 12'b0};
        end

        default: begin
       
        end
    endcase
end

endmodule

