`timescale 1ns / 1ps

module processing_block_tb # (
  parameter INPUT_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter FILTER_INT_BITS = 0,
  parameter FILTER_FRACT_BITS = 8
)();
    reg [INPUT_WIDTH-1:0] left_input;
    reg [INPUT_WIDTH-1:0] middle_input;
    reg [INPUT_WIDTH-1:0] right_input;

    wire [INPUT_WIDTH-1:0] left_output;
    wire [INPUT_WIDTH-1:0] middle_output;
    wire [INPUT_WIDTH-1:0] right_output;
    wire [RESULT_WIDTH-1:0] filter_output;



    reg clk;
    reg reset;
    reg enable;
    
    integer i;
    
    processing_block #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH),
        .FILTER_INT_BITS(FILTER_INT_BITS),
        .FILTER_FRACT_BITS(FILTER_FRACT_BITS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .left_input(left_input),
        .middle_input(middle_input),
        .right_input(right_input),
        .left_output(left_output),
        .middle_output(middle_output),
        .right_output(right_output),
        .filter_output(filter_output)
    );
    
    // Generate a clock (period 10 ns)
    initial begin
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end
    
    initial
    begin
        reset = 1'b1;
        enable = 1'b0;
        #20
        reset = 1'b0;
        for (i=0; i < 16; i=i+1)
        begin
            #10 
            left_input=i;
            middle_input=i;
            right_input=i;
        end
        #100

        reset = 1'b1;
        enable = 1'b0;
        #20
        reset = 1'b0;
        enable = 1'b1;
        for (i=0; i < 16; i=i+1)
        begin
            #10 
            left_input=i;
            middle_input=i;
            right_input=i;
        end
        #100
    end
      
endmodule
