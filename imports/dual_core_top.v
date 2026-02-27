`timescale 1ns / 1ps

module dual_core_top (
    input  wire        clk,
    input  wire        rst,

    output wire [31:0] core0_pc,
    output wire [31:0] core1_pc,

    // Debug
    output wire [1:0]  dbg_core_enable,
    output wire [1:0]  dbg_core_idle,
    output wire [1:0]  dbg_core_fault,
    output wire [1:0]  dbg_task_done,

    output wire        dbg_mem_req,
    output wire        dbg_mem_we,
    output wire [31:0] dbg_mem_addr
);

    // =================================================
    // Scheduler <-> Core signals
    // =================================================
    wire [1:0] core_idle;
    wire [1:0] core_fault;
    wire [1:0] core_task_done;

    wire [1:0] core_enable;
    wire [1:0] core_task_valid;

    wire [1:0] core0_task_id;
    wire [1:0] core1_task_id;

    // =================================================
    // Instruction memory
    // =================================================
    wire [31:0] imem_addr_0, imem_addr_1;
    wire [31:0] imem_rdata_0, imem_rdata_1;

    // =================================================
    // Core 0 <-> Arbiter
    // =================================================
    wire        c0_mem_req;
    wire        c0_mem_we;
    wire [31:0] c0_mem_addr;
    wire [31:0] c0_mem_wdata;
    wire [31:0] c0_mem_rdata;
    wire        c0_stall;

    // =================================================
    // Core 1 <-> Arbiter
    // =================================================
    wire        c1_mem_req;
    wire        c1_mem_we;
    wire [31:0] c1_mem_addr;
    wire [31:0] c1_mem_wdata;
    wire [31:0] c1_mem_rdata;
    wire        c1_stall;

    // =================================================
    // Shared DMEM
    // =================================================
    wire        mem_req;
    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    // =================================================
    // Scheduler
    // =================================================
    scheduler_with_tcbs scheduler (
        .clk(clk),
        .rst(rst),
        .core_idle(core_idle),
        .core_fault(core_fault),
        .core_task_done(core_task_done),
        .core_enable(core_enable),
        .core_task_valid(core_task_valid),
        .core0_task_id(core0_task_id),
        .core1_task_id(core1_task_id)
    );

    // =================================================
    // Core 0
    // =================================================
    core_top_wrapper CORE0 (
        .clk(clk),
        .rst(rst),
        .core_enable(core_enable[0]),
        .task_valid(core_task_valid[0]),
        .task_id(core0_task_id),

        .imem_addr(imem_addr_0),
        .imem_rdata(imem_rdata_0),

        .mem_req(c0_mem_req),
        .mem_we(c0_mem_we),
        .mem_addr(c0_mem_addr),
        .mem_wdata(c0_mem_wdata),
        .mem_rdata(c0_mem_rdata),
        .arb_stall(c0_stall),

        .core_idle(core_idle[0]),
        .fault(core_fault[0]),
        .task_done(core_task_done[0]),
        .pc_out(core0_pc)
    );

    // =================================================
    // Core 1
    // =================================================
    core_top_wrapper CORE1 (
        .clk(clk),
        .rst(rst),
        .core_enable(core_enable[1]),
        .task_valid(core_task_valid[1]),
        .task_id(core1_task_id),

        .imem_addr(imem_addr_1),
        .imem_rdata(imem_rdata_1),

        .mem_req(c1_mem_req),
        .mem_we(c1_mem_we),
        .mem_addr(c1_mem_addr),
        .mem_wdata(c1_mem_wdata),
        .mem_rdata(c1_mem_rdata),
        .arb_stall(c1_stall),

        .core_idle(core_idle[1]),
        .fault(core_fault[1]),
        .task_done(core_task_done[1]),
        .pc_out(core1_pc)
    );

    // =================================================
    // Instruction Memory (dual-port, no clk)
    // =================================================
    instr_mem IMEM (
        .addr_a(imem_addr_0),
        .rdata_a(imem_rdata_0),
        .addr_b(imem_addr_1),
        .rdata_b(imem_rdata_1)
    );

    // =================================================
    // Data Memory Arbiter
    // =================================================
    dmem_arbiter ARBITER (
        .c0_mem_req(c0_mem_req),
        .c0_mem_we(c0_mem_we),
        .c0_mem_addr(c0_mem_addr),
        .c0_mem_wdata(c0_mem_wdata),
        .c0_mem_rdata(c0_mem_rdata),
        .c0_stall(c0_stall),

        .c1_mem_req(c1_mem_req),
        .c1_mem_we(c1_mem_we),
        .c1_mem_addr(c1_mem_addr),
        .c1_mem_wdata(c1_mem_wdata),
        .c1_mem_rdata(c1_mem_rdata),
        .c1_stall(c1_stall),

        .mem_req(mem_req),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );

    // =================================================
    // Shared Data Memory
    // =================================================
    data_mem DMEM (
        .clk(clk),
        .req(mem_req),
        .we(mem_we),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .rdata(mem_rdata)
    );

    // =================================================
    // Debug
    // =================================================
    assign dbg_core_enable = core_enable;
    assign dbg_core_idle   = core_idle;
    assign dbg_core_fault  = core_fault;
    assign dbg_task_done   = core_task_done;

    assign dbg_mem_req     = mem_req;
    assign dbg_mem_we      = mem_we;
    assign dbg_mem_addr    = mem_addr;

endmodule
