`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 00:29:49
// Design Name: 
// Module Name: regfile
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


// regfile.v
module regfile # (parameter nTHREAD = 4)(
input clk,we,               // we : write enable
input [1:0]thread_id,
input [4:0] ra1,ra2,wa,     // wa : write address ,  ra1 : read address 1 (ADdress of the register on which R/W op takes place)
input [31:0] wd,            // wd : write data
output [31:0] rd1, rd2
);
    reg [31:0] regs [0:nTHREAD-1][31:0];
    integer i;
    initial begin
        for (i=0;i<32;i=i+1) regs[thread_id][i] = 32'd0;
    end

assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[thread_id][ra1];
assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[thread_id][ra2];

    always @(posedge clk) begin
        if (we && wa != 5'd0) regs[thread_id][wa] <= wd;
    end
endmodule
