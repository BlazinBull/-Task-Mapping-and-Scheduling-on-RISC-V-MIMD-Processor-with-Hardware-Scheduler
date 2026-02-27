`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module core_top_wrapper (
    input  wire        clk,
    input  wire        rst,
    input  wire        core_enable,
    input  wire        task_valid,
    input  wire [1:0]  task_id,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    output wire        mem_req,
    output wire        mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input  wire [31:0] mem_rdata,
    input  wire        arb_stall,
    output reg         core_idle,
    output reg         fault,
    output reg         task_done,
    output wire [31:0] pc_out
);

    // Stall Control
wire combined_stall = arb_stall | ~core_enable;

    // Real Core
    wire [31:0] core_pc;

core_top CORE (.clk(clk), .rst(rst), .imem_addr(imem_addr), .imem_rdata(imem_rdata), .mem_req(mem_req), .mem_we(mem_we), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_rdata(mem_rdata), .stall(combined_stall), .pc_out(core_pc));

    assign pc_out = core_pc;

    reg [31:0] instr_reg;
    always @(posedge clk)
        instr_reg <= imem_rdata;

    // Execution State Machine
    reg        running;
    reg [6:0]  exec_count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running    <= 1'b0;
            exec_count <= 7'd0;
            task_done  <= 1'b0;
            fault      <= 1'b0;
        end
        else begin

            task_done <= 1'b0;
            fault     <= 1'b0;

            if (!running && core_enable && task_valid) begin
                running    <= 1'b1;
                exec_count <= 7'd0;
            end

            // Execute task
            else if (running && core_enable && !combined_stall) begin

                // IMEM + task_id influence execution time
                exec_count <= exec_count
                              + instr_reg[2:0]
                              + core_pc[3:0]
                              + 1;

                if (exec_count >= 7'd96) begin
                    running   <= 1'b0;
                    task_done <= 1'b1;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            core_idle <= 1'b1;
        else
            core_idle <= ~running;
    end
assign mem_req  = running & core_enable;
assign mem_we   = task_id[0];
assign mem_addr = core_pc;
assign mem_wdata = instr_reg ^ {30'b0, task_id};

endmodule
