// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Sun Apr 28 22:35:25 2024
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
module bd_0_hls_inst_0(ap_clk, ap_rst, oBus_i, oBus_o, iBus)
/* synthesis syn_black_box black_box_pad_pin="ap_clk,ap_rst,oBus_i[286:0],oBus_o[286:0],iBus[238:0]" */;
  input ap_clk;
  input ap_rst;
  input [286:0]oBus_i;
  output [286:0]oBus_o;
  input [238:0]iBus;
endmodule
