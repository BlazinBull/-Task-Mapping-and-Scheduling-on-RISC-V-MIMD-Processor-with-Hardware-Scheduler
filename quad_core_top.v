`timescale 1ns / 1ps
(* keep_hierarchy = "yes" *)
module quad_core_top (
    input wire clk, rst,
    output wire [31:0] core0_pc, core1_pc, core2_pc, core3_pc,
    output wire [3:0]  dbg_core_enable, dbg_core_idle, dbg_core_fault, dbg_task_done,
    output wire        dbg_mem_req, dbg_mem_we,
    output wire [31:0] dbg_mem_addr
);

    // Scheduler & IMEM signals
    wire [3:0] core_idle, core_fault, core_task_done;
    (* keep = "true" *) wire [3:0] core_enable, core_task_valid;
    wire [1:0] core0_task_id, core1_task_id, core2_task_id, core3_task_id;
    wire [31:0] c0_imem_addr, c1_imem_addr, c2_imem_addr, c3_imem_addr;
    wire [31:0] c0_imem_rdata, c1_imem_rdata, c2_imem_rdata, c3_imem_rdata;
    wire c0_imem_stall, c1_imem_stall, c2_imem_stall, c3_imem_stall;
    wire [31:0] imem_addr_a, imem_addr_b, imem_rdata_a, imem_rdata_b;

    // DMEM signals
    wire c0_mem_req, c1_mem_req, c2_mem_req, c3_mem_req;
    wire c0_mem_we, c1_mem_we, c2_mem_we, c3_mem_we;
    wire [31:0] c0_mem_addr, c1_mem_addr, c2_mem_addr, c3_mem_addr;
    wire [31:0] c0_mem_wdata, c1_mem_wdata, c2_mem_wdata, c3_mem_wdata;
    wire [31:0] c0_mem_rdata, c1_mem_rdata, c2_mem_rdata, c3_mem_rdata;
    wire c0_dmem_stall, c1_dmem_stall, c2_dmem_stall, c3_dmem_stall;
    wire mem_req_a, mem_req_b, mem_we_a, mem_we_b;
    wire [31:0] mem_addr_a, mem_addr_b, mem_wdata_a, mem_wdata_b, mem_rdata_a, mem_rdata_b;

    // Scheduler Instance
    (* keep_hierarchy = "yes" *) (* dont_touch = "true" *)
    scheduler_with_tcbs scheduler(.clk(clk), .rst(rst), .core_idle(core_idle), .core_fault(core_fault), .core_task_done(core_task_done), .core_enable(core_enable), .core_task_valid(core_task_valid), .core0_task_id(core0_task_id), .core1_task_id(core1_task_id), .core2_task_id(core2_task_id), .core3_task_id(core3_task_id));

    // Core Wrappers
    core_top_wrapper CORE0(.clk(clk), .rst(rst), .core_enable(core_enable[0]), .task_valid(core_task_valid[0]), .task_id(core0_task_id), .imem_addr(c0_imem_addr), .imem_rdata(c0_imem_rdata), .mem_req(c0_mem_req), .mem_we(c0_mem_we), .mem_addr(c0_mem_addr), .mem_wdata(c0_mem_wdata), .mem_rdata(c0_mem_rdata), .arb_stall(c0_imem_stall | c0_dmem_stall), .core_idle(core_idle[0]), .fault(core_fault[0]), .task_done(core_task_done[0]), .pc_out(core0_pc));
    core_top_wrapper CORE1(.clk(clk), .rst(rst), .core_enable(core_enable[1]), .task_valid(core_task_valid[1]), .task_id(core1_task_id), .imem_addr(c1_imem_addr), .imem_rdata(c1_imem_rdata), .mem_req(c1_mem_req), .mem_we(c1_mem_we), .mem_addr(c1_mem_addr), .mem_wdata(c1_mem_wdata), .mem_rdata(c1_mem_rdata), .arb_stall(c1_imem_stall | c1_dmem_stall), .core_idle(core_idle[1]), .fault(core_fault[1]), .task_done(core_task_done[1]), .pc_out(core1_pc));
    core_top_wrapper CORE2(.clk(clk), .rst(rst), .core_enable(core_enable[2]), .task_valid(core_task_valid[2]), .task_id(core2_task_id), .imem_addr(c2_imem_addr), .imem_rdata(c2_imem_rdata), .mem_req(c2_mem_req), .mem_we(c2_mem_we), .mem_addr(c2_mem_addr), .mem_wdata(c2_mem_wdata), .mem_rdata(c2_mem_rdata), .arb_stall(c2_imem_stall | c2_dmem_stall), .core_idle(core_idle[2]), .fault(core_fault[2]), .task_done(core_task_done[2]), .pc_out(core2_pc));
    core_top_wrapper CORE3(.clk(clk), .rst(rst), .core_enable(core_enable[3]), .task_valid(core_task_valid[3]), .task_id(core3_task_id), .imem_addr(c3_imem_addr), .imem_rdata(c3_imem_rdata), .mem_req(c3_mem_req), .mem_we(c3_mem_we), .mem_addr(c3_mem_addr), .mem_wdata(c3_mem_wdata), .mem_rdata(c3_mem_rdata), .arb_stall(c3_imem_stall | c3_dmem_stall), .core_idle(core_idle[3]), .fault(core_fault[3]), .task_done(core_task_done[3]), .pc_out(core3_pc));

    imem_arbiter_4core IMEM_ARB(.clk(clk), .rst(rst), .c0_imem_addr(c0_imem_addr),
     .c1_imem_addr(c1_imem_addr), .c2_imem_addr(c2_imem_addr), .c3_imem_addr(c3_imem_addr),
      .c0_imem_rdata(c0_imem_rdata), .c1_imem_rdata(c1_imem_rdata), .c2_imem_rdata(c2_imem_rdata), 
      .c3_imem_rdata(c3_imem_rdata), .c0_imem_stall(c0_imem_stall), .c1_imem_stall(c1_imem_stall),
       .c2_imem_stall(c2_imem_stall), .c3_imem_stall(c3_imem_stall), .addr_a(imem_addr_a),
        .addr_b(imem_addr_b), .rdata_a(imem_rdata_a), .rdata_b(imem_rdata_b));
        
    instr_mem IMEM(.clk(clk), .rdata_a(imem_rdata_a), .rdata_b(imem_rdata_b), .addr_a(imem_addr_a[12:0]), 
    .addr_b(imem_addr_b[12:0]));

    assign mem_req_a = c0_mem_req | c1_mem_req;
     assign mem_req_b = c2_mem_req | c3_mem_req;
    assign mem_we_a = c0_mem_we | c1_mem_we;
     assign mem_we_b = c2_mem_we | c3_mem_we;
    assign mem_addr_a = c0_mem_req ? c0_mem_addr : c1_mem_addr;
     assign mem_addr_b = c2_mem_req ? c2_mem_addr : c3_mem_addr;
    assign mem_wdata_a = c0_mem_req ? c0_mem_wdata : c1_mem_wdata;
     assign mem_wdata_b = c2_mem_req ? c2_mem_wdata : c3_mem_wdata;

    dmem_arbiter DMEM_ARB(.clk(clk), .rst(rst), .c0_mem_req(c0_mem_req), .c0_mem_we(c0_mem_we),
     .c0_mem_addr(c0_mem_addr), .c0_mem_wdata(c0_mem_wdata), .c0_mem_rdata(c0_mem_rdata),
      .c0_stall(c0_dmem_stall), .c1_mem_req(c1_mem_req), .c1_mem_we(c1_mem_we), 
      .c1_mem_addr(c1_mem_addr), .c1_mem_wdata(c1_mem_wdata), .c1_mem_rdata(c1_mem_rdata),
       .c1_stall(c1_dmem_stall), .c2_mem_req(c2_mem_req), .c2_mem_we(c2_mem_we), 
       .c2_mem_addr(c2_mem_addr), .c2_mem_wdata(c2_mem_wdata), .c2_mem_rdata(c2_mem_rdata),
        .c2_stall(c2_dmem_stall), .c3_mem_req(c3_mem_req), .c3_mem_we(c3_mem_we),
         .c3_mem_addr(c3_mem_addr), .c3_mem_wdata(c3_mem_wdata), .c3_mem_rdata(c3_mem_rdata),
          .c3_stall(c3_dmem_stall), .req_a(mem_req_a), .we_a(mem_we_a), .addr_a(mem_addr_a),
           .wdata_a(mem_wdata_a), .rdata_a(mem_rdata_a), .req_b(mem_req_b), .we_b(mem_we_b),
            .addr_b(mem_addr_b), .wdata_b(mem_wdata_b), .rdata_b(mem_rdata_b));
            
    data_mem DMEM(.clk(clk), .req_a(mem_req_a), .we_a(mem_we_a), .addr_a(mem_addr_a),
     .wdata_a(mem_wdata_a), .rdata_a(mem_rdata_a), .req_b(mem_req_b), .we_b(mem_we_b),
      .addr_b(mem_addr_b), .wdata_b(mem_wdata_b), .rdata_b(mem_rdata_b));

    // Logic & Debug Routing
    assign c0_mem_rdata = mem_rdata_a;
     assign c1_mem_rdata = mem_rdata_a;
    assign c2_mem_rdata = mem_rdata_b; 
    assign c3_mem_rdata = mem_rdata_b;
    assign c0_dmem_stall = 0; 
    assign c1_dmem_stall = 0; 
    assign c2_dmem_stall = 0; 
    assign c3_dmem_stall = 0;
    assign dbg_core_enable = core_enable;
     assign dbg_core_idle = core_idle;
    assign dbg_core_fault = core_fault;
     assign dbg_task_done = core_task_done;
    assign dbg_mem_req = mem_req_a | mem_req_b; 
    assign dbg_mem_we = mem_we_a | mem_we_b;
     assign dbg_mem_addr = mem_addr_a;
endmodule