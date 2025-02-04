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
