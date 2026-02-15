`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 00:30:38
// Design Name: 
// Module Name: imem
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


// imem.v
module imem #(parameter DEPTH = 1024)(
input  [31:0] addr,   
  output [31:0] data
);
reg [31:0] mem [0:DEPTH-1];

initial begin
        // This command looks for the text file and fills the 'mem' array
        $readmemh("imem.txt", mem);
    end
assign data = mem[addr[31:2]];
endmodule

