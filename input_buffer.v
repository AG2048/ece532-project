module input_buffer #(
  parameter DATA_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter C_AXIS_TDATA_WIDTH = 32,

  // These two parameters should be the same, could change for "advanced" features
  parameter BUFFER_HEIGHT = 480, // How many rows to buffer
  parameter INPUT_HEIGHT = 480 // How many rows to input (used for the BLOCK_SIZE delay after INPUT_HEIGHT inputs)
)
(
  // AXI-Stream interface
  aclk, aresetn,
  tready, tvalid, 
  tstrb, tdata, tlast,

  // Internal signals
  // inputs [(BLOCK_SIZE-1) * DATA_WIDTH - 1:0] (does not include the last col)
  // outputs [BLOCK_SIZE * DATA_WIDTH - 1:0] (includes the last col)
  // Input is from processing block, output is to block
  inputs_R, outputs_R,
  inputs_G, outputs_G,
  inputs_B, outputs_B,

  // Output module signals (!(output_module_tvalid && !output_module_tready)) (if output is valid, but we can't write it out)
  output_has_back_pressure, // If the output module has back pressure, 1 means we shouldn't have any data flow

  // Output signal to output_module, to help it figure out what data is useful
  is_full_columns_first_input, // If the data input to the processing block has all valid data on all its columns 
  // This signal is true when: ALL columns are full, and we are sending the FIRST row of input to the processing block
  // The output buffer is supposed to count how many cycles delay from input to output...
  data_flowing, // If data is flowing from input to output (write enable or padding)

  output_buffer_is_done // If output buffer is done sending OUT this "batch" of data (as in a full set of INPUT_HEIGHT outputs. This is useful for the last column of input, so input_buffer knows when to stop just pumping out data and start accepting new data)
);
  // AXI-Stream interface
  input wire aclk;
  input wire aresetn;
  output wire tready;
  input wire tvalid;
  input wire [(C_AXIS_TDATA_WIDTH/8)-1:0] tstrb; // Not used
  input wire [C_AXIS_TDATA_WIDTH-1:0] tdata;
  input wire tlast;

  // I/O signals for the processing block
  input wire [BLOCK_SIZE*DATA_WIDTH-1:0] inputs_R;
  output wire [BLOCK_SIZE*DATA_WIDTH-1:0] outputs_R;

  input wire [BLOCK_SIZE*DATA_WIDTH-1:0] inputs_G;
  output wire [BLOCK_SIZE*DATA_WIDTH-1:0] outputs_G;

  input wire [BLOCK_SIZE*DATA_WIDTH-1:0] inputs_B;
  output wire [BLOCK_SIZE*DATA_WIDTH-1:0] outputs_B;

  // Output module signals
  input wire output_has_back_pressure;
  output wire is_full_columns_first_input;
  output wire data_flowing;
  input wire output_buffer_is_done;

  // Define the memory buffer (3 x IMAGE_HEIGHT x BLOCK_SIZE) of [DATA_WIDTH-1:0]
  // [RGB][Y][X]
  reg [DATA_WIDTH-1:0] data_reg[0:2][0:BUFFER_HEIGHT-1][0:BLOCK_SIZE-1];
  // Write enable signal - tvalid and tready
  wire write_enable;
  assign write_enable = tvalid && tready;

  // Define counters (calculate bit width of INPUT_HEIGHT)
  reg [$clog2(INPUT_HEIGHT)-1:0] counter_input;
  // Counter for padding
  reg [$clog2(BLOCK_SIZE)-1:0] counter_padding;
  
  // tready: when there are no back pressure AND counter 1 is not 0. AND if we are flushing buffer after tlast. 
  assign tready = !output_has_back_pressure && (counter_input != 0) && !(tlast_received);

  // a flag to indicate if the upcoming input data is the FIRST input data (which may contain useful data in last byte)
  reg first_input;
  always @(posedge aclk) begin
    if (!aresetn) begin
      first_input <= 1'b1; // Initialize to 1
    end else begin
      // If writing and it's the LAST input (indicated by tlast), the reset the flag
      if (write_enable && tlast) begin
        first_input <= 1'b1;
      end else if (write_enable) begin
        // If writing and it's not the last input, then reset the flag
        first_input <= 1'b0;
      end
    end
  end

  // a flag that is set true only after a tlast signal is received. Only set to false when the output buffer is done sending out the data
  reg tlast_received;
  always @(posedge aclk) begin
    if (!aresetn) begin
      tlast_received <= 1'b0;
    end else begin
      if (write_enable && tlast) begin
        tlast_received <= 1'b1;
      end else if (output_buffer_is_done && counter_after_tlast == 0) begin
        // Stop the flag after output_buffer has finished all its output, and we have at least flushed the entire buffer once. 
        tlast_received <= 1'b0;
      end
    end
  end
  // a counter that counts INPUT_HEIGHT cycles after tlast is received, so we can be sure that the output buffer is done sending out the data. Counts down to 0.
  reg [$clog2(INPUT_HEIGHT)-1:0] counter_after_tlast;
  always @(posedge aclk) begin
    if (!aresetn) begin
      counter_after_tlast <= INPUT_HEIGHT;
    end else begin
      if (!tlast_received) begin // Keep resetting counter as long as we are not in tlast_received. 
        counter_after_tlast <= INPUT_HEIGHT;
      end else if (counter_after_tlast != 0 && tlast_received) begin // don't decrement at all times...
        counter_after_tlast <= counter_after_tlast - 1;
      end
    end
  end

  // A counter to check if the current output to processor block has the full BLOCK_SIZE columns
  reg [$clog2(BLOCK_SIZE)-1:0] counter_full_columns;
  always @(posedge aclk) begin
    if (!aresetn) begin
      counter_full_columns <= BLOCK_SIZE;
    end else begin
      if (first_input) begin 
        // If first input, then keep the counter at 0
        counter_full_columns <= BLOCK_SIZE;
      end else if (counter_input == 1 && counter_padding == BLOCK_SIZE-1 && counter_full_columns != 0 && write_enable) begin
        // If it's not the first input anymore, AND counter_input == 1 (and we are writing immediately) AND counter_padding == BLOCK_SIZE-1, counter_full_columns should -= 1
        // Because this combination of counters only occur when a col is FULL and we are about to write padding zeros
        // Stop incrementing when counter_full_columns == 0 (since next inputs we would be all writing full columns)
        counter_full_columns <= counter_full_columns - 1; 
      end
    end
  end

  // Assign a flag to indicate to the output module that we are inputting full columns
  // This signal is true when: ALL columns are full, and we are sending the FIRST row of input to the processing block
  assign is_full_columns_first_input = counter_full_columns == 0 && counter_input == 0 && counter_padding == BLOCK_SIZE-1;

  // If we are writing to the module, OR we are still doing padding. Or, we are currently sending last data after tlast (but also check if no back pressure)
  assign data_flowing = write_enable || ((counter_input == 0 || tlast_received) && !output_has_back_pressure);

  // Backpressure: when the output buffer has a valid value, but ready is not asserted
  // Explanation: If output buffer isn't valid, then we won't worry about "deleting" a valid output
  //              If output buffer is valid, but ready not asserted, meaning any data flow risks "deleting" a valid output
  //              If counter 1 is 0, then we have to delay the input by "BLOCK_SIZE" cycles
  // assign tready = !output_has_back_pressure && (counter_1 != 0);

  // Counter Input: Counts down from INPUT_HEIGHT to 0 (if count == 0, then input zero to buffer)
  // Counter Padding: Counts down from BLOCK_SIZE-1 to 0 (if count == 0, then reset counter 1)

  // Output signals come from the top row of the data_reg
  genvar i_o_assign_channel, i_o_assign_j;
  generate
    for (i_o_assign_channel = 0; i_o_assign_channel < 3; i_o_assign_channel = i_o_assign_channel + 1) begin
      for (i_o_assign_j = 0; i_o_assign_j < BLOCK_SIZE; i_o_assign_j = i_o_assign_j + 1) begin
        assign outputs_R[(i_o_assign_j+1)*DATA_WIDTH-1:i_o_assign_j*DATA_WIDTH] = data_reg[0][0][i_o_assign_j];
        assign outputs_G[(i_o_assign_j+1)*DATA_WIDTH-1:i_o_assign_j*DATA_WIDTH] = data_reg[1][0][i_o_assign_j];
        assign outputs_B[(i_o_assign_j+1)*DATA_WIDTH-1:i_o_assign_j*DATA_WIDTH] = data_reg[2][0][i_o_assign_j];
      end
    end
  endgenerate

  // Counters logic: 
  always @(posedge aclk) begin
    if (!aresetn || (output_buffer_is_done && counter_after_tlast == 0)) begin
      // Reset all counters. If resetting, OR if we are done sending out the data after tlast (this signal kinda re-enables tready)
      counter_input <= INPUT_HEIGHT;
      counter_padding <= BLOCK_SIZE-1;
    end else begin
      if (write_enable) begin
        // If we are writing, decrement counter_input (basically counter_input isn't 0 and we are writing)
        counter_input <= counter_input - 1;
      end else if (counter_input == 0 && !output_has_back_pressure) begin
        // Not writing, but counter_input is 0 meaning we should be padding
        // If we are not writing, and counter_input is 0, decrement counter_padding
        counter_padding <= counter_padding - 1;
        if (counter_padding == 0) begin
          // If both counters are 0, means we should reset both
          // If counter_padding is 0, reset counter_input
          counter_input <= INPUT_HEIGHT;
          counter_padding <= BLOCK_SIZE-1;
        end
      end
    end
  end

  // Generate the data shift register
  genvar channel, i, j;
  generate 
    for (channel = 0; channel < 3; channel = channel + 1) begin
      // For each channel: R, G, B
      for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
        // For each row
        for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
          // For each column:
          always @(posedge aclk) begin
            if (!aresetn) begin
              // Reset: set all values to 0 (although this is not necessary)
              data_reg[channel][i][j] <= 0;
            end else begin
              // Shift data upward by one, bottom comes from input
              // Only write if tvalid and tready
              if (write_enable) begin
                // Write enable is true, meaning we wish to input FROM axi-stream
                if (i != INPUT_HEIGHT-1) begin
                  // Top row and middle row
                  data_reg[channel][i][j] <= data_reg[channel][i+1][j];
                end else begin
                  // Bottom row
                  if (j == BLOCK_SIZE-1) begin
                    // Bottom RIGHT
                    if (channel == 0) begin
                      data_reg[channel][i][j] <= tdata[31:24]; // First byte is R
                    end else if (channel == 1) begin
                      data_reg[channel][i][j] <= tdata[23:16]; // Second byte is G
                    end else begin
                      data_reg[channel][i][j] <= tdata[15:8]; // Third byte is B
                    end
                  end else begin
                    // Bottom ROW but not the rightmost column
                    if (channel == 0) begin
                      data_reg[channel][i][j] <= inputs_R[ (j+2)*DATA_WIDTH-1 : (j+1)*DATA_WIDTH ]; // Input 7:0 is leftmost, 15:8 is next, 23:16 is next... (but we don't want LEFTMOST)
                    end else if (channel == 1) begin
                      data_reg[channel][i][j] <= inputs_G[ (j+2)*DATA_WIDTH-1 : (j+1)*DATA_WIDTH ]; 
                    end else begin
                      data_reg[channel][i][j] <= inputs_B[ (j+2)*DATA_WIDTH-1 : (j+1)*DATA_WIDTH ];
                    end
                  end
                end
              end else if ((counter_input == 0 || tlast_received) && !output_has_back_pressure) begin
                // We are not reading from AXI-S, but we are padding AND we don't have back pressure
                // If we are only not writing because counter_input is 0, we should pad.
                // Also we will pad zeros if we are sending the last data after tlast
                if (i != INPUT_HEIGHT-1) begin
                  // Top row and middle row
                  data_reg[channel][i][j] <= data_reg[channel][i+1][j];
                end else begin
                  // Bottom row
                  if (j == BLOCK_SIZE-1) begin
                    // Bottom RIGHT
                    if (channel == 0) begin
                      data_reg[channel][i][j] <= 0;
                    end else if (channel == 1) begin
                      data_reg[channel][i][j] <= 0;
                    end else begin
                      data_reg[channel][i][j] <= 0;
                    end
                  end else begin
                    // Bottom ROW but not the rightmost column
                    if (channel == 0) begin
                      data_reg[channel][i][j] <= inputs_R[ (j+1)*DATA_WIDTH-1 : j*DATA_WIDTH ]; // Input 7:0 is leftmost, 15:8 is next, 23:16 is next...
                    end else if (channel == 1) begin
                      data_reg[channel][i][j] <= inputs_G[ (j+1)*DATA_WIDTH-1 : j*DATA_WIDTH ]; 
                    end else begin
                      data_reg[channel][i][j] <= inputs_B[ (j+1)*DATA_WIDTH-1 : j*DATA_WIDTH ];
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  endgenerate
  
  // TODO: tready signal
  // TODO: tstrb signal -- will it be used by microblaze?
  //       if so, we have to add additional logic to handle it
endmodule