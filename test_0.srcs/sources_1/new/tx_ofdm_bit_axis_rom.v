`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 2hang1iang
// 
// Create Date: 2024/03/06 17:08:26
// Design Name: 
// Module Name: tx_ofdm_bit_axis_rom
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


module tx_ofdm_bit_axis_rom(
    input wire clk,
    input wire rst_n,
        
    input wire  [31:0] tx_interval,
    input wire  [31:0] tx_frame_length,
//    input wire  [95:0] tx_data, // Add this line
    
    
    input wire scan_Enable, // ��־��ǰΪɨ����Ƚ׶�
    input wire scan_Pulse,  // ����ɨ����ȹ��̣���ÿ��ɨ��ʱ϶��ʼʱ�̸���
    input wire  [15:0] currentScanSlot,  //��ǰɨ��ʱ϶������ͨ����ʱʱ϶����ȷ����ǰ��������

    output wire [15:0] bit_out_tdata,
    output wire        bit_out_tvalid,
    input  wire        bit_out_tready,
    output wire  [1:0] bit_out_tkeep,
    output wire  [1:0] bit_out_tstrb,
    output reg         bit_out_tlast,
    output reg [31:0] cnt_tlast,
    output reg [31:0] cnt_point_transed,
    
    output wire synNode_valid,
    output wire [7:0] synNode,
    
    output wire isScanCompleted 
    );
    
//    reg [31:0] cnt_tlast;
//    reg [31:0] cnt_point_transed;
    reg [5:0]  segment; // Add this line
 
    
    assign bit_out_tvalid = (cnt_point_transed < tx_frame_length) ? bit_out_tready : 1'b0;
    assign bit_out_tdata = tx_data[segment*16+:16]; // Replace this line
    assign bit_out_tkeep = 2'b11;
    assign bit_out_tstrb = 2'b00;

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            cnt_point_transed <= 32'd0;
            segment <= 6'd0; // Add this line
        end
        else begin
            if (cnt_point_transed < tx_frame_length) begin
                if (bit_out_tready == 1'b1) begin
                    cnt_point_transed <= cnt_point_transed + 32'd1;
                    if (segment < 6'd5) begin
                        segment <= segment + 6'd1;
                    end
                    else begin
                        segment <= 6'd0;
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
//��δ����е�tx_data��һ��96λ�����룬����ʹ��segment��������ѡ��ǰҪ���͵�16λ�Ρ�
//ÿ��bit_out_treadyΪ1ʱ�����Ǿͽ�segment����1����ѡ����һ��Ҫ���͵�16λ�Ρ�������6���ζ�������Ϻ����Ǿͽ�segment����Ϊ0���Ա�����һ�ε����ݷ��͡�
//ע�⣬����������tx_data�ĸ���Ƶ�ʵ���tx_frame_length���������ڷ�����һ��tx_data����һ��tx_data���Ѿ�׼�����ˡ�
//����ⲻ�������������������Ҫ��Ӹ�����߼�������������⡣