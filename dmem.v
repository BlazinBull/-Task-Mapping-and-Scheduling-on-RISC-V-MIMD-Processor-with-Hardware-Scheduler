`timescale 1ns / 1ps
module dmem #(parameter DEPTH = 512 )(
input clk, write,read,
input [3:0] be,       
input [31:0] addr,wdata,   
output [31:0] rdata
);
    reg [7:0] mem [0:(DEPTH*4)-1];
    integer i;
    initial for (i=0;i<DEPTH*4;i=i+1) mem[i] = 8'h00;

    always @(posedge clk) begin
        if (write) begin
            if (be[0]) mem[addr + 0] <= wdata[7:0];
            if (be[1]) mem[addr + 1] <= wdata[15:8];
            if (be[2]) mem[addr + 2] <= wdata[23:16];
            if (be[3]) mem[addr + 3] <= wdata[31:24];
        end
    end

    wire [7:0] b0 = mem[addr + 0];
    wire [7:0] b1 = mem[addr + 1];
    wire [7:0] b2 = mem[addr + 2];
    wire [7:0] b3 = mem[addr + 3];
    assign rdata = {b3, b2, b1, b0};
endmodule
