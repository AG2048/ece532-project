# Microblaze Code Structure
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

## Microblaze Code Structure (Mar 10 Version)
```c
// Initialize / Reset (use an external button as such trigger)
prev_angle = 0
current_angle = 0
// camera start writing to frame buffer
while current_angle < prev_angle:
  current_angle = current_angle + f(gyro_angular_velocity()) // handle some threshold and gyro stuff
endwhile

// Capture Image
pause_camera()

// Bring data to another location
*new_location_data = read_from_frame_buffer()

// Initialize IP AXIS read
set_up_read_from_IP_to_DMA() // this is because our read has backpressure, has to be initialized before write to IP. (also specify length wanted to be read)

// Send image to IP core
if (first_image): 
  send_right_edge_to_ip()
else if(last_image):
  send_left_edge_to_ip()
else:
  send_both_edges_to_ip()

// Update gyroscope angle
prev_angle = current_angle

// Camera start again
camera_resume()

repeat;

if (all_images_taken){
  camera_stop();
  // Write to frame buffer
  write_image_to_frame_buffer(starting_col);
  while (!reset) {
    if (left_button_pressed){
      starting_col = max(starting_col-1, 0);
      write_image_to_frame_buffer(starting_col);
    } else if (right_button_pressed){
      starting_col = min(starting_col+1, max_col);
      write_image_to_frame_buffer(starting_col);
    }
  }
}
```
