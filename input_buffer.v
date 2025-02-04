module processing_block #(
  parameter INPUT_WIDTH = 8
)
(
  clk, reset,
  ready, valid, strb, data_in
);
  input wire clk;
  input wire reset;

  output wire ready;
  input wire valid;
  output wire strb;
  input wire [INPUT_WIDTH-1:0] data_in;

  // We won't really need an IFIFO, since we assume all processing is 1 cycle
  
  // Ready: not always 1 due to output pipeline pileup

endmodule