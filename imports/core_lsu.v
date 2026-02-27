`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.01.2026 14:50:52
// Design Name: 
// Module Name: core_lsu
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


module core_lsu (
    input  wire [2:0]  funct3,
    input  wire        is_load,
    input  wire        is_store,
    input  wire [31:0] addr,
    input  wire [31:0] store_data,
    input  wire [31:0] mem_rdata,

    output wire        mem_req,
    output wire        mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output reg  [31:0] load_data
);

assign mem_req  = is_load | is_store;
assign mem_we   = is_store;
assign mem_addr = addr;
assign mem_wdata= store_data;

always @(*) begin
    case (funct3)
        3'b000: load_data = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
        3'b001: load_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
        3'b010: load_data = mem_rdata;
        3'b100: load_data = {24'b0, mem_rdata[7:0]};
        3'b101: load_data = {16'b0, mem_rdata[15:0]};
        default: load_data = mem_rdata;
    endcase
end

endmodule

