`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.01.2026 10:10:54
// Design Name: 
// Module Name: top_module
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


module top_module(
    input clk, reset,
    input [3:0] physical_buttons
    );
    
    wire [31:0] instr,pc;
    // The Integrated Core
    simple_core core (
        .clk(clk),
        .reset(reset),
        .external_inputs(physical_buttons),
        .dbg_pc(pc),
        .dbg_instr(instr)
    );

//    // Instruction Memory (Contains the code for all tasks)
//    imem instruction_mem (
//        .addr(pc),
//        .data(instr)
//    );
endmodule
