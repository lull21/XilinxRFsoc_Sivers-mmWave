
module tb_beam_scan_bs;
    reg clk;
    reg rst_n;
    
    reg [31:0] tx_interval;
    reg [31:0] tx_frame_length;
    
    reg scan_Enable;
    reg scan_Pulse;
    reg [7:0] currentScanSlot;
    
    wire [15:0] bit_out_tdata;
    wire [7:0] tx_segment;
    wire bit_out_tvalid;
    reg bit_out_tready;
    wire [1:0] bit_out_tkeep;
    wire [1:0] bit_out_tstrb;
    wire bit_out_tlast;
    
    //���Խӿ�
    wire [15:0]data_rx;
    wire [7:0] out_user_beam;// �洢ÿ���û��Ĳ�����
    wire [15:0] out_user_snr;
    wire pause_state;
    
    reg [15:0] bit_in_tdata;
    wire [7:0] rx_segment;
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
        .out_user_beam(out_user_beam),// �洢ÿ���û��Ĳ�����
        .out_user_snr(out_user_snr),
        .pause_state(pause_state), // ������״̬������1Ϊ��ͣ��0Ϊ����
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
        bit_in_tdata = 16'hABAB;
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
                #20;
            end
//            #100; // Wait for the next slot
        end
    end
    always #10 clk = ~clk;
endmodule