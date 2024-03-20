`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/07 16:13:57
// Design Name: 
// Module Name: tb_beam_scan
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


module tb_beam_scan;

    // Parameters
    reg clk;
    reg rst_n;
    reg [31:0] tx_interval;
    reg [31:0] tx_frame_length;
    reg scan_Enable;
    reg scan_Pulse;
    reg [7:0] currentScanSlot;
    wire [15:0] bit_out_tdata;
    wire bit_out_tvalid;
    wire tx_rx_sw;
    reg bit_out_tready;
    wire [1:0] bit_out_tkeep;
    wire [1:0] bit_out_tstrb;
    wire bit_out_tlast;
    wire synNode_valid;
    wire [7:0] synNode;
    wire isScanCompleted;

    // Instantiate the Unit Under Test (UUT)
    beam_scan uut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_interval(tx_interval),
        .tx_frame_length(tx_frame_length),
        .scan_Enable(scan_Enable),
        .scan_Pulse(scan_Pulse),
        .currentScanSlot(currentScanSlot),
        .bit_out_tdata(bit_out_tdata),
        .bit_out_tvalid(bit_out_tvalid),
        .tx_rx_sw(tx_rx_sw),
        .bit_out_tready(bit_out_tready),
        .bit_out_tkeep(bit_out_tkeep),
        .bit_out_tstrb(bit_out_tstrb),
        .bit_out_tlast(bit_out_tlast),
        .synNode_valid(synNode_valid),
        .synNode(synNode),
        .isScanCompleted(isScanCompleted)
    );

    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        tx_interval = 32'd400000;
        tx_frame_length = 32'd4800;
        scan_Enable = 0;
        scan_Pulse = 0;
        currentScanSlot = 8'd0;
        bit_out_tready = 0;
        
            
        // Wait for 100 ns
        #400;
        rst_n = 1;
        bit_out_tready = 1;
        scan_Enable = 1;

        // Wait for 100 ns
        #190;
        currentScanSlot = 8'd1;
        scan_Pulse = 1;
        #20;//半个时钟周期
        scan_Pulse = 0;
        #10000;
        
        currentScanSlot = 8'd2;
        scan_Pulse = 1;
        #20;
        scan_Pulse = 0;
        #10000;
        
        scan_Pulse = 1;
        currentScanSlot = 8'd3;
        #20;
        scan_Pulse = 0;
        #10000;
        
        scan_Pulse = 1;
        currentScanSlot = 8'd4;
        #20;
        scan_Pulse = 0;
        #8000;
        
        scan_Pulse = 1;
        currentScanSlot = 8'd5;
        #20;
        scan_Pulse = 0;
        

//        // Wait for 100 ns
//        #2000;
//        scan_Pulse = 1;
//        currentScanSlot = 8'd6;
//        #20;
//        scan_Pulse = 0;
        

//        // Wait for 100 ns
//        #2000;
//        scan_Pulse = 1;
//        currentScanSlot = 8'd7;
//        #20;
//        scan_Pulse = 0;
        

//        // Wait for 100 ns
//        #2000;
//        scan_Pulse = 1;
//        currentScanSlot = 8'd8;
//        #20;
//        scan_Pulse = 0;
        

//        // Wait for 100 ns
//        #2000;
//        scan_Pulse = 1;
//        currentScanSlot = 8'd9;
//        #20;
//        scan_Pulse = 0;
        
        
//        // Wait for 100 ns
//        #2000;
//        scan_Pulse = 1;
//        currentScanSlot = 8'd10;
//        #20;
//        scan_Pulse = 0;
        
        
//        // Wait for 100 ns
//        #2000;
//        scan_Pulse = 1;
//        currentScanSlot = 8'd11;
//        #20;
//        scan_Pulse = 0;
        
        
        // Wait for 100 ns
        #8000;
        scan_Pulse = 1;
        currentScanSlot = 8'd64;
        #20;
        scan_Pulse = 0;
        
        #8000;
        scan_Pulse = 1;
        currentScanSlot = 8'd0;
        #20;
        scan_Pulse = 0;
        
        
        // Wait for 100 ns      
        #400;
    end
    

    always #10 clk = ~clk;

endmodule


