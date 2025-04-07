`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/09/2025 12:24:57 AM
// Design Name: 
// Module Name: top
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


module top(
  inout DDC_scl_io,
  inout DDC_sda_io,
  output [14:0]DDR3_addr,
  output [2:0]DDR3_ba,
  output DDR3_cas_n,
  output [0:0]DDR3_ck_n,
  output [0:0]DDR3_ck_p,
  output [0:0]DDR3_cke,
  output [1:0]DDR3_dm,
  inout [15:0]DDR3_dq,
  inout [1:0]DDR3_dqs_n,
  inout [1:0]DDR3_dqs_p,
  output [0:0]DDR3_odt,
  output DDR3_ras_n,
  output DDR3_reset_n,
  output DDR3_we_n,
  input TMDS_IN_clk_n,
  input TMDS_IN_clk_p,
  input [2:0]TMDS_IN_data_n,
  input [2:0]TMDS_IN_data_p,
  output TMDS_OUT_clk_n,
  output TMDS_OUT_clk_p,
  output [2:0]TMDS_OUT_data_n,
  output [2:0]TMDS_OUT_data_p,
  output [0:0]hdmi_hpd,
  output [0:0]hdmi_rx_txen,
  input reset,
  input sys_clk_i,
  input usb_uart_rxd,
  output usb_uart_txd,
  output config_done,
  output config_not_done,
  input switch, 
  output led,


      // Camera Interface
    input         OV7670_PCLK,
    output        OV7670_XCLK,
    input         OV7670_VSYNC,
    input         OV7670_HREF,
    input  [ 7:0] OV7670_D,
    output        OV7670_RESET,
    output        OV7670_PWDN,
    inout        OV7670_SIOC,
    inout        OV7670_SIOD,
    
    input [4:0]push_buttons_5bits_tri_i

    );
    
  wire [23:0]OV_AXIS_tdata;
  wire [3:0]OV_AXIS_tkeep;
  wire OV_AXIS_tlast;
  wire OV_AXIS_tready;
  wire [0:0]OV_AXIS_tuser;
  wire OV_AXIS_tvalid;
  wire [23:0] data_out;
    
    // Force powerdown and reset to enable the camera
    assign OV7670_RESET = 1'b1;
    assign OV7670_PWDN = 1'b0;    
    assign OV_AXIS_tdata = data_out;
    assign OV_AXIS_tkeep = 4'b1111;
    assign OV_AXIS_tuser = 4'b0001;
    wire cd;
    assign config_done = cd;
    assign config_not_done = ~cd;
assign led = switch;

hdmi_wrapper hdi_top(
  .DDC_scl_io(DDC_scl_io),
  .DDC_sda_io(DDC_sda_io),
  .DDR3_addr(DDR3_addr),
  .DDR3_ba(DDR3_ba),
  .DDR3_cas_n(DDR3_cas_n),
  .DDR3_ck_n(DDR3_ck_n),
  .DDR3_ck_p(DDR3_ck_p),
  .DDR3_cke(DDR3_cke),
  .DDR3_dm(DDR3_dm),
  .DDR3_dq(DDR3_dq),
  .DDR3_dqs_n(DDR3_dqs_n),
  .DDR3_dqs_p(DDR3_dqs_p),
  .DDR3_odt(DDR3_odt),
  .DDR3_ras_n(DDR3_ras_n),
  .DDR3_reset_n(DDR3_reset_n),
  .DDR3_we_n(DDR3_we_n),
  .OV7670_PCLK(OV7670_PCLK),
  .OV7670_VSYNC(OV7670_VSYNC),
  .OV7670_XCLK(OV7670_XCLK),
  .OV_AXIS_tdata(OV_AXIS_tdata),
  .OV_AXIS_tkeep(OV_AXIS_tkeep),
  .OV_AXIS_tlast(OV_AXIS_tlast),
  .OV_AXIS_tready(OV_AXIS_tready),
  .OV_AXIS_tuser(OV_AXIS_tuser),
  .OV_AXIS_tvalid(OV_AXIS_tvalid),
  .TMDS_IN_clk_n(TMDS_IN_clk_n),
  .TMDS_IN_clk_p(TMDS_IN_clk_p),
  .TMDS_IN_data_n(TMDS_IN_data_n),
  .TMDS_IN_data_p(TMDS_IN_data_p),
  .TMDS_OUT_clk_n(TMDS_OUT_clk_n),
  .TMDS_OUT_clk_p(TMDS_OUT_clk_p),
  .TMDS_OUT_data_n(TMDS_OUT_data_n),
  .TMDS_OUT_data_p(TMDS_OUT_data_p),
  .hdmi_hpd(hdmi_hpd),
  .hdmi_rx_txen(hdmi_rx_txen),
  .reset(reset),
  .sys_clk_i(sys_clk_i),
  .usb_uart_rxd(usb_uart_rxd),
  .usb_uart_txd(usb_uart_txd),
  .IIC_0_scl_io(OV7670_SIOC),
  .IIC_0_sda_io(OV7670_SIOD),
  .push_buttons_5bits_tri_i(push_buttons_5bits_tri_i),
  .probe0_0(OV7670_D)
);

    // Camera Data Capture
    pmod_cam cam (
        .pclk       (OV7670_PCLK),
        .vsync      (OV7670_VSYNC),
        .href       (OV7670_HREF),
        .din        (OV7670_D),
        .dout       (data_out),   // BRAM Data
        .valid      (OV_AXIS_tvalid),      // Write Enable
        .last       (OV_AXIS_tlast)    // End of Frame
//        .pclk_out   (pclk_out)
    );
    
//    camera_configure cc (
//        .clk      (OV7670_XCLK),    
//        .start     (switch),
//        .done(cd),
//        .siod   (OV7670_SIOD),    
//        .sioc   (OV7670_SIOC)
//    );
    // Camera I2C Configuration
//    I2C_AV_Config IIC (
//        .iCLK       (OV7670_XCLK),    
//        .iRST_N     (1'b1),
//         .Config_Done(cd),
//        .I2C_SDAT   (OV7670_SIOD),    
//        .I2C_SCLK   (OV7670_SIOC)
//    );

endmodule
