//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Command: generate_target bd_9025_wrapper.bd
//Design : bd_9025_wrapper
//Purpose: IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module bd_9025_wrapper
   (clk,
    probe0);
  input clk;
  input [7:0]probe0;

  wire clk;
  wire [7:0]probe0;

  bd_9025 bd_9025_i
       (.clk(clk),
        .probe0(probe0));
endmodule
