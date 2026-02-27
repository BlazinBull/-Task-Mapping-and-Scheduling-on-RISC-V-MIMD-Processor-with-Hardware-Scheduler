`timescale 1ns / 1ps
(* keep_hierarchy = "yes" *)
module instr_mem (
    input  wire        clk,

    input  wire [31:0] addr_a,
    output reg  [31:0] rdata_a,

    input  wire [31:0] addr_b,
    output reg  [31:0] rdata_b
);

    (* ram_style = "block" *)
    reg [31:0] mem [0:2047];   // 8KB

    always @(posedge clk) begin
        rdata_a <= mem[addr_a[12:2]];
        rdata_b <= mem[addr_b[12:2]];
    end

endmodule
