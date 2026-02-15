`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 00:28:54
// Design Name: 
// Module Name: decoder
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


// decoder.v - RV32I decoder (subset: full RV32I control signals)
module control_unit(
input  [6:0] opcode,
input  [2:0] funct3,
input  [6:0] funct7,
output reg [3:0] alu_op,
output reg       alu_src,rf_we, mem_read, mem_write,is_load,is_store,is_branch,is_jal, is_jalr,
output reg       is_lui, is_auipc
);
    // alu op encoding same as alu.v
    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_SLL  = 4'd5;
    localparam ALU_SRL  = 4'd6;
    localparam ALU_SRA  = 4'd7;
    localparam ALU_SLT  = 4'd8;
    localparam ALU_SLTU = 4'd9;

    always @(*) begin
        // defaults
        alu_op = ALU_ADD;
        alu_src = 1'b0;
        rf_we = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        is_load = 1'b0;
        is_store = 1'b0;
        is_branch = 1'b0;
        is_jal = 1'b0;
        is_jalr = 1'b0;
        is_lui = 1'b0;
        is_auipc = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                rf_we = 1;
                alu_src = 0;
                case ({funct7,funct3})
                    {7'b0000000,3'b000}: alu_op = ALU_ADD; // add
                    {7'b0100000,3'b000}: alu_op = ALU_SUB; // sub
                    {7'b0000000,3'b001}: alu_op = ALU_SLL; // sll
                    {7'b0000000,3'b010}: alu_op = ALU_SLT; // slt
                    {7'b0000000,3'b011}: alu_op = ALU_SLTU;// sltu
                    {7'b0000000,3'b100}: alu_op = ALU_XOR; // xor
                    {7'b0000000,3'b101}: alu_op = ALU_SRL; // srl
                    {7'b0100000,3'b101}: alu_op = ALU_SRA; // sra
                    {7'b0000000,3'b110}: alu_op = ALU_OR;  // or
                    {7'b0000000,3'b111}: alu_op = ALU_AND; // and
                    default: alu_op = ALU_ADD;
                endcase
            end
            7'b0010011: begin // I-type ALU immediate
                rf_we = 1;
                alu_src = 1;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;  // addi
                    3'b010: alu_op = ALU_SLT;  // slti
                    3'b011: alu_op = ALU_SLTU; // sltiu
                    3'b100: alu_op = ALU_XOR;  // xori
                    3'b110: alu_op = ALU_OR;   // ori
                    3'b111: alu_op = ALU_AND;  // andi
                    3'b001: alu_op = ALU_SLL;  // slli
                    3'b101: alu_op = (funct7 == 7'b0000000) ? ALU_SRL : ALU_SRA; // srli/srai
                    default: alu_op = ALU_ADD;
                endcase
            end
            7'b0000011: begin // loads
                is_load = 1;
                mem_read = 1;
                rf_we = 1;
                alu_src = 1;
                alu_op = ALU_ADD; // compute address
            end
            7'b0100011: begin // stores
                is_store = 1;
                mem_write = 1;
                alu_src = 1;
                alu_op = ALU_ADD; // compute address
            end
            7'b1100011: begin // branches
                is_branch = 1;
                alu_src = 0;
                alu_op = ALU_SUB; 
            end
            7'b1101111: begin // JAL
                is_jal = 1;
                rf_we = 1;
            end
            7'b1100111: begin // JALR
                is_jalr = 1;
                rf_we = 1;
                alu_src = 1;
            end
            7'b0110111: begin // LUI
                is_lui = 1;
                rf_we = 1;
            end
            7'b0010111: begin // AUIPC
                is_auipc = 1;
                rf_we = 1;
            end
            default: begin
            end
        endcase
    end
endmodule
