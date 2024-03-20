`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/06 17:21:00
// Design Name: 
// Module Name: tb_tx_ofdm_bit_axis_rom
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

module tb_tx_ofdm_bit_axis_rom;

    // Parameters
    reg clk;
    reg rst_n;
    reg [31:0] tx_interval;
    reg [31:0] tx_frame_length;
    reg [95:0] tx_data;
    wire [15:0] bit_out_tdata;
    wire bit_out_tvalid;
    reg bit_out_tready;
    wire [1:0] bit_out_tkeep;
    wire [1:0] bit_out_tstrb;
    wire bit_out_tlast;
    wire [31:0] cnt_tlast;
    wire [31:0] cnt_point_transed;

    // Instantiate the Unit Under Test (UUT)
    tx_ofdm_bit_axis_rom uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_interval(tx_interval),
        .tx_frame_length(tx_frame_length),
        .tx_data(tx_data),
        .bit_out_tdata(bit_out_tdata),
        .bit_out_tvalid(bit_out_tvalid),
        .bit_out_tready(bit_out_tready),
        .bit_out_tkeep(bit_out_tkeep),
        .bit_out_tstrb(bit_out_tstrb),
        .bit_out_tlast(bit_out_tlast),
        .cnt_tlast(cnt_tlast),
        .cnt_point_transed(cnt_point_transed)
    );

    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        tx_interval = 32'd400000;
        tx_frame_length = 32'd9600;
        tx_data = 96'h123456789ABCDEF012345678;
        bit_out_tready = 0;

        // Wait for 100 ns
        #100;
        rst_n = 1;
        bit_out_tready = 1;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 0;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 1;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 0;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 1;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 0;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 1;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 0;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 1;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 0;

//        // Wait for 100 ns
//        #100;
//        bit_out_tready = 1;

//        // Wait for 100 ns
//        #100;
    end

    always #10 clk = ~clk;

endmodule
