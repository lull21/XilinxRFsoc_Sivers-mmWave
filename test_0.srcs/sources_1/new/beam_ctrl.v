`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/07 09:57:52
// Design Name: 
// Module Name: beam_ctrl
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


module beam_ctrl(
    input wire clk,           // ʱ���ź�
    input wire rst,           // ��λ�ź�
    output reg BF_RST,        // BF_RST�ź�
    output reg BF_RTN,        // BF_RTN�ź�
    output reg BF_INC         // BF_INC�ź�
);

reg [5:0] beam_index;        // ��������ֵ����64��ֵ��0-63��

// Ĭ��ֵ
parameter DEFAULT_INDEX = 6;  // Ԥ��̵�Ĭ������ֵ

// ״̬��
reg [1:0] state;            // ״̬���������ڱ�ʾIDLE��SCAN��SELECT����״̬
localparam IDLE = 2'b00;    // ����IDLE״̬��ֵΪ2'b00
localparam SCAN = 2'b01;    // ����SCAN״̬��ֵΪ2'b01
localparam SELECT = 2'b10;  // ����SELECT״̬��ֵΪ2'b10
reg [3:0] frame_counter;    // ֡������

//��һ������Ҫ�����������Ƶ�˿ڽ������������ڷ��˿�����һ������ʱ����Ҫͨ����Ƶ�˹㲥��ǰ������

//��һ���ֽ�������������Ƶ������GPIO��
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        BF_RST <= 1'b0;
        BF_RTN <= 1'b0;
        BF_INC <= 1'b0;
        beam_index <= DEFAULT_INDEX;
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
                if (beam_index == 6'b111111) begin //6'b111111=63
                    state <= SELECT;
                end else begin
                    beam_index <= beam_index + 1;
                end
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

endmodule

