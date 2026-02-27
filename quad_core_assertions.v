`timescale 1ns / 1ps

// ============================================================
// Quad-Core Assertion Checker (Verilog-2001)
// ============================================================

module quad_core_assertions (
    input wire        clk,
    input wire        rst,

    // Scheduler
    input wire [3:0]  core_enable,
    input wire [3:0]  core_task_valid,

    // IMEM stall signals
    input wire [3:0]  imem_stall,

    // DMEM
    input wire        mem_req,
    input wire [3:0]  dmem_req
);

    integer i;
    integer active_imem;
    integer active_dmem;

    // ========================================================
    // A1: Core must not be enabled without task_valid
    // ========================================================
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (core_enable[i] && !core_task_valid[i]) begin
                    $display("ASSERTION FAIL @%0t: Core %0d enabled without task_valid",
                             $time, i);
                    $stop;
                end
            end
        end
    end

    // ========================================================
    // A2: At most ONE IMEM fetch per cycle
    // (i.e., at most one core NOT stalled)
    // ========================================================
    always @(posedge clk) begin
        if (!rst) begin
            active_imem = 0;
            for (i = 0; i < 4; i = i + 1)
                if (!imem_stall[i])
                    active_imem = active_imem + 1;

            if (active_imem > 1) begin
                $display("ASSERTION FAIL @%0t: Multiple IMEM fetches in same cycle (%0d)",
                         $time, active_imem);
                $stop;
            end
        end
    end

    // ========================================================
    // A3: At most ONE DMEM request per cycle
    // ========================================================
    always @(posedge clk) begin
        if (!rst) begin
            active_dmem = 0;
            for (i = 0; i < 4; i = i + 1)
                if (dmem_req[i])
                    active_dmem = active_dmem + 1;

            if (active_dmem > 1) begin
                $display("ASSERTION FAIL @%0t: Multiple DMEM requests in same cycle (%0d)",
                         $time, active_dmem);
                $stop;
            end
        end
    end

    // ========================================================
    // A4: mem_req must equal OR of core DMEM requests
    // ========================================================
    always @(posedge clk) begin
        if (!rst) begin
            if (mem_req !== (|dmem_req)) begin
                $display("ASSERTION FAIL @%0t: mem_req mismatch (mem_req=%b, cores=%b)",
                         $time, mem_req, dmem_req);
                $stop;
            end
        end
    end

    // ========================================================
    // A5: IMEM-stalled core must not issue DMEM request
    // ========================================================
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (imem_stall[i] && dmem_req[i]) begin
                    $display("ASSERTION FAIL @%0t: Core %0d DMEM request while IMEM-stalled",
                             $time, i);
                    $stop;
                end
            end
        end
    end

endmodule
