`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 14:52:18
// Design Name: 
// Module Name: core_top
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
(* keep_hierarchy = "yes" *)
(* dont_touch = "true" *)
module core_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,

    // Instruction memory
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    // Data memory
    output wire        mem_req,
    output wire        mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input  wire [31:0] mem_rdata,

    // Debug
    output wire [31:0] pc_out
);

`include "isa_defs.vh"

    // --------------------------------------------------
    // Internal wires
    // --------------------------------------------------
    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] imm;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] alu_out;
    wire [31:0] load_data;
    wire [31:0] pc_next;

    wire [6:0] opcode, funct7;
    wire [2:0] funct3;
    wire [4:0] rs1, rs2, rd;

    wire [3:0] alu_op;
    wire [1:0] wb_sel;

    wire reg_we, mem_read, mem_write;
    wire branch, jump, alu_src_imm;
    wire pc_sel;

    reg take_branch;

    // --------------------------------------------------
    // Program Counter
    // --------------------------------------------------
    core_pc PC (
        .clk     (clk),
        .rst     (rst),
        .stall   (stall),
        .pc_sel  (pc_sel),
        .pc_next (pc_next),
        .pc      (pc)
    );

    assign pc_out = pc;

    // --------------------------------------------------
    // Instruction Fetch
    // --------------------------------------------------
    core_ifetch IF (
        .pc         (pc),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .instr      (instr)
    );

    // --------------------------------------------------
    // Decode
    // --------------------------------------------------
    core_decode DEC (
        .instr      (instr),
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .imm        (imm),
        .reg_we     (reg_we),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .alu_op     (alu_op),
        .alu_src_imm(alu_src_imm),
        .wb_sel     (wb_sel)
    );

    // --------------------------------------------------
    // Register File
    // --------------------------------------------------
    core_regfile RF (
        .clk (clk),
        .we  (reg_we && !stall),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  ((wb_sel == 2'b00) ? alu_out :
              (wb_sel == 2'b01) ? load_data :
                                  pc + 32'd4),
        .rd1 (rs1_data),
        .rd2 (rs2_data)
    );

    // --------------------------------------------------
    // ALU
    // --------------------------------------------------
    core_alu ALU (
        .a      (rs1_data),
        .b      (alu_src_imm ? imm : rs2_data),
        .alu_op (alu_op),
        .y      (alu_out)
    );

    // --------------------------------------------------
    // Load / Store Unit (STALL-AWARE)
    // --------------------------------------------------
    core_lsu LSU (
        .funct3     (funct3),
        .is_load    (mem_read  && !stall),
        .is_store   (mem_write && !stall),
        .addr       (alu_out),
        .store_data (rs2_data),
        .mem_rdata  (mem_rdata),
        .mem_req    (mem_req),
        .mem_we     (mem_we),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .load_data  (load_data)
    );

    // --------------------------------------------------
    // Branch logic
    // --------------------------------------------------
    always @(*) begin
        take_branch = 1'b0;
        if (branch) begin
            case (funct3)
                `BEQ:  take_branch = (rs1_data == rs2_data);
                `BNE:  take_branch = (rs1_data != rs2_data);
                `BLT:  take_branch = ($signed(rs1_data) <  $signed(rs2_data));
                `BGE:  take_branch = ($signed(rs1_data) >= $signed(rs2_data));
                `BLTU: take_branch = (rs1_data < rs2_data);
                `BGEU: take_branch = (rs1_data >= rs2_data);
                default: take_branch = 1'b0;
            endcase
        end
    end

    assign pc_sel = jump | take_branch;

    // Only meaningful when pc_sel = 1
    assign pc_next = jump
                     ? ((opcode == `OP_JALR)
                         ? ((rs1_data + imm) & ~32'b1)
                         : (pc + imm))
                     : (pc + imm);

    // --------------------------------------------------
    // Anti-optimization datapath
    // --------------------------------------------------
    reg [31:0] dummy_exec;

    always @(posedge clk or posedge rst) begin
        if (rst)
            dummy_exec <= 32'b0;
        else if (!stall)
            dummy_exec <= dummy_exec + imem_rdata;
    end

endmodule

