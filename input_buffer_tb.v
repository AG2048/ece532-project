// First test: input always valid, no back pressure
// Second test: input sometimes valid, no back pressure
// Third test: input always valid, back pressure
// Fourth test: input always valid, no back pressure. Test if module still outputs data after tlast.
// Fifth test: No reset in between Fourth and Fifth test. Also see if module can handle back pressure during the last cycle of data.

// Currently the module is doing correctly. The "full columns first input" is at correct time of "00, 0a, 14" (0, 10, 20) and the data is flowing correctly.
// Handles valid and back pressure correctly. (for valid case, only odd numbers got through. For back pressure, data only flows when back pressure is false)
// Also handles tlast correctly. (after tlast, the module still outputs data properly, the full columns first input still happens at the correct time) During output state, still react to back pressure correctly.

module input_buffer_tb #(
  parameter DATA_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter C_AXIS_TDATA_WIDTH = 32,

  // These two parameters should be the same, could change for "advanced" features
  // For testbench, we set this value to 10. 
  parameter BUFFER_HEIGHT = 10, // How many rows to buffer
  parameter INPUT_HEIGHT = 10 // How many rows to input (used for the BLOCK_SIZE delay after INPUT_HEIGHT inputs)
)
();
    // Some axi-stream signals
    reg aclk, aresetn;
    reg tvalid;
    reg [(C_AXIS_TDATA_WIDTH/8)-1:0] tstrb;
    wire tready;
    reg [C_AXIS_TDATA_WIDTH-1:0] tdata;
    reg tlast;
    reg output_buffer_is_done;

    // Internal signals
    wire [BLOCK_SIZE * DATA_WIDTH - 1:0] inputs_R;
    wire [BLOCK_SIZE * DATA_WIDTH - 1:0] outputs_R;
    wire [BLOCK_SIZE * DATA_WIDTH - 1:0] inputs_G;
    wire [BLOCK_SIZE * DATA_WIDTH - 1:0] outputs_G;
    wire [BLOCK_SIZE * DATA_WIDTH - 1:0] inputs_B;
    wire [BLOCK_SIZE * DATA_WIDTH - 1:0] outputs_B;

    // Output module signals (!(output_module_tvalid && !output_module_tready)) (if output is valid, but we can't write it out)
    reg output_has_back_pressure; // if true, data will flow.
    wire is_full_columns_first_input; // Output from module, we monitor this.
    wire data_flowing; // If data is flowing from input to output (write enable or padding) (output from module)

    integer i, j;

    input_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .BLOCK_SIZE(BLOCK_SIZE),
        .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
        .BUFFER_HEIGHT(BUFFER_HEIGHT),
        .INPUT_HEIGHT(INPUT_HEIGHT)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .tready(tready),
        .tvalid(tvalid),
        .tstrb(tstrb),
        .tdata(tdata),
        .tlast(tlast),
        .inputs_R(inputs_R),
        .outputs_R(outputs_R),
        .inputs_G(inputs_G),
        .outputs_G(outputs_G),
        .inputs_B(inputs_B),
        .outputs_B(outputs_B),
        .output_has_back_pressure(output_has_back_pressure),
        .is_full_columns_first_input(is_full_columns_first_input),
        .data_flowing(data_flowing),
        .output_buffer_is_done(output_buffer_is_done)
    );

    processing_block #(
        .INPUT_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(DATA_WIDTH),
        .FILTER_INT_BITS(0),
        .FILTER_FRACT_BITS(20),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) dut_R (
        .clk(aclk),
        .resetn(aresetn),
        .enable(data_flowing),
        .inputs(outputs_R),
        .outputs(inputs_R),
        .filter_output()
    );

    processing_block #(
        .INPUT_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(DATA_WIDTH),
        .FILTER_INT_BITS(0),
        .FILTER_FRACT_BITS(20),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) dut_G (
        .clk(aclk),
        .resetn(aresetn),
        .enable(data_flowing),
        .inputs(outputs_G),
        .outputs(inputs_G),
        .filter_output()
    );

    processing_block #(
        .INPUT_WIDTH(DATA_WIDTH),
        .RESULT_WIDTH(DATA_WIDTH),
        .FILTER_INT_BITS(0),
        .FILTER_FRACT_BITS(20),
        .BLOCK_SIZE(BLOCK_SIZE)
    ) dut_B (
        .clk(aclk),
        .resetn(aresetn),
        .enable(data_flowing),
        .inputs(outputs_B),
        .outputs(inputs_B),
        .filter_output()
    );

    // Generate a clock (period 10 ns)
    initial begin
        aclk = 1'b0;
        forever begin
            #5 aclk = ~aclk;
        end
    end

    initial begin
        // Here, we want to send the values 0, 1, 2, 3, 4, 5... and keep going into the input buffer. 
        // Test capability of device to not move data when valid is false.
        // Test capability of device not to move data when back pressure is true.

        // We assume tstrb all 1s.

        tstrb = 4'hF;
        aresetn = 1'b0;
        tvalid = 1'b0;
        tdata = 32'h00000000;
        output_has_back_pressure = 1'b0;
        tlast = 1'b0;
        output_buffer_is_done = 1'b0;

        // Reset
        #10 
        
        // Reset finished
        aresetn = 1'b1;
        #10

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9... (TEST 1)
        for (i = 0; i < 100; i = i + 1) begin
            tvalid = 1'b1;
            // Note here data is 32 bits, and the value we actually want to send would be 0x00000000, 0x01010100, 0x02020200, 0x03030300, 0x04040400, 0x05050500, 0x06060600, 0x07070700, 0x08080800, 0x09090900...
            tdata = i * 32'h01010100;
            // Note if not ready&&valid, we should not change the data.
            if (!(tready && tvalid)) begin
                i = i - 1;
            end
            #10;
        end
        
        // Reset, now test for if valid is sometimes false. (let valid be false for even numbers)
        aresetn = 1'b0;
        tvalid = 1'b0;

        // Reset
        #10

        // Reset finished
        aresetn = 1'b1;
        #10

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9... (TEST 2)
        for (i = 0; i < 100; i = i + 1) begin
            tvalid = (i % 2 == 0) ? 1'b0 : 1'b1;
            // Note here data is 32 bits, and the value we actually want to send would be 0x00000000, 0x01010100, 0x02020200, 0x03030300, 0x04040400, 0x05050500, 0x06060600, 0x07070700, 0x08080800, 0x09090900...
            tdata = i * 32'h01010100;
            // Note if not ready, we should not change the data. (So we expect the data to only send odd numbers)
            if (!tready) begin
                i = i - 1;
            end
            #10;
        end

        // Reset, now test for if back pressure is true.
        aresetn = 1'b0;
        tvalid = 1'b0;
        
        // Reset
        #10

        // Reset finished
        aresetn = 1'b1;
        j = 0;
        #10

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9... (TEST 3)
        for (i = 0; i < 100; i = i + 1) begin
            tvalid = 1'b1;
            output_has_back_pressure = (i % 2 == 0) ? 1'b0 : 1'b1;
            // Note here data is 32 bits, and the value we actually want to send would be 0x00000000, 0x01010100, 0x02020200, 0x03030300, 0x04040400, 0x05050500, 0x06060600, 0x07070700, 0x08080800, 0x09090900...
            tdata = j * 32'h01010100;
            #1; // just delay by 1 so in simulation the output_has_backpressure can propagate through logic. In reality the module should have almost the full clock period to do so
            // Note if not ready&&valid, we should not change the data.
            if ((tready && tvalid)) begin
                j = j + 1;
            end
            #9;
        end
        
        // Here we test if the module can handle MULTIPLE cycles of data input. (most importantly the tlast signal)
        tstrb = 4'hF;
        aresetn = 1'b0;
        tvalid = 1'b0;
        tdata = 32'h00000000;
        output_has_back_pressure = 1'b0;
        tlast = 1'b0;

        // Reset
        #10 
        
        // Reset finished
        aresetn = 1'b1;
        #10

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9... (TEST 4)
        for (i = 0; i < 100; i = i + 1) begin
            tvalid = 1'b1;
            // Note here data is 32 bits, and the value we actually want to send would be 0x00000000, 0x01010100, 0x02020200, 0x03030300, 0x04040400, 0x05050500, 0x06060600, 0x07070700, 0x08080800, 0x09090900...
            tdata = i * 32'h01010100;
            // Note if not ready&&valid, we should not change the data.
            if (!(tready && tvalid)) begin
                i = i - 1;
            end
            if (i==99) tlast = 1'b1;
            #10;
        end
        tlast = 1'b0; //deassert last
        tvalid = 1'b0;
        output_buffer_is_done = 1'b1; // a "fake" output is done. This is the "previous" output done signal...
        #10;
        output_buffer_is_done = 1'b0; // a "fake" output is done. This is the "previous" output done signal...
        #150;

        // 15 cycles later, output is done, we should be able to send more data.
        output_buffer_is_done = 1'b1;
        #10;
        output_buffer_is_done = 1'b0;

        #100; // Wait a few more cycles to test if the output data is flushed out, even if tvalid is still true. (During this time tready should be false)
        
        tstrb = 4'hF;
        tvalid = 1'b0;
        tdata = 32'h00000000;
        output_has_back_pressure = 1'b0;
        tlast = 1'b0;

        // NOTE: no reset here.

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9...
        for (i = 0; i < 100; i = i + 1) begin
            tvalid = 1'b1;
            // Note here data is 32 bits, and the value we actually want to send would be 0x00000000, 0x01010100, 0x02020200, 0x03030300, 0x04040400, 0x05050500, 0x06060600, 0x07070700, 0x08080800, 0x09090900...
            tdata = i * 32'h01010100;
            // Note if not ready&&valid, we should not change the data.
            if (!(tready && tvalid)) begin
                i = i - 1;
            end
            if (i==99) tlast = 1'b1;
            #10;
        end
        tlast = 1'b0; //deassert last
        tvalid = 1'b0;
        output_buffer_is_done = 1'b1; // a "fake" output is done. This is the "previous" output done signal...
        #10;
        output_buffer_is_done = 1'b0; // a "fake" output is done. This is the "previous" output done signal...
        #30;
        output_has_back_pressure = 1'b1; // simulate output has back pressure during the last cycle
        #100;
        output_has_back_pressure = 1'b0; // simulate output has back pressure during the last cycle
        #150;

        // 15 cycles later, output is done, we should be able to send more data.
        output_buffer_is_done = 1'b1;
        #10;
        output_buffer_is_done = 1'b0;

        #100; // Wait a few more cycles to test if the output data is flushed out, even if tvalid is still true. (During this time tready should be false)

        $display("Testbench finished.");
    end
endmodule