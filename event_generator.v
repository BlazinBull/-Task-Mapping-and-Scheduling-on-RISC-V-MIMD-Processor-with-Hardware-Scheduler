`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.01.2026 20:36:42
// Design Name: 
// Module Name: event_generator
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

module event_generator (
    input clk, reset,
    input [3:0] external_inputs, // Physical buttons/sensors
    // input [3:0] timer_interrupts, // From internal timers*
    input [3:0] clear_events,    // From CPU (to reset event after handling)
    output reg [3:0] crEVi// The Event Register
); 
always @(posedge clk or posedge reset) begin
    if (reset) begin
        crEVi<= 4'b0000;
    end else begin
        crEVi<= ~clear_events & (crEVi | external_inputs); // | timer_interrupts);
    end
end
endmodule