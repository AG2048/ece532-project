# ece532-project

## Microblaze Code Structure
```c
// Receive angle value from gyroscope
get_gyroscope_angle();
// Receive joystick input
get_joystick_input();

// Display a target image to HDMI screen
display_HDMI(image);

// Collect the image from the camera
read_camera();

// Send portion of image to the IP core, and receive the processed version
call_ip(image);

// Call the built-in OLED to deliver user instructions
display_OLED(message);

// Extract for the IP to use
extract_edge(image1, image2);

// Extract a cutout for HDMI display with joystick 
extract_cutout(x,y);
```

Pseudocode:
```
main:
  initialize memory.
  Reset IP core
  Establish SPI / AXI connections (if necessary)
  wait until capture button pressed:
  do while (not all angles image captured)
    angle = get_gyroscope_angle
    if angle is at correct threshold
      image_storage = read_camera()
    else:
      display_OLED(angle)
      continue
    if not first image:
      edge = extract_edge(image1, image2)
      processed_edge = call_ip(edge)

  while not reset:
    // if we using joystick:
    scaled_image = extract_cutout(joystick_x, joystick_y);
    display_HDMI(scaled_image)

    // if not using joystick:
    display_HDMI(processed_image)
    
```

# Custom IP
The custom IP is 2 modules working together.

## Processing Block
Input: 3 8-bit values representing one of the RGB channels of a pixel, the three values are from 3 neighboring pixels in the same row.

Output: One 8-bit value representing the processed pixel value, and 3 8-bit values that are the three inputs 3 clock cycles ago.

Processing Logic:
- The input values are averaged and the result is outputted.
- There are 3x3 internal registers that stores the values of a 3x3 grid of pixels. Every cycle, the values are pushed into the register above them, and the new values are pushed into the bottom row. The bottom row is the input to the processing block. 
- The 3 output values are from the top row of the register.
- Each register is also input to a multiplier block that multiplies the register value with a constant value (fixed point <8 to 20>-bit representation of 1/9). The result is stored in a register. 
- The result of multiplication of the same row is summed together and stored in a register.
- The sum result is summed across the 3 rows, and the output is bit-shifted back to an 8-bit representation (Due to filter being less than 1, the result will be less than max of 8-bits).

## Input Buffer
This module stores an Nx3 grid of pixels, where N is the number of pixels in a column. Each pixel is represented by 3 8-bit values, one for each RGB channel. (Thus the memory requirement is `N x 3 x BLOCK_SIZE x 8`)

The buffer receives input from its bottom right corner, and every time an input is received, the buffer shifts all the values up by one row. The new input is stored in the bottom row, where data from top row is discarded into the Processing block. 

The input will occationally be set to 0, where we are anticipating data to be travelling through the processing block, so we wait until the data is about to pass through the processing block to allow the input to "align" with the previous data just returning from the processing block. (Done by 2 counters, one counting column valid inputs, and one counting number of padding zeros to be added)

There's another counter, that counts number of times a FULL COLUMN's input is ready to be sent to processing block. We count number of time this happens, and the BLOCK_SIZE'th time, it means we are inputting FULL data to the processing block.

When the input is complete (last signal), the buffer continues to output one entire column of data to the processing block. From here on out, the input to the buffer should be ignored and ready is set to 0.

Ready may also be set to zero when the pipeline is stalled, where the output buffer is full and not ready to receive new data. (In this case, the processing block's enable will be set to 0, and the input buffer will not write or read data)

### Major TODO:
- tready signal (done, set to equal to if the output has a back-pressure happening)
- tlast signal
  - Last is high, buffer will keep pushing anything into buffer for IMAGE_HEIGHT+6 cycles (account for the offset). 

**NOTE: Currently a small issue faced is that after tlast is asserted, the program doesn't keep running for another INPUT_HEIGHT cycles. We should make it such that it asserts tready=0 and run for another INPUT_HEIGHT cycles to flush out the data**

## Output Buffer
This module outputs pixels. It may use a FIFO structure, or it could be just one single register that stores the pixel value. 

Output via AXI-S interface.

# IP Modules I/O Spec

## Processing Block
`enable`: 1 if we want this block to read in and output data. 0 if we stalling the pipeline.

`inputs`: one wide input, `BLOCK_SIZE*INPUT_WIDTH` bits of data. Bits `INPUT_WIDTH-1:0` is the leftmost value input, next value is `INPUT_WIDTH*2-1:INPUT_WIDTH`, and so on.

`outputs`: One wide output. Same shape as input. Should be identical to the input BLOCK_SIZE cycles ago. (assuming no stalling)

`filter_output`: one number, OUTPUT_WIDTH bits. The output of the filter. This value should appear 3 cycles after the last row of the input is received.

## Input Buffer
`AXI-S Interface`: AXI streaming interface. Ready if we can accept data (we are not stalling and we are not writing padding zeros). tdata should be in the form of \[R,G,B,0\] (each 8 bits).

`tready`: We are ready to receive data. If no backpressure AND `counter_input` is not 0

`inputs_R`: Wide input, same shape as `outputs` of the processing block. This is the data processing block sends to the input buffer. Since the left-most output from the processing block is not used, we do not connect `inputs_R[DATA_WIDTH-1:0]` to anything in the processing block. This value is read back directly to the bottom row of the input buffer, excluding the last column.

`outputs_R`: Wide output, same shape as `inputs` of the processing block. This is the data the input buffer sends to the processing block. This value is output from the top row of the input buffer. 

(Repeat for G and B channels) (There should be 3 processing blocks, one for each channel)

`output_has_back_pressure`: Reading from output buffer. If this value is high, entire pipeline should stall.

`is_full_columns_first_input`: Output to output buffer. If this value is high, the input buffer is sending the first row of data to the processing block. (So the output buffer can count and determine which data is correct output).

`data_flowing`: Output to every module. If this value is high, the input buffer is sending data to the processing block. This is the input buffer's way of telling all other modules that the data is flowing through the pipeline. (This acts as `enable` for the processing block, and changes `tvalid` for the AXI-S output interface)

`output_buffer_is_done`: Input into input buffer. If this is high, it means output buffer has finished one full INPUT_HEIGHT of data. This is used to tell the input buffer to stop feeding data, and begin accepting new data after `tlast` is first asserted. The logic is: after `tlast` is true, we remember that `tlast` was true, and start counting down until all INPUT_HEIGHT data has been outputted. Then, we wait until output buffer is done, then we can forget about `tlast`. In the mean time, tready always false, and we just keep doing same thing as "padding zeros" until we are ready to output data. The other counters will reset at the end of the tlast flushing. (`output_buffer_is_done && counter_after_tlast == 0`)

## Output Buffer
`AXI-S Interface`: AXI streaming interface.

`tvalid`: When internal counter since when `is_full_columns_first_input` was first set to high AND `data_flowing` is high. We check if the counter is within a range where the `filter_output` of processing block is correct. If so, we are valid. We are NOT valid if: after/during a handshake of tvalid and tready, the `data_flowing` is false (this means we had a correct output, but since pipeline is stalled elsewhere, we don't yet have any new data to output) OR counter is out of range (meaning the data here is not meaningful). When `tvalid` is false, wait until a point where `data_flowing` is true and counter is within range. If handshake just happened, we are valid if `data_flowing` AND counter still in range.

`tdata`: Data output. This is the data the processing block sends to the output buffer. \[R,G,B,0\] (each 8 bits)

`tlast`: Last signal. This is high when the last pixel is outputted. (but we might not need this signal if it's handled at software level)

`output_has_back_pressure`: We set this to high if we are valid, but ready is low. Since this mean we have data to output, but the output device is not ready to receive it.

`is_full_columns_first_input`: When this is high with `data_flowing`, we are outputting the first row of data from the processing block. This is used to determine if the data is correct output.

`data_flowing`: If this is high, the output buffer is outputting data. This is the output buffer's way of telling all other modules that the data is flowing through the pipeline. (This acts as `enable` for the processing block, and changes `tvalid` for the AXI-S output interface)

`output_buffer_is_done`: If this is high, the output buffer has finished outputting one full INPUT_HEIGHT of data. Should be set to some `counter==0 && tready && tvalid`... Set to true if this is the last output data successfully sent out after receiving `is_full_columns_first_input` signal.