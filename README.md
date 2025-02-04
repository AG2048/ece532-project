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
