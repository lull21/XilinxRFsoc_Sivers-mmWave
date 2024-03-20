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
    input wire clk,           // 时钟信号
    input wire rst,           // 复位信号
    output reg BF_RST,        // BF_RST信号
    output reg BF_RTN,        // BF_RTN信号
    output reg BF_INC         // BF_INC信号
);

reg [5:0] beam_index;        // 波束索引值，共64个值（0-63）

// 默认值
parameter DEFAULT_INDEX = 6;  // 预编程的默认索引值

// 状态机
reg [1:0] state;            // 状态变量，用于表示IDLE、SCAN和SELECT三种状态
localparam IDLE = 2'b00;    // 定义IDLE状态的值为2'b00
localparam SCAN = 2'b01;    // 定义SCAN状态的值为2'b01
localparam SELECT = 2'b10;  // 定义SELECT状态的值为2'b10
reg [3:0] frame_counter;    // 帧计数器

//这一部分需要与下面控制射频端口进行联动，当在发端控制哪一个波束时，需要通过射频端广播当前波束号

//这一部分仅是用来控制射频端三个GPIO口
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
                // 自行选择控制的波束索引值
                // 这里暂时未做具体实现，可以根据需要添加相应的逻辑
                //根据反馈数据进行选择
                state <= IDLE;
            end
        endcase
    end
end

endmodule

