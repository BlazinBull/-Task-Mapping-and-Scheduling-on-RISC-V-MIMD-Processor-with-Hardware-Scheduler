`timescale 1ns / 1ps
(* keep_hierarchy = "yes" *)
module imem_arbiter_4core (
    input wire clk, rst,
    input wire [31:0] c0_imem_addr, c1_imem_addr, c2_imem_addr, c3_imem_addr,
    output reg [31:0] c0_imem_rdata, c1_imem_rdata, c2_imem_rdata, c3_imem_rdata,
    output reg c0_imem_stall, c1_imem_stall, c2_imem_stall, c3_imem_stall,
    output reg [31:0] addr_a, addr_b, input wire [31:0] rdata_a, rdata_b
);

    reg phase, phase_d;
    reg [1:0] owner_a, owner_b, owner_a_d, owner_b_d;
    reg [3:0] fairness_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin phase <= 1'b0; fairness_counter <= 4'd0; end
        else begin phase <= ~phase; fairness_counter <= fairness_counter + 1'b1; end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin addr_a <= 0; addr_b <= 0; owner_a <= 2'd0; owner_b <= 2'd1; end
        
        else if (phase == 1'b0) begin 
            addr_a <= c0_imem_addr; 
            addr_b <= c1_imem_addr;
            
            owner_a <= 2'd0;
            owner_b <= 2'd1; end
            
        else begin 
            addr_a <= c2_imem_addr; 
            addr_b <= c3_imem_addr; 
            
            owner_a <= 2'd2; 
            owner_b <= 2'd3; end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin 
        owner_a_d <= 2'd0; 
        owner_b_d <= 2'd1; 
        phase_d <= 1'b0; end
        
        else begin 
        owner_a_d <= owner_a; 
        owner_b_d <= owner_b; 
        phase_d <= phase; end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin 
        c0_imem_rdata <= 32'h13; 
        c1_imem_rdata <= 32'h13; 
        c2_imem_rdata <= 32'h13; 
        c3_imem_rdata <= 32'h13; end
        else begin
            case (owner_a_d) 
            2'd0: c0_imem_rdata <= rdata_a;
            2'd1: c1_imem_rdata <= rdata_a; 
            2'd2: c2_imem_rdata <= rdata_a; 
            2'd3: c3_imem_rdata <= rdata_a; endcase
            
            case (owner_b_d) 
            2'd0: c0_imem_rdata <= rdata_b;
            2'd1: c1_imem_rdata <= rdata_b; 
            2'd2: c2_imem_rdata <= rdata_b; 
            2'd3: c3_imem_rdata <= rdata_b; endcase
        end
    end

    always @(*) begin
        c0_imem_stall = 1'b1; 
        c1_imem_stall = 1'b1; 
        c2_imem_stall = 1'b1; 
        c3_imem_stall = 1'b1;
        
        if (phase == 1'b0) begin 
            c0_imem_stall = 1'b0; 
            c1_imem_stall = 1'b0; end
        else begin 
            c2_imem_stall = 1'b0; 
            c3_imem_stall = 1'b0; end
    end
endmodule