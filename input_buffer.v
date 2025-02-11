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
  tstrb, tdata,

  // Internal signals
  // inputs [(BLOCK_SIZE-1) * DATA_WIDTH - 1:0] (does not include the last col)
  // outputs [BLOCK_SIZE * DATA_WIDTH - 1:0] (includes the last col)
  inputs_R, outputs_R,
  inputs_G, outputs_G,
  inputs_B, outputs_B,

  // Output module signals (!(output_module_tvalid && !output_module_tready))
  output_has_back_pressure // If the output module has back pressure, 1 means we shouldn't have any data flow
);
  // AXI-Stream interface
  input wire aclk;
  input wire aresetn;
  output wire tready;
  input wire tvalid;
  input wire [(C_AXIS_TDATA_WIDTH/8)-1:0] tstrb; // Not used
  input wire [C_AXIS_TDATA_WIDTH-1:0] tdata;

  // I/O signals for the processing block
  input wire [(BLOCK_SIZE-1)*DATA_WIDTH-1:0] inputs_R;
  output wire [BLOCK_SIZE*DATA_WIDTH-1:0] outputs_R;

  input wire [(BLOCK_SIZE-1)*DATA_WIDTH-1:0] inputs_G;
  output wire [BLOCK_SIZE*DATA_WIDTH-1:0] outputs_G;

  input wire [(BLOCK_SIZE-1)*DATA_WIDTH-1:0] inputs_B;
  output wire [BLOCK_SIZE*DATA_WIDTH-1:0] outputs_B;

  // Define the memory buffer (3 x IMAGE_HEIGHT x BLOCK_SIZE) of [DATA_WIDTH-1:0]
  // [RGB][Y][X]
  reg [DATA_WIDTH-1:0] data_reg[0:2][0:BUFFER_HEIGHT-1][0:BLOCK_SIZE-1];
  // Write enable signal - tvalid and tready
  wire write_enable;
  assign write_enable = tvalid && tready;

  // tready: when there are no back pressure AND counter 1 is not 0
  // Backpressure: when the output buffer has a valid value, but ready is not asserted
  // Explanation: If output buffer isn't valid, then we won't worry about "deleting" a valid output
  //              If output buffer is valid, but ready not asserted, meaning any data flow risks "deleting" a valid output
  //              If counter 1 is 0, then we have to delay the input by "BLOCK_SIZE" cycles
  // assign tready = !output_has_back_pressure && (counter_1 != 0);

  // Counter 1: Counts down from INPUT_HEIGHT to 0 (if count == 0, then input zero to buffer)
  // Counter 2: Counts down from BLOCK_SIZE-1 to 0 (if count == 0, then reset counter 1)

  // Output signals come from the top row of the data_reg
  genvar i_o_assign_channel, i_o_assign_j
  generate
    for (i_o_assign_channel = 0; i_o_assign_channel < 3; i_o_assign_channel = i_o_assign_channel + 1) begin
      for (i_o_assign_j = 0; i_o_assign_j < BLOCK_SIZE; i_o_assign_j = i_o_assign_j + 1) begin
        assign outputs_R[(i_o_assign_j+1)*DATA_WIDTH-1:i_o_assign_j*DATA_WIDTH] = data_reg[0][0][i_o_assign_j];
        assign outputs_G[(i_o_assign_j+1)*DATA_WIDTH-1:i_o_assign_j*DATA_WIDTH] = data_reg[1][0][i_o_assign_j];
        assign outputs_B[(i_o_assign_j+1)*DATA_WIDTH-1:i_o_assign_j*DATA_WIDTH] = data_reg[2][0][i_o_assign_j];
      end
    end
  endgenerate

  // TODO

  // Generate the data shift register
  genvar channel, i, j;
  generate 
    for (channel = 0; channel < 3; channel = channel + 1) begin
      // For each channel: R, G, B
      for (i = 0; i < IMAGE_HEIGHT; i = i + 1) begin
        for (j = 0; j < 3; j = j + 1) begin
          always @(posedge aclk) begin
            if (!aresetn) begin
              data_reg[channel][i][j] <= 0;
            end else begin
              // Shift data upward by one, bottom comes from input
              // Only write if tvalid and tready
              if (write_enable) begin
                if (i != IMAGE_HEIGHT-1) begin
                  // Top row and middle row
                  data_reg[channel][i][j] <= data_reg[channel][i+1][j];
                end else begin
                  // Bottom row
                  if (j == 0) begin
                    if (channel == 0) begin
                      data_reg[channel][i][j] <= left_in_R;
                    end else if (channel == 1) begin
                      data_reg[channel][i][j] <= left_in_G;
                    end else begin
                      data_reg[channel][i][j] <= left_in_B;
                    end
                  end else if (j == 1) begin
                    data_reg[channel][i][j] <= middle_buffer[channel][0];
                  end else begin
                    data_reg[channel][i][j] <= right_buffer[channel][0];
                  end
                end
              end
            end
          end
        end
      end
    end
  endgenerate

  // Generate the delay buffer for the middle and right inputs
  genvar channel, i;
  // MIDDLE
  generate
    for (channel = 0; channel < 3; channel = channel + 1) begin
      for (i = 0; i < 3; i = i + 1) begin
        always @(posedge aclk) begin
          if (!aresetn) begin
            middle_buffer[channel][i] <= 0;
          end else begin
            if (write_enable) begin
              // Shift data upward by one, bottom comes from input
              if (i != 2) begin
                middle_buffer[channel][i] <= middle_buffer[channel][i+1];
              end else begin
                if (channel == 0) begin
                  middle_buffer[channel][i] <= middle_in_R;
                end else if (channel == 1) begin
                  middle_buffer[channel][i] <= middle_in_G;
                end else begin
                  middle_buffer[channel][i] <= middle_in_B;
                end
              end
            end
          end
        end
      end
    end
  endgenerate
  // RIGHT
  generate 
    for (channel = 0; channel < 3; channel = channel + 1) begin
      for (i = 0; i < 6; i = i + 1) begin
        always @(posedge aclk) begin
          if (!aresetn) begin
            right_buffer[channel][i] <= 0;
          end else begin
            if (write_enable) begin
              // Shift data upward by one, bottom comes from input
              if (i != 5) begin
                right_buffer[channel][i] <= right_buffer[channel][i+1];
              end else begin
                // First 8 bits are R, next 8 bits are G, last 8 bits are B
                right_buffer[channel][i] <= tdata[(channel+1)*DATA_WIDTH-1:channel*DATA_WIDTH];
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