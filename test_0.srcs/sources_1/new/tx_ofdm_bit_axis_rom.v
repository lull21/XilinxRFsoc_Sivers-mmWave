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
    
    
    input wire scan_Enable, // 标志当前为扫描调度阶段
    input wire scan_Pulse,  // 触发扫描调度过程，在每个扫描时隙起始时刻给出
    input wire  [15:0] currentScanSlot,  //当前扫描时隙，可以通过此时时隙号来确定当前波束索引

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
//这段代码中的tx_data是一个96位的输入，我们使用segment计数器来选择当前要发送的16位段。
//每当bit_out_tready为1时，我们就将segment增加1，以选择下一个要发送的16位段。当所有6个段都发送完毕后，我们就将segment重置为0，以便于下一次的数据发送。
//注意，这个代码假设tx_data的更新频率低于tx_frame_length，即我们在发送完一个tx_data后，下一个tx_data就已经准备好了。
//如果这不是您的情况，您可能需要添加更多的逻辑来处理这个问题。