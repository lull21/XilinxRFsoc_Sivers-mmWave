`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: XidianUniversity
// Engineer: 2hang1iang
// 
// Create Date: 2024/04/07 09:45:52
// Design Name: 
// Module Name: beam_scan_v2
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
`include "header.vh"
module beam_scan_v2(
    input wire clk,
    input wire rst_n,
        
    input wire  [31:0] tx_interval,
    input wire  [31:0] tx_frame_length,
    
    input wire scan_Enable, // 标志当前为扫描调度阶段
    input wire scan_Pulse,  // 触发扫描调度过程，在每个扫描时隙起始时刻给出
    input wire  [7:0] currentScanSlot,  //当前扫描时隙，可以通过此时时隙号来确定当前波束索引
    
    //此部分为发送数据接口
    //对于基站：发送广播信号包含波束信息
    //对于用户：向基站反馈信息: (1)一个时隙内，每接收到一帧的数据，反馈当前波束对应的信噪比
    //                        （2）
    output wire [15:0] bit_out_tdata,
    output wire        bit_out_tvalid,
    input  wire        bit_out_tready,
    output wire  [1:0] bit_out_tkeep,
    output wire  [1:0] bit_out_tstrb,
    output reg         bit_out_tlast,
    
    //此部分为接收数据接口
    //对于基站：在一个时隙内，每广播一个波束信息立刻转为接收状态，接收不同用户反馈每一个波束信号数据的信噪比，并在一个时隙完成后进行判断
    //对于用户：接收到基站的每一个波束信号数据后立马反馈当前波束信息的信噪比，同时用户要存储信噪比最高的
    input  wire [15:0] bit_in_tdata,
    input  wire        bit_in_tvalid,
    output wire        bit_in_tready,
    input  wire  [1:0] bit_in_tkeep,
    input  wire  [1:0] bit_in_tstrb,
    input  wire        bit_in_tlast,
    
    output wire synNode_valid,
    output wire [7:0] synNode,
    output wire isScanCompleted,
    
    input  wire SNR, //输入信号信噪比
    
    output reg [7:0]  out_user_beam,// 存储每个用户的波束号
    output reg [15:0] out_user_snr,  // 存储每个用户的信噪比
    
    output reg [15:0] data_rx,
    output reg pause_state, // 新增的状态变量，基站：1为暂停，0为发送，用户：1为暂停，0为发送
    output reg [15:0]  tx_segment,
    output reg [15:0]  rx_segment,
    
    output reg [15:0] tx_cnt,
    output reg [15:0] rx_cnt,
    
    output reg [31:0] cnt_tlast,
    output reg [31:0] cnt_point_transed,
    
//    output reg [31:0] counter = 0,
    
//    output reg send_data,
    output reg [31:0] pause_counter,
    
    output wire tx_rx_sw, //RX模式(TX_RX_SW=0)或TX模式(TX_RX_SW=1)
    output reg beam_state,//1为调整 
    output reg rx_state, //1为接收
    output reg tx_state, //1为发送
    
    output reg bf_rst, // BF_RST将索引重置为预编程的默认值=0  bs-> reg  ue->wire
    output reg bf_rtn, // BF_INC指数加1
    output reg bf_inc  // BF_RTN将索引临时设置为预编程的默认值
    
    );
    parameter [15:0] PAUSE_TIME = 16'd4799;
    parameter [15:0] BEAM_TIME  = 16'd9599;
    
//    reg [15:0] data_rx;
//    reg pause_state;
    
//    reg [7:0]  out_user_beam;// 存储每个用户的波束号
//    reg [15:0] out_user_snr;
    
    // 假设有个初始状态标志，表示是否为一轮新的发送的开始
    reg init_state = 1'b1; 
    
    reg [31:0] counter = 0;
    
    reg [7:0] beam_index [63:0]; //// 这有问题 Array to store the beam numbers,前面是每个寄存器大小，后面是有多少寄存器
    reg [7:0] beam_count = 0; // Counter for the beam numbers
    
//    reg [7:0] tx_cnt;
//    reg [7:0] rx_cnt;
    
//    reg [31:0] cnt_tlast; 
//    reg [31:0] cnt_point_transed;
    
    reg send_data;
    
//    reg beam_state;//1为调整 
//    reg rx_state; //1为接收
//    reg tx_state; //1为发送
    
//    reg [7:0]  tx_segment = 0; 
    reg [76799:0] tx_data; // Data to be transmitted
    reg [76799:0] rx_data; // 存储接收到的数据
//    reg [7:0]  rx_segment = 0; // 存储接收数据的段号
    
//    reg send_data; // Flag to control data transmission
    
    reg [7:0]  best_bs_beam; // 存储最佳基站的波束
    reg [7:0]  best_user_beam;//// 存储最佳用户的波束
    reg [15:0] best_snr; // 存储最佳波束的信噪比
    
    integer i;
    
//    reg [31:0] pause_counter = 0; // 新增的计数器 //4.1 20:23 删除cnt相关代码
//    reg [31:0] counter = 0;
//    reg pause_state; // 新增的状态变量，1为暂停，0为发送
//    reg [7:0] tx_cnt = 0;
//    reg [7:0] rx_cnt = 0;
    
    `ifdef NODE_BS
        // 基站接收数据的逻辑       
        reg [7:0] user_beam [63:0]; // 存储每个用户的波束号
        reg [15:0] bs_snr [63:0]; // 存储每个发送波束的信噪比
//        reg beam_state;//波束调整周期 在一次发送接收完成后预留时间进行波束调整 为1时调整  为0时不调整
    `endif
    
    `ifdef NODE_BS  //基站端:准备发送数据\接收数据  基站部分别再动
        always @(posedge clk or posedge scan_Pulse) begin
            if (rst_n == 1'b0) begin
                cnt_point_transed <= 32'd0;
                cnt_tlast         <= 32'd0;
                
                tx_segment <= 16'd0;   tx_data <= 0;
                rx_segment <= 16'd0;   rx_data <= 0;
                
                send_data  <= 1'b0; 
                pause_counter <= 32'd0;  pause_state <= 1'b0;
                best_snr <= 16'd0;
                
                beam_state <= 1'b0;
                rx_state <= 1'b0;
                tx_state <= 1'b1;
                
                init_state <= 1'b0; 
                
                bf_inc <= 1'b0;
                bf_rtn <= 1'b0;
                bf_rst <= 1'b1;
                for (i = 0; i < 64; i = i + 1)
                    user_beam[i] <= 8'd0;
                for (i = 0; i < 64; i = i + 1)
                    bs_snr[i] <= 16'd0;
                for (i = 0; i < 64; i = i + 1'b1)
                    beam_index[i] <= i;
            end
            else begin
            
                //接收
//                if (pause_state == 1'b1) begin //暂停发送，接收空隙
                if (rx_state == 1'b1) begin //暂停发送，接收空隙
//                    if (bit_in_tvalid)begin
                        rx_data[rx_segment*16+:16] = bit_in_tdata;
                        data_rx  <= rx_data[rx_segment*16+:16];
                        if (rx_segment < 16'd4799 ) begin
                            rx_segment = rx_segment + 16'd1;
                        end
                        else begin
                            rx_segment = 16'd0;
                            user_beam[rx_data[39:32]] = rx_data[39:32];
                            //最后选
//                            if(rx_data[7:0] != )
//                                user_counter <= user_counter + 1'b1;
//                            end
                            bs_snr [beam_count] <=  rx_data[55:40];
                            out_user_beam       <=  rx_data[39:32]; // 存储用户的波束号
                            out_user_snr        <=  rx_data[55:40]; // 存储每个基站波束的信噪比
                            // 在暂停发送时，接收并存储来自用户端反馈的基站端发送波束号的信噪比以及用户当前的波束号
                            if (bs_snr [beam_count] > best_snr) begin
                                best_bs_beam   <=   beam_count;
                                best_user_beam <=   rx_data[39:32];
                                best_snr       <=   bs_snr[beam_count]; //存储一个时隙内64个波束中信噪比最大的信噪比
                            end
                        end
//                    end
                    if (pause_counter < PAUSE_TIME) begin
                        pause_counter  =   pause_counter + 32'd1;
                    end
                    else begin
//                        pause_state    =   1'b0;
//                        pause_counter  =   32'd0;
                        pause_counter  <=   pause_counter + 32'd1;
                        beam_state     <=   1'b1; //更改 本状态和下一个状态
                        rx_state     <=   1'b0;
                        tx_state    <=   1'b0;
                        rx_data <= 0;
                        data_rx <= 0;
                    end
                end
                
                //波束调整周期
                else if(beam_state == 1'b1)begin
//                else if(beam_state == 1'b1)begin
                
                    if(pause_counter < BEAM_TIME)begin //  <10
                        pause_counter  <=   pause_counter + 32'd1;
                        if(beam_count > 0 && beam_count <= 63)begin //inc自增
                            bf_inc <= 1'b1;
                        end
                        else if( beam_count == 0 && send_data == 0)begin
//                        else if(beam_count == 63 || beam_count == 0)begin
                            bf_rst <= 1'b1;
                        end
                        
                    end
                    else begin //结束波束调整阶段
//                        pause_state   <=   1'b0;
                        pause_counter <= 32'd0;
                        beam_state    <=   1'b0;
                        tx_state      <=   1'b1;
                        rx_state      <=   1'b0;
                        bf_inc <= 1'b0;
                        bf_rst <= 1'b0;
                        bf_rtn <= 1'b0;
                    end
                    
                end
                
                //发送
                else if(tx_state == 1 )begin
//                if(tx_state == 1 || (beam_state == 0 && rx_state == 0) )begin
//                if(pause_state == 0 && beam_state == 0)begin
//                else if(pause_state == 0 && beam_state == 0)begin
                    rx_data <= 0;
                    data_rx <= 0;
//                    if (scan_Enable && beam_count == 0) begin //第一个波束信号发送 【3.31 14：41修改，进行编译看是否可以】
                    if (scan_Enable && scan_Pulse  && beam_count == 0) begin //第一个波束信号发送
                        // Construct the data to be transmitted
                        send_data  <=  1'b1;
                        init_state <= 1'b1;
                        bf_rst <= 1'b0;
                        tx_data [76799:96] <= 76704'hFEDCFEDC;
                        tx_data [95:40] <=  56'h4321567890ABCD; // Reserved
                        tx_data [39:32] <=  beam_index[beam_count]; // Beam index
                        tx_data [31:22] <=  10'd96; // Data length
                        tx_data [21:16] <=  6'b001001; // Data type
                        tx_data [15:8]  <=  8'hFF; // Destination address
                        tx_data [7:0]   <=  8'h01; // Source address
                    end
//                    else if (scan_Enable && bit_out_tready) begin//后面波束信号发送 【3.31 14：41修改，进行编译看是否可以】
                    else if (scan_Enable && bit_out_tready  && beam_count != 0) begin//后面波束信号发送
                        send_data <= 1'b1;
                        tx_data [76799:96] <= 76704'hDCBADCBA;
                        tx_data [95:40] <=  56'h1234567890ABCD; // Reserved
                        tx_data [39:32] <=  beam_index[beam_count]; // Beam index
                        tx_data [31:22] <=  10'd96; // Data length
                        tx_data [21:16] <=  6'b001001; // Data type
                        tx_data [15:8]  <=  8'hFF; // Destination address
                        tx_data [7:0]   <=  8'h01; // Source address
                    end
                    if (cnt_point_transed < tx_frame_length && send_data ) begin
                        if (bit_out_tready == 1'b1) begin
//                            cnt_point_transed <= cnt_point_transed + 32'd1;
                            if (tx_segment < 16'd4799) begin
                                tx_segment = tx_segment + 16'd1;
                            end
                            else begin
                                tx_segment  = 16'd0; 
                                beam_count  = beam_count + 1'b1;
//                                pause_state = 1'b1;
                                tx_state = 1'b0;
                                rx_state = 1'b1;
                                beam_state = 1'b0;
                                rx_data[rx_segment*16+:16] = bit_in_tdata;
                                data_rx  <= rx_data[rx_segment*16+:16];
                                if (beam_count > 63) begin
                                    beam_count <=  0;
                                    send_data  <=  1'b0;
                                    tx_data    <=  96'd0;    
                                end
                            end
                        end
                    end
//                    else if (cnt_point_transed < tx_interval) begin
//                        cnt_point_transed  <=  cnt_point_transed + 32'd1;
//                    end
//                    else if (cnt_point_transed == tx_interval) begin
//                        cnt_point_transed  <=  32'd0;
//                    end
                end
            end
        end
    `endif
    
    `ifdef NODE_BS //基站发送数据模块
    //    assign bit_out_tvalid = (cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0;
        assign bit_out_tvalid  =  (tx_state == 1'b0)  ?  1'b0 : ((cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0);
        assign bit_out_tdata   =  (send_data == 1'b1) ?  tx_data[tx_segment*16+:16] : 16'd0;
//        assign bit_out_tdata  =  (tx_state == 1'b0) ? 16'd0 : tx_data[tx_segment*16+:16];
        assign bit_out_tkeep   =   2'b11;
        assign bit_out_tstrb   =   2'b00;
//        assign bit_in_tready  =  (rx_state == 1'b1) ? 1'b1 : 1'b0;
        assign bit_in_tready   =   1'b1;
        assign tx_rx_sw = (rx_state == 1'b1) ? 1'b0 :1'b1; // RX模式(TX_RX_SW=0)或TX模式(TX_RX_SW=1)
        assign isScanCompleted = (currentScanSlot == 64) ? 1'b1 : 1'b0;
    `endif
 
    // 输出为TX_MODE（BS）:下游同步节点数（8bit）、下游节点ID_1（8bit）、所使用的发送波束（8bit）、下游节点ID_2（8bit）、所使用的发送波束（8bit）；
    //RX_MODE（UE）:BS节点地址（8bit）、所使用的接收波束（8bit）
     `ifdef NODE_BS //基站端向同步模块发送数据模块
//        assign [7:0] synNode = (currentScanSlot == 64) ?  //在64个时隙发送完成，而且经过判断哪一个波束最好时，发送给同步模块下游节点数，各个节点的ID，以及基站与每个用户发送时的对应的波束。
        assign synNode_valid = (currentScanSlot == 64) ? 1'b1 : 1'b0;
     `endif
    
    always @(posedge clk or negedge rst_n) //4.1 20:23 删除cnt相关代码
    begin
        if (rst_n == 1'b0) begin
            cnt_tlast <= 32'd0;
            bit_out_tlast <= 1'b0;
        end
        else begin
            if (cnt_point_transed < tx_frame_length && send_data ) begin
                if (bit_out_tready == 1'b1) begin
                cnt_point_transed <= cnt_point_transed + 32'd1;
                    if (cnt_tlast == (tx_frame_length - 32'd2)) begin
                        cnt_tlast <= cnt_tlast + 32'd1;
                        bit_out_tlast <= 1'b1; //表示一帧结束
                    end
                    else if (cnt_tlast == (tx_frame_length - 32'd1)) begin
                        cnt_tlast <= 32'd0;
                        bit_out_tlast <= 1'b0;
                    end
                    else begin
                        cnt_tlast <= cnt_tlast + 32'd1;
                        bit_out_tlast <= 1'b0;
                    end
                end
            end
            else if (cnt_point_transed < tx_interval && init_state) begin
                cnt_point_transed  <=  cnt_point_transed + 32'd1;
                cnt_tlast <= 32'd0;
                bit_out_tlast <= 1'b0;
            end
            else if (cnt_point_transed == tx_interval) begin  
                cnt_point_transed  <= 32'd0;          
                cnt_tlast <= 32'd0;
                bit_out_tlast <= 1'b0;
            end
        end
    end 
endmodule
