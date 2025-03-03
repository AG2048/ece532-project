/*
module input_buffer #(
  parameter DATA_WIDTH = 8,
  parameter BLOCK_SIZE = 3,
  parameter C_AXIS_TDATA_WIDTH = 32,

  // These two parameters should be the same, could change for "advanced" features
  parameter BUFFER_HEIGHT = 480, // How many rows to buffer
  parameter INPUT_HEIGHT = 480 // How many rows to input (used for the BLOCK_SIZE delay after INPUT_HEIGHT inputs)
)
(
  // AXI-Stream interface
  aclk, aresetn,
  tready, tvalid, 
  tstrb, tdata,

  // Internal signals
  // inputs [(BLOCK_SIZE-1) * DATA_WIDTH - 1:0] (does not include the last col)
  // outputs [BLOCK_SIZE * DATA_WIDTH - 1:0] (includes the last col)
  // Input is from processing block, output is to block
  inputs_R, outputs_R,
  inputs_G, outputs_G,
  inputs_B, outputs_B,

  // Output module signals (!(output_module_tvalid && !output_module_tready)) (if output is valid, but we can't write it out)
  output_has_back_pressure, // If the output module has back pressure, 1 means we shouldn't have any data flow

  // Output signal to output_module, to help it figure out what data is useful
  is_full_columns_first_input, // If the data input to the processing block has all valid data on all its columns 
  // This signal is true when: ALL columns are full, and we are sending the FIRST row of input to the processing block
  // The output buffer is supposed to count how many cycles delay from input to output...
  data_flowing // If data is flowing from input to output (write enable or padding)
);
*/

// This test bench should send the values 1, 2, 3, 4, 5... to input buffer. Initialize 3 processing_block module, each tied to inputs_R, inputs_G, inputs_B, and outputs_R, outputs_G, outputs_B.

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
        .data_flowing(data_flowing)
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

        // Reset
        #10 
        
        // Reset finished
        aresetn = 1'b1;
        #10

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9...
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

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9...
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

        // Send 0, 1, 2, 3, 4, 5, 6, 7, 8, 9...
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

        $display("Testbench finished.");
    end
endmodule