// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Fri Apr 26 09:41:03 2024
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
module bd_0_hls_inst_0(dataReady_ap_vld, amplitude_0_ap_vld, 
  onflag_0_ap_vld, ap_clk, ap_rst, ap_start, ap_done, ap_idle, ap_ready, dataReady, FIFO_0, FIFO_1, 
  FIFO_2, FIFO_3, FIFO_4, FIFO_5, FIFO_6, FIFO_7, FIFO_8, FIFO_9, FIFO_10, FIFO_11, amplitude_0, 
  amplitude_1, amplitude_2, amplitude_3, amplitude_4, amplitude_5, amplitude_6, amplitude_7, 
  amplitude_8, amplitude_9, amplitude_10, amplitude_11, onflag_0, onflag_1, onflag_2, onflag_3, 
  onflag_4, onflag_5, onflag_6, onflag_7, onflag_8, onflag_9, onflag_10, onflag_11)
/* synthesis syn_black_box black_box_pad_pin="dataReady_ap_vld,amplitude_0_ap_vld,onflag_0_ap_vld,ap_clk,ap_rst,ap_start,ap_done,ap_idle,ap_ready,dataReady[0:0],FIFO_0[13:0],FIFO_1[13:0],FIFO_2[13:0],FIFO_3[13:0],FIFO_4[13:0],FIFO_5[13:0],FIFO_6[13:0],FIFO_7[13:0],FIFO_8[13:0],FIFO_9[13:0],FIFO_10[13:0],FIFO_11[13:0],amplitude_0[16:0],amplitude_1[16:0],amplitude_2[16:0],amplitude_3[16:0],amplitude_4[16:0],amplitude_5[16:0],amplitude_6[16:0],amplitude_7[16:0],amplitude_8[16:0],amplitude_9[16:0],amplitude_10[16:0],amplitude_11[16:0],onflag_0[0:0],onflag_1[0:0],onflag_2[0:0],onflag_3[0:0],onflag_4[0:0],onflag_5[0:0],onflag_6[0:0],onflag_7[0:0],onflag_8[0:0],onflag_9[0:0],onflag_10[0:0],onflag_11[0:0]" */;
  input dataReady_ap_vld;
  output amplitude_0_ap_vld;
  output onflag_0_ap_vld;
  input ap_clk;
  input ap_rst;
  input ap_start;
  output ap_done;
  output ap_idle;
  output ap_ready;
  input [0:0]dataReady;
  input [13:0]FIFO_0;
  input [13:0]FIFO_1;
  input [13:0]FIFO_2;
  input [13:0]FIFO_3;
  input [13:0]FIFO_4;
  input [13:0]FIFO_5;
  input [13:0]FIFO_6;
  input [13:0]FIFO_7;
  input [13:0]FIFO_8;
  input [13:0]FIFO_9;
  input [13:0]FIFO_10;
  input [13:0]FIFO_11;
  output [16:0]amplitude_0;
  output [16:0]amplitude_1;
  output [16:0]amplitude_2;
  output [16:0]amplitude_3;
  output [16:0]amplitude_4;
  output [16:0]amplitude_5;
  output [16:0]amplitude_6;
  output [16:0]amplitude_7;
  output [16:0]amplitude_8;
  output [16:0]amplitude_9;
  output [16:0]amplitude_10;
  output [16:0]amplitude_11;
  output [0:0]onflag_0;
  output [0:0]onflag_1;
  output [0:0]onflag_2;
  output [0:0]onflag_3;
  output [0:0]onflag_4;
  output [0:0]onflag_5;
  output [0:0]onflag_6;
  output [0:0]onflag_7;
  output [0:0]onflag_8;
  output [0:0]onflag_9;
  output [0:0]onflag_10;
  output [0:0]onflag_11;
endmodule
