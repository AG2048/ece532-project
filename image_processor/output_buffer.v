/*
Output buffer: 
assign out valid to: if the count after receiving is_full_columns_first_input
  Count changes when data_flowing is true
  When counter is in correct range (> minimum cycles to get first output, and < input_height...)

  Set valid to 1 if data flowing and counter is in range. Only check valid condition on the cycle where both valid and ready are high.

  Set valid to 1. Else, set valid to 0

Assign output_has_backpressure: !(valid && !ready) (if we are valid but not ready, it means backpressure).


Summary:
If data is flowing and we have correct data, we are valid.
If we already wrote data, and we are not having data flow / data is not correct, we are not valid.
If we wrote data, and data is still flowing with correct data, we are still valid.

If we have valid data but AXI-S is not ready, we have backpressure and the whole IP should stop.

To tell if our data is correct:
once we receive the flag is_full_columns_first_input, we can start counting cycles. (the immediate following rising edge is data entering the processing block)
It will take BLOCK_SIZE cycles to fill the entire block, then it takes 3 more cycles to get MAC result...
The next INPUT_HEIGHT cycles will be the output of the processing block.
Only increment count if data_flowing is true.
*/
module output_buffer # (
  parameter RESULT_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter C_AXIS_TDATA_WIDTH = 32,

  // These two parameters should be the same, could change for "advanced" features
  parameter BUFFER_HEIGHT = 480, // How many rows to buffer
  parameter INPUT_HEIGHT = 480 // How many rows to input (used for the BLOCK_SIZE delay after INPUT_HEIGHT inputs)
) (
  // AXI Stream interface
  aclk, aresetn,
  tready, tvalid, 
  tstrb, tdata, tlast,

  // Internal signals
  result_R, result_G, result_B, // Result from the 3 blocks

  // Output module signals (!(output_module_tvalid && !output_module_tready)) (if output is valid, but we can't write it out)
  output_has_back_pressure, // If the output module has back pressure, 1 means we shouldn't have any data flow

  // Output signal to output_module, to help it figure out what data is useful
  is_full_columns_first_input, // If the data input to the processing block has all valid data on all its columns 
  // This signal is true when: ALL columns are full, and we are sending the FIRST row of input to the processing block
  // The output buffer is supposed to count how many cycles delay from input to output...
  data_flowing, // If data is flowing from input to output (write enable or padding)

  output_buffer_is_done // true if we are done sending out this batch of data (ready && valid && is last value sent)
);

input wire aclk;
input wire aresetn;
input wire tready;
output reg tvalid; // Valid is a reg signal. 
output wire [(C_AXIS_TDATA_WIDTH/8)-1:0] tstrb;
output wire [C_AXIS_TDATA_WIDTH-1:0] tdata;
output wire tlast;

input wire [RESULT_WIDTH-1:0] result_R;
input wire [RESULT_WIDTH-1:0] result_G;
input wire [RESULT_WIDTH-1:0] result_B;

output wire output_has_back_pressure;
input wire is_full_columns_first_input;
input wire data_flowing;
output wire output_buffer_is_done;

// General logic: Initialize a initial_wait_counter = BLOCK_SIZE + 2 so that when counter = 0, the data is good.
// Initialize a counter of outputting_counter = INPUT_HEIGHT-1 when initial_wait_counter = 0. When this count is 0, we are done for the column.
// Both counters only decrement when data_flowing is true.
// When receivibng is_full_columns_first_input, set both counter to their initial values.
// Valid if wait_counter = 0, outputting counter can be 0 for the last value. Reset both counters when both counters reached 0 and valid&&ready.
// Valid will be set to false if ready&&valid but data is not flowing.

reg [$clog2(INPUT_HEIGHT+2 + 1)-1:0] initial_wait_counter;
reg [$clog2(INPUT_HEIGHT-BLOCK_SIZE+1 + 1)-1:0] outputting_counter;
reg outputting; // a flag register set to true when we receive is_full_columns_first_input
always @(posedge aclk) begin
  if (!aresetn) begin
    // Reset: set counters to their initial values.
    initial_wait_counter <= BLOCK_SIZE + 2;
    outputting <= 0;
  end else begin
    if (data_flowing) begin
      // If got full columns first input, start counting
      if (is_full_columns_first_input) begin
        initial_wait_counter <= BLOCK_SIZE + 1;
        outputting <= 1;
      end else if (outputting) begin
        // We are in the output cycle:
        if (initial_wait_counter != 0) begin
          // Decrease initial wait counter if it's not 0
          initial_wait_counter <= initial_wait_counter - 1;
        end else if (outputting_counter == 0) begin
          // Both counters are 0, we reset outputting flag only if we are valid and ready
          if (tvalid && tready) begin
            initial_wait_counter <= BLOCK_SIZE + 2;
            outputting <= 0;
          end
        end
      end
    end
  end
end

always @(posedge aclk) begin
  if (!aresetn) begin
    // Reset: set counters to their initial values.
    outputting_counter <= INPUT_HEIGHT-BLOCK_SIZE+1; // Output we don't output the edges which may be mixed with zero paddings (Number of output is INPUT_HEIGHT-BLOCK_SIZE+1)
  end else begin
    if (data_flowing && outputting) begin
      // We are in the output cycle:
      if (initial_wait_counter == 0 && outputting_counter != 0) begin
        // Then decrease outputting counter if it's not 0 (after initial wait counter is 0)
        outputting_counter <= outputting_counter - 1;
      end else if (outputting_counter == 0) begin
        // Both counters are 0, we reset outputting flag only if we are valid and ready
        if (tvalid && tready) begin
          outputting_counter <= INPUT_HEIGHT-BLOCK_SIZE+1;
        end
      end
    end
  end
end

// Valid assignment: Initial to 0. Set to 1 if wait_counter == 0, data flowing, ready&&valid. 
// If ready&&valid, set to 0 if data is not flowing, set to 1 if data is flowing. (don't repeat send same value)
// If valid is false, and data is flowing && (counter is 1, or counter is 0), set to 1. (if we were not valid, we are now valid knowing data is flowing)
// Also have to set to 0 if this is the last value to send out.

// VALID: 
/*
First output: init_wait_counter is 1 and data flowing
Other outputs: init_wait_counter is 0 and data flowing
Do not send duplicate data: ZERO if ready and valid, but data is not flowing
Stop sending after last value: if ready&&valid and outputting_counter is 0, set to 0
*/
always @(posedge aclk) begin
  if (!aresetn) begin
    tvalid <= 0;
  end else begin
    if (tready && tvalid && outputting_counter == 0) begin
      // If we are ready and valid, and we are done outputting, set valid to 0 (the last value)
      tvalid <= 0;
    end else if (data_flowing) begin
      // Data is flowing, we are valid as long as counter is in range
      if (initial_wait_counter == 0) begin
        tvalid <= 1;
      end
    end else begin
      // If data is NOT flowing, do not send duplicate data
      if (tvalid && tready) begin
        tvalid <= 0;
      end
    end
  end
end

// Hardwire some axi streaming signals (strb is all 1)
assign tstrb = {C_AXIS_TDATA_WIDTH/8{1'b1}};
assign tdata = {result_R, result_G, result_B, {(C_AXIS_TDATA_WIDTH - RESULT_WIDTH*3){1'b0}}}; // last byte is just 0
assign tlast = outputting_counter == 0; // last signal if outputting counter is 0 (probably not really used tho)

// Output has back pressure if we are valid but not ready
assign output_has_back_pressure = tvalid && !tready;

// Output buffer is done if we are valid and ready and this is the last value to send out
assign output_buffer_is_done = tvalid && tready && outputting_counter == 0;
endmodule