`timescale 1ns / 1ps
(* keep_hierarchy = "yes" *)

module data_mem (
    input  wire        clk,

    // -------- PORT A --------
    input  wire        req_a,
    input  wire        we_a,
    input  wire [31:0] addr_a,
    input  wire [31:0] wdata_a,
    output reg  [31:0] rdata_a,

    // -------- PORT B --------
    input  wire        req_b,
    input  wire        we_b,
    input  wire [31:0] addr_b,
    input  wire [31:0] wdata_b,
    output reg  [31:0] rdata_b
);

    // 8KB = 2048 x 32-bit words
    (* ram_style = "block" *)
    reg [31:0] mem [0:2047];

         // PORT A
    always @(posedge clk) begin
        if (we_a)
            mem[addr_a[12:2]] <= wdata_a;
        rdata_a <= mem[addr_a[12:2]];
    end

    // PORT B
    always @(posedge clk) begin
        if (we_b)
            mem[addr_b[12:2]] <= wdata_b;
        rdata_b <= mem[addr_b[12:2]];
    end
    

endmodule
