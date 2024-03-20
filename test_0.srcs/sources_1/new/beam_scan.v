`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: XidianUniversity
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/07 15:57:43
// Design Name: 
// Module Name: beam_scan
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: beam_scan
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
`include "header.vh"
module beam_scan(
    input wire clk,
    input wire rst_n,
        
    input wire  [31:0] tx_interval,
    input wire  [31:0] tx_frame_length,
    
    input wire scan_Enable, // ��־��ǰΪɨ����Ƚ׶�
    input wire scan_Pulse,  // ����ɨ����ȹ��̣���ÿ��ɨ��ʱ϶��ʼʱ�̸���
    input wire  [7:0] currentScanSlot,  //��ǰɨ��ʱ϶������ͨ����ʱʱ϶����ȷ����ǰ��������
    
    //�˲���Ϊ�������ݽӿ�
    //���ڻ�վ�����͹㲥�źŰ���������Ϣ
    //�����û������վ������Ϣ: (1)һ��ʱ϶�ڣ�ÿ���յ�һ֡�����ݣ�������ǰ������Ӧ�������
    //                        ��2��
    output wire [15:0] bit_out_tdata,
    output wire        bit_out_tvalid,
    input  wire        bit_out_tready,
    output wire  [1:0] bit_out_tkeep,
    output wire  [1:0] bit_out_tstrb,
    output reg         bit_out_tlast,
    
    //�˲���Ϊ�������ݽӿ�
    //���ڻ�վ����һ��ʱ϶�ڣ�ÿ�㲥һ��������Ϣ����תΪ����״̬�����ղ�ͬ�û�����ÿһ�������ź����ݵ�����ȣ�����һ��ʱ϶��ɺ�����ж�
    //�����û������յ���վ��ÿһ�������ź����ݺ���������ǰ������Ϣ������ȣ�ͬʱ�û�Ҫ�洢�������ߵ�
    input  wire [15:0] bit_in_tdata,
    input  wire        bit_in_tvalid,
    output wire        bit_in_tready,
    input  wire  [1:0] bit_in_tkeep,
    input  wire  [1:0] bit_in_tstrb,
    input  wire        bit_in_tlast,
    
    output wire synNode_valid,
    output wire [7:0] synNode,
    output wire isScanCompleted,
    output wire tx_rx_sw, //RXģʽ(TX_RX_SW=0)��TXģʽ(TX_RX_SW=1)
    input  wire SNR, //�����ź������
    
    output reg [7:0]  out_user_beam,// �洢ÿ���û��Ĳ�����
    output reg [15:0] out_user_snr,  // �洢ÿ���û��������
    
    output reg [15:0] data_rx,
    output reg pause_state, // ������״̬��������վ��1Ϊ��ͣ��0Ϊ���ͣ��û���1Ϊ��ͣ��0Ϊ����
    output reg [7:0]  tx_segment,
    output reg [7:0]  rx_segment,
    
    output wire bf_rst,
    output wire bf_rtn,
    output wire bf_inc
    );
    parameter [31:0] PAUSE_TIME = 5;
    
    reg [7:0] beam_index [63:0]; //// �������� Array to store the beam numbers,ǰ����ÿ���Ĵ�����С���������ж��ټĴ���
    reg [7:0] beam_count = 0; // Counter for the beam numbers
    
    reg [31:0] cnt_tlast; 
    reg [31:0] cnt_point_transed;
    
//    reg [5:0]  tx_segment = 0; 
    reg [95:0] tx_data; // Data to be transmitted
    reg [95:0] rx_data; // �洢���յ�������
//    reg [7:0]  rx_segment = 0; // �洢�������ݵĶκ�
    
    reg send_data; // Flag to control data transmission
    
    reg [7:0]  best_bs_beam; // �洢��ѻ�վ�Ĳ���
    reg [7:0]  best_user_beam;//// �洢����û��Ĳ���
    reg [15:0] best_snr; // �洢��Ѳ����������
    
    integer i;
    
    reg [31:0] pause_counter = 0; // �����ļ�����
//    reg pause_state; // ������״̬������1Ϊ��ͣ��0Ϊ����
    
    `ifdef NODE_UE
        // �û��ض����߼�
        reg [15:0] snr [63:0]; // �洢ÿ�������������
        reg [7:0]  user_beam ; // �洢ÿ���û��Ĳ�����
        reg [7:0]  user_counter;
        reg [7:0]  rx_counter;
    `endif
    `ifdef NODE_BS
        // ��վ�������ݵ��߼�       
        reg [7:0] user_beam [63:0]; // �洢ÿ���û��Ĳ�����
        reg [15:0] bs_snr [63:0]; // �洢ÿ�����Ͳ����������
    `endif
    
    `ifdef NODE_BS  //��վ��:׼����������\��������
        always @(posedge clk or posedge scan_Pulse) begin
            if (rst_n == 1'b0) begin
                cnt_point_transed <= 32'd0;
                tx_segment <= 6'd0;   tx_data <= 96'd0;
                rx_segment <= 6'd0;   rx_data <= 96'd0;
                send_data  <= 1'b0; 
                pause_counter <= 32'd0;  pause_state <= 1'b0;
                best_snr <= 16'd0;
                for (i = 0; i < 64; i = i + 1)
                    user_beam[i] <= 8'd0;
                for (i = 0; i < 64; i = i + 1)
                    bs_snr[i] <= 16'd0;
                for (i = 0; i < 64; i = i + 1'b1)
                    beam_index[i] <= i;
            end
            else begin
                //����
                if (pause_state == 1'b1) begin //��ͣ���ͣ����տ�϶
                    if (pause_counter < PAUSE_TIME) begin
                        pause_counter  <=   pause_counter + 32'd1;
                    end
                    else begin
                        pause_state    <=   1'b0;
                        pause_counter  <=   32'd0;
                    end
                    
//                    if (bit_in_tvalid)begin
                        rx_data[rx_segment*16+:16] = bit_in_tdata;
                        data_rx  = rx_data[rx_segment*16+:16];
//                        data_rx  = bit_in_tdata;
                        if (rx_segment < 8'd5) begin
                            rx_segment = rx_segment + 8'd1;
                        end
                        else begin
                            rx_segment = 8'd0;
                            user_beam[rx_data[39:32]] = rx_data[39:32];
                            //���ѡ
//                            if(rx_data[7:0] != )
//                                user_counter <= user_counter + 1'b1;
//                            end
                            bs_snr [beam_count] <=  rx_data[55:40];
                            out_user_beam       <=  rx_data[39:32]; // �洢�û��Ĳ�����
                            out_user_snr        <=  rx_data[55:40]; // �洢ÿ����վ�����������
                            // ����ͣ����ʱ�����ղ��洢�����û��˷����Ļ�վ�˷��Ͳ����ŵ�������Լ��û���ǰ�Ĳ�����
                            if (bs_snr [beam_count] > best_snr) begin
                                best_bs_beam   <=   beam_count;
                                best_user_beam <=   rx_data[39:32];
                                best_snr       <=   bs_snr[beam_count]; //�洢һ��ʱ϶��64����������������������
                            end
                        end
//                    end
                end
                //����
                else begin
                    rx_data <= 96'd0;
                    if (scan_Enable && scan_Pulse  && beam_count == 0) begin //��һ�������źŷ���
                        // Construct the data to be transmitted
                        send_data  <=  1'b1;
                        tx_data [95:40] <=  56'h1234567890ABCD; // Reserved
                        tx_data [39:32] <=  beam_index[beam_count]; // Beam index
                        tx_data [31:22] <=  10'd96; // Data length
                        tx_data [21:16] <=  6'b001001; // Data type
                        tx_data [15:8]  <=  8'hFF; // Destination address
                        tx_data [7:0]   <=  8'h01; // Source address
                    end
                    else if (scan_Enable && bit_out_tready  && beam_count != 0) begin//���沨���źŷ���
                        send_data <= 1'b1;
                        tx_data [95:40] <=  56'h1234567890ABCD; // Reserved
                        tx_data [39:32] <=  beam_index[beam_count]; // Beam index
                        tx_data [31:22] <=  10'd96; // Data length
                        tx_data [21:16] <=  6'b001001; // Data type
                        tx_data [15:8]  <=  8'hFF; // Destination address
                        tx_data [7:0]   <=  8'h01; // Source address
                    end
                    if (cnt_point_transed < tx_frame_length && send_data ) begin
                        if (bit_out_tready == 1'b1) begin
                            cnt_point_transed <= cnt_point_transed + 32'd1;
                            if (tx_segment < 6'd5) begin
                                tx_segment = tx_segment + 6'd1;
                            end
                            else begin
                                tx_segment  = 6'd0; 
                                beam_count  <= beam_count + 1'b1;
                                pause_state <= 1'b1;
                                if (beam_count >= 63) begin
                                    beam_count <=  0;
                                    send_data  <=  1'b0;
                                    tx_data    <=  96'd0;    
                                end
                            end
                        end
                    end
                    else if (cnt_point_transed < tx_interval) begin
                        cnt_point_transed  <=  cnt_point_transed + 32'd1;
                    end
                    else if (cnt_point_transed == tx_interval) begin
                        cnt_point_transed  <=  32'd0;
                    end
                end
            end
        end
    `endif
     `ifdef NODE_UE //�û���:׼����������\��������
//  �˲�������:��ÿ��ʱ϶�У��û��˻��յ���վ�˷��͵�64�������Ĳ�ͬ���ݣ�ͨ������Ƚ��бȽϡ�
//  ���ȣ���ÿ��ʱ϶����ʱѡ������������ȵĻ�վ�˷��͵Ĳ����š�Ȼ����64��ʱ϶������
//  �Ƚ�ÿ��ʱ϶��ѡ���ľ����������ȵĻ�վ�˷��͵Ĳ����ţ�ѡ���������Ĳ����ţ���ȷ�����Ӧ���û����ղ����źţ��������Ѳ����ԡ�
    // ��ÿ��ʱ϶����ʱ������ÿ������������Ⱥ�ѡ����ѵĲ���
        always @(posedge clk or posedge scan_Pulse) begin
            if (rst_n == 1'b0) begin
                cnt_point_transed <= 32'd0;
                best_bs_beam <= 8'd0; best_user_beam  <=  8'd0; best_snr  <=  16'd0;
                tx_segment  <=  6'd0; tx_data  <=  96'd0;
                rx_segment  <=  6'd0; rx_data  <=  96'd0;
                user_beam   <=  8'd0;
                pause_counter  <=  32'd0; pause_state  <=  1'b0;
                rx_counter <= 8'd0;
                for (i = 0; i < 64; i = i + 1)
                    snr[i] <= 16'd0;
            end
//            else if (bit_in_tvalid) begin
            else  begin
                // ��������
                if (bit_in_tvalid) begin
                    pause_state <=  1'b0;
                    send_data   <=  1'b0;
                    if (rx_segment < 8'd5) begin
    //                    rx_segment <= rx_segment + 8'd1;
                        rx_segment = rx_segment + 8'd1;
//                        pause_state =  1'b0;
                    end
                    else begin
                        rx_segment  =  8'd0;// ������ɣ�רΪ����
                        pause_counter = 32'd0;
                        send_data   =  1'b1;
//                        pause_state =  1'b1;// ������״̬��������վ��1Ϊ���գ�0Ϊ���ͣ��û���1Ϊ���ͣ�0Ϊ����
                        // ���µ�ǰ�����������
                        snr[rx_data[39:32]] <= SNR;
                        // �����ǰ����������ȱ���Ѳ���������ȴ��������ѵĲ����������
                        if (SNR > best_snr) begin
                            best_bs_beam    <=  rx_data[39:32];//�洢һ��ʱ϶��64����������������ķ��Ͳ�����
                            best_user_beam  <=  user_beam;
                            best_snr <= SNR;//�洢һ��ʱ϶��64����������������������
                        end
//                        if (pause_counter < PAUSE_TIME) begin //��վ���ͳ���ʱ�䣺���뷢��״̬��pause_state   ==  1'b1��ʱ�ſ�ʼ��ʱ
//                               pause_counter <= pause_counter + 32'd1;
//                            pause_counter = pause_counter + 32'd1;
//                        end
//                        else begin
//                            pause_state   <=  1'b0;
//                            pause_counter <=  32'd0;
//                        end
                    end
               end
            else if(send_data)begin
                pause_state <=  1'b1;
                pause_counter <= pause_counter + 32'd1;
            end
//            if (pause_counter > 6) begin
//                pause_counter = 32'd0;
//            end
            //��������
            if (pause_state == 1'b1) begin
                // �ڻ�վ��ͣ����ʱ�������յ��Ķ�Ӧ��վ���Ͳ����ŵ�����ȷ��ͳ�ȥ
//                tx_data[95:0] =  96'h1234567890ABCDEF01020304; // TEST
                tx_data[95:56] =  40'h1234567890; // Reserved
//                tx_data[47:40] = snr[best_beam]; // SNR of the best beam
                tx_data[55:40] =  snr[rx_data[39:32]]; // SNR of current BS's beam
//                tx_data[39:32] = best_beam; // User's current beam
                tx_data[39:32] =  user_beam; // User's current beam
                tx_data[31:22] =  10'd96; // Data length
                tx_data[21:16] =  6'b001001; // Data type
                tx_data[15:8]  =  8'h01; // Destination address
                tx_data[7:0]   =  8'h02; // Source address
                send_data     <=  1'b1;
            end
//            if (cnt_point_transed < tx_frame_length && send_data ) begin
            if (cnt_point_transed < tx_frame_length && pause_state ) begin
                    if (bit_out_tready == 1'b1) begin
                        cnt_point_transed <= cnt_point_transed + 32'd1;
                        if (tx_segment < 6'd5 && pause_counter > 1) begin
//                        if (tx_segment < 6'd5 ) begin
                            tx_segment = tx_segment + 6'd1;
                        end
                        else begin
                            tx_segment  <=  6'd0; 
//                            tx_data     =  96'hFFFFFFFFFFFFFFFFFFFFFFFF;   
//                            send_data  <=  1'b0;
//                            beam_count  <= beam_count + 1'b1;
//                            pause_state <= 1'b0;
//                            if (beam_count >= 63) begin
//                                beam_count <=  0;
//                                send_data  <=  1'b0;
//                                tx_data    <=  96'd0;    
//                            end
                        end
                    end
                end
                else if (cnt_point_transed < tx_interval) begin
                    cnt_point_transed  <=  cnt_point_transed + 32'd1;
                end
                else if (cnt_point_transed == tx_interval) begin
                    cnt_point_transed  <=  32'd0;
                end
            //�û��˲�������һ��ʱ϶�ڸ���һ��
                if (scan_Pulse) begin
//                    user_beam = user_beam + 8'd1;
                    if(rx_counter >= 1) begin //user_beam��0��ʼ
                        user_beam = user_beam + 8'd1;
                    end
                    rx_counter = rx_counter + 1'b1;
                    if(rx_counter == 64) begin
                        user_beam  <=  8'd0;
                        rx_counter <=  8'd0;
                    end
                    if(user_beam == 64) begin
                        user_beam  <=  8'd0;
                    end
                end
            end
        end
    `endif
    
    `ifdef NODE_BS //��վ��������ģ��
    //    assign bit_out_tvalid = (cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0;
        assign bit_out_tvalid =  (pause_state == 1'b1) ? 1'b0 : ((cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0);
        assign bit_out_tdata  =  (pause_state == 1'b1) ? 16'd0 : tx_data[tx_segment*16+:16];
        assign bit_out_tkeep  =   2'b11;
        assign bit_out_tstrb  =   2'b00;
        assign bit_in_tready  =  (pause_state == 1'b1) ? 1'b1 : 1'b0;
        assign tx_rx_sw = (pause_state == 1'b1) ? 1'b0 : 1'b1; // RXģʽ(TX_RX_SW=0)��TXģʽ(TX_RX_SW=1)
        assign isScanCompleted = (currentScanSlot == 64) ? 1'b1 : 1'b0;
    `endif
    `ifdef NODE_UE //�û��˷�������ģ��
    //�����û���������ݲ���
//        assign bit_out_tvalid =  (pause_state == 1'b1) ? bit_out_tready : ((cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0);
        assign bit_out_tvalid =  (pause_state == 1'b1) ? ((cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0) : 1'b0;
//        assign bit_out_tdata  =  (pause_state == 1'b1) ? tx_data[tx_segment*16+:16] : ((pause_state == 1'b1) ? 16'd0 : tx_data[tx_segment*16+:16]); 
        assign bit_out_tdata  =  (pause_state == 1'b1) ? tx_data[tx_segment*16+:16] : 16'd0; 
        assign bit_out_tkeep  =   2'b11;
        assign bit_out_tstrb  =   2'b00;   
        assign bit_in_tready  =  (pause_state == 1'b0) ? 1'b1 : 1'b0;
        assign tx_rx_sw = (pause_state == 1'b1) ? 1'b1 : 1'b0; // RXģʽ(TX_RX_SW=0)��TXģʽ(TX_RX_SW=1)
    `endif
    
    // ���ΪTX_MODE��BS��:����ͬ���ڵ�����8bit�������νڵ�ID_1��8bit������ʹ�õķ��Ͳ�����8bit�������νڵ�ID_2��8bit������ʹ�õķ��Ͳ�����8bit����
    //RX_MODE��UE��:BS�ڵ��ַ��8bit������ʹ�õĽ��ղ�����8bit��
     `ifdef NODE_BS //��վ����ͬ��ģ�鷢������ģ��
//        assign [7:0] synNode = (currentScanSlot == 64) ?  //��64��ʱ϶������ɣ����Ҿ����ж���һ���������ʱ�����͸�ͬ��ģ�����νڵ����������ڵ��ID���Լ���վ��ÿ���û�����ʱ�Ķ�Ӧ�Ĳ�����
        assign synNode_valid = (currentScanSlot == 64) ? 1'b1 : 1'b0;
     `endif
    `ifdef NODE_UE //�û�����ͬ��ģ�鷢������ģ��
//        assign [7:0] synNode = (currentScanSlot == 64) ?  
        assign synNode_valid = (currentScanSlot == 64) ? 1'b1 : 1'b0;
     `endif 
    
    always @(posedge clk)
    begin
        if (rst_n == 1'b0) begin
            cnt_tlast <= 32'd0;
            bit_out_tlast <= 1'b0;
        end
        else begin
            if (cnt_point_transed < tx_frame_length) begin
                if (bit_out_tready == 1'b1) begin
                    if (cnt_tlast == (tx_frame_length - 32'd2)) begin
                        cnt_tlast <= cnt_tlast + 32'd1;
                        bit_out_tlast <= 1'b1; //��ʾһ֡����
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
            else if (cnt_point_transed < tx_interval) begin
                cnt_tlast <= 32'd0;
                bit_out_tlast <= 1'b0;
            end
            else if (cnt_point_transed == tx_interval) begin
                cnt_tlast <= 32'd0;
                bit_out_tlast <= 1'b0;
            end
        end
    end 
endmodule