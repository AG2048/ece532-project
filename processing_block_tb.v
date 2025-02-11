`timescale 1ns / 1ps

module processing_block_tb # (
  parameter INPUT_WIDTH = 8,
  parameter RESULT_WIDTH = 8,
  parameter FILTER_INT_BITS = 0,
  parameter FILTER_FRACT_BITS = 20,
  parameter FILTER_VALUE = 116509,

  parameter BLOCK_SIZE = 3
)();
    wire [INPUT_WIDTH * BLOCK_SIZE-1:0] inputs;
    wire [INPUT_WIDTH * BLOCK_SIZE-1:0] outputs;
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

    // Helpful output display
    reg [INPUT_WIDTH-1:0] inputs_display[BLOCK_SIZE-1:0];
    wire [RESULT_WIDTH-1:0] outputs_display[BLOCK_SIZE-1:0];
    genvar unpacking_index;
    generate
        for (unpacking_index = 0; unpacking_index < BLOCK_SIZE; unpacking_index = unpacking_index + 1) begin
            assign inputs[(unpacking_index+1)*INPUT_WIDTH-1:unpacking_index*INPUT_WIDTH] = inputs_display[unpacking_index];
            assign outputs_display[unpacking_index] = outputs[(unpacking_index+1)*RESULT_WIDTH-1:unpacking_index*RESULT_WIDTH];
        end
    endgenerate

    
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
                inputs_display[j] = i+j;
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
                inputs_display[j] = i+j;
            end
        end
        #100
        enable = 1'b1;
        #100
        resetn = 1'b0;
        enable = 1'b0;
        #20
        resetn = 1'b1;
        for (i=0; i < (1<<INPUT_WIDTH); i=i+1)
        begin
            #10 
            enable = 1'b1;
            inputs_display[0] = i/3;
            inputs_display[1] = 0;
            inputs_display[2] = 0;
        end
        #100
        enable = 1'b1;
        #100
        resetn = 1'b0;
        enable = 1'b0;
        #20
        resetn = 1'b1;
        for (i=0; i < 10; i=i+1)
        begin
            #10 
            enable = 1'b1;
            inputs_display[0] = 255;
            inputs_display[1] = 255;
            inputs_display[2] = 255;
        end
        #100
        enable = 1'b1;
    end
      
endmodule
