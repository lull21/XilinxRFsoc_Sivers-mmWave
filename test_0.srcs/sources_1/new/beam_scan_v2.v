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
    
    input  wire SNR, //�����ź������
    
    output reg [7:0]  out_user_beam,// �洢ÿ���û��Ĳ�����
    output reg [15:0] out_user_snr,  // �洢ÿ���û��������
    
    output reg [15:0] data_rx,
    output reg pause_state, // ������״̬��������վ��1Ϊ��ͣ��0Ϊ���ͣ��û���1Ϊ��ͣ��0Ϊ����
    output reg [15:0]  tx_segment,
    output reg [15:0]  rx_segment,
    
    output reg [15:0] tx_cnt,
    output reg [15:0] rx_cnt,
    
    output reg [31:0] cnt_tlast,
    output reg [31:0] cnt_point_transed,
    
//    output reg [31:0] counter = 0,
    
//    output reg send_data,
    output reg [31:0] pause_counter,
    
    output wire tx_rx_sw, //RXģʽ(TX_RX_SW=0)��TXģʽ(TX_RX_SW=1)
    output reg beam_state,//1Ϊ���� 
    output reg rx_state, //1Ϊ����
    output reg tx_state, //1Ϊ����
    
    output reg bf_rst, // BF_RST����������ΪԤ��̵�Ĭ��ֵ=0  bs-> reg  ue->wire
    output reg bf_rtn, // BF_INCָ����1
    output reg bf_inc  // BF_RTN��������ʱ����ΪԤ��̵�Ĭ��ֵ
    
    );
    parameter [15:0] PAUSE_TIME = 16'd4799;
    parameter [15:0] BEAM_TIME  = 16'd9599;
    
//    reg [15:0] data_rx;
//    reg pause_state;
    
//    reg [7:0]  out_user_beam;// �洢ÿ���û��Ĳ�����
//    reg [15:0] out_user_snr;
    
    // �����и���ʼ״̬��־����ʾ�Ƿ�Ϊһ���µķ��͵Ŀ�ʼ
    reg init_state = 1'b1; 
    
    reg [31:0] counter = 0;
    
    reg [7:0] beam_index [63:0]; //// �������� Array to store the beam numbers,ǰ����ÿ���Ĵ�����С���������ж��ټĴ���
    reg [7:0] beam_count = 0; // Counter for the beam numbers
    
//    reg [7:0] tx_cnt;
//    reg [7:0] rx_cnt;
    
//    reg [31:0] cnt_tlast; 
//    reg [31:0] cnt_point_transed;
    
    reg send_data;
    
//    reg beam_state;//1Ϊ���� 
//    reg rx_state; //1Ϊ����
//    reg tx_state; //1Ϊ����
    
//    reg [7:0]  tx_segment = 0; 
    reg [76799:0] tx_data; // Data to be transmitted
    reg [76799:0] rx_data; // �洢���յ�������
//    reg [7:0]  rx_segment = 0; // �洢�������ݵĶκ�
    
//    reg send_data; // Flag to control data transmission
    
    reg [7:0]  best_bs_beam; // �洢��ѻ�վ�Ĳ���
    reg [7:0]  best_user_beam;//// �洢����û��Ĳ���
    reg [15:0] best_snr; // �洢��Ѳ����������
    
    integer i;
    
//    reg [31:0] pause_counter = 0; // �����ļ����� //4.1 20:23 ɾ��cnt��ش���
//    reg [31:0] counter = 0;
//    reg pause_state; // ������״̬������1Ϊ��ͣ��0Ϊ����
//    reg [7:0] tx_cnt = 0;
//    reg [7:0] rx_cnt = 0;
    
    `ifdef NODE_BS
        // ��վ�������ݵ��߼�       
        reg [7:0] user_beam [63:0]; // �洢ÿ���û��Ĳ�����
        reg [15:0] bs_snr [63:0]; // �洢ÿ�����Ͳ����������
//        reg beam_state;//������������ ��һ�η��ͽ�����ɺ�Ԥ��ʱ����в������� Ϊ1ʱ����  Ϊ0ʱ������
    `endif
    
    `ifdef NODE_BS  //��վ��:׼����������\��������  ��վ���ֱ��ٶ�
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
            
                //����
//                if (pause_state == 1'b1) begin //��ͣ���ͣ����տ�϶
                if (rx_state == 1'b1) begin //��ͣ���ͣ����տ�϶
//                    if (bit_in_tvalid)begin
                        rx_data[rx_segment*16+:16] = bit_in_tdata;
                        data_rx  <= rx_data[rx_segment*16+:16];
                        if (rx_segment < 16'd4799 ) begin
                            rx_segment = rx_segment + 16'd1;
                        end
                        else begin
                            rx_segment = 16'd0;
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
                    if (pause_counter < PAUSE_TIME) begin
                        pause_counter  =   pause_counter + 32'd1;
                    end
                    else begin
//                        pause_state    =   1'b0;
//                        pause_counter  =   32'd0;
                        pause_counter  <=   pause_counter + 32'd1;
                        beam_state     <=   1'b1; //���� ��״̬����һ��״̬
                        rx_state     <=   1'b0;
                        tx_state    <=   1'b0;
                        rx_data <= 0;
                        data_rx <= 0;
                    end
                end
                
                //������������
                else if(beam_state == 1'b1)begin
//                else if(beam_state == 1'b1)begin
                
                    if(pause_counter < BEAM_TIME)begin //  <10
                        pause_counter  <=   pause_counter + 32'd1;
                        if(beam_count > 0 && beam_count <= 63)begin //inc����
                            bf_inc <= 1'b1;
                        end
                        else if( beam_count == 0 && send_data == 0)begin
//                        else if(beam_count == 63 || beam_count == 0)begin
                            bf_rst <= 1'b1;
                        end
                        
                    end
                    else begin //�������������׶�
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
                
                //����
                else if(tx_state == 1 )begin
//                if(tx_state == 1 || (beam_state == 0 && rx_state == 0) )begin
//                if(pause_state == 0 && beam_state == 0)begin
//                else if(pause_state == 0 && beam_state == 0)begin
                    rx_data <= 0;
                    data_rx <= 0;
//                    if (scan_Enable && beam_count == 0) begin //��һ�������źŷ��� ��3.31 14��41�޸ģ����б��뿴�Ƿ���ԡ�
                    if (scan_Enable && scan_Pulse  && beam_count == 0) begin //��һ�������źŷ���
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
//                    else if (scan_Enable && bit_out_tready) begin//���沨���źŷ��� ��3.31 14��41�޸ģ����б��뿴�Ƿ���ԡ�
                    else if (scan_Enable && bit_out_tready  && beam_count != 0) begin//���沨���źŷ���
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
    
    `ifdef NODE_BS //��վ��������ģ��
    //    assign bit_out_tvalid = (cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0;
        assign bit_out_tvalid  =  (tx_state == 1'b0)  ?  1'b0 : ((cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0);
        assign bit_out_tdata   =  (send_data == 1'b1) ?  tx_data[tx_segment*16+:16] : 16'd0;
//        assign bit_out_tdata  =  (tx_state == 1'b0) ? 16'd0 : tx_data[tx_segment*16+:16];
        assign bit_out_tkeep   =   2'b11;
        assign bit_out_tstrb   =   2'b00;
//        assign bit_in_tready  =  (rx_state == 1'b1) ? 1'b1 : 1'b0;
        assign bit_in_tready   =   1'b1;
        assign tx_rx_sw = (rx_state == 1'b1) ? 1'b0 :1'b1; // RXģʽ(TX_RX_SW=0)��TXģʽ(TX_RX_SW=1)
        assign isScanCompleted = (currentScanSlot == 64) ? 1'b1 : 1'b0;
    `endif
 
    // ���ΪTX_MODE��BS��:����ͬ���ڵ�����8bit�������νڵ�ID_1��8bit������ʹ�õķ��Ͳ�����8bit�������νڵ�ID_2��8bit������ʹ�õķ��Ͳ�����8bit����
    //RX_MODE��UE��:BS�ڵ��ַ��8bit������ʹ�õĽ��ղ�����8bit��
     `ifdef NODE_BS //��վ����ͬ��ģ�鷢������ģ��
//        assign [7:0] synNode = (currentScanSlot == 64) ?  //��64��ʱ϶������ɣ����Ҿ����ж���һ���������ʱ�����͸�ͬ��ģ�����νڵ����������ڵ��ID���Լ���վ��ÿ���û�����ʱ�Ķ�Ӧ�Ĳ�����
        assign synNode_valid = (currentScanSlot == 64) ? 1'b1 : 1'b0;
     `endif
    
    always @(posedge clk or negedge rst_n) //4.1 20:23 ɾ��cnt��ش���
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
