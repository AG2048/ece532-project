module processing_block (
  left_input, middle_input, right_input,
  left_output, middle_output, right_output,
  filter_output
)
  // Reg: have 3x3 reg, that on ready shifts all data upward by one

  // Could have 9 more temp reg that stores multiplication result prior to adding, thus 1 cycle delay but improves timing

  // Input tied to the bottom 3 reg, output tied to top 3 reg

endmodule
