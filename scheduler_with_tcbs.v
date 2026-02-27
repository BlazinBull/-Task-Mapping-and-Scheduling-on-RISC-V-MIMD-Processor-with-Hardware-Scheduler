`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)

module scheduler_with_tcbs (
    input wire clk, rst, [3:0] core_idle, core_fault, core_task_done,
    output reg [3:0] core_enable, core_task_valid, 
    output reg [1:0] core0_task_id, core1_task_id, core2_task_id, core3_task_id
);
    localparam TASK_READY = 2'b00, TASK_RUNNING = 2'b01, TASK_ISOLATED = 2'b11, FAULT_NONE = 2'b00, FAULT_CRIT = 2'b01, FAULT_ISO = 2'b10;
    
    reg [1:0] tcb_state [0:3], tcb_fault [0:3]; 
    reg [3:0] tcb_fault_cnt [0:3], tcb_base_prio [0:3], tcb_running_mask [0:3]; 
    reg [4:0] tcb_eff_prio [0:3];
    
// RESET
integer i;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tcb_base_prio[0] <= 4'd8;
        tcb_base_prio[1] <= 4'd6;
        tcb_base_prio[2] <= 4'd4;
        tcb_base_prio[3] <= 4'd2;

        for (i = 0; i < 4; i = i + 1) begin
            tcb_state[i]         <= TASK_READY;
            tcb_fault[i]         <= FAULT_NONE;
            tcb_fault_cnt[i]      <= 4'd0;
            tcb_running_mask[i]  <= 4'b0000;
        end
    end
end

// FAULT HANDLING
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 4; i = i + 1) begin
            if ((tcb_running_mask[i] & core_fault) != 4'b0000) begin
                tcb_fault_cnt[i] <= tcb_fault_cnt[i] + 1'b1;

                if (tcb_fault_cnt[i] >= 4'd3) begin
                    tcb_fault[i] <= FAULT_ISO;
                    tcb_state[i] <= TASK_ISOLATED;
                end else begin
                    tcb_fault[i] <= FAULT_CRIT;
                end
            end
        end
    end
end

// EFFECTIVE PRIORITY (PARALLEL HARDWARE)
always @(*) begin
    tcb_eff_prio[0] = (tcb_fault[0] == FAULT_NONE) ? tcb_base_prio[0] :
                       (tcb_fault[0] == FAULT_CRIT) ? tcb_base_prio[0] + 4'd7 : 5'd0;

    tcb_eff_prio[1] = (tcb_fault[1] == FAULT_NONE) ? tcb_base_prio[1] :
                       (tcb_fault[1] == FAULT_CRIT) ? tcb_base_prio[1] + 4'd7 : 5'd0;

    tcb_eff_prio[2] = (tcb_fault[2] == FAULT_NONE) ? tcb_base_prio[2] :
                       (tcb_fault[2] == FAULT_CRIT) ? tcb_base_prio[2] + 4'd7 : 5'd0;

    tcb_eff_prio[3] = (tcb_fault[3] == FAULT_NONE) ? tcb_base_prio[3] :
                       (tcb_fault[3] == FAULT_CRIT) ? tcb_base_prio[3] + 4'd7 : 5'd0;
end

// TASK COMPLETION
always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 4; i = i + 1) begin
            if ((tcb_running_mask[i] & core_task_done) != 4'b0000) begin
                tcb_state[i]        <= TASK_READY;
                tcb_running_mask[i] <= 4'b0000;
            end
        end
    end
end

wire t0_valid = (tcb_state[0] == TASK_READY) && (tcb_fault[0] != FAULT_ISO) && (tcb_running_mask[0] == 4'b0000);
wire t1_valid = (tcb_state[1] == TASK_READY) && (tcb_fault[1] != FAULT_ISO) && (tcb_running_mask[1] == 4'b0000);
wire t2_valid = (tcb_state[2] == TASK_READY) && (tcb_fault[2] != FAULT_ISO) && (tcb_running_mask[2] == 4'b0000);
wire t3_valid = (tcb_state[3] == TASK_READY) && (tcb_fault[3] != FAULT_ISO) && (tcb_running_mask[3] == 4'b0000);

wire [1:0] best01 = (tcb_eff_prio[0] >= tcb_eff_prio[1]) ? 2'd0 : 2'd1;
wire [1:0] best23 = (tcb_eff_prio[2] >= tcb_eff_prio[3]) ? 2'd2 : 2'd3;

wire [1:0] global_best =
    (tcb_eff_prio[best01] >= tcb_eff_prio[best23]) ? best01 : best23;

// CORE ASSIGNMENT (FORCES DECODE LOGIC)
always @(*) begin

    core_enable     = 4'b0000;
    core_task_valid = 4'b0000;

    core0_task_id = global_best;
    core1_task_id = global_best;
    core2_task_id = global_best;
    core3_task_id = global_best;

    if (core_idle[0] && t0_valid) begin
        core_enable[0]     = 1'b1;
        core_task_valid[0] = 1'b1;
    end

    if (core_idle[1] && t1_valid) begin
        core_enable[1]     = 1'b1;
        core_task_valid[1] = 1'b1;
    end

    if (core_idle[2] && t2_valid) begin
        core_enable[2]     = 1'b1;
        core_task_valid[2] = 1'b1;
    end

    if (core_idle[3] && t3_valid) begin
        core_enable[3]     = 1'b1;
        core_task_valid[3] = 1'b1;
    end

end

// DISPATCH
always @(posedge clk) begin
    if (!rst) begin
        if (core_task_valid[0]) begin
            tcb_state[core0_task_id] <= TASK_RUNNING;
            tcb_running_mask[core0_task_id][0] <= 1'b1;
        end
        if (core_task_valid[1]) begin
            tcb_state[core1_task_id] <= TASK_RUNNING;
            tcb_running_mask[core1_task_id][1] <= 1'b1;
        end
        if (core_task_valid[2]) begin
            tcb_state[core2_task_id] <= TASK_RUNNING;
            tcb_running_mask[core2_task_id][2] <= 1'b1;
        end
        if (core_task_valid[3]) begin
            tcb_state[core3_task_id] <= TASK_RUNNING;
            tcb_running_mask[core3_task_id][3] <= 1'b1;
        end
    end
end

endmodule
