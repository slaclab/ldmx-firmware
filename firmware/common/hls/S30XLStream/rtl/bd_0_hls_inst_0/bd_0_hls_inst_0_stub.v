// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Tue Apr 23 18:39:29 2024
// Host        : Big-Daddys-Numbering-Machine running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/Rory/AppData/Roaming/Xilinx/Vitis/S30XLhitmakerStream/solution1/impl/vhdl/project.gen/sources_1/bd/bd_0/ip/bd_0_hls_inst_0/bd_0_hls_inst_0_stub.v
// Design      : bd_0_hls_inst_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu9p-flga2577-1-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "hitproducerStream_hw,Vivado 2022.2" *)
module bd_0_hls_inst_0(amplitude_0_ap_vld, onflag_0_ap_vld, ap_clk, 
  ap_rst_n, ap_start, ap_done, ap_idle, ap_ready, FIFO_0_TVALID, FIFO_0_TREADY, FIFO_0_TDATA, 
  FIFO_1_TVALID, FIFO_1_TREADY, FIFO_1_TDATA, FIFO_2_TVALID, FIFO_2_TREADY, FIFO_2_TDATA, 
  FIFO_3_TVALID, FIFO_3_TREADY, FIFO_3_TDATA, FIFO_4_TVALID, FIFO_4_TREADY, FIFO_4_TDATA, 
  FIFO_5_TVALID, FIFO_5_TREADY, FIFO_5_TDATA, FIFO_6_TVALID, FIFO_6_TREADY, FIFO_6_TDATA, 
  FIFO_7_TVALID, FIFO_7_TREADY, FIFO_7_TDATA, FIFO_8_TVALID, FIFO_8_TREADY, FIFO_8_TDATA, 
  FIFO_9_TVALID, FIFO_9_TREADY, FIFO_9_TDATA, FIFO_10_TVALID, FIFO_10_TREADY, FIFO_10_TDATA, 
  FIFO_11_TVALID, FIFO_11_TREADY, FIFO_11_TDATA, amplitude_1_TVALID, amplitude_1_TREADY, 
  amplitude_1_TDATA, onflag_1_TVALID, onflag_1_TREADY, onflag_1_TDATA, amplitude_2_TVALID, 
  amplitude_2_TREADY, amplitude_2_TDATA, onflag_2_TVALID, onflag_2_TREADY, onflag_2_TDATA, 
  amplitude_3_TVALID, amplitude_3_TREADY, amplitude_3_TDATA, onflag_3_TVALID, 
  onflag_3_TREADY, onflag_3_TDATA, amplitude_4_TVALID, amplitude_4_TREADY, 
  amplitude_4_TDATA, onflag_4_TVALID, onflag_4_TREADY, onflag_4_TDATA, amplitude_5_TVALID, 
  amplitude_5_TREADY, amplitude_5_TDATA, onflag_5_TVALID, onflag_5_TREADY, onflag_5_TDATA, 
  amplitude_6_TVALID, amplitude_6_TREADY, amplitude_6_TDATA, onflag_6_TVALID, 
  onflag_6_TREADY, onflag_6_TDATA, amplitude_7_TVALID, amplitude_7_TREADY, 
  amplitude_7_TDATA, onflag_7_TVALID, onflag_7_TREADY, onflag_7_TDATA, amplitude_8_TVALID, 
  amplitude_8_TREADY, amplitude_8_TDATA, onflag_8_TVALID, onflag_8_TREADY, onflag_8_TDATA, 
  amplitude_9_TVALID, amplitude_9_TREADY, amplitude_9_TDATA, onflag_9_TVALID, 
  onflag_9_TREADY, onflag_9_TDATA, amplitude_10_TVALID, amplitude_10_TREADY, 
  amplitude_10_TDATA, onflag_10_TVALID, onflag_10_TREADY, onflag_10_TDATA, 
  amplitude_11_TVALID, amplitude_11_TREADY, amplitude_11_TDATA, onflag_11_TVALID, 
  onflag_11_TREADY, onflag_11_TDATA, amplitude_0, onflag_0)
/* synthesis syn_black_box black_box_pad_pin="amplitude_0_ap_vld,onflag_0_ap_vld,ap_clk,ap_rst_n,ap_start,ap_done,ap_idle,ap_ready,FIFO_0_TVALID,FIFO_0_TREADY,FIFO_0_TDATA[15:0],FIFO_1_TVALID,FIFO_1_TREADY,FIFO_1_TDATA[15:0],FIFO_2_TVALID,FIFO_2_TREADY,FIFO_2_TDATA[15:0],FIFO_3_TVALID,FIFO_3_TREADY,FIFO_3_TDATA[15:0],FIFO_4_TVALID,FIFO_4_TREADY,FIFO_4_TDATA[15:0],FIFO_5_TVALID,FIFO_5_TREADY,FIFO_5_TDATA[15:0],FIFO_6_TVALID,FIFO_6_TREADY,FIFO_6_TDATA[15:0],FIFO_7_TVALID,FIFO_7_TREADY,FIFO_7_TDATA[15:0],FIFO_8_TVALID,FIFO_8_TREADY,FIFO_8_TDATA[15:0],FIFO_9_TVALID,FIFO_9_TREADY,FIFO_9_TDATA[15:0],FIFO_10_TVALID,FIFO_10_TREADY,FIFO_10_TDATA[15:0],FIFO_11_TVALID,FIFO_11_TREADY,FIFO_11_TDATA[15:0],amplitude_1_TVALID,amplitude_1_TREADY,amplitude_1_TDATA[23:0],onflag_1_TVALID,onflag_1_TREADY,onflag_1_TDATA[7:0],amplitude_2_TVALID,amplitude_2_TREADY,amplitude_2_TDATA[23:0],onflag_2_TVALID,onflag_2_TREADY,onflag_2_TDATA[7:0],amplitude_3_TVALID,amplitude_3_TREADY,amplitude_3_TDATA[23:0],onflag_3_TVALID,onflag_3_TREADY,onflag_3_TDATA[7:0],amplitude_4_TVALID,amplitude_4_TREADY,amplitude_4_TDATA[23:0],onflag_4_TVALID,onflag_4_TREADY,onflag_4_TDATA[7:0],amplitude_5_TVALID,amplitude_5_TREADY,amplitude_5_TDATA[23:0],onflag_5_TVALID,onflag_5_TREADY,onflag_5_TDATA[7:0],amplitude_6_TVALID,amplitude_6_TREADY,amplitude_6_TDATA[23:0],onflag_6_TVALID,onflag_6_TREADY,onflag_6_TDATA[7:0],amplitude_7_TVALID,amplitude_7_TREADY,amplitude_7_TDATA[23:0],onflag_7_TVALID,onflag_7_TREADY,onflag_7_TDATA[7:0],amplitude_8_TVALID,amplitude_8_TREADY,amplitude_8_TDATA[23:0],onflag_8_TVALID,onflag_8_TREADY,onflag_8_TDATA[7:0],amplitude_9_TVALID,amplitude_9_TREADY,amplitude_9_TDATA[23:0],onflag_9_TVALID,onflag_9_TREADY,onflag_9_TDATA[7:0],amplitude_10_TVALID,amplitude_10_TREADY,amplitude_10_TDATA[23:0],onflag_10_TVALID,onflag_10_TREADY,onflag_10_TDATA[7:0],amplitude_11_TVALID,amplitude_11_TREADY,amplitude_11_TDATA[23:0],onflag_11_TVALID,onflag_11_TREADY,onflag_11_TDATA[7:0],amplitude_0[16:0],onflag_0[0:0]" */;
  output amplitude_0_ap_vld;
  output onflag_0_ap_vld;
  input ap_clk;
  input ap_rst_n;
  input ap_start;
  output ap_done;
  output ap_idle;
  output ap_ready;
  input FIFO_0_TVALID;
  output FIFO_0_TREADY;
  input [15:0]FIFO_0_TDATA;
  input FIFO_1_TVALID;
  output FIFO_1_TREADY;
  input [15:0]FIFO_1_TDATA;
  input FIFO_2_TVALID;
  output FIFO_2_TREADY;
  input [15:0]FIFO_2_TDATA;
  input FIFO_3_TVALID;
  output FIFO_3_TREADY;
  input [15:0]FIFO_3_TDATA;
  input FIFO_4_TVALID;
  output FIFO_4_TREADY;
  input [15:0]FIFO_4_TDATA;
  input FIFO_5_TVALID;
  output FIFO_5_TREADY;
  input [15:0]FIFO_5_TDATA;
  input FIFO_6_TVALID;
  output FIFO_6_TREADY;
  input [15:0]FIFO_6_TDATA;
  input FIFO_7_TVALID;
  output FIFO_7_TREADY;
  input [15:0]FIFO_7_TDATA;
  input FIFO_8_TVALID;
  output FIFO_8_TREADY;
  input [15:0]FIFO_8_TDATA;
  input FIFO_9_TVALID;
  output FIFO_9_TREADY;
  input [15:0]FIFO_9_TDATA;
  input FIFO_10_TVALID;
  output FIFO_10_TREADY;
  input [15:0]FIFO_10_TDATA;
  input FIFO_11_TVALID;
  output FIFO_11_TREADY;
  input [15:0]FIFO_11_TDATA;
  output amplitude_1_TVALID;
  input amplitude_1_TREADY;
  output [23:0]amplitude_1_TDATA;
  output onflag_1_TVALID;
  input onflag_1_TREADY;
  output [7:0]onflag_1_TDATA;
  output amplitude_2_TVALID;
  input amplitude_2_TREADY;
  output [23:0]amplitude_2_TDATA;
  output onflag_2_TVALID;
  input onflag_2_TREADY;
  output [7:0]onflag_2_TDATA;
  output amplitude_3_TVALID;
  input amplitude_3_TREADY;
  output [23:0]amplitude_3_TDATA;
  output onflag_3_TVALID;
  input onflag_3_TREADY;
  output [7:0]onflag_3_TDATA;
  output amplitude_4_TVALID;
  input amplitude_4_TREADY;
  output [23:0]amplitude_4_TDATA;
  output onflag_4_TVALID;
  input onflag_4_TREADY;
  output [7:0]onflag_4_TDATA;
  output amplitude_5_TVALID;
  input amplitude_5_TREADY;
  output [23:0]amplitude_5_TDATA;
  output onflag_5_TVALID;
  input onflag_5_TREADY;
  output [7:0]onflag_5_TDATA;
  output amplitude_6_TVALID;
  input amplitude_6_TREADY;
  output [23:0]amplitude_6_TDATA;
  output onflag_6_TVALID;
  input onflag_6_TREADY;
  output [7:0]onflag_6_TDATA;
  output amplitude_7_TVALID;
  input amplitude_7_TREADY;
  output [23:0]amplitude_7_TDATA;
  output onflag_7_TVALID;
  input onflag_7_TREADY;
  output [7:0]onflag_7_TDATA;
  output amplitude_8_TVALID;
  input amplitude_8_TREADY;
  output [23:0]amplitude_8_TDATA;
  output onflag_8_TVALID;
  input onflag_8_TREADY;
  output [7:0]onflag_8_TDATA;
  output amplitude_9_TVALID;
  input amplitude_9_TREADY;
  output [23:0]amplitude_9_TDATA;
  output onflag_9_TVALID;
  input onflag_9_TREADY;
  output [7:0]onflag_9_TDATA;
  output amplitude_10_TVALID;
  input amplitude_10_TREADY;
  output [23:0]amplitude_10_TDATA;
  output onflag_10_TVALID;
  input onflag_10_TREADY;
  output [7:0]onflag_10_TDATA;
  output amplitude_11_TVALID;
  input amplitude_11_TREADY;
  output [23:0]amplitude_11_TDATA;
  output onflag_11_TVALID;
  input onflag_11_TREADY;
  output [7:0]onflag_11_TDATA;
  output [16:0]amplitude_0;
  output [0:0]onflag_0;
endmodule
