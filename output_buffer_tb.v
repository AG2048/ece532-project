// Probably just use the input_buffer and processing blocks that they are already tested.
// Simulate inputs of again 1,2,3,4,5... to all RGB channels, and now test cases 
// where input valid is sometimes not valid in middle
// Output ready is not ready in the middle
// Just print output result to display. 
// Also just test a case where output is ALWAYS ready, input is ALWAYS valid (until finished a batch of inputs, wait for 100 cycles, then start again)

module output_buffer_tb #(
  parameter DATA_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter C_AXIS_TDATA_WIDTH = 32,

  // These two parameters should be the same, could change for "advanced" features
  parameter BUFFER_HEIGHT = 10, // How many rows to buffer
  parameter INPUT_HEIGHT = BUFFER_HEIGHT
) ();

  reg aclk, aresetn;

  // Input buffer AXI signals
  reg [C_AXIS_TDATA_WIDTH-1:0] input_buffer_tdata;
  reg input_buffer_tvalid;
  wire input_buffer_tready;
  reg input_buffer_tlast;
  reg input_buffer_tstrb;

  // Output buffer AXI signals
  wire [C_AXIS_TDATA_WIDTH-1:0] output_buffer_tdata;
  wire output_buffer_tvalid;
  reg output_buffer_tready;
  wire output_buffer_tlast;
  wire output_buffer_tstrb;

  // Internal signals
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
      .FILTER_INT_BITS(0),
      .FILTER_FRACT_BITS(20),
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
      .FILTER_INT_BITS(0),
      .FILTER_FRACT_BITS(20),
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
      .FILTER_INT_BITS(0),
      .FILTER_FRACT_BITS(20),
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

  // Clock generation
  initial begin
      aclk = 1'b0;
      forever begin
          #5 aclk = ~aclk;
      end
  end

  // Testing case:
  integer i;
  initial begin
    aresetn = 1'b0;
    input_buffer_tstrb = 4'hF;
    input_buffer_tvalid = 1'b0;
    input_buffer_tdata = 32'h00000000;
    input_buffer_tlast = 1'b0;
    output_buffer_tready = 1'b0;
    #10 aresetn = 1'b1;
    #10;

    // Reset Finished.
    output_buffer_tready = 1'b1;
    for (i = 0; i < INPUT_HEIGHT*10; i = i + 1) begin
      input_buffer_tvalid = 1'b1;
      input_buffer_tdata = i * 32'h01010100;
      if (!(input_buffer_tready && input_buffer_tvalid)) begin
          i = i - 1;
      end
      if (i == INPUT_HEIGHT*10-1) begin
        input_buffer_tlast = 1'b1;
      end
      #10;
    end
    input_buffer_tvalid = 1'b0;
    input_buffer_tlast = 1'b0;
    #100;
  end

  initial begin
    // Print output buffer outputs, if output ready && valid, print the output
    #5;
    while (1) begin
      if (output_buffer_tready && output_buffer_tvalid) begin
        $display("Output: R=%d, G=%d, B=%d", output_buffer_tdata[31:24], output_buffer_tdata[23:16], output_buffer_tdata[15:8]);
        if (output_buffer_tlast) begin
          $display("ONE COLUMN DONE");
        end
      end
      
      #10;
    end
  end

endmodule