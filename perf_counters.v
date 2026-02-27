module perf_counters (
    input  wire        clk,
    input  wire        rst,

    // -------- REQUIRED (THIS WAS MISSING) ----------
    input  wire [3:0]  core_task_done,

    // Stall indicators
    input  wire [3:0]  imem_stall,
    input  wire [3:0]  dmem_stall,

    // Global
    output reg [31:0]  cycle_count,

    // Per-core retired counters
    output reg [31:0]  instr_retired_0,
    output reg [31:0]  instr_retired_1,
    output reg [31:0]  instr_retired_2,
    output reg [31:0]  instr_retired_3,

    // Per-core IMEM stall counters
    output reg [31:0]  imem_stall_0,
    output reg [31:0]  imem_stall_1,
    output reg [31:0]  imem_stall_2,
    output reg [31:0]  imem_stall_3,

    // Per-core DMEM stall counters
    output reg [31:0]  dmem_stall_0,
    output reg [31:0]  dmem_stall_1,
    output reg [31:0]  dmem_stall_2,
    output reg [31:0]  dmem_stall_3
);

    // ------------------------------------------------
    // Cycle counter
    // ------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            cycle_count <= 32'd0;
        else
            cycle_count <= cycle_count + 1'b1;
    end

    // ------------------------------------------------
    // Per-core counters
    // ------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_retired_0 <= 0; instr_retired_1 <= 0;
            instr_retired_2 <= 0; instr_retired_3 <= 0;

            imem_stall_0 <= 0; imem_stall_1 <= 0;
            imem_stall_2 <= 0; imem_stall_3 <= 0;

            dmem_stall_0 <= 0; dmem_stall_1 <= 0;
            dmem_stall_2 <= 0; dmem_stall_3 <= 0;
        end else begin
            if (core_task_done[0]) instr_retired_0 <= instr_retired_0 + 1;
            if (core_task_done[1]) instr_retired_1 <= instr_retired_1 + 1;
            if (core_task_done[2]) instr_retired_2 <= instr_retired_2 + 1;
            if (core_task_done[3]) instr_retired_3 <= instr_retired_3 + 1;

            if (imem_stall[0]) imem_stall_0 <= imem_stall_0 + 1;
            if (imem_stall[1]) imem_stall_1 <= imem_stall_1 + 1;
            if (imem_stall[2]) imem_stall_2 <= imem_stall_2 + 1;
            if (imem_stall[3]) imem_stall_3 <= imem_stall_3 + 1;

            if (dmem_stall[0]) dmem_stall_0 <= dmem_stall_0 + 1;
            if (dmem_stall[1]) dmem_stall_1 <= dmem_stall_1 + 1;
            if (dmem_stall[2]) dmem_stall_2 <= dmem_stall_2 + 1;
            if (dmem_stall[3]) dmem_stall_3 <= dmem_stall_3 + 1;
        end
    end

endmodule
