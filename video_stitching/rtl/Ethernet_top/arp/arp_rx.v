//************************************************
// Author       : Jack
// Create Date  : 2023-04-28 17:01:48
// File Name    : arp_rx.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module arp_rx #(
    parameter BOARD_MAC     = 48'h00_11_22_33_44_55         , //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_IP      = {8'd192, 8'd168, 8'd1, 8'd10}   //开发板IP地址 192.168.1.10
)(
    input   wire            clk         , //时钟信号
    input   wire            rst_n       , //复位信号，低电平有效
    
    input   wire            gmii_rx_dv  , //GMII输入数据有效信号
    input   wire    [7:0]   gmii_rxd    , //GMII输入数据
    output  reg             arp_rx_done , //ARP接收完成信号
    output  reg             arp_rx_type , //ARP接收类型 0:请求  1:应答
    output  reg     [47:0]  src_mac     , //接收到的源MAC地址
    output  reg     [31:0]  src_ip        //接收到的源IP地址
);
/*************************parameter**************************/
localparam CODE_PREAMBLE = 8'h55    ; // 前导码其实是7个8'h55
localparam CODE_SFD      = 8'hd5    ; // 帧起始界定符
localparam ETH_TYPE      = 16'h0806 ; // 以太网帧类型 ARP
localparam MIN_DATA_NUM  = 46 + 4   ; // 以太网数据最小为46个字节，还有4个字节是校验码

/****************************reg*****************************/
reg             skip_en     ; // 控制状态跳转使能信号
reg             error_en    ; // 解析错误使能信号
reg     [ 5:0]  cnt         ; // 解析数据计数器
reg     [15:0]  op_data     ; // 操作码
reg     [15:0]  eth_type    ; // 以太网类型
reg             r_rx_done   ; // ARP 接收完成信号

reg     [47:0]  r_des_mac   ; // 接收到的目的MAC地址
reg     [31:0]  r_des_ip    ; // 接收到的目的IP地址
reg     [47:0]  r_src_mac   ; // 接收到的源MAC地址
reg     [31:0]  r_src_ip    ; // 接收到的源IP地址

/****************************FSM*****************************/
reg     [4:0]   fsm_c;
reg     [4:0]   fsm_n;

localparam ST_IDLE      = 5'b00001; //初始状态，等待接收前导码
localparam ST_PREAMBLE  = 5'b00010; //接收前导码状态 
localparam ST_ETH_HEAD  = 5'b00100; //接收以太网帧头
localparam ST_ARP_DATA  = 5'b01000; //接收ARP数据
localparam ST_RX_END    = 5'b10000; //接收结束

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
        ST_IDLE:                    //等待接收前导码
            if(skip_en)
                fsm_n = ST_PREAMBLE;
            else
                fsm_n = ST_IDLE;
        ST_PREAMBLE:                // 接收前导码
            if(skip_en)
                fsm_n = ST_ETH_HEAD;
            else if(error_en)
                fsm_n = ST_RX_END;
            else
                fsm_n = ST_PREAMBLE;
        ST_ETH_HEAD:                // 接收以太网帧头
            if(skip_en)
                fsm_n = ST_ARP_DATA;
            else if(error_en)
                fsm_n = ST_RX_END;
            else
                fsm_n = ST_ETH_HEAD;
        ST_ARP_DATA:                // 接收ARP数据
            if(skip_en)
                fsm_n = ST_RX_END;
            else if(error_en)
                fsm_n = ST_RX_END;
            else
                fsm_n = ST_ARP_DATA;
        ST_RX_END:                  // 接收结束
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
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_IDLE:
                if(gmii_rxd == CODE_PREAMBLE) // 检测到前导码
                    skip_en <= 1'b1;
                else
                    skip_en <= 1'b0;
            ST_PREAMBLE:
                if(cnt == 6'd6)
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
            default:
                    skip_en <= 1'b0;
        endcase
    else if(fsm_n == ST_RX_END) // 最后一个状态且数据无效时返回IDLE
        skip_en <= 1'b1;
    else
        skip_en <= 1'b0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        error_en <= 1'b0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_IDLE:
                    error_en <= 1'b0;
            ST_PREAMBLE:
                if((cnt < 6'd6) && (gmii_rxd != CODE_PREAMBLE)) // 判断前导码
                    error_en <=1'b1;
                else if((cnt == 6'd6) && (gmii_rxd != CODE_SFD)) // 判断帧起始界定符
                    error_en <= 1'b1;
                else
                    error_en <= error_en;
            ST_ETH_HEAD:
                if((cnt == 6'd6) && (r_des_mac != BOARD_MAC) && (r_des_mac != 48'hff_ff_ff_ff_ff_ff)) //判断MAC地址是否为开发板MAC地址或者公共地址
                    error_en <= 1'b1;
                else if((cnt == 6'd13) && ((eth_type[15:8] != ETH_TYPE[15:8]) || (gmii_rxd != ETH_TYPE[7:0]))) //判断是否为ARP协议
                    error_en <= 1'b1;
                else
                    error_en <= error_en;
            ST_ARP_DATA:
                if((cnt == 6'd28) && ((op_data != 16'd1) && (op_data != 16'd2) || (r_des_ip != BOARD_IP))) // 判断目的 IP 地址和 ARP 数据包的操作码
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
        cnt <= 6'd0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_IDLE:
                    cnt <= 6'd0;
            ST_PREAMBLE:
                if(cnt == 6'd6)
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
            ST_RX_END:
                    cnt <= 6'd0;
            default:
                    cnt <= 6'd0;
        endcase
    else
        cnt <= 6'd0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_des_mac <= 48'd0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_ETH_HEAD:
                if(cnt < 6'd6)
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
            ST_ARP_DATA:
                if((cnt >= 6'd24) && (cnt <6'd28))
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
        r_src_mac <= 48'd0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_ARP_DATA:
                if((cnt >= 6'd8) && (cnt <6'd14))
                    r_src_mac <= {r_src_mac[39:0], gmii_rxd};
                else
                    r_src_mac <= r_src_mac;
            default:
                    r_src_mac <= r_src_mac;
        endcase
    else
        r_src_mac <= 48'd0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_src_ip <= 32'd0;
    else if(gmii_rx_dv) // 数据有效时进行判断
        case(fsm_n)
            ST_ARP_DATA:
                if((cnt >= 6'd14) && (cnt < 6'd18))
                    r_src_ip <= {r_src_ip[23:0], gmii_rxd};
                else
                    r_src_ip <= r_src_ip;
            default:
                    r_src_ip <= r_src_ip;
        endcase
    else
        r_src_ip <= 32'd0;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            src_mac <= 48'd0;
            src_ip  <= 32'd0;
        end
    else if((fsm_n == ST_RX_END) && (!error_en))
        begin
            src_mac <= r_src_mac;
            src_ip  <= r_src_ip ;
        end
    else
        begin
            src_mac <= src_mac;
            src_ip  <= src_ip ;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        eth_type <= 16'd0;
    else if(gmii_rx_dv && (fsm_n == ST_ETH_HEAD))
        if(cnt == 6'd12)
            eth_type[15:8] <= gmii_rxd;
        else if(cnt == 6'd13)
            eth_type[7:0]  <= gmii_rxd;
        else
            eth_type <= eth_type;
    else
        eth_type <= eth_type;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        op_data <= 16'd0;
    else if(gmii_rx_dv && (fsm_n == ST_ARP_DATA))
        if(cnt == 6'd6)
            op_data[15:8] <= gmii_rxd;
        else if(cnt == 6'd7)
            op_data[7:0]  <= gmii_rxd;
        else
            op_data <= op_data;
    else
        op_data <= op_data;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_rx_done <= 1'b0;
    else if((fsm_n == ST_RX_END) && (!error_en))
        r_rx_done <= 1'b1;
    else
        r_rx_done <= 1'b0;
end

// 打一拍再输出有助于时序
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        arp_rx_done <= 1'b0;
    else
        arp_rx_done <= r_rx_done;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        arp_rx_type <= 1'b0;
    else if(fsm_n == ST_ARP_DATA)
        if((cnt == 6'd28) && (r_des_ip == BOARD_IP) && ((op_data == 16'd1) || (op_data == 16'd2)))
            if(op_data == 16'd1)
                arp_rx_type <= 1'b0;
            else
                arp_rx_type <= 1'b1;
        else
            arp_rx_type <= arp_rx_type;
    else
        arp_rx_type <= arp_rx_type;
end

endmodule