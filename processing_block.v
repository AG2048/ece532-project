module processing_block #(
  parameter INPUT_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter ROW_ADDITION_EXTRA_BITS = $clog2(BLOCK_SIZE), // Extra bits for row addition
  parameter FILTER_INT_BITS = 0,
  parameter FILTER_FRACT_BITS = 20,
  parameter FILTER_VALUE = ((1<<FILTER_FRACT_BITS)/BLOCK_SIZE/BLOCK_SIZE)+1 // 1/9 << 20 + 1
)
(
  clk, resetn, enable,
  inputs, outputs,
  filter_output
);
  input wire clk;
  input wire resetn;
  input wire enable;

  input wire [(INPUT_WIDTH * BLOCK_SIZE) - 1:0] inputs;
  output wire [(INPUT_WIDTH * BLOCK_SIZE) - 1:0] outputs;
  output wire [RESULT_WIDTH-1:0] filter_output;
  
  // Note the filter values are in fixed point format with FILTER_INT_BITS integer bits and FILTER_FRACT_BITS fractional bits
  wire [FILTER_INT_BITS+FILTER_FRACT_BITS-1:0] FILTER_VALUES[0:BLOCK_SIZE*BLOCK_SIZE-1];
  for (genvar i = 0; i < BLOCK_SIZE*BLOCK_SIZE; i = i + 1) begin
    assign FILTER_VALUES[i] = FILTER_VALUE;
  end
  // Genvar 9 reg in a BLOCK_SIZExBLOCK_SIZE grid, define 9 reg first with i,j index
  reg [INPUT_WIDTH-1:0] data_reg[0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
  genvar i, j;
  generate
    for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
      for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
        always @(posedge clk) begin
          if (!resetn) begin
            data_reg[i][j] <= 0;
          end else begin
            // Shift data upward by one, bottom comes from input
            if (enable) begin
              if (i != BLOCK_SIZE-1) begin
                // Top row and middle row
                data_reg[i][j] <= data_reg[i+1][j];
              end else begin
                // Bottom row (jth input from inputs)
                data_reg[i][j] <= inputs[(j+1) * INPUT_WIDTH - 1:j * INPUT_WIDTH];
              end
            end
          end
        end
      end
    end
  endgenerate

  // Multiply and accumulate
  reg [FILTER_INT_BITS+FILTER_FRACT_BITS+INPUT_WIDTH-1:0] filter_multiply_result[0:BLOCK_SIZE-1][0:BLOCK_SIZE-1];
  generate
    for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
      for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
        always @(posedge clk) begin
          if (!resetn) begin
            filter_multiply_result[i][j] <= 0;
          end else begin
            if (enable) begin
              filter_multiply_result[i][j] <= data_reg[i][j] * (FILTER_VALUES[i*BLOCK_SIZE+j]);
            end
          end
        end
      end
    end
  endgenerate

  // Add all the multiplication result
  reg [FILTER_INT_BITS+FILTER_FRACT_BITS+INPUT_WIDTH+ROW_ADDITION_EXTRA_BITS-1:0] row_accumulate_result[0:BLOCK_SIZE-1];
  // Filter result has width of predefined value, ASSUMING wouldn't overflow
  reg [RESULT_WIDTH-1:0] filter_accumulate_result;
  integer col_index, sum_col, sum_row, row_index;
  generate
    for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
      always @(posedge clk) begin
        if (!resetn) begin
          row_accumulate_result[i] <= 0;
        end else begin
          if (enable) begin
            // Compute the sum over j (columns)
            sum_row = 0;
            for (col_index = 0; col_index < BLOCK_SIZE; col_index = col_index + 1) begin
              sum_row = sum_row + filter_multiply_result[i][col_index];
            end

            row_accumulate_result[i] <= sum_row;
          end
        end
      end
    end
    always @(posedge clk) begin
      if (!resetn) begin
        filter_accumulate_result <= 0;
      end else begin
        if (enable) begin
          // Compute the sum over i (rows)
          sum_col = 0;
          for (row_index = 0; row_index < BLOCK_SIZE; row_index = row_index + 1) begin
            sum_col = sum_col + row_accumulate_result[row_index];
          end
          filter_accumulate_result <= sum_col >> FILTER_FRACT_BITS;
        end
      end
    end
  endgenerate

  // Output output[j] = data_reg[0][j], comb logic
  genvar output_col_index;
  generate
      for(output_col_index = 0; output_col_index < BLOCK_SIZE; output_col_index = output_col_index+1) begin 
          assign outputs[(output_col_index+1) * INPUT_WIDTH - 1:output_col_index * INPUT_WIDTH] = data_reg[0][output_col_index];
      end
  endgenerate
  assign filter_output = filter_accumulate_result;
endmodule
