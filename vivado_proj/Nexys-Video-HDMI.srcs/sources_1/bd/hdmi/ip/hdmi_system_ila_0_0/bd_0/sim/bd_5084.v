//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Command: generate_target bd_5084.bd
//Design : bd_5084
//Purpose: IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "bd_5084,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=bd_5084,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=1,numReposBlks=1,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=SBD,synth_mode=Global}" *) (* HW_HANDOFF = "hdmi_system_ila_0_0.hwdef" *) 
module bd_5084
   (SLOT_0_IIC_scl_i,
    SLOT_0_IIC_scl_o,
    SLOT_0_IIC_scl_t,
    SLOT_0_IIC_sda_i,
    SLOT_0_IIC_sda_o,
    SLOT_0_IIC_sda_t,
    clk);
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SCL_I" *) input SLOT_0_IIC_scl_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SCL_O" *) input SLOT_0_IIC_scl_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SCL_T" *) input SLOT_0_IIC_scl_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SDA_I" *) input SLOT_0_IIC_sda_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SDA_O" *) input SLOT_0_IIC_sda_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 SLOT_0_IIC SDA_T" *) input SLOT_0_IIC_sda_t;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK, CLK_DOMAIN /clk_wiz_0_clk_out1, FREQ_HZ 25000000, INSERT_VIP 0, PHASE 0.0" *) input clk;

  wire SLOT_0_IIC_scl_i_1;
  wire SLOT_0_IIC_scl_o_1;
  wire SLOT_0_IIC_scl_t_1;
  wire SLOT_0_IIC_sda_i_1;
  wire SLOT_0_IIC_sda_o_1;
  wire SLOT_0_IIC_sda_t_1;
  wire clk_1;

  assign SLOT_0_IIC_scl_i_1 = SLOT_0_IIC_scl_i;
  assign SLOT_0_IIC_scl_o_1 = SLOT_0_IIC_scl_o;
  assign SLOT_0_IIC_scl_t_1 = SLOT_0_IIC_scl_t;
  assign SLOT_0_IIC_sda_i_1 = SLOT_0_IIC_sda_i;
  assign SLOT_0_IIC_sda_o_1 = SLOT_0_IIC_sda_o;
  assign SLOT_0_IIC_sda_t_1 = SLOT_0_IIC_sda_t;
  assign clk_1 = clk;
  bd_5084_ila_lib_0 ila_lib
       (.clk(clk_1),
        .probe0(SLOT_0_IIC_scl_i_1),
        .probe1(SLOT_0_IIC_scl_o_1),
        .probe2(SLOT_0_IIC_scl_t_1),
        .probe3(SLOT_0_IIC_sda_i_1),
        .probe4(SLOT_0_IIC_sda_o_1),
        .probe5(SLOT_0_IIC_sda_t_1));
endmodule
