# 项目描述

- 功能：该项目实现了四路视频拼接，输入包括1920x1080@60 HDMI、960x540@30 摄像头、960x540网口（HDMI输入复用一次），输出为1920x1080@60 HDMI。可以通过修改DDR3_interface_top模块的输入实现任意视频源的拼接。
- 硬件平台：紫光同创盘古-50K
- EDA平台：Pango Design Suite 2022.1

# 各模块功能

- Camera_top（摄像头顶层模块）
  - sccb_driver：产生sccb协议信号，配合ov5640_lut模块储存的寄存器信息，配置ov5640寄存器
  - cam_data_converter：将摄像头产生的8位数据拼接为16位数据
- HDMI_top（HDMI顶层模块）
  - ms72xx_init：产生iic时序配置ms7200和ms7210的寄存器
  - video_driver：产生HDMI行场同步信号，并根据协议要求请求DDR中的像素数据
- Video_processing_top（图像处理模块）
  - bilinear_interpolation：将HDMI输入的分辨率利用双线性插值缩小，以满足视频拼接的需求
- Ethernet_top（以太网顶层模块）
  - gmii_to_rgmii：实现GMII和RGMII接口信号转换
  - arp：接收和发送ARP请求和应答数据包
  - udp：接收UDP数据包
- DDR3_interface_top（DDR顶层模块）
  - AXI_rw_FIFO：实现跨时钟域数据传输和数据位宽转换，产生读写请求信号
  - wr_arbiter/rd_arbiter：实现读写请求信号仲裁
  - simplified_AXI：产生AXI信号，调用DDR接口IP，内部通过写地址实现视频拼接

# 操作指南

### 网口配置

- 将电脑以太网网卡的ip地址配置为代码中的参数DES_IP（即192.168.1.102）、MAC地址配置为参数DES_MAC（即255.255.255.0）

- 打开网卡的巨型帧（具体操作可以上网搜索）

- 安装socket、opencv-python、time等python库

  ```
  pip install opencv-python
  pip install socket
  pip install time
  ```

- 将bit流烧录进FPGA后，运行python文件

### 调整拼接视频源

- 修改顶层模块中ddr_interface_top模块的输入（如，将网口输入换成摄像头输入，只保留了关键代码）

  ```verilog
  DDR3_interface_top u_DDR3_interface_top(
      .video0_wr_clk          (cam_pclk           ), // input
      .video0_wr_en           (cam_frame_valid    ), // input
      .video0_wr_data         (cam_wr_data        ), // input
      .video0_wr_rst          (cam_frame_vsync    ), // input
      
      .video1_wr_clk          (cam_pclk           ), // input
      .video1_wr_en           (cam_frame_valid    ), // input
      .video1_wr_data         (cam_wr_data        ), // input
      .video1_wr_rst          (cam_frame_vsync    ), // input
      
      // .video1_wr_clk          (eth_rx_clk         ), // input
      // .video1_wr_en           (eth_frame_valid    ), // input
      // .video1_wr_data         (eth_frame_data     ), // input
      // .video1_wr_rst          (eth_frame_rst      ), // input
  
      .video2_wr_clk          (hdmi_rx_pix_clk    ), // input
      .video2_wr_en           (hdmi_frame_valid   ), // input
      .video2_wr_data         (hdmi_wr_data       ), // input
      .video2_wr_rst          (hdmi_frame_vs      ), // input
  
      .video3_wr_clk          (hdmi_rx_pix_clk    ), // input
      .video3_wr_en           (hdmi_frame_valid   ), // input
      .video3_wr_data         (hdmi_wr_data       ), // input
      .video3_wr_rst          (hdmi_frame_vs      ), // input
  );
  ```

  

 # 常见问题

- 包括网口在内时，拼接显示了一会后就卡住了
  - 本拼接代码必须在每个输入源都有输入时才能正常显示
  - 可能问题是网口发送的视频播放完了，重新运行一下python代码即可
- 显示器黑屏
  - 尝试按一下复位按键（第8个按键）
- 显示器花屏
  - HDMI的输入是否为1920x1080@60，可以先尝试一下官方的HDMI回环例程
- 摄像头没显示
  - 本代码使用的是配套的双目摄像头，如使用自己的ov5640，需要修改管脚配置，并保证单独摄像头可以正常显示



# 调试日志

| 日期      | 现象                       | 预计问题                       | 解决办法                                         |
| --------- | -------------------------- | ------------------------------ | ------------------------------------------------ |
| 2023/4/13 | 摄像头有输入，HDMI没有输出 | 不知道是不是摄像头的配置有问题 | 把摄像头的分辨率调回1080x768，再检查一下HDMI模块 |
| 2023/4/14 |                            | 感觉写入地址的时序还是有点问题 | 可以组合逻辑改为时序逻辑                         |
| 2023/5/8  | arp模块有问题              |                                |                                                  |

