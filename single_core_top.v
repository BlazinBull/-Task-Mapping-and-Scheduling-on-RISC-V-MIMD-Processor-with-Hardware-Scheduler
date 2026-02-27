`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.02.2026 11:19:45
// Design Name: 
// Module Name: single_core_top
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


module single_core_top (
    input  wire        clk,
    input  wire        rst,

    // ---------------- Observability ----------------
    output wire [31:0] core_pc,
output wire [31:0] cycle_count,

    output wire        dbg_mem_req,
    output wire        dbg_mem_we,
    output wire [31:0] dbg_mem_addr,
    
    output wire [31:0] imem_stall_cycles,
output wire [31:0] dmem_stall_cycles,
output wire [31:0] instr_retired
);

    // =================================================
    // Core ↔ IMEM
    // =================================================
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    // =================================================
    // Core ↔ DMEM
    // =================================================
    wire        mem_req;
    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    // =================================================
    // Stall signals
    // =================================================
    wire imem_stall = 1'b0;
    wire dmem_stall = 1'b0;

    // =================================================
    // Instruction retire pulse (MODEL)
    // =================================================
    wire instr_retired;

    // =================================================
    // CORE WRAPPER (always enabled)
    // =================================================
    core_top_wrapper CORE (
        .clk(clk),
        .rst(rst),

        .core_enable(1'b1),
        .task_valid (1'b1),
        .task_id    (2'b00),

        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),

        .mem_req    (mem_req),
        .mem_we     (mem_we),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),

        .arb_stall  (imem_stall | dmem_stall),

        .core_idle  (),          // unused in single-core
        .fault      (),          // unused
        .task_done  (instr_retired),

        .pc_out     (core_pc)
    );

    // INSTRUCTION MEMORY (DUAL PORT NOT NEEDED)
    // =================================================
    instr_mem IMEM (
        .addr_a  (imem_addr),
        .rdata_a (imem_rdata),
        .addr_b  (32'b0),
        .rdata_b ()
    );

    // =================================================
    // DATA MEMORY
    // =================================================
    data_mem DMEM (
        .clk   (clk),
        .req   (mem_req),
        .we    (mem_we),
        .addr  (mem_addr),
        .wdata (mem_wdata),
        .rdata (mem_rdata)
    );

    // =================================================
    // PERFORMANCE COUNTERS (SINGLE CORE)
    // =================================================
   perf_counters PERF (
    .clk(clk),
    .rst(rst),

    .core_task_done({3'b000, instr_retired_pulse}),
    .imem_stall    ({3'b000, imem_stall}),
    .dmem_stall    ({3'b000, dmem_stall}),

    .cycle_count(cycle_count),

    .instr_retired_0(instr_retired),
    .instr_retired_1(),
    .instr_retired_2(),
    .instr_retired_3(),

    .imem_stall_0(imem_stall_cycles),
    .imem_stall_1(),
    .imem_stall_2(),
    .imem_stall_3(),

    .dmem_stall_0(dmem_stall_cycles),
    .dmem_stall_1(),
    .dmem_stall_2(),
    .dmem_stall_3()
);


    // Debug
    // =================================================
    assign dbg_mem_req  = mem_req;
    assign dbg_mem_we   = mem_we;
    assign dbg_mem_addr = mem_addr;

endmodule
