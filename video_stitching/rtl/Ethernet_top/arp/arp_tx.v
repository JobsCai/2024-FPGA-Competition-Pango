//************************************************
// Author       : Jack
// Create Date  : 2023-04-28 21:12:55
// File Name    : arp_tx.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module arp_tx #(
    parameter BOARD_MAC     = 48'h00_11_22_33_44_55         , //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_IP      = {8'd192, 8'd168, 8'd1, 8'd10} , //开发板IP地址 192.168.1.10
    parameter DES_MAC       = 48'hff_ff_ff_ff_ff_ff         , //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter DES_IP        = {8'd192, 8'd168, 8'd1, 8'd102}  //目的IP地址 192.168.1.102
)(
    input   wire            clk        , //时钟信号
    input   wire            rst_n      , //复位信号，低电平有效
    
    input   wire            arp_tx_en  , //ARP发送使能信号
    input   wire            arp_tx_type, //ARP发送类型 0:请求  1:应答
    input   wire    [47:0]  des_mac    , //发送的目标MAC地址
    input   wire    [31:0]  des_ip     , //发送的目标IP地址
    input   wire    [31:0]  crc_data   , //CRC校验数据
    input   wire    [ 7:0]  crc_next   , //CRC下次校验完成数据
    output  reg             tx_done    , //以太网发送完成信号
    output  reg             gmii_tx_en , //GMII输出数据有效信号
    output  reg     [ 7:0]  gmii_txd   , //GMII输出数据
    output  reg             crc_en     , //CRC开始校验使能
    output  reg             crc_clr      //CRC数据复位信号 
);
/*************************parameter**************************/
localparam CODE_PREAMBLE = 8'h55    ; // 前导码其实是7个8'h55
localparam CODE_SFD      = 8'hd5    ; // 帧起始界定符
localparam ETH_TYPE      = 16'h0806 ; // 以太网帧类型：ARP协议
localparam HD_TYPE       = 16'h0001 ; // 硬件类型：以太网
localparam PROTOCOL_TYPE = 16'h0800 ; // 上层协议为IP协议
localparam MIN_DATA_NUM  = 16'd46   ; // 以太网数据最小为46个字节,不足部分填充数据

/****************************reg*****************************/
reg             r0_arp_tx_en    ;
reg             r1_arp_tx_en    ;

reg             skip_en         ; // 控制状态跳转使能信号
reg     [ 5:0]  cnt             ; // 解析数据计数器
reg     [ 4:0]  data_cnt        ; // 发送数据个数计数器
reg             r_tx_done       ;

reg     [ 7:0]  preamble[7:0]   ; // 前导码+SFD
reg     [ 7:0]  eth_head[13:0]  ; // 以太网首部
reg     [ 7:0]  arp_data[27:0]  ; // ARP 数据

/****************************wire****************************/
wire            arp_tx_en_posedge;

/********************combinational logic*********************/
assign arp_tx_en_posedge = r0_arp_tx_en && (!r1_arp_tx_en);

/****************************FSM*****************************/
reg     [4:0]   fsm_c;
reg     [4:0]   fsm_n;

localparam ST_IDLE     = 5'b00001; // 初始状态，等待开始发送信号
localparam ST_PREAMBLE = 5'b00010; // 发送前导码+帧起始界定符
localparam ST_ETH_HEAD = 5'b00100; // 发送以太网帧头
localparam ST_ARP_DATA = 5'b01000; // 发送 ARP 数据包
localparam ST_CRC      = 5'b10000; // 发送 CRC 校验值

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        fsm_c <= ST_IDLE;
    else
        fsm_c <= fsm_n;
end

always@(*)
begin
    case(fsm_c)
        ST_IDLE:                        // 空闲状态
            if(skip_en)
                fsm_n = ST_PREAMBLE;
            else
                fsm_n = ST_IDLE;
        ST_PREAMBLE:                    // 发送前导码+帧起始界定符
            if(skip_en)
                fsm_n = ST_ETH_HEAD;
            else
                fsm_n = ST_PREAMBLE;
        ST_ETH_HEAD:                    // 发送以太网首部
            if(skip_en)
                fsm_n = ST_ARP_DATA;
            else
                fsm_n = ST_ETH_HEAD;
        ST_ARP_DATA:                    // 发送 ARP 数据
            if(skip_en)
                fsm_n = ST_CRC;
            else
                fsm_n = ST_ARP_DATA;
        ST_CRC:                         // 发送 CRC 校验值
            if(skip_en)
                fsm_n = ST_IDLE;
            else
                fsm_n = ST_CRC;
        default:
                fsm_n = ST_IDLE;
    endcase
end

/**************************process***************************/
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r0_arp_tx_en <= 1'b0;
            r1_arp_tx_en <= 1'b0;
        end
    else
        begin
            r0_arp_tx_en <= arp_tx_en;
            r1_arp_tx_en <= r0_arp_tx_en;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        skip_en <= 1'b0;
    else case(fsm_n)
        ST_IDLE:
            if(arp_tx_en_posedge)
                skip_en <= 1'b1;
            else
                skip_en <= 1'b0;
        ST_PREAMBLE:
            if(cnt == 6'd7)
                skip_en <= 1'b1;
            else
                skip_en <= 1'b0;
        ST_ETH_HEAD:
            if(cnt == 6'd13)
                skip_en <= 1'b1;
            else
                skip_en <= 1'b0;
        ST_ARP_DATA:
            if(cnt == MIN_DATA_NUM - 1)
                skip_en <= 1'b1;
            else
                skip_en <= 1'b0;
        ST_CRC:
            if(cnt == 6'd3)
                skip_en <= 1'b1;
            else
                skip_en <= 1'b0;
        default:
                skip_en <= 1'b0;
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt <= 6'd0;
    else case(fsm_n)
        ST_PREAMBLE:
            if(cnt == 6'd7)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        ST_ETH_HEAD:
            if(cnt == 6'd13)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        ST_ARP_DATA:
            if(cnt == MIN_DATA_NUM - 1)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        ST_CRC:
            if(cnt == 6'd3)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        default:
                cnt <= 6'd0;
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        data_cnt <= 5'd0;
    else if(fsm_n == ST_ARP_DATA)
        if(cnt == MIN_DATA_NUM - 1)
            data_cnt <= 5'd0;
        else if(data_cnt <= 5'd27)
            data_cnt <= data_cnt + 1'b1;
        else
            data_cnt <= data_cnt;
    else
        data_cnt <= data_cnt;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        crc_en <= 1'b0;
    else case(fsm_n)
        ST_ETH_HEAD:
            crc_en <= 1'b1;
        ST_ARP_DATA:
            crc_en <= 1'b1;
        default:
            crc_en <= 1'b0;
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        gmii_tx_en <= 1'b0;
    else case(fsm_n)
        ST_PREAMBLE:
            gmii_tx_en <= 1'b1;
        ST_ETH_HEAD:
            gmii_tx_en <= 1'b1;
        ST_ARP_DATA:
            gmii_tx_en <= 1'b1;
        ST_CRC:
            gmii_tx_en <= 1'b1;
        default:
            gmii_tx_en <= 1'b0;
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        gmii_txd <= 8'd0;
    else case(fsm_n)
        ST_PREAMBLE:
            gmii_txd <= preamble[cnt];
        ST_ETH_HEAD:
            gmii_txd <= eth_head[cnt];
        ST_ARP_DATA:
            if(data_cnt <= 6'd27)
                gmii_txd <= arp_data[data_cnt];
            else
                gmii_txd <= 8'd0;
        ST_CRC:
            if(cnt == 6'd0)
                gmii_txd <= {!crc_next[0], !crc_next[1], !crc_next[2], !crc_next[3], 
                             !crc_next[4], !crc_next[5], !crc_next[6], !crc_next[7]};
            else if(cnt == 6'd1)
                gmii_txd <= {!crc_data[16], !crc_data[17], !crc_data[18], !crc_data[19], 
                             !crc_data[20], !crc_data[21], !crc_data[22], !crc_data[23]};
            else if(cnt == 6'd2)
                gmii_txd <= {!crc_data[ 8], !crc_data[ 9], !crc_data[10], !crc_data[11], 
                             !crc_data[12], !crc_data[13], !crc_data[14], !crc_data[15]};
            else if(cnt == 6'd3)
                gmii_txd <= {!crc_data[0], !crc_data[1], !crc_data[2], !crc_data[3], 
                             !crc_data[4], !crc_data[5], !crc_data[6], !crc_data[7]};
            else
                gmii_txd <= gmii_txd;
        default:
                gmii_txd <= gmii_txd;
    endcase
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_tx_done <= 1'b0;
    else if(fsm_n == ST_CRC)
        if(cnt == 6'd3)
            r_tx_done <= 1'b1;
        else
            r_tx_done <= 1'b0;
    else
        r_tx_done <= 1'b0;
end

// 打一拍发送完成信号及 crc 值复位信号
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            tx_done <= 1'b0;
            crc_clr <= 1'b0;
        end
    else
        begin
            tx_done <= r_tx_done;
            crc_clr <= r_tx_done;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            preamble[0] <= CODE_PREAMBLE;           // 前导码
            preamble[1] <= CODE_PREAMBLE;
            preamble[2] <= CODE_PREAMBLE;
            preamble[3] <= CODE_PREAMBLE;
            preamble[4] <= CODE_PREAMBLE;
            preamble[5] <= CODE_PREAMBLE;
            preamble[6] <= CODE_PREAMBLE;
            preamble[7] <= CODE_SFD;                // 帧起始界定符
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            eth_head[ 0] <= DES_MAC[47:40];         // 目的 eth_head
            eth_head[ 1] <= DES_MAC[39:32];
            eth_head[ 2] <= DES_MAC[31:24];
            eth_head[ 3] <= DES_MAC[23:16];
            eth_head[ 4] <= DES_MAC[15: 8];
            eth_head[ 5] <= DES_MAC[ 7: 0];
            eth_head[ 6] <= BOARD_MAC[47:40];       // 源 eth_head
            eth_head[ 7] <= BOARD_MAC[39:32];
            eth_head[ 8] <= BOARD_MAC[31:24];
            eth_head[ 9] <= BOARD_MAC[23:16];
            eth_head[10] <= BOARD_MAC[15: 8];
            eth_head[11] <= BOARD_MAC[ 7: 0];
            eth_head[12] <= ETH_TYPE[15: 8];        // eth_head类型
            eth_head[13] <= ETH_TYPE[ 7: 0];
        end
    else if(fsm_n == ST_IDLE)
        if(arp_tx_en_posedge && (des_mac != 48'd0)) // 如果目标 MAC 地址已经更新，则发送正确的地址
            begin
                eth_head[ 0] <= des_mac[47:40];         // 目的 MAC 地址
                eth_head[ 1] <= des_mac[39:32];
                eth_head[ 2] <= des_mac[31:24];
                eth_head[ 3] <= des_mac[23:16];
                eth_head[ 4] <= des_mac[15: 8];
                eth_head[ 5] <= des_mac[ 7: 0];
            end
end


always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            arp_data[ 0] <= HD_TYPE[15: 8];         // 硬件类型
            arp_data[ 1] <= HD_TYPE[ 7: 0];
            arp_data[ 2] <= PROTOCOL_TYPE[15: 8];   // 上层协议类型
            arp_data[ 3] <= PROTOCOL_TYPE[ 7: 0];
            arp_data[ 4] <= 8'h06;                  // 硬件地址长度，6
            arp_data[ 5] <= 8'h04;                  // 协议地址长度，4
            arp_data[ 6] <= 8'h00;                  // 操作码(OP) 16'h0001：ARP请求  16'h0002：ARP应答
            arp_data[ 7] <= 8'h01;                  // 操作码
            arp_data[ 8] <= BOARD_MAC[47:40];       // 源 MAC 地址
            arp_data[ 9] <= BOARD_MAC[39:32];
            arp_data[10] <= BOARD_MAC[31:24];
            arp_data[11] <= BOARD_MAC[23:16];
            arp_data[12] <= BOARD_MAC[15: 8];
            arp_data[13] <= BOARD_MAC[ 7: 0];
            arp_data[14] <= BOARD_IP[31:24];        // 源 IP 地址
            arp_data[15] <= BOARD_IP[23:16];
            arp_data[16] <= BOARD_IP[15: 8];
            arp_data[17] <= BOARD_IP[ 7: 0];
            arp_data[18] <= DES_MAC[47:40];         // 目的 MAC 地址
            arp_data[19] <= DES_MAC[39:32];
            arp_data[20] <= DES_MAC[31:24];
            arp_data[21] <= DES_MAC[23:16];
            arp_data[22] <= DES_MAC[15: 8];
            arp_data[23] <= DES_MAC[ 7: 0];
            arp_data[24] <= DES_IP[31:24];          // 目的 IP 地址
            arp_data[25] <= DES_IP[23:16];
            arp_data[26] <= DES_IP[15: 8];
            arp_data[27] <= DES_IP[ 7: 0];
        end
    else if(fsm_n == ST_IDLE)
        if(arp_tx_en_posedge && ((des_mac != 48'd0) || (des_ip != 32'd0))) // 如果目标 MAC 地址和 IP 地址已经更新，则发送正确的地址
            begin
                begin
                    arp_data[18] <= des_mac[47:40];         // 目的 MAC 地址
                    arp_data[19] <= des_mac[39:32];
                    arp_data[20] <= des_mac[31:24];
                    arp_data[21] <= des_mac[23:16];
                    arp_data[22] <= des_mac[15: 8];
                    arp_data[23] <= des_mac[ 7: 0];
                    arp_data[24] <= des_ip[31:24];          // 目的 IP 地址
                    arp_data[25] <= des_ip[23:16];
                    arp_data[26] <= des_ip[15: 8];
                    arp_data[27] <= des_ip[ 7: 0];
                end if(arp_tx_type == 1'b0)
                    arp_data[ 7] <= 8'h01;                  // ARP 请求
                else
                    arp_data[ 7] <= 8'h02;                  // ARP 应答
            end
end

endmodule