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
- tstrb signal
  - Would have to account for non-aligned data. Might need to separate R, G, B into different modules
  - Could split into 3 modules, each only deals with one channel, and have a small block that splits AXIS data into 3 bytes. 

## Output Buffer
This module outputs pixels. It may use a FIFO structure, or it could be just one single register that stores the pixel value. 

Output via AXI-S interface.