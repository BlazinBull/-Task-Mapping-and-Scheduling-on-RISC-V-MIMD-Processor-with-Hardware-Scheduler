`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.01.2026 11:23:00
// Design Name: 
// Module Name: nHSE
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

module nHSE(
    input [3:0] crEVi,           // From Event Generator
    // Task Config (these would be set by RISCV processor by storing the values in memory and 
    // we will map these registers onto the data memory (dmem) ).
    input [3:0] crTR0, crTR1, crTR2, crTR3,   //crTRi
    input [3:0] prio0, prio1, prio2, prio3,   //prioi
    output reg [1:0] current_thread_id
);
    wire [3:0] task_ready;
    assign task_ready[0] = |(crEVi & crTR0); //the | operator will bitwise OR, All the bits to produce a single bit  
    assign task_ready[1] = |(crEVi & crTR1); 
    assign task_ready[2] = |(crEVi & crTR2);
    assign task_ready[3] = |(crEVi & crTR3);

    always @(*) begin
        // Default to Task 0 (Idle task)
        current_thread_id = 2'b00;

        // Priority Logic 
        if (task_ready[3] && (prio3 <= prio2) && (prio3 <= prio1) && (prio3 <= prio0)) //NOTE :
            current_thread_id = 2'b11;                                                 //HERE INSTEAD
        else if (task_ready[2] && (prio2 <= prio1) && (prio2 <= prio0))                //OF USING IF
            current_thread_id = 2'b10;                                                 //ELSE
        else if (task_ready[1] && (prio1 <= prio0))                                    //WE CAN USE
            current_thread_id = 2'b01;                                                 //A FOR LOOP
        else                                                                           //TO BUILD A
            current_thread_id = 2'b00;                                                 //dYNAMIC pRIORITY eNCODER(more prof way could be used when no.of threads increases)
                                                                                       //WITH PRIORITIES Alterable.
       // the current thread id will now be used by the simple_core module 
      //  to select the regfile and PC that is selection of appropriate thread or TASK 
    end
endmodule