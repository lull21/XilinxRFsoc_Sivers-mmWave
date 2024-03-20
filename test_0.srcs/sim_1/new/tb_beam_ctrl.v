`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/07 10:02:18
// Design Name: 
// Module Name: tb_beam_ctrl
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


`timescale 1ns / 1ps

module tb_beam_ctrl;

    // Parameters
    reg clk;
    reg rst;
    wire BF_RST;
    wire BF_RTN;
    wire BF_INC;

    // Instantiate the Unit Under Test (UUT)
    beam_ctrl uut (
        .clk(clk),
        .rst(rst),
        .BF_RST(BF_RST),
        .BF_RTN(BF_RTN),
        .BF_INC(BF_INC)
    );

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;

        // Wait for 100 ns
        #100;
        rst = 1;

        // Wait for 100 ns
        #100;
        rst = 0;

        // Wait for 100 ns
        #100;
        rst = 1;

        // Wait for 100 ns
        #100;
        rst = 0;

        // Wait for 100 ns
        #100;
        rst = 1;

        // Wait for 100 ns
        #100;
        rst = 0;

        // Wait for 100 ns
        #100;
        rst = 1;

        // Wait for 100 ns
        #100;
        rst = 0;

        // Wait for 100 ns
        #100;
        rst = 1;

        // Wait for 100 ns
        #100;
        rst = 0;

        // Wait for 100 ns
        #100;
        rst = 1;

        // Wait for 100 ns
        #100;
    end

    always #1.25 clk = ~clk;

endmodule

