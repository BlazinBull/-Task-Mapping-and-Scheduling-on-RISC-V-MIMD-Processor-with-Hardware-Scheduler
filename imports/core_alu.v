`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 14:45:31
// Design Name: 
// Module Name: core_alu
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


module core_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] y
);

always @(*) begin
    case (alu_op)
        4'b0000: y = a + b;
        4'b0001: y = a - b;
        4'b0010: y = a << b[4:0];
        4'b0011: y = ($signed(a) < $signed(b));
        4'b0100: y = (a < b);
        4'b0101: y = a ^ b;
        4'b0110: y = a >> b[4:0];
        4'b0111: y = $signed(a) >>> b[4:0];
        4'b1000: y = a | b;
        4'b1001: y = a & b;
        default: y = 32'b0;
    endcase
end

endmodule
