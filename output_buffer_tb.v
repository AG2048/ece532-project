// Probably just use the input_buffer and processing blocks that they are already tested.
// Simulate inputs of again 1,2,3,4,5... to all RGB channels, and now test cases 
// where input valid is sometimes not valid in middle
// Output ready is not ready in the middle
// Just print output result to display. 
// Also just test a case where output is ALWAYS ready, input is ALWAYS valid (until finished a batch of inputs, wait for 100 cycles, then start again)