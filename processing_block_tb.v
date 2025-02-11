`timescale 1ns / 1ps

module processing_block_tb # (
  parameter INPUT_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter FILTER_INT_BITS = 0,
  parameter FILTER_FRACT_BITS = 20,
  parameter FILTER_VALUE = 116509,

  parameter BLOCK_SIZE = 3
)();
    reg [INPUT_WIDTH-1:0] inputs[0:BLOCK_SIZE-1];
    wire [RESULT_WIDTH-1:0] outputs[0:BLOCK_SIZE-1];
    wire [RESULT_WIDTH-1:0] filter_output;

    reg clk;
    reg resetn;
    reg enable;
    
    integer i, j;
    
    processing_block #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .RESULT_WIDTH(RESULT_WIDTH),
        .FILTER_INT_BITS(FILTER_INT_BITS),
        .FILTER_FRACT_BITS(FILTER_FRACT_BITS),
        .FILTER_VALUE(FILTER_VALUE),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .inputs(inputs),
        .outputs(outputs),
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
        resetn = 1'b0;
        enable = 1'b0;
        #20
        resetn = 1'b1;
        for (i=0; i < (1<<INPUT_WIDTH)-BLOCK_SIZE; i=i+BLOCK_SIZE)
        begin
            #10 
            for (j=0; j < BLOCK_SIZE; j=j+1) begin
                inputs[j] = i+j;
            end
        end
        #100

        resetn = 1'b0;
        enable = 1'b0;
        #20
        resetn = 1'b1;
        for (i=0; i < (1<<INPUT_WIDTH)-BLOCK_SIZE; i=i+BLOCK_SIZE)
        begin
            #10 
            enable = 1'b1;
            for (j=0; j < BLOCK_SIZE; j=j+1) begin
                inputs[j] = i+j;
            end
        end
        #10
        enable = 1'b0;
        #100
        enable = 1'b0;
    end
      
endmodule
