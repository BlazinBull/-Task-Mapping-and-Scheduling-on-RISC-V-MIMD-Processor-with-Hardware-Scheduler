`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.11.2025 00:32:38
// Design Name: 
// Module Name: simple_core
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


// simple_core.v - single-cycle RV32I core (complete)
module simple_core (
    input clk, reset,
    input [3:0] external_inputs,
    output [31:0] dbg_pc, dbg_instr
);
    wire [1:0]current_thread_id; 
    wire [3:0]crEVi;        
    
    reg [31:0] pc_bank [0:3]; 
    wire [31:0] pc = pc_bank[current_thread_id]; // Active PC based on scheduler

    wire [31:0] instr;
    imem imem_inst(.addr(pc), .data(instr));
    wire [31:0] pc_plus4 = pc + 4;

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    // register file
    wire [31:0] rs1_data, rs2_data;
    reg [31:0] wb_data;
    reg rf_we;
    reg [4:0] rf_wa;
    regfile rf(.clk(clk), 
               .we(rf_we),
               .thread_id(current_thread_id), 
               .ra1(rs1), .ra2(rs2), 
               .wa(rf_wa), 
               .wd(wb_data),
               .rd1(rs1_data),.rd2(rs2_data)
    );

    // imm generator
    wire [31:0] imm;
    imm_gen immgen(.instr(instr), .imm_out(imm));

    // Control Unit
    wire [3:0] alu_op;
    wire alu_src;
    wire is_load, is_store, is_branch, is_jal, is_jalr, is_lui, is_auipc;
    wire mem_read, mem_write, rf_write_enable;
    wire ctrl_rf_we, ctrl_mem_read, ctrl_mem_write;
    control_unit ctrl(.opcode(opcode), .funct3(funct3), .funct7(funct7),
                      .alu_op(alu_op), .alu_src(alu_src), .rf_we(ctrl_rf_we),
                      .mem_read(ctrl_mem_read), .mem_write(ctrl_mem_write),
                      .is_load(is_load), .is_store(is_store), .is_branch(is_branch),
                      .is_jal(is_jal), .is_jalr(is_jalr), .is_lui(is_lui), .is_auipc(is_auipc));

    assign rf_write_enable = ctrl_rf_we;
    assign mem_read  = ctrl_mem_read;
    assign mem_write = ctrl_mem_write;

    // ALU
    wire [31:0] alu_in2 = alu_src ? imm : rs2_data;
    wire [31:0] alu_res;
    wire alu_eq, alu_lt_s, alu_lt_u;
    alu main_alu(.a(rs1_data), .b(alu_in2), .alu_op(alu_op), .y(alu_res), .eq(alu_eq), .lt_s(alu_lt_s), .lt_u(alu_lt_u));

    // Data memory
    reg dmem_write;
    reg dmem_read;
    reg [3:0] dmem_be;
    wire [31:0] dmem_rdata;
    dmem dmem_inst(.clk(clk), .be(dmem_be), .write(dmem_write), .read(dmem_read), .addr(alu_res), .wdata(rs2_data), .rdata(dmem_rdata));

    // determine byte enables for store (SB/SH/SW) and set dmem control signals
    always @(*) begin
        dmem_write = 1'b0;
        dmem_read  = 1'b0;
        dmem_be    = 4'b0000;
        if (mem_write) begin
            dmem_write = 1'b1;
            case (funct3)
                3'b000: // SB
                    dmem_be = 4'b0001 << alu_res[1:0];
                3'b001: // SH
                    if (alu_res[1:0] == 2'b00) dmem_be = 4'b0011;
                    else if (alu_res[1:0] == 2'b10) dmem_be = 4'b1100;
                    else dmem_be = 4'b0011; // unaligned fallback
                3'b010: // SW
                    dmem_be = 4'b1111;
                default:
                    dmem_be = 4'b0000;
            endcase
        end
        if (mem_read) begin
            dmem_read = 1'b1;
        end
    end

    // load sign/zero extension logic
    reg [31:0] load_result;
    always @(*) begin
        load_result = 32'd0;
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB
                    case (alu_res[1:0])
                        2'b00: load_result = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
                        2'b01: load_result = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                        2'b10: load_result = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                        2'b11: load_result = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
                    endcase
                end
                3'b001: begin // LH
                    if (alu_res[1] == 1'b0) load_result = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                    else load_result = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
                end
                3'b010: load_result = dmem_rdata; // LW
                3'b100: begin // LBU
                    case (alu_res[1:0])
                        2'b00: load_result = {24'd0, dmem_rdata[7:0]};
                        2'b01: load_result = {24'd0, dmem_rdata[15:8]};
                        2'b10: load_result = {24'd0, dmem_rdata[23:16]};
                        2'b11: load_result = {24'd0, dmem_rdata[31:24]};
                    endcase
                end
                3'b101: begin // LHU
                    if (alu_res[1] == 1'b0) load_result = {16'd0, dmem_rdata[15:0]};
                    else load_result = {16'd0, dmem_rdata[31:16]};
                end
                default: load_result = dmem_rdata;
            endcase
        end
    end

    // write-back selection
    always @(*) begin
        if (is_jal || is_jalr) wb_data = pc_plus4;
        else if (is_lui) wb_data = imm;
        else if (is_auipc) wb_data = pc + imm;
        else if (mem_read) wb_data = load_result;
        else wb_data = alu_res;
    end

    // set register file write signals
    always @(*) begin
        rf_we = rf_write_enable;
        rf_wa = rd;
    end

    // branch/jump decisions & next PC
    wire branch_taken;
    reg beq, bne, blt, bge, bltu, bgeu;
    always @(*) begin
        beq  = (funct3 == 3'b000);
        bne  = (funct3 == 3'b001);
        blt  = (funct3 == 3'b100);
        bge  = (funct3 == 3'b101);
        bltu = (funct3 == 3'b110);
        bgeu = (funct3 == 3'b111);
    end

    assign branch_taken = (is_branch && ((beq  && (rs1_data == rs2_data)) ||
                                         (bne  && (rs1_data != rs2_data)) ||
                                         (blt  && ($signed(rs1_data) < $signed(rs2_data))) ||
                                         (bge  && ($signed(rs1_data) >= $signed(rs2_data))) ||
                                         (bltu && (rs1_data < rs2_data)) ||
                                         (bgeu && (rs1_data >= rs2_data))
                                        ));

    wire [31:0] next_pc_jal  = pc + imm;
    wire [31:0] next_pc_jalr = (rs1_data + imm) & ~32'd1;
    reg [31:0] next_pc;

    always @(*) begin
        if (is_jal) next_pc = next_pc_jal;
        else if (is_jalr) next_pc = next_pc_jalr;
        else if (branch_taken) next_pc = pc + imm;
        else next_pc = pc_plus4;
    end
    //Current thread's program Counter Update
    integer i;                                      //INITIALIZATIONS
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_bank[0] <= 32'h0000_0000; // Task 0 : Management/Idle code
            pc_bank[1] <= 32'h0000_0400; // Task 1
            pc_bank[2] <= 32'h0000_0800; // Task 2
            pc_bank[3] <= 32'h0000_0C00; // Task 3
        end
        else begin
            pc_bank[current_thread_id] <= next_pc; // Only update the running task
        end
    end
    
    // EVENT GENERATOR :
    reg [3:0] cpu_clear_event;
    
    event_generator ev_gen (
        .clk(clk), .reset(reset),
        .external_inputs(external_inputs),
        .clear_events(cpu_clear_event),
        .crEVi(crEVi)
    );    
    /////////////////////////////////////////////////////////////////////////////////  
    //HARDWARE SCHEDULER ENGINE Block :
    reg [3:0] task_triggers [0:3];    //Some registers   THESE ARE MMIO registers(ONTO DMEM)
    reg [3:0] task_priorities [0:3];  //    for
                                      //    nHSE
    
    // wires for decoding the NHSE reg write or DMEM write
    wire is_nhse_addr = (alu_res >= 32'h2000 && alu_res <= 32'h2020);
    wire actual_dmem_write = mem_write && !is_nhse_addr;

    // Writing to nHSE Registers from CPU
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize DEFAULT priorities 
            task_priorities[0] <= 4'hF;  // <= LOWEST
            task_priorities[1] <= 4'h1;  // <= HIGhEST (Small no., HIGH priority)
            task_priorities[2] <= 4'h5;
            task_priorities[3] <= 4'h3;
            cpu_clear_event <= 4'b0;
        end 
        else if (mem_write && is_nhse_addr) begin
            case (alu_res)
                32'h2000: task_triggers[0] <= rs2_data[3:0]; //YOU CAN USE
                32'h2004: task_triggers[1] <= rs2_data[3:0]; //the entire length 
                32'h2008: task_triggers[2] <= rs2_data[3:0]; //of rs2_data from [31:0]
                32'h200C: task_triggers[3] <= rs2_data[3:0]; //That will help reduce no.of cycles (CONTROL WORD kinda)

                32'h2010: task_priorities[0] <= rs2_data[3:0];
                32'h2014: task_priorities[1] <= rs2_data[3:0];
                32'h2018: task_priorities[2] <= rs2_data[3:0];
                32'h201C: task_priorities[3] <= rs2_data[3:0];
                
                32'h2020: cpu_clear_event <= rs2_data[3:0]; // CPU resets the event
            endcase
        end     
        else begin
            cpu_clear_event <= 4'b0; // Pulse only for one cycle
        end
    end
    
    //Connecting these registers to your nHSE instance
    nHSE nHSE_scheduler(
        .crEVi(crEVi),
        .crTR0(task_triggers[0]), .crTR1(task_triggers[1]), .crTR2(task_triggers[2]), .crTR3(task_triggers[3]), 
        .prio0(task_priorities[0]), .prio1(task_priorities[1]),.prio2(task_priorities[2]), .prio3(task_priorities[3]), 
        .current_thread_id(current_thread_id)
    );
    ///////////////////////////////////////////////////////////////////////////////////
    // debug outputs
    assign dbg_pc = pc;
    assign dbg_instr = instr;
endmodule