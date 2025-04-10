// (c) Copyright 1995-2025 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:ip:system_ila:1.1
// IP Revision: 4

`timescale 1ns/1ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module hdmi_system_ila_0_0 (
  clk,
  SLOT_0_IIC_scl_i,
  SLOT_0_IIC_scl_o,
  SLOT_0_IIC_scl_t,
  SLOT_0_IIC_sda_i,
  SLOT_0_IIC_sda_o,
  SLOT_0_IIC_sda_t
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.clk, FREQ_HZ 25000000, PHASE 0.0, CLK_DOMAIN /clk_wiz_0_clk_out1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.clk CLK" *)
input wire clk;
(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SCL_I" *)
input wire SLOT_0_IIC_scl_i;
(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SCL_O" *)
input wire SLOT_0_IIC_scl_o;
(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SCL_T" *)
input wire SLOT_0_IIC_scl_t;
(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SDA_I" *)
input wire SLOT_0_IIC_sda_i;
(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SDA_O" *)
input wire SLOT_0_IIC_sda_o;
(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SDA_T" *)
input wire SLOT_0_IIC_sda_t;

  bd_5084 inst (
    .clk(clk),
    .SLOT_0_IIC_scl_i(SLOT_0_IIC_scl_i),
    .SLOT_0_IIC_scl_o(SLOT_0_IIC_scl_o),
    .SLOT_0_IIC_scl_t(SLOT_0_IIC_scl_t),
    .SLOT_0_IIC_sda_i(SLOT_0_IIC_sda_i),
    .SLOT_0_IIC_sda_o(SLOT_0_IIC_sda_o),
    .SLOT_0_IIC_sda_t(SLOT_0_IIC_sda_t)
  );
endmodule
