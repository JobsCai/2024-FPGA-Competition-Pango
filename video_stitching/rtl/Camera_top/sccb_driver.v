//************************************************
// Author       : Jack
// Creat Date   : 2023年3月27日 17:01:36
// File Name    : sccb_driver.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : SCCB驱动模块
//************************************************

module sccb_driver#(
    parameter SLAVE_ADDR    = 7'b1010000    , // 从器件的地址
    parameter CLK_FREQ      = 26'd50_000_000, // SCCB模块的时钟频率
    parameter SCCB_FREQ     = 18'd250_000     // SCCB的驱动时钟频率
)(
    input   wire            clk         , // 输入时钟
    input   wire            rst_n       , // 复位信号
    input   wire            sccb_exec   , // 开始执行I2C传输信号
    input   wire    [15:0]  sccb_addr   , // 读写地址
    input   wire    [ 7:0]  sccb_data_w , // 写入数据
    output  reg             sccb_done   , // SCCB一次操作完成信号
    output  reg             scl         /*synthesis PAP_MARK_DEBUG="true"*/, // SCCB的SCL时钟信号
    inout   wire            sda         , // SCCB的SDA信号
    output  reg             dri_clk       // 驱动SCCB操作的驱动时钟
);
/****************************reg*****************************/
reg             sda_dir     ; // SCCB端口的控制信号
reg             sda_out     ; // SCCB端口的输出数据

reg     [ 7:0]  clk_cnt     ; // 倍频时钟的计数器

/****************************wire****************************/
wire            sda_in      ; // SCCB端口的输入数据

wire    [ 7:0]  clk_divide  ; // 驱动时钟的分频系数

/********************combinational logic*********************/
// SDA三态控制，通过控制信号输出数据或高阻
assign sda = sda_dir ? sda_out : 1'bz;
// SDA输入数据
assign sda_in = sda;

// 模块驱动时钟的分频系数
assign clk_divide = (CLK_FREQ / SCCB_FREQ) >> 2'd3;

/****************************FSM*****************************/
localparam IDLE     = 6'b00_0001; // 空闲状态
localparam WR_ADDR  = 6'b00_0010; // 输出器件地址和写命令（0）
localparam ADDR16   = 6'b00_0100; // 输出字地址的高8位
localparam ADDR8    = 6'b00_1000; // 输出字地址的低8位
localparam DATA_WR  = 6'b01_0000; // 输出写入的数据
localparam STOP     = 6'b10_0000; // 结束I2C操作

reg     [ 5:0]  fsm_c       ;
reg     [ 5:0]  fsm_n       ;
reg             st_done     ; // 状态完成标志位
reg     [ 6:0]  cnt         ; // 状态中的计数器
reg     [15:0]  addr        ; // 操作的地址
reg     [ 7:0]  data_wr     ; // 写入的数据

/*------------------------segment 1-------------------------*/
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        fsm_c <= IDLE;
    else
        fsm_c <= fsm_n;
end

/*------------------------segment 2-------------------------*/
always@(*)
begin
    case(fsm_c)
        IDLE:
            if(sccb_exec)
                fsm_n = WR_ADDR;
            else
                fsm_n = fsm_c;
        WR_ADDR:
            if(st_done)
                fsm_n = ADDR16;
            else
                fsm_n = fsm_c;
        ADDR16:
            if(st_done)
                fsm_n = ADDR8;
            else
                fsm_n = fsm_c;
        ADDR8:
            if(st_done)
                fsm_n = DATA_WR;
            else
                fsm_n = fsm_c;
        DATA_WR:
            if(st_done)
                fsm_n = STOP;
            else
                fsm_n = fsm_c;
        STOP:
            if(st_done)
                fsm_n = IDLE;
            else
                fsm_n = fsm_c;
        default:
            fsm_n = IDLE;
    endcase
end

/*------------------------segment 3-------------------------*/
// 状态中的计数器
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        cnt <= 6'd0;
    else case(fsm_c)
        IDLE:
            cnt <= 7'd0;
        ADDR16, ADDR8, DATA_WR:
            if(cnt == 6'd35)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        WR_ADDR:
            if(cnt == 6'd39)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        STOP:
            if(cnt == 6'd3)
                cnt <= 6'd0;
            else
                cnt <= cnt + 1'b1;
        default:
            cnt <= 6'd0;
    endcase
end

// 操作的地址
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        addr <= 1'b0;
    else if(sccb_exec && fsm_c == IDLE)
        addr <= sccb_addr;
    else
        addr <= addr;
end

// 写入的数据
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        data_wr <= 1'b0;
    else if(sccb_exec && fsm_c == IDLE)
        data_wr <= sccb_data_w;
    else
        data_wr <= data_wr;
end

// SCL信号
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        scl <= 1'b1;
    else case(fsm_c)
        IDLE:
            scl <= 1'b1;
        WR_ADDR:
            case(cnt)
                6'd 1	: scl <= 1'b1	;
                6'd 3	: scl <= 1'b0	;
                6'd 5	: scl <= 1'b1	;
                6'd 7	: scl <= 1'b0	;
                6'd 9	: scl <= 1'b1	;
                6'd11	: scl <= 1'b0	;
                6'd13	: scl <= 1'b1	;
                6'd15	: scl <= 1'b0	;
                6'd17	: scl <= 1'b1	;
                6'd19	: scl <= 1'b0	;
                6'd21	: scl <= 1'b1	;
                6'd23	: scl <= 1'b0	;
                6'd25	: scl <= 1'b1	;
                6'd27	: scl <= 1'b0	;
                6'd29	: scl <= 1'b1	;
                6'd31	: scl <= 1'b0	;
                6'd33	: scl <= 1'b1	;
                6'd35	: scl <= 1'b0	;
                6'd37	: scl <= 1'b1	;
                6'd39	: scl <= 1'b0	;
                default	: scl <= scl	;
            endcase
        ADDR16, ADDR8, DATA_WR:
            case(cnt)
                6'd 1	: scl <= 1'b1	;
                6'd 3	: scl <= 1'b0	;
                6'd 5	: scl <= 1'b1	;
                6'd 7	: scl <= 1'b0	;
                6'd 9	: scl <= 1'b1	;
                6'd11	: scl <= 1'b0	;
                6'd13	: scl <= 1'b1	;
                6'd15	: scl <= 1'b0	;
                6'd17	: scl <= 1'b1	;
                6'd19	: scl <= 1'b0	;
                6'd21	: scl <= 1'b1	;
                6'd23	: scl <= 1'b0	;
                6'd25	: scl <= 1'b1	;
                6'd27	: scl <= 1'b0	;
                6'd29	: scl <= 1'b1	;
                6'd31	: scl <= 1'b0	;
                6'd33	: scl <= 1'b1	;
                6'd35	: scl <= 1'b0	;
                default	: scl <= scl	;
            endcase
        STOP:
            if(cnt == 6'd1)
                scl <= 1'b1;
            else
                scl <= scl;
        default:
            scl <= 1'b1;
    endcase
end

// SDA信号
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        sda_dir <= 1'b1;
    else case(fsm_c)
        IDLE, STOP:
            sda_dir <= 1'b1;
        WR_ADDR:
            case(cnt)
                6'd 0	: sda_dir <= 1'b1		;
                6'd36	: sda_dir <= 1'b0		;
                default	: sda_dir <= sda_dir	;
            endcase
        ADDR16, ADDR8, DATA_WR:
            case(cnt)
                6'd 0	: sda_dir <= 1'b1		;
                6'd32	: sda_dir <= 1'b0		;
                default	: sda_dir <= sda_dir	;
            endcase
        default:
            sda_dir <= 1'b1;
    endcase
end
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        sda_out <= 1'b1;
    else case(fsm_c)
        IDLE:
            sda_out <= 1'b1;
        WR_ADDR:
            case(cnt)
                6'd 0	: sda_out <= 1'b0			;
                6'd 4	: sda_out <= SLAVE_ADDR[6]	;
                6'd 8	: sda_out <= SLAVE_ADDR[5]	;
                6'd12	: sda_out <= SLAVE_ADDR[4]	;
                6'd16	: sda_out <= SLAVE_ADDR[3]	;
                6'd20	: sda_out <= SLAVE_ADDR[2]	;
                6'd24	: sda_out <= SLAVE_ADDR[1]	;
                6'd28	: sda_out <= SLAVE_ADDR[0]	;
                6'd32	: sda_out <= 1'b0			;
                default	: sda_out <= sda_out		;
            endcase
        ADDR16:
            case(cnt)
                6'd 0	: sda_out <= addr[15]	;
                6'd 4	: sda_out <= addr[14]	;
                6'd 8	: sda_out <= addr[13]	;
                6'd12	: sda_out <= addr[12]	;
                6'd16	: sda_out <= addr[11]	;
                6'd20	: sda_out <= addr[10]	;
                6'd24	: sda_out <= addr[ 9]	;
                6'd28	: sda_out <= addr[ 8]	;
                default	: sda_out <= sda_out	;
            endcase
        ADDR8:
            case(cnt)
                6'd 0	: sda_out <= addr[ 7]	;
                6'd 4	: sda_out <= addr[ 6]	;
                6'd 8	: sda_out <= addr[ 5]	;
                6'd12	: sda_out <= addr[ 4]	;
                6'd16	: sda_out <= addr[ 3]	;
                6'd20	: sda_out <= addr[ 2]	;
                6'd24	: sda_out <= addr[ 1]	;
                6'd28	: sda_out <= addr[ 0]	;
                default	: sda_out <= sda_out	;
            endcase
        DATA_WR:
            case(cnt)
                6'd 0	: sda_out <= data_wr[7]	;
                6'd 4	: sda_out <= data_wr[6]	;
                6'd 8	: sda_out <= data_wr[5]	;
                6'd12	: sda_out <= data_wr[4]	;
                6'd16	: sda_out <= data_wr[3]	;
                6'd20	: sda_out <= data_wr[2]	;
                6'd24	: sda_out <= data_wr[1]	;
                6'd28	: sda_out <= data_wr[0]	;
                default	: sda_out <= sda_out	;
            endcase
        STOP:
            case(cnt)
                6'd0	: sda_out <= 1'b0	;
                6'd3	: sda_out <= 1'b1	;
                default	: sda_out <= sda_out;
            endcase
        default:
            sda_out <= 1'b1;
    endcase
end

// 状态完成标志位
always@(posedge dri_clk or negedge rst_n)
begin
    if(!rst_n)
        st_done <= 1'b0;
    else case(fsm_c)
        IDLE:
            st_done <= 1'b0;
        WR_ADDR:
            if(cnt == 6'd38)
                st_done <= 1'b1;
            else
                st_done <= 1'b0;
        ADDR16, ADDR8, DATA_WR:
            if(cnt == 6'd34)
                st_done <= 1'b1;
            else
                st_done <= 1'b0;
        STOP:
            if(cnt == 6'd2)
                st_done <= 1'b1;
            else
                st_done <= 1'b0;
        default:
            st_done <= 1'b0;
    endcase
end

// 一次传输完成信号
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sccb_done <= 1'b0;
    else if(fsm_c == STOP && cnt == 6'd3)
        sccb_done <= 1'b1;
    else
        sccb_done <= 1'b0;
end

/**************************process***************************/
// 生成SCCB的SCL的四倍频率的驱动时钟用于驱动SCCB的操作
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        clk_cnt <= 8'd0;
    else if(clk_cnt == clk_divide - 1'b1)
        clk_cnt <= 8'd0;
    else
        clk_cnt <= clk_cnt + 1'b1;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        dri_clk <= 1'b0;
    else if(clk_cnt == clk_divide - 1'b1)
        dri_clk <= !dri_clk;
    else
        dri_clk <= dri_clk;
end

endmodule
