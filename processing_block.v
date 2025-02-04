module processing_block #(
  parameter INPUT_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter FILTER_INT_BITS = 0,
  parameter FILTER_FRACT_BITS = 20,
  parameter FILTER_VALUE = 116509
)
(
  clk, reset, enable,
  left_input, middle_input, right_input,
  left_output, middle_output, right_output,
  filter_output
);
  input wire clk;
  input wire reset;
  input wire enable;
  input wire [INPUT_WIDTH-1:0] left_input;
  input wire [INPUT_WIDTH-1:0] middle_input;
  input wire [INPUT_WIDTH-1:0] right_input;
  output wire [INPUT_WIDTH-1:0] left_output;
  output wire [INPUT_WIDTH-1:0] middle_output;
  output wire [INPUT_WIDTH-1:0] right_output;
  output wire [RESULT_WIDTH-1:0] filter_output;
  
  // Note the filter values are in fixed point format with FILTER_INT_BITS integer bits and FILTER_FRACT_BITS fractional bits
  wire [FILTER_INT_BITS+FILTER_FRACT_BITS-1:0] FILTER_VALUES[0:8];
  assign FILTER_VALUES[0] = FILTER_VALUE;
  assign FILTER_VALUES[1] = FILTER_VALUE;
  assign FILTER_VALUES[2] = FILTER_VALUE;
  assign FILTER_VALUES[3] = FILTER_VALUE;
  assign FILTER_VALUES[4] = FILTER_VALUE;
  assign FILTER_VALUES[5] = FILTER_VALUE;
  assign FILTER_VALUES[6] = FILTER_VALUE;
  assign FILTER_VALUES[7] = FILTER_VALUE;
  assign FILTER_VALUES[8] = FILTER_VALUE;
  // Genvar 9 reg in a 3x3 grid, define 9 reg first with i,j index
  reg [INPUT_WIDTH-1:0] data_reg[0:2][0:2];
  genvar i, j;
  generate
    for (i = 0; i < 3; i = i + 1) begin
      for (j = 0; j < 3; j = j + 1) begin
        always @(posedge clk) begin
          if (reset) begin
            data_reg[i][j] <= 0;
          end else begin
            // Shift data upward by one, bottom comes from input
            if (enable) begin
              if (i != 2) begin
                // Top row and middle row
                data_reg[i][j] <= data_reg[i+1][j];
              end else begin
                // Bottom row
                if (j == 0) begin
                  data_reg[i][j] <= left_input;
                end else if (j == 1) begin
                  data_reg[i][j] <= middle_input;
                end else begin
                  data_reg[i][j] <= right_input;
                end
              end
            end
          end
        end
      end
    end
  endgenerate

  // Multiply and accumulate
  reg [FILTER_INT_BITS+FILTER_FRACT_BITS+INPUT_WIDTH-1:0] filter_multiply_result[0:2][0:2];
  generate
    for (i = 0; i < 3; i = i + 1) begin
      for (j = 0; j < 3; j = j + 1) begin
        always @(posedge clk) begin
          if (reset) begin
            filter_multiply_result[i][j] <= 0;
          end else begin
            if (enable) begin
              filter_multiply_result[i][j] <= data_reg[i][j] * (FILTER_VALUES[i*3+j]);
            end
          end
        end
      end
    end
  endgenerate

  // Add all the multiplication result
  reg [FILTER_INT_BITS+FILTER_FRACT_BITS+INPUT_WIDTH-1:0] row_accumulate_result[0:2];
  reg [RESULT_WIDTH-1:0] filter_accumulate_result;
  generate
    for (i = 0; i < 3; i = i + 1) begin
      always @(posedge clk) begin
        if (reset) begin
          row_accumulate_result[i] <= 0;
        end else begin
          if (enable) begin
            row_accumulate_result[i] <= filter_multiply_result[i][0] + filter_multiply_result[i][1] + filter_multiply_result[i][2];
          end
        end
      end
    end
    always @(posedge clk) begin
      if (reset) begin
        filter_accumulate_result <= 0;
      end else begin
        if (enable) begin
          filter_accumulate_result <= (row_accumulate_result[0] + row_accumulate_result[1] + row_accumulate_result[2]) >> FILTER_FRACT_BITS;
        end
      end
    end
  endgenerate

  // Output
  assign left_output = data_reg[0][0];
  assign middle_output = data_reg[0][1];
  assign right_output = data_reg[0][2];
  assign filter_output = filter_accumulate_result;
endmodule
