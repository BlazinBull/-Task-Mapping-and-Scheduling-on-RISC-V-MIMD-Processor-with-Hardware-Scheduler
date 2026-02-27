`timescale 1ns / 1ps

module core_pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        pc_sel,      // 1 = use pc_next
    input  wire [31:0] pc_next,     // branch/jump target
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'd0;
        end
        else if (!stall) begin
            if (pc_sel)
                pc <= pc_next;
            else
                pc <= pc + 32'd4;
        end
        // else: stall → hold PC
    end

endmodule
