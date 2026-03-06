# ece532-project (PanCam)
This project uses a Nexys Video FPGA board along with Gyroscope and OV7670 Camera PMODs to capture panoramic images. A custom IP is used to apply Gaussian blur on the edge of images taken to allow more smooth transitions between images stitched together.

```
README.md
image_processor/
OV7670_RGB565/
packaged_IP/
final_software/
vivado_proj/
```

`image_processor/` contains relevant verilog modules and testbench for the image stitching IP

`OV7670_RGB565/` contains a verilog module used to convert OV7670 camera input in RGB565 format to AXI Streaming RGB888 format for VDMA

`packaged_IP/` contains packaged IPs used in this project, including the image processor and Digilent gyroscope PMOD IP

`final_software/` contains the final C file used to control the system

`vivado_proj/` contains the Vivado project for PanCam, this project is based on the Digilent Nexys Video HDMI Demo project
