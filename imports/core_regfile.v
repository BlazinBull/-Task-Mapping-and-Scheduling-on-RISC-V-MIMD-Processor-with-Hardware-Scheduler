`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 14:44:41
// Design Name: 
// Module Name: core_regfile
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
//////////////////////////////////////////////////////////////////////////////////

module core_regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

reg [31:0] regs [0:31];

assign rd1 = (rs1 != 0) ? regs[rs1] : 32'b0;
assign rd2 = (rs2 != 0) ? regs[rs2] : 32'b0;

always @(posedge clk)
    if (we && rd != 0)
        regs[rd] <= wd;

endmodule

