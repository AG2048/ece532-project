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

void DemoISR(void *callBackRef, void *pVideo)
{
	char *data = (char *) callBackRef;
	*data = 1; //set fRefresh to 1
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
