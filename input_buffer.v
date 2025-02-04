module input_buffer #(
  parameter DATA_WIDTH = 8,
  parameter C_AXIS_TDATA_WIDTH = 32,
  parameter IMAGE_HEIGHT = 480
)
(
  // AXI-Stream interface
  aclk, aresetn,
  tready, tvalid, 
  tstrb, tdata,

  // Internal signals
  left_out_R, middle_out_R, right_out_R,
  left_in_R, middle_in_R,
  left_out_G, middle_out_G, right_out_G,
  left_in_G, middle_in_G,
  left_out_B, middle_out_B, right_out_B,
  left_in_B, middle_in_B
);
  // AXI-Stream interface
  input wire aclk;
  input wire aresetn;
  output wire tready;
  input wire tvalid;
  input wire [(C_AXIS_TDATA_WIDTH/8)-1:0] tstrb;
  input wire [C_AXIS_TDATA_WIDTH-1:0] tdata;

  // I/O signals for the processing block
  output wire [DATA_WIDTH-1:0] left_out_R;
  output wire [DATA_WIDTH-1:0] middle_out_R;
  output wire [DATA_WIDTH-1:0] right_out_R;

  input wire [DATA_WIDTH-1:0] left_in_R;
  input wire [DATA_WIDTH-1:0] middle_in_R;

  output wire [DATA_WIDTH-1:0] left_out_G;
  output wire [DATA_WIDTH-1:0] middle_out_G;
  output wire [DATA_WIDTH-1:0] right_out_G;

  input wire [DATA_WIDTH-1:0] left_in_G;
  input wire [DATA_WIDTH-1:0] middle_in_G;

  output wire [DATA_WIDTH-1:0] left_out_B;
  output wire [DATA_WIDTH-1:0] middle_out_B;
  output wire [DATA_WIDTH-1:0] right_out_B;

  input wire [DATA_WIDTH-1:0] left_in_B;
  input wire [DATA_WIDTH-1:0] middle_in_B;

  // Define the memory buffer (3 x IMAGE_HEIGHT x 3) of [DATA_WIDTH-1:0]
  // [RGB][Y][X]
  reg [DATA_WIDTH-1:0] data_reg[0:2][0:IMAGE_HEIGHT-1][0:2];
  // Write enable signal - tvalid and tready
  wire write_enable;
  assign write_enable = tvalid && tready;
  // The two registers are to delay input data by the delay from processing block
  // [RGB][Y]
  reg [DATA_WIDTH-1:0] middle_buffer[0:2][0:2];
  reg [DATA_WIDTH-1:0] right_buffer[0:2][0:5];

  // Output signals come from the top row of the data_reg
  assign left_out_R = data_reg[0][0][0];
  assign middle_out_R = data_reg[0][0][1];
  assign right_out_R = data_reg[0][0][2];

  assign left_out_G = data_reg[1][0][0];
  assign middle_out_G = data_reg[1][0][1];
  assign right_out_G = data_reg[1][0][2];
  
  assign left_out_B = data_reg[2][0][0];
  assign middle_out_B = data_reg[2][0][1];
  assign right_out_B = data_reg[2][0][2];

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