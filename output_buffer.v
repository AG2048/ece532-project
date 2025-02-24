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
