//************************************************
// Author       : Jack
// Create Date  : 2023-04-30 21:23:17
// File Name    : udp_rx.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module udp_rx #(
    parameter BOARD_MAC     = 48'h00_11_22_33_44_55         , //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_IP      = {8'd192, 8'd168, 8'd1, 8'd10}   //开发板IP地址 192.168.1.10
)(
    input   wire            clk         , // 时钟信号
    input   wire            rst_n       , // 复位信号，低电平有效
    
    input   wire            gmii_rx_dv  , // GMII输入数据有效信号
    input   wire    [7:0]   gmii_rxd    , // GMII输入数据
    output  reg             rx_start    , // 以太网接收的新一帧数据即将开始信号
    output  wire            rx_valid    , // 以太网接收的数据使能信号
    output  reg     [31:0]  rx_data       // 以太网接收的数据
);

/*************************parameter**************************/
localparam CODE_PREAMBLE = 8'h55    ; // 前导码其实是7个8'h55
localparam CODE_SFD      = 8'hd5    ; // 帧起始界定符
localparam ETH_TYPE      = 16'h0800 ; // 以太网协议类型 IP协议
localparam UDP_TYPE      = 8'd17    ; // UDP 协议类型
localparam ROW_VALID     = 8'h00    ; // 行有效信号
localparam FRAME_SIGNAL  = 8'hff    ; // 帧开始信号

/****************************reg*****************************/
reg             skip_en         ; // 控制状态跳转使能信号
reg             error_en        ; // 解析错误使能信号
reg     [ 4:0]  cnt             ; // 解析数据计数器
reg     [15:0]  eth_type        ; // 以太网类型
reg     [ 5:0]  ip_head_byte_num; // IP首部长度
reg     [15:0]  udp_byte_num    ; // UDP长度
reg     [15:0]  data_byte_num   ; // 数据长度
reg     [15:0]  data_cnt        ; // 有效数据计数
reg     [ 1:0]  rx_en_cnt       ; // 8bit转24bit计数器
reg             rx_en           ; // 每24bit有效信号
reg             rx_success      ; // 接收到的是有效信号

reg     [47:0]  r_des_mac       ; // 接收到的目的MAC地址
reg     [31:0]  r_des_ip        ; // 接收到的目的IP地址

/****************************wire****************************/


/********************combinational logic*********************/
assign rx_valid = rx_en && rx_success;

/****************************FSM*****************************/
reg     [6:0]   fsm_c   ;
reg     [6:0]   fsm_n   ;

localparam ST_IDLE      = 7'b000_0001; // 初始状态，等待接收前导码
localparam ST_PREAMBLE  = 7'b000_0010; // 接收前导码状态 
localparam ST_ETH_HEAD  = 7'b000_0100; // 接收以太网帧头
localparam ST_IP_HEAD   = 7'b000_1000; // 接收IP首部
localparam ST_UDP_HEAD  = 7'b001_0000; // 接收UDP首部
localparam ST_RX_DATA   = 7'b010_0000; // 接收有效数据
localparam ST_RX_END    = 7'b100_0000; // 接收结束

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
        ST_IDLE:
            if(skip_en)
                fsm_n = ST_PREAMBLE;
            else
                fsm_n = ST_IDLE;
        ST_PREAMBLE:
            if(error_en)
                fsm_n = ST_RX_END;
            else if(skip_en)
                fsm_n = ST_ETH_HEAD;
            else
                fsm_n = ST_PREAMBLE;
        ST_ETH_HEAD:
            if(error_en)
                fsm_n = ST_RX_END;
            else if(skip_en)
                fsm_n = ST_IP_HEAD;
            else
                fsm_n = ST_ETH_HEAD;
        ST_IP_HEAD:
            if(error_en)
                fsm_n = ST_RX_END;
            else if(skip_en)
                fsm_n = ST_UDP_HEAD;
            else
                fsm_n = ST_IP_HEAD;
        ST_UDP_HEAD:
            if(skip_en)
                fsm_n = ST_RX_DATA;
            else
                fsm_n = ST_UDP_HEAD;
        ST_RX_DATA:
            if(skip_en)
                fsm_n = ST_RX_END;
            else
                fsm_n = ST_RX_DATA;
        ST_RX_END:
            if(skip_en)
                fsm_n = ST_IDLE;
            else
                fsm_n = ST_RX_END;
        default:
                fsm_n = ST_IDLE;
    endcase
end

/**************************process***************************/
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        skip_en <= 1'b0;
    else if(gmii_rx_dv)
        case(fsm_n)
            ST_IDLE:
                if(gmii_rxd == CODE_PREAMBLE)
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            ST_PREAMBLE:
                if(cnt == 5'd6)
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            ST_ETH_HEAD:
                if(cnt == 5'd13)
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            ST_IP_HEAD:
                if(cnt == ip_head_byte_num - 1'b1)
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            ST_UDP_HEAD:
                if(cnt == 5'd7)
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            ST_RX_DATA:
                if(data_cnt == data_byte_num - 1'b1)
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            default:
                    skip_en <= 1'b0;
        endcase
    else if(fsm_n == ST_RX_END)
                    skip_en <= 1'b1;
    else
                    skip_en <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        error_en <= 1'b0;
    else if(gmii_rx_dv)
        case(fsm_n)
            ST_IDLE:
                error_en <= 1'b0;
            ST_PREAMBLE:
                if((cnt < 5'd6) && (gmii_rxd != CODE_PREAMBLE))
                    error_en <= 1'b1;
                else if((cnt == 5'd6) && (gmii_rxd != CODE_SFD))
                    error_en <= 1'b1;
                else
                    error_en <= error_en;
            ST_ETH_HEAD:
                if((cnt == 5'd6) && (r_des_mac != BOARD_MAC) && (r_des_mac != 48'hff_ff_ff_ff_ff_ff)) //判断MAC地址是否为开发板MAC地址或者公共地址
                    error_en <= 1'b1;
                else if((cnt == 5'd13) && ((eth_type[15:8] != ETH_TYPE[15:8]) || (gmii_rxd != ETH_TYPE[7:0]))) //判断是否为UDP协议
                    error_en <= 1'b1;
                else
                    error_en <= error_en;
            ST_IP_HEAD:
                if((cnt == 5'd9) && (gmii_rxd != UDP_TYPE))
                    error_en <= 1'b1;
                else if((cnt == 5'd19) && ((r_des_ip[23:0] != BOARD_IP[31:8]) || (gmii_rxd != BOARD_IP[7:0])))
                    error_en <= 1'b1;
                else
                    error_en <= error_en;
            default:
                    error_en <= error_en;
        endcase
    else
        error_en <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt <= 5'd0;
    else if(gmii_rx_dv)
        case(fsm_n)
            ST_PREAMBLE:
                if(cnt == 5'd6)
                    cnt <= 5'd0;
                else
                    cnt <= cnt + 1'b1;
            ST_ETH_HEAD:
                if(cnt == 5'd13)
                    cnt <= 5'd0;
                else
                    cnt <= cnt + 1'b1;
            ST_IP_HEAD:
                if(cnt == ip_head_byte_num - 1'b1)
                    cnt <= 5'd0;
                else
                    cnt <= cnt + 1'b1;
            ST_UDP_HEAD:
                if(cnt == 5'd7)
                    cnt <= 5'd0;
                else
                    cnt <= cnt + 1'b1;
            default:
                    cnt <= 5'd0;
        endcase
    else
        cnt <= 5'd0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_des_mac <= 48'd0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_ETH_HEAD:
                if(cnt < 5'd6)
                    r_des_mac <= {r_des_mac[39:0], gmii_rxd};
                else
                    r_des_mac <= r_des_mac;
            default:
                    r_des_mac <= r_des_mac;
        endcase
    else
        r_des_mac <= 48'd0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_des_ip <= 32'd0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_IP_HEAD:
                if((cnt >= 5'd16) && (cnt < 5'd20))
                    r_des_ip <= {r_des_ip[23:0], gmii_rxd};
                else
                    r_des_ip <= r_des_ip;
            default:
                    r_des_ip <= r_des_ip;
        endcase
    else
        r_des_ip <= 32'd0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        eth_type <= 16'd0;
    else if(gmii_rx_dv && (fsm_n == ST_ETH_HEAD))
        if(cnt == 5'd12)
            eth_type[15:8] <= gmii_rxd;
        else if(cnt == 5'd13)
            eth_type[7:0]  <= gmii_rxd;
        else
            eth_type <= eth_type;
    else
        eth_type <= eth_type;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        ip_head_byte_num <= 6'd0;
    else if(gmii_rx_dv && (fsm_n == ST_IP_HEAD))
        if(cnt == 5'd0)
            ip_head_byte_num <= {gmii_rxd[3:0], 2'd0};
        else
            ip_head_byte_num <= ip_head_byte_num;
    else
        ip_head_byte_num <= ip_head_byte_num;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        udp_byte_num <= 16'd0;
    else if(gmii_rx_dv && (fsm_n == ST_UDP_HEAD))
        if(cnt == 5'd4)
            udp_byte_num[15:8] <= gmii_rxd;
        else if(cnt == 5'd5)
            udp_byte_num[7:0]  <= gmii_rxd;
        else
            udp_byte_num <= udp_byte_num;
    else
            udp_byte_num <= udp_byte_num;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        data_byte_num <= 16'd0;
    else if(gmii_rx_dv && (fsm_n == ST_UDP_HEAD))
        if(cnt == 5'd7)
            data_byte_num <= udp_byte_num - 16'd8;
        else
            data_byte_num <= data_byte_num;
    else
            data_byte_num <= data_byte_num;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        data_cnt <= 16'd0;
    else if(gmii_rx_dv && (fsm_n == ST_RX_DATA))
        if(data_cnt == data_byte_num - 1'b1)
            data_cnt <= 16'd0;
        else
            data_cnt <= data_cnt + 1'b1;
    else
            data_cnt <= data_cnt;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rx_en_cnt <= 2'd0;
    else if(gmii_rx_dv && (fsm_n == ST_RX_DATA))
        if(data_cnt == data_byte_num - 1'b1)
            rx_en_cnt <= 2'd0;
        else if(data_cnt == 16'd0)
            rx_en_cnt <= 2'd0;
        else if(rx_en_cnt == 2'd2)
            rx_en_cnt <= 2'd0;
        else
            rx_en_cnt <= rx_en_cnt + 1'b1;
    else
            rx_en_cnt <= rx_en_cnt;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rx_en <= 1'b0;
    else if(gmii_rx_dv && (fsm_n == ST_RX_DATA))
        if(data_cnt == data_byte_num - 1'b1)
            rx_en <= 1'b1;
        else if(rx_en_cnt == 2'd2)
            rx_en <= 1'b1;
        else
            rx_en <= 1'b0;
    else
            rx_en <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rx_success <= 1'b0;
    else if(gmii_rx_dv && (fsm_n == ST_RX_DATA))
        if((data_cnt == 16'd0) && (gmii_rxd == ROW_VALID))
            rx_success <= 1'b1;
        else
            rx_success <= rx_success;
    else
        rx_success <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rx_data <= 32'd0;
    else if(gmii_rx_dv && (fsm_n == ST_RX_DATA))
        if(rx_en_cnt == 2'd0)
            rx_data[23:16] <= gmii_rxd;
        else if(rx_en_cnt == 2'd1)
            rx_data[15: 8] <= gmii_rxd;
        else if(rx_en_cnt == 2'd2)
            rx_data[ 7: 0] <= gmii_rxd;
        else
            rx_data <= rx_data;
    else
            rx_data <= rx_data;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rx_start <= 1'b0;
    else if(gmii_rx_dv && (fsm_n == ST_RX_DATA))
        if((data_cnt == 16'd0) && (gmii_rxd == FRAME_SIGNAL))
            rx_start <= 1'b1;
        else
            rx_start <= rx_start;
    else
        rx_start <= 1'b0;
end

/*---------------------------------------------------*/


endmodule