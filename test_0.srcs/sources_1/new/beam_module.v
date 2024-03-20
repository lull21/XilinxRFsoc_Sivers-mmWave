`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/11 11:13:44
// Design Name: 
// Module Name: beam_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: ��ģ�齫����ɨ���벨����Ƶ�������
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module beam_module(
    input wire clk,           // ʱ���ź�
    input wire rst,           // ��λ�ź�
    
    output reg BF_RST,        // BF_RST�ź�
    output reg BF_RTN,        // BF_RTN�ź�
    output reg BF_INC,         // BF_INC�ź�
    
    input wire  [31:0] tx_interval,
    input wire  [31:0] tx_frame_length,
    
    input wire scan_Enable, // ��־��ǰΪɨ����Ƚ׶�
    input wire scan_Pulse,  // ����ɨ����ȹ��̣���ÿ��ɨ��ʱ϶��ʼʱ�̸���
    input wire  [7:0] currentScanSlot,  //��ǰɨ��ʱ϶������ͨ����ʱʱ϶����ȷ����ǰ��������

    output wire [15:0] bit_out_tdata,
    output wire        bit_out_tvalid,
    input  wire        bit_out_tready,
    output wire  [1:0] bit_out_tkeep,
    output wire  [1:0] bit_out_tstrb,
    output reg         bit_out_tlast,
    
    output wire synNode_valid,
    output wire [7:0] synNode,
    
    output wire isScanCompleted
    );
// ============�������Ʋ��ֳ�ʼֵ============= //
    // Ĭ��ֵ
    parameter DEFAULT_INDEX = 6;  // Ԥ��̵�Ĭ������ֵ
    // ״̬��
    reg [1:0] state;            // ״̬���������ڱ�ʾIDLE��SCAN��SELECT����״̬
    localparam IDLE = 2'b00;    // ����IDLE״̬��ֵΪ2'b00
    localparam SCAN = 2'b01;    // ����SCAN״̬��ֵΪ2'b01
    localparam SELECT = 2'b10;  // ����SELECT״̬��ֵΪ2'b10
    reg [3:0] frame_counter;    // ֡������
    
// ============����ɨ�貿�ֳ�ʼֵ============= //    
    reg [7:0] beam_index [63:0]; //// �������� Array to store the beam numbers,ǰ����ÿ���Ĵ�����С���������ж��ټĴ���
    reg [7:0] beam_count = 0; // Counter for the beam numbers
    reg [31:0] cnt_tlast; 
    reg [31:0] cnt_point_transed;
    reg [5:0]  segment = 0; 
    reg [95:0] tx_data; // Data to be transmitted
    reg send_data; // Flag to control data transmission
    integer i; 
 
// ====��һ���ֽ�������������Ƶ������GPIO�ڣ��������ģ����Է���RF_Ctrl�У�==== //
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            BF_RST <= 1'b0;
            BF_RTN <= 1'b0;
            BF_INC <= 1'b0;
    //        beam_index <= DEFAULT_INDEX;
            frame_counter <= 4'b0;
        end else begin
            case (state)
                IDLE: begin
                    BF_RST <= 1'b1;
                    BF_RTN <= 1'b0;
                    BF_INC <= 1'b0;
                    if (frame_counter == 4'b1011) begin
                        state <= SCAN;
                        frame_counter <= 4'b0;
                    end else begin
                        frame_counter <= frame_counter + 1;
                    end
                end
                SCAN: begin
                    BF_RST <= 1'b0;
                    BF_RTN <= 1'b0;
                    BF_INC <= 1'b1;
    //                if (beam_index == 6'b111111) begin //6'b111111=63
    //                    state <= SELECT;
    //                end else begin
    //                    beam_index <= beam_index + 1;
    //                end
                end
                SELECT: begin
                    // ����ѡ����ƵĲ�������ֵ
                    // ������ʱδ������ʵ�֣����Ը�����Ҫ�����Ӧ���߼�
                    //���ݷ������ݽ���ѡ��
                    state <= IDLE;
                end
            endcase
        end
    end

// ====��һ�����������Ͳ���ɨ��֡==== //
    always @(posedge clk or posedge scan_Pulse) begin
        if (rst == 1'b0) begin
            cnt_point_transed <= 32'd0;
            segment <= 6'd0;
            tx_data <= 96'd0;
            send_data <= 1'b0; 
            for (i = 0; i < 64; i = i + 1'b1)
                beam_index[i] <= i;
        end
        else begin
            if (scan_Enable && scan_Pulse  && beam_count == 0) begin
                // Construct the data to be transmitted
                send_data <= 1'b1;
                tx_data[95:88] = 8'h01; // Source address
                tx_data[87:80] = 8'hFF; // Destination address
                tx_data[79:74] = 6'b001001; // Data type
                tx_data[73:64] = 10'd96; // Data length
                tx_data[63:56] = beam_index[beam_count]; // Beam index 
                tx_data[55:0] = 56'h1234567890ABCD; // Reserved

            end
            else if (scan_Enable && bit_out_tready  && beam_count != 0) begin
                tx_data[63:56] = beam_index[beam_count]; // Beam index
            end
            
            if (cnt_point_transed < tx_frame_length && send_data ) begin
                if (bit_out_tready == 1'b1) begin
                    cnt_point_transed <= cnt_point_transed + 32'd1;
                    if (segment < 6'd5) begin
                        segment <= segment + 6'd1;
                    end
                    else begin
                        segment <= 6'd0;
                        beam_count <= beam_count + 1'b1;
                        if (beam_count >= 63) begin
                            beam_count <= 0;
                            send_data <= 1'b0;
                            tx_data <= 96'd0;    
                        end
                    end
                end
            end
            else if (cnt_point_transed < tx_interval) begin
                cnt_point_transed <= cnt_point_transed + 32'd1;
            end
            else if (cnt_point_transed == tx_interval) begin
                cnt_point_transed <= 32'd0;
            end
        end
    end

    assign bit_out_tvalid = (cnt_point_transed < tx_frame_length && send_data) ? bit_out_tready : 1'b0;
    assign bit_out_tdata =  tx_data[segment*16+:16];
    assign bit_out_tkeep =  2'b11;
    assign bit_out_tstrb =  2'b00;
    assign isScanCompleted = (currentScanSlot == 64) ? 1'b1 : 1'b0;
    always @(posedge clk)
    begin
        if (rst == 1'b0) begin
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
