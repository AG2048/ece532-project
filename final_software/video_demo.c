/************************************************************************/
/*																		*/
/*	video_demo.c	--	Nexys Video HDMI demonstration 						*/
/*																		*/
/************************************************************************/
/*	Author: Sam Bobrowicz												*/
/*	Copyright 2015, Digilent Inc.										*/
/************************************************************************/
/*  Module Description: 												*/
/*																		*/
/*		This file contains code for running a demonstration of the		*/
/*		Video input and output capabilities on the Nexys Video. It is a good	*/
/*		example of how to properly use the display_ctrl and				*/
/*		video_capture drivers.											*/
/*																		*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/* 																		*/
/*		11/25/2015(SamB): Created										*/
/*		03/31/2017(ArtVVB): Updated sleep functions for 2016.4			*/
/*																		*/
/************************************************************************/

/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */

#include "video_demo.h"
#include "video_capture/video_capture.h"
#include "display_ctrl/display_ctrl.h"
#include "intc/intc.h"
#include <stdio.h>
#include "xuartlite_l.h"
//#include "xuartps.h"
#include "math.h"
#include <ctype.h>
#include <stdlib.h>
#include "xil_types.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "sleep.h"
/*
 * XPAR redefines
 */
#define DYNCLK_BASEADDR XPAR_AXI_DYNCLK_0_BASEADDR
#define VGA_VDMA_ID XPAR_AXIVDMA_0_DEVICE_ID
#define DISP_VTC_ID XPAR_VTC_0_DEVICE_ID
#define VID_VTC_ID XPAR_VTC_1_DEVICE_ID
#define VID_GPIO_ID XPAR_AXI_GPIO_VIDEO_DEVICE_ID
#define VID_VTC_IRPT_ID XPAR_INTC_0_VTC_1_VEC_ID
#define VID_GPIO_IRPT_ID XPAR_INTC_0_GPIO_0_VEC_ID
#define SCU_TIMER_ID XPAR_AXI_TIMER_0_DEVICE_ID
#define UART_BASEADDR XPAR_UARTLITE_0_BASEADDR

#define FILTER_WIDTH 3 // the image processor has a 3x3 filter. 
#define START_COLUMN_INDEX 120 // the column index to start processing the image.
#define END_COLUMN_INDEX 520 // the column index to end processing the image. (exclusive)
#define BLUR_WIDTH 20 // How many pixels from each side to blur. 

/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */

/*
 * Display and Video Driver structs
 */
DisplayCtrl dispCtrl;
XAxiVdma vdma;
VideoCapture videoCapt;
INTC intc;
char fRefresh; //flag used to trigger a refresh of the Menu on video detect

/*
 * Framebuffers for video data (3 frames buffer) (define buffer array for 1920*1080*3 screen. )
 */
u8 frameBuf[DISPLAY_NUM_FRAMES][DEMO_MAX_FRAME];
u8 *pFrames[DISPLAY_NUM_FRAMES]; //array of pointers to the frame buffers

/*
 * Interrupt vector table. Contains pointers to the handlers for the core interrupts.
 */
const ivt_t ivt[] = {
	videoGpioIvt(VID_GPIO_IRPT_ID, &videoCapt),
	videoVtcIvt(VID_VTC_IRPT_ID, &(videoCapt.vtc))
};

// #############################################################################################
// ########################### Camera DMA Functions ############################################
// #############################################################################################

 void camera_dma_init(){
	int currentFrame = dispCtrl.curFrame;
	int Status;
	XAxiVdma AxiVdma;
	XAxiVdma_Config *Config;
	XAxiVdma_DmaSetup WriteCfg;

	// Get Hardware VDMA Config from device ID
	Config = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_1_DEVICE_ID);
	// Initialize the VDMA
	Status = XAxiVdma_CfgInitialize(&AxiVdma, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
	  xil_printf("Camera Cfg init failed %d\r\n", Status);
	}

	// Define a DMA Transfer Configuration
	WriteCfg.VertSizeInput = 480;
	WriteCfg.HoriSizeInput = 640 * 3; // 640 pixels by 4 bytes per pixel
	WriteCfg.Stride = DEMO_STRIDE;
	WriteCfg.FrameDelay = 0;
	WriteCfg.PointNum = 0;
	WriteCfg.EnableFrameCounter = 0;
	WriteCfg.EnableCircularBuf = 1;
	WriteCfg.EnableSync = 0;
	WriteCfg.FixedFrameStoreAddr = currentFrame;

	//WriteCfg.FrameStoreStartAddr[0] = (u32) framePtr[0];
	for (int i = 0; i < DISPLAY_NUM_FRAMES; i++) {
		WriteCfg.FrameStoreStartAddr[i] = (u32) pFrames[i];
	}

	// Apply the write transfer config
	Status = XAxiVdma_DmaConfig(&AxiVdma, XAXIVDMA_WRITE, &WriteCfg);
	if (Status != XST_SUCCESS) {
	  xil_printf("Write channel config failed %d\r\n", Status);
	}

	// Set the destination address to be the base address of DDR memory
	// same location as the AXI TFT
	Status = XAxiVdma_DmaSetBufferAddr(&AxiVdma, XAXIVDMA_WRITE, WriteCfg.FrameStoreStartAddr);
	if (Status != XST_SUCCESS) {
	  xil_printf("Write channel set buffer address failed %d\r\n", Status);
	}
	Status = XAxiVdma_DmaStart(&AxiVdma, XAXIVDMA_WRITE);
	if (Status != XST_SUCCESS) {
	  xil_printf("Start Write transfer failed %d\r\n", Status);
	}
	Status = XAxiVdma_StartParking(&AxiVdma, currentFrame, XAXIVDMA_WRITE);
	if (Status != XST_SUCCESS) {
	  xil_printf("Unable to park the Write channel %d\r\n", Status);
	}
}
void camera_dma_stop() {
  // Tell the VDMA core to stop reading from Camera (used if we want to extract current frame)
	int Status;
	XAxiVdma AxiVdma;
	XAxiVdma_Config *Config;

	// Get Hardware VDMA Config from device ID
	Config = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_1_DEVICE_ID);
	// Initialize the VDMA
	Status = XAxiVdma_CfgInitialize(&AxiVdma, Config, Config->BaseAddress);

	// Stop the VDMA Core
	XAxiVdma_DmaStop(&AxiVdma, XAXIVDMA_READ);
	while(XAxiVdma_IsBusy(&AxiVdma, XAXIVDMA_READ));

	if (XAxiVdma_GetDmaChannelErrors(&AxiVdma, XAXIVDMA_READ))
	{
		xil_printf("Clearing DMA errors...\r\n");
		XAxiVdma_ClearDmaChannelErrors(&AxiVdma, XAXIVDMA_READ, 0xFFFFFFFF);
	}
}
void camera_dma_change_frame(u32 frameIndex) {
  // Tell camera dma to write to a different one of the frame buffers for HDMI output
	int Status;
	XAxiVdma AxiVdma;
	XAxiVdma_Config *Config;

	// Get Hardware VDMA Config from device ID
	Config = XAxiVdma_LookupConfig(XPAR_AXI_VDMA_1_DEVICE_ID);
	// Initialize the VDMA
	Status = XAxiVdma_CfgInitialize(&AxiVdma, Config, Config->BaseAddress);

	Status = XAxiVdma_StartParking(&AxiVdma, frameIndex, XAXIVDMA_WRITE);
	if (Status != XST_SUCCESS) {
		xil_printf("Cannot change frame, unable to start parking %d\r\n", Status);
	}
}

// #############################################################################################
// ################################# HDMI Functions ############################################  
// #############################################################################################

void HDMIInitialize()
{
  /*
   * Tell the HDMI where to read the frame data from, and repeat this for all frames
   */
	int Status;
	XAxiVdma_Config *vdmaConfig;
	int i;

	/*
	 * Initialize an array of pointers to the 3 frame buffers
	 */
	for (i = 0; i < DISPLAY_NUM_FRAMES; i++)
	{
		pFrames[i] = frameBuf[i];
	}

	/*
	 * Initialize VDMA driver
	 */
	vdmaConfig = XAxiVdma_LookupConfig(VGA_VDMA_ID); // Find config
	if (!vdmaConfig)
	{
		xil_printf("No video DMA found for ID %d\r\n", VGA_VDMA_ID);
		return;
	}
	Status = XAxiVdma_CfgInitialize(&vdma, vdmaConfig, vdmaConfig->BaseAddress); // Initialize driver
	if (Status != XST_SUCCESS)
	{
		xil_printf("VDMA Configuration Initialization failed %d\r\n", Status);
		return;
	}

	/*
	 * Initialize the Display controller and start it
	 */
	Status = DisplayInitialize(&dispCtrl, &vdma, DISP_VTC_ID, DYNCLK_BASEADDR, pFrames, DEMO_STRIDE); // Initialize display
	if (Status != XST_SUCCESS)
	{
		xil_printf("Display Ctrl initialization failed during demo initialization%d\r\n", Status);
		return;
	}
	Status = DisplayStart(&dispCtrl);
	if (Status != XST_SUCCESS)
	{
		xil_printf("Couldn't start display during demo initialization%d\r\n", Status);
		return;
	}

  // The following code is for interrupt, just not really used currently so commented out. 
//	/*
//	 * Initialize the Interrupt controller and start it.
//	 */
//	Status = fnInitInterruptController(&intc);
//	if(Status != XST_SUCCESS) {
//		xil_printf("Error initializing interrupts");
//		return;
//	}
//	fnEnableInterrupts(&intc, &ivt[0], sizeof(ivt)/sizeof(ivt[0]));
//
//	/*
//	 * Initialize the Video Capture device
//	 */
//	Status = VideoInitialize(&videoCapt, &intc, &vdma, VID_GPIO_ID, VID_VTC_ID, VID_VTC_IRPT_ID, pFrames, DEMO_STRIDE, DEMO_START_ON_DET);
//	if (Status != XST_SUCCESS)
//	{
//		xil_printf("Video Ctrl initialization failed during demo initialization%d\r\n", Status);
//		return;
//	}
//
//	/*
//	 * Set the Video Detect callback to trigger the menu to reset, displaying the new detected resolution
//	 */
//	VideoSetCallback(&videoCapt, DemoISR, &fRefresh);

//	DemoPrintTest(dispCtrl.framePtr[dispCtrl.curFrame], dispCtrl.vMode.width, dispCtrl.vMode.height, dispCtrl.stride, DEMO_PATTERN_1);

	return;
}

void HDMIISR(void *callBackRef, void *pVideo)
{
	char *data = (char *) callBackRef;
	*data = 1; //set fRefresh to 1
}

// #############################################################################################
// ################################# Image Processing Functions ################################  
// #############################################################################################

/*
1. Read specific columns of the image to a buffer. (to extract border columns for processor to use)
2. Store columns of an image to a large buffer, with rooms left for the border columns after processor. 
3. From the large final image buffer, send specific columns of image to the HDMI output (controlled by button)

For each image, declare a buffer of size: SCAN_WIDTH * 478 * 3 (because 2 rows are used for border...)
(to be strict, should be 480 - (filter_size // 2))
row major order. 


####### ################################################################
####### ################################################################
####### ################################################################
####### ################################################################
####### ################################################################
####### ################################################################
####### ################################################################
####### ################################################################
####### ################################################################
*/
void store_columns_row_major_order_from_frame_buffer(int beg_col, int end_col, u8* in_buffer, u8* out_buffer){
  // store columns from frame buffer to a buffer. in_buffer is meant to be the frame buffer used for HDMI output, which stores the camera inputs.
  // The size of input buffer is 
  // beg_col: beginning column to store
  // end_col: end column to store, EXCLUSIVE
  // in_buffer: input frame buffer (1920*3 strided, only first 640*3 columns is actually used)
  // out_buffer: output buffer to store the columns (continuous, the size matches the number of columns stored)
  // Assuming the input we care about is an image of 640*480*3
  // Output is in row-major format: pixel i,j is stored at i*(width)*3 + j*3, where width = end_col-beg_col
  int current_col_pixel = 0;
  int current_line_pixel = 0;
  int pixel_count = 0;
  for(int r = 0; r < 480; r++){
    for(int c = 0; c < 640; c++){
      if(c >= beg_col && c < end_col){
        // Find the index in the in_buffer (column number + row number)
        u32 current_pixel = current_col_pixel + current_line_pixel;
        // output buffer at pixel_count is set to the pixel value of the frame buffer
        out_buffer[pixel_count] = in_buffer[current_pixel];
        out_buffer[pixel_count+1] = in_buffer[current_pixel+1];
        out_buffer[pixel_count+2] = in_buffer[current_pixel+2];
        pixel_count += 3;
      }
      current_col_pixel+=3;
    }
    current_col_pixel = 0;
    current_line_pixel += 1920*3;
  }
}

void store_image_to_buffer_and_ip_buffer(u8* in_buffer, u8* centre_buffer, u32* edge_ip_input_buffer_left, u32* edge_ip_input_buffer_right, u32* edge_ip_output_buffer, u8* edge_result_buffer, bool is_first, bool is_last){
  // From input buffer of size 1920*1080*3, which only contains 640*480*3 image,
  // store the image from START_COLUMN_INDEX + BLUR_WIDTH - 1 to END_COLUMN_INDEX - BLUR_WIDTH + 1 (exclusive) to the centre_buffer.
  // (reason: the blur will produce border of width BLUR_WIDTH-2, the last column sent to blur is also directly displayed)

  // From in buffer, move centre to centre buffer.
  // Move left edge to ip input buffer, start ip write.
  // Wait until ip read is done, move edge_ip_output buffer result to an edge_result buffer in row major order in u8 format.
  // Write RIGHT edge to edge buffer, begin ip read.

  /*
  (here, the IP dma is already in reading and writing mode, to a target edge_result buffer already)
  1. Put centre to where we want.
  2. If not first, put left to the edge_buffer. AND START AXI WRITE. 
  2.5: wait until IP DMA read is done.
  2.75: move edge_result_buffer's result to some memory location, change format from u32 to u8
  3. if not last, put right to the edge_buffer.
  4. Start IP DMA read
  */

  // 1. Put centre to where we want.
  int out_index = 0;
  for (int row = 0; row < 480-2; row++){
    for(int col = START_COLUMN_INDEX + BLUR_WIDTH - 1; col < END_COLUMN_INDEX - BLUR_WIDTH + 1; col++){
      int in_index = row * 1920 * 3 + col * 3;
      centre_buffer[out_index] = in_buffer[in_index];
      centre_buffer[out_index+1] = in_buffer[in_index+1];
      centre_buffer[out_index+2] = in_buffer[in_index+2];
      out_index += 3;
    }
  }

  // 2. If not first, put left to the edge_buffer. AND START AXI WRITE.
  if(!is_first){
    // Move left edge to the edge_ip_input_buffer, in column major order.
    int out_index = 0;
    for (int col = START_COLUMN_INDEX; col < START_COLUMN_INDEX + BLUR_WIDTH; col++){
      for(int row = 0; row < 480; row++){
        int in_index = row * 1920 * 3 + col * 3;
        edge_ip_input_buffer_right[out_index] = ((in_buffer[in_index] << 24) | (in_buffer[in_index+1] << 16) | in_buffer[in_index+2] << 8) & 0xFFFFFF00;
        out_index++;
      }
    }
    // Start IP DMA write
    // TODO: start IP DMA write
    // Wait until IP DMA write and read is done.
    // Move edge_ip_output_buffer to edge_result_buffer in row major order, in u8 format.
    // The edge_result_buffer is in column major order from left to right.
    out_index = 0;
    for (int col = 0; col < BLUR_WIDTH * 2 - 2; col++) {
      for (int row = 0; row < 478; row++) {
        int in_index = row * (BLUR_WIDTH * 2 - 2) + col;
        edge_result_buffer[out_index] = (edge_ip_output_buffer[in_index] >> 24) & 0xFF;
        edge_result_buffer[out_index+1] = (edge_ip_output_buffer[in_index] >> 16) & 0xFF;
        edge_result_buffer[out_index+2] = (edge_ip_output_buffer[in_index] >> 8) & 0xFF;
        out_index += 3;
      }
    }
  }

  // 3. If not last, put right to the edge_buffer.
  if(!is_last){
    // Move right edge to the edge_ip_input_buffer, in column major order.
    int out_index = 0;
    for (int col = END_COLUMN_INDEX - BLUR_WIDTH; col < END_COLUMN_INDEX; col++){
      for(int row = 0; row < 480; row++){
        int in_index = row * 1920 * 3 + col * 3;
        edge_ip_input_buffer_left[out_index] = ((in_buffer[in_index] << 24) | (in_buffer[in_index+1] << 16) | in_buffer[in_index+2] << 8) & 0xFFFFFF00;
        out_index++;
      }
    }
    // Start IP DMA read
    // TODO start IP DMA read to edge_ip_output_buffer
  }


}

void convert_centres_and_edges_to_row_major(centre_buffers_pointers, edge_buffers_pointers, u8* full_image_buffer){
  //input argument: a list of pointers to all centre buffers, and a list of pointers to all edge buffers. In the order of: centre, edge, centre edge, centre edge... centre
  // convert all the buffers to row major order. and store in ONE big buffer.
}

void display_image_from_start_col(u8* image_buffer, u8* frame_buffer, int begin_col){
  // Move image from a full row-major order image buffer to the frame buffer, starting from the begin_col. (don't need to error check if begin_col + 640 > total image length, some other function should handle that)
}

int compute_new_begin_col(int current_col, int direction, int max_col){
  // Compute the new begin column based on the current column and the direction. 
  // If direction is 1, move right, if direction is -1, move left. 
  // If the new column is out of bounds, keep it at the max or min value. 
  // max_col is the maximum column value. (the ENDING column value cannot be >= to this. )
}

/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */

int main(void)
{
	Xil_ICacheEnable();
	Xil_DCacheEnable();

	HDMIInitialize();
	camera_dma_init();
	u8* frame = dispCtrl.framePtr[dispCtrl.curFrame];
//	xil_printf("ajlsdhfajk\n");
//	usleep(10000000);
//	for(int i = 0; i < 640*3; i=i+3){
//		u8 a0 = frame[i];
//		u8 a1= frame[i+1];
//		u8 a2 = frame[i+2];
//		xil_printf("%x %x %x\t\n", a0, a1, a2);
//	}
//	while(1){
//		u32 current_col_pixel = 0;
//		u32 current_line_pixel = 0;
//		int pixel_count = 0;
//		for(int r = 0; r < 480; r++){
//			for(int c = 0; c < 640; c++){
//				u32 current_pixel = current_col_pixel + current_line_pixel;
//
////				u8 t0 = frame_read[current_pixel];
////				u8 t1 = frame_read[current_pixel+1];
////				u8 t2 = frame_read[current_pixel+2];
//
//				frame[current_pixel] = 0xFF;
//				frame[current_pixel+1] = 0x00;
//				frame[current_pixel+2] = 0x00;
//
//				current_col_pixel+=3;
//				pixel_count ++;
//			}
//			current_col_pixel = 0;
//			current_line_pixel += 1920*3;
//		}
//		Xil_DCacheFlushRange((unsigned int) frame, DEMO_MAX_FRAME);
//	}
//	DemoRun();
//	usleep(1000000);
//
//	for(int f = 0; f < 100; f++){
//		xil_printf("%x\t\n", frame[f]);
//	}
	return 0;
}
