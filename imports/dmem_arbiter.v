`timescale 1ns / 1ps

module dmem_arbiter (
    input  wire        clk,
    input  wire        rst,
    
    input  wire        c0_mem_req, //mem request 
    input  wire        c0_mem_we, // mem write enable
    input  wire [31:0] c0_mem_addr, // mem address
    input  wire [31:0] c0_mem_wdata, //mem_write_data bus
    output reg  [31:0] c0_mem_rdata, // mem read data bus
    output wire        c0_stall,      // stall signal
    
    input  wire        c1_mem_req,
    input  wire        c1_mem_we,
    input  wire [31:0] c1_mem_addr,
    input  wire [31:0] c1_mem_wdata,
    output reg  [31:0] c1_mem_rdata,
    output wire        c1_stall,
    
    input  wire        c2_mem_req,
    input  wire        c2_mem_we,
    input  wire [31:0] c2_mem_addr,
    input  wire [31:0] c2_mem_wdata,
    output reg  [31:0] c2_mem_rdata,
    output wire        c2_stall,
    
    input  wire        c3_mem_req,
    input  wire        c3_mem_we,
    input  wire [31:0] c3_mem_addr,
    input  wire [31:0] c3_mem_wdata,
    output reg  [31:0] c3_mem_rdata,
    output wire        c3_stall,
    
    output reg         req_a,
    output reg         we_a,
    output reg  [31:0] addr_a,
    output reg  [31:0] wdata_a,
    input  wire [31:0] rdata_a,
    
    output reg         req_b,
    output reg         we_b,
    output reg  [31:0] addr_b,
    output reg  [31:0] wdata_b,
    input  wire [31:0] rdata_b
);

    wire grant_a = c0_mem_req;
    assign c0_stall = c0_mem_req & ~grant_a;
    assign c1_stall = c1_mem_req & grant_a;

    always @(posedge clk) begin
        if (grant_a) begin
            req_a <= c0_mem_req;
            we_a <= c0_mem_we;
            addr_a <= c0_mem_addr;
            wdata_a <= c0_mem_wdata;
            c0_mem_rdata <= rdata_a;
        end else begin
            req_a <= c1_mem_req;
            we_a <= c1_mem_we;
            addr_a <= c1_mem_addr;
            wdata_a <= c1_mem_wdata;
            c1_mem_rdata <= rdata_a;
        end
    end

    wire grant_b = c2_mem_req;
    assign c2_stall = c2_mem_req & ~grant_b;
    assign c3_stall = c3_mem_req & grant_b;

    always @(posedge clk) begin
        if (grant_b) begin
            req_b <= c2_mem_req;
            we_b <= c2_mem_we;
            addr_b <= c2_mem_addr;
            wdata_b <= c2_mem_wdata;
            c2_mem_rdata <= rdata_b;
        end else begin
            req_b <= c3_mem_req;
            we_b <= c3_mem_we;
            addr_b <= c3_mem_addr;
            wdata_b <= c3_mem_wdata;
            c3_mem_rdata <= rdata_b;
        end
    end

endmodule