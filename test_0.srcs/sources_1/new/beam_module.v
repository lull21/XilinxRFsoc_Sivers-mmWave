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
// Description: 此模块将波束扫描与波束射频控制耦合
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module beam_module(
    input wire clk,           // 时钟信号
    input wire rst,           // 复位信号
    
    output reg BF_RST,        // BF_RST信号
    output reg BF_RTN,        // BF_RTN信号
    output reg BF_INC,         // BF_INC信号
    
    input wire  [31:0] tx_interval,
    input wire  [31:0] tx_frame_length,
    
    input wire scan_Enable, // 标志当前为扫描调度阶段
    input wire scan_Pulse,  // 触发扫描调度过程，在每个扫描时隙起始时刻给出
    input wire  [7:0] currentScanSlot,  //当前扫描时隙，可以通过此时时隙号来确定当前波束索引

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
// ============波束控制部分初始值============= //
    // 默认值
    parameter DEFAULT_INDEX = 6;  // 预编程的默认索引值
    // 状态机
    reg [1:0] state;            // 状态变量，用于表示IDLE、SCAN和SELECT三种状态
    localparam IDLE = 2'b00;    // 定义IDLE状态的值为2'b00
    localparam SCAN = 2'b01;    // 定义SCAN状态的值为2'b01
    localparam SELECT = 2'b10;  // 定义SELECT状态的值为2'b10
    reg [3:0] frame_counter;    // 帧计数器
    
// ============波束扫描部分初始值============= //    
    reg [7:0] beam_index [63:0]; //// 这有问题 Array to store the beam numbers,前面是每个寄存器大小，后面是有多少寄存器
    reg [7:0] beam_count = 0; // Counter for the beam numbers
    reg [31:0] cnt_tlast; 
    reg [31:0] cnt_point_transed;
    reg [5:0]  segment = 0; 
    reg [95:0] tx_data; // Data to be transmitted
    reg send_data; // Flag to control data transmission
    integer i; 
 
// ====这一部分仅是用来控制射频端三个GPIO口（或许这个模块可以放在RF_Ctrl中）==== //
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
                    // 自行选择控制的波束索引值
                    // 这里暂时未做具体实现，可以根据需要添加相应的逻辑
                    //根据反馈数据进行选择
                    state <= IDLE;
                end
            endcase
        end
    end

// ====这一部分用来发送波束扫描帧==== //
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
