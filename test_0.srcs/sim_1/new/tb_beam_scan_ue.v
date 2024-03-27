`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/13 11:19:38
// Design Name: 
// Module Name: tb_beam_scan_ue
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
module tb_beam_scan_ue;
    reg clk;
    reg rst_n;
    
    reg [31:0] tx_interval;
    reg [31:0] tx_frame_length;
    
    reg scan_Enable;
    reg scan_Pulse;
    reg [7:0] currentScanSlot;
    
    wire [15:0] bit_out_tdata;
    wire [7:0] tx_segment;
//    wire send_data;
    wire bit_out_tvalid;
    reg bit_out_tready;
    wire [1:0] bit_out_tkeep;
    wire [1:0] bit_out_tstrb;
    wire bit_out_tlast;
    
    wire rx_state;
    wire tx_state;
    wire beam_state;
    wire bf_rst;// BF_RST将索引重置为预编程的默认值=0
    wire bf_inc;
    wire bf_rtn; // BF_INC指数加1
    
    //测试接口
    
    wire [7:0] out_user_beam;// 存储每个用户的波束号
    wire [15:0] out_user_snr;
    wire pause_state;
    
    wire [31:0] counter;
    
    wire [7:0] tx_cnt;
    wire [15:0]data_rx;
    wire [7:0] rx_cnt;
    
    wire [7:0] rx_segment;
    reg [15:0] bit_in_tdata;
    reg bit_in_tvalid;
    wire bit_in_tready;
    reg [1:0] bit_in_tkeep;
    reg [1:0] bit_in_tstrb;
    reg bit_in_tlast;
    
    wire synNode_valid;
    wire [7:0] synNode;
    
    wire isScanCompleted;
    
    wire tx_rx_sw;
    
    reg SNR;
    
    beam_scan uut (
        .clk(clk), .rst_n(rst_n), .tx_interval(tx_interval), .tx_frame_length(tx_frame_length),
        .scan_Enable(scan_Enable), .scan_Pulse(scan_Pulse), .currentScanSlot(currentScanSlot),
        .bit_out_tdata(bit_out_tdata), .bit_out_tvalid(bit_out_tvalid), .bit_out_tready(bit_out_tready),
        .bit_out_tkeep(bit_out_tkeep), .bit_out_tstrb(bit_out_tstrb), .bit_out_tlast(bit_out_tlast),
        .data_rx(data_rx),
//        .send_data(send_data),
        .tx_cnt(tx_cnt),
        .rx_cnt(rx_cnt),
        .tx_state(tx_state),
        .rx_state(rx_state),
        .beam_state(beam_state),
        .bf_rst(bf_rst), // BF_RST将索引重置为预编程的默认值=0
        .bf_rtn(bf_rtn), // BF_INC指数加1
        .bf_inc(bf_inc),
        .out_user_beam(out_user_beam),// 存储每个用户的波束号
        .out_user_snr(out_user_snr),
        .counter(counter),
        .pause_state(pause_state), // 新增的状态变量，1为暂停，0为发送
        .rx_segment(rx_segment),
        .tx_segment(tx_segment),
        .bit_in_tdata(bit_in_tdata), .bit_in_tvalid(bit_in_tvalid), .bit_in_tready(bit_in_tready),
        .bit_in_tkeep(bit_in_tkeep), .bit_in_tstrb(bit_in_tstrb), .bit_in_tlast(bit_in_tlast),
        .synNode_valid(synNode_valid), .synNode(synNode), .isScanCompleted(isScanCompleted), .tx_rx_sw(tx_rx_sw),
        .SNR(SNR)
    );
    integer i,j;
    // Add your test logic here
    initial begin
        // Initialize the inputs
        clk = 0;
        rst_n = 0;
        tx_interval = 32'd400000;
        tx_frame_length = 32'd4800;
        scan_Enable = 0;
        scan_Pulse = 0;
        currentScanSlot = 8'd0;
        bit_out_tready = 0;
        bit_in_tdata = 16'hABCD;
        bit_in_tvalid = 0;
        bit_in_tkeep = 2'b00;
        bit_in_tstrb = 2'b00;
        bit_in_tlast = 0;
        SNR = 0;
        #400;
        rst_n = 1;
        bit_out_tready = 1;
        scan_Enable = 1;
        #190;
        // Start sending and receiving data
        for (currentScanSlot = 0; currentScanSlot < 64; currentScanSlot = currentScanSlot + 1) begin
            // Trigger the scan pulse
//            #190 scan_Pulse = 1;
            scan_Pulse = 1;
//            bit_in_tdata = 2; bit_in_tvalid = 1; bit_in_tkeep = 2'b11; bit_in_tstrb = 2'b00; bit_in_tlast = 0;
            #20
            scan_Pulse = 0;
            // Send and receive data 64 times within one slot
            for (i = 0; i < 64; i = i + 1) begin
                #100; // Wait for the data to be transmitted
                for(j = 2; j < 8; j = j + 1)begin
                    bit_in_tdata = j; bit_in_tvalid = 1; bit_in_tkeep = 2'b11; bit_in_tstrb = 2'b00; bit_in_tlast = 0;
                    #20;
                end                                         
                bit_in_tdata = 16'hABCD;
                bit_in_tvalid = 0;
                #120;                
//              #40;
            end
//            #100; // Wait for the next slot
        end
    end
    always #10 clk = ~clk;
endmodule