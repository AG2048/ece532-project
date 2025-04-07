onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L xil_defaultlib -L xpm -L axi_lite_ipif_v3_0_4 -L lib_cdc_v1_0_2 -L interrupt_control_v3_1_4 -L axi_gpio_v2_0_20 -L lib_pkg_v1_0_2 -L axi_timer_v2_0_20 -L lib_srl_fifo_v1_0_2 -L axi_uartlite_v2_0_22 -L fifo_generator_v13_2_3 -L lib_fifo_v1_0_12 -L blk_mem_gen_v8_4_2 -L lib_bmg_v1_0_11 -L axi_datamover_v5_1_20 -L axi_vdma_v6_3_6 -L mdm_v3_2_15 -L microblaze_v11_0_0 -L axi_intc_v4_1_12 -L xlconcat_v2_1_1 -L proc_sys_reset_v5_0_13 -L v_tc_v6_1_13 -L v_vid_in_axi4s_v4_0_9 -L v_axi4s_vid_out_v4_0_10 -L xlconstant_v1_1_5 -L lmb_bram_if_cntlr_v4_0_15 -L lmb_v10_v3_0_9 -L generic_baseblocks_v2_1_0 -L axi_infrastructure_v1_1_0 -L axi_register_slice_v2_1_18 -L axi_data_fifo_v2_1_17 -L axi_crossbar_v2_1_19 -L axi_sg_v4_1_11 -L axi_dma_v7_1_19 -L axi_protocol_converter_v2_1_18 -L axi_clock_converter_v2_1_17 -L axi_dwidth_converter_v2_1_18 -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.hdmi xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {hdmi.udo}

run -all

quit -force
