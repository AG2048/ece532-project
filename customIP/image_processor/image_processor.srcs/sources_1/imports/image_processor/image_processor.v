`timescale 1ns / 1ps

module image_processor #(
  parameter DATA_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter C_AXIS_TDATA_WIDTH = 32,

  parameter FILTER_INT_BITS = 0,
  parameter FILTER_FRACT_BITS = 20,

  // These two parameters should be the same, could change for "advanced" features
  parameter BUFFER_HEIGHT = 32'd480, // How many rows to buffer
  parameter INPUT_HEIGHT = 32'd480
)(
  // AXI Stream Input
  input wire                              aclk,
  input wire                              aresetn,

  input wire [C_AXIS_TDATA_WIDTH-1:0]     s_axis_tdata,
  input wire                              s_axis_tvalid,
  output wire                             s_axis_tready,
  input wire [C_AXIS_TDATA_WIDTH/8-1:0]   s_axis_tstrb,
  input wire                              s_axis_tlast,
  
  // AXI Stream Output
  output wire [C_AXIS_TDATA_WIDTH-1:0]    m_axis_tdata,
  output wire                             m_axis_tvalid,
  input wire                              m_axis_tready,
  output wire [C_AXIS_TDATA_WIDTH/8-1:0]  m_axis_tstrb,
  output wire                             m_axis_tlast
);

  wire [BLOCK_SIZE * DATA_WIDTH - 1:0] inputs_R;
  wire [BLOCK_SIZE * DATA_WIDTH - 1:0] outputs_R;
  wire [BLOCK_SIZE * DATA_WIDTH - 1:0] inputs_G;
  wire [BLOCK_SIZE * DATA_WIDTH - 1:0] outputs_G;
  wire [BLOCK_SIZE * DATA_WIDTH - 1:0] inputs_B;
  wire [BLOCK_SIZE * DATA_WIDTH - 1:0] outputs_B;

  wire [RESULT_WIDTH-1:0] filter_output_R;
  wire [RESULT_WIDTH-1:0] filter_output_G;
  wire [RESULT_WIDTH-1:0] filter_output_B;

  wire output_has_back_pressure;
  wire is_full_columns_first_input;
  wire data_flowing;
  wire output_buffer_is_done;

  // Instantiate the output buffer
  output_buffer #(
    .RESULT_WIDTH(RESULT_WIDTH),
    .BLOCK_SIZE(BLOCK_SIZE),
    .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
    .BUFFER_HEIGHT(BUFFER_HEIGHT),
    .INPUT_HEIGHT(INPUT_HEIGHT)
  ) output_buffer_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .tready(output_buffer_tready),
    .tvalid(output_buffer_tvalid),
    .tstrb(output_buffer_tstrb),
    .tdata(output_buffer_tdata),
    .tlast(output_buffer_tlast),
    .result_R(filter_output_R),
    .result_G(filter_output_G),
    .result_B(filter_output_B),
    .output_has_back_pressure(output_has_back_pressure),
    .is_full_columns_first_input(is_full_columns_first_input),
    .data_flowing(data_flowing),
    .output_buffer_is_done(output_buffer_is_done)
  );

  // Instantiate the processing block
  processing_block #(
      .INPUT_WIDTH(DATA_WIDTH),
      .RESULT_WIDTH(RESULT_WIDTH),
      .FILTER_INT_BITS(FILTER_INT_BITS),
      .FILTER_FRACT_BITS(FILTER_FRACT_BITS),
      .BLOCK_SIZE(BLOCK_SIZE)
  ) dut_R (
      .clk(aclk),
      .resetn(aresetn),
      .enable(data_flowing),
      .inputs(outputs_R),
      .outputs(inputs_R),
      .filter_output(filter_output_R)
  );

  processing_block #(
      .INPUT_WIDTH(DATA_WIDTH),
      .RESULT_WIDTH(RESULT_WIDTH),
      .FILTER_INT_BITS(FILTER_INT_BITS),
      .FILTER_FRACT_BITS(FILTER_FRACT_BITS),
      .BLOCK_SIZE(BLOCK_SIZE)
  ) dut_G (
      .clk(aclk),
      .resetn(aresetn),
      .enable(data_flowing),
      .inputs(outputs_G),
      .outputs(inputs_G),
      .filter_output(filter_output_G)
  );

  processing_block #(
      .INPUT_WIDTH(DATA_WIDTH),
      .RESULT_WIDTH(RESULT_WIDTH),
      .FILTER_INT_BITS(FILTER_INT_BITS),
      .FILTER_FRACT_BITS(FILTER_FRACT_BITS),
      .BLOCK_SIZE(BLOCK_SIZE)
  ) dut_B (
      .clk(aclk),
      .resetn(aresetn),
      .enable(data_flowing),
      .inputs(outputs_B),
      .outputs(inputs_B),
      .filter_output(filter_output_B)
  );

  // Instantiate the input buffer
  input_buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .BLOCK_SIZE(BLOCK_SIZE),
    .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
    .BUFFER_HEIGHT(BUFFER_HEIGHT),
    .INPUT_HEIGHT(INPUT_HEIGHT)
  ) input_buffer_inst (
    .aclk(aclk),
    .aresetn(aresetn),
    .tvalid(input_buffer_tvalid),
    .tready(input_buffer_tready),
    .tstrb(input_buffer_tstrb),
    .tdata(input_buffer_tdata),
    .tlast(input_buffer_tlast),
    .inputs_R(inputs_R),
    .outputs_R(outputs_R),
    .inputs_G(inputs_G),
    .outputs_G(outputs_G),
    .inputs_B(inputs_B),
    .outputs_B(outputs_B),
    .output_has_back_pressure(output_has_back_pressure),
    .is_full_columns_first_input(is_full_columns_first_input),
    .data_flowing(data_flowing),
    .output_buffer_is_done(output_buffer_is_done)
  );
endmodule