// (c) Copyright 1995-2024 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:hls:hitproducerStream_hw:1.0
// IP Revision: 2113538327

`timescale 1ns/1ps

(* IP_DEFINITION_SOURCE = "HLS" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module bd_0_hls_inst_0 (
  ap_clk,
  ap_rst,
  timestamp_in,
  timestamp_out,
  dataReady_in,
  dataReady_out,
  FIFO_0,
  FIFO_1,
  FIFO_2,
  FIFO_3,
  FIFO_4,
  FIFO_5,
  FIFO_6,
  FIFO_7,
  FIFO_8,
  FIFO_9,
  FIFO_10,
  FIFO_11,
  onflag_0,
  onflag_1,
  onflag_2,
  onflag_3,
  onflag_4,
  onflag_5,
  onflag_6,
  onflag_7,
  onflag_8,
  onflag_9,
  onflag_10,
  onflag_11,
  amplitude_0,
  amplitude_1,
  amplitude_2,
  amplitude_3,
  amplitude_4,
  amplitude_5,
  amplitude_6,
  amplitude_7,
  amplitude_8,
  amplitude_9,
  amplitude_10,
  amplitude_11
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ap_clk, ASSOCIATED_RESET ap_rst, FREQ_HZ 185000000.0, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
input wire ap_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ap_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst RST" *)
input wire ap_rst;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME timestamp_in, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 timestamp_in DATA" *)
input wire [69 : 0] timestamp_in;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME timestamp_out, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 timestamp_out DATA" *)
input wire [69 : 0] timestamp_out;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME dataReady_in, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 dataReady_in DATA" *)
input wire [0 : 0] dataReady_in;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME dataReady_out, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 dataReady_out DATA" *)
input wire [0 : 0] dataReady_out;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_0, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_0 DATA" *)
input wire [13 : 0] FIFO_0;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_1, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_1 DATA" *)
input wire [13 : 0] FIFO_1;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_2, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_2 DATA" *)
input wire [13 : 0] FIFO_2;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_3, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_3 DATA" *)
input wire [13 : 0] FIFO_3;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_4, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_4 DATA" *)
input wire [13 : 0] FIFO_4;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_5, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_5 DATA" *)
input wire [13 : 0] FIFO_5;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_6, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_6 DATA" *)
input wire [13 : 0] FIFO_6;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_7, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_7 DATA" *)
input wire [13 : 0] FIFO_7;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_8, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_8 DATA" *)
input wire [13 : 0] FIFO_8;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_9, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_9 DATA" *)
input wire [13 : 0] FIFO_9;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_10, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_10 DATA" *)
input wire [13 : 0] FIFO_10;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_11, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 FIFO_11 DATA" *)
input wire [13 : 0] FIFO_11;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_0, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_0 DATA" *)
output wire [0 : 0] onflag_0;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_1, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_1 DATA" *)
output wire [0 : 0] onflag_1;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_2, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_2 DATA" *)
output wire [0 : 0] onflag_2;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_3, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_3 DATA" *)
output wire [0 : 0] onflag_3;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_4, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_4 DATA" *)
output wire [0 : 0] onflag_4;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_5, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_5 DATA" *)
output wire [0 : 0] onflag_5;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_6, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_6 DATA" *)
output wire [0 : 0] onflag_6;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_7, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_7 DATA" *)
output wire [0 : 0] onflag_7;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_8, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_8 DATA" *)
output wire [0 : 0] onflag_8;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_9, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_9 DATA" *)
output wire [0 : 0] onflag_9;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_10, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_10 DATA" *)
output wire [0 : 0] onflag_10;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_11, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_11 DATA" *)
output wire [0 : 0] onflag_11;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_0, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_0 DATA" *)
output wire [16 : 0] amplitude_0;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_1, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_1 DATA" *)
output wire [16 : 0] amplitude_1;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_2, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_2 DATA" *)
output wire [16 : 0] amplitude_2;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_3, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_3 DATA" *)
output wire [16 : 0] amplitude_3;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_4, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_4 DATA" *)
output wire [16 : 0] amplitude_4;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_5, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_5 DATA" *)
output wire [16 : 0] amplitude_5;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_6, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_6 DATA" *)
output wire [16 : 0] amplitude_6;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_7, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_7 DATA" *)
output wire [16 : 0] amplitude_7;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_8, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_8 DATA" *)
output wire [16 : 0] amplitude_8;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_9, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_9 DATA" *)
output wire [16 : 0] amplitude_9;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_10, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_10 DATA" *)
output wire [16 : 0] amplitude_10;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_11, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_11 DATA" *)
output wire [16 : 0] amplitude_11;

(* SDX_KERNEL = "true" *)
(* SDX_KERNEL_TYPE = "hls" *)
(* SDX_KERNEL_SIM_INST = "" *)
  hitproducerStream_hw inst (
    .ap_clk(ap_clk),
    .ap_rst(ap_rst),
    .timestamp_in(timestamp_in),
    .timestamp_out(timestamp_out),
    .dataReady_in(dataReady_in),
    .dataReady_out(dataReady_out),
    .FIFO_0(FIFO_0),
    .FIFO_1(FIFO_1),
    .FIFO_2(FIFO_2),
    .FIFO_3(FIFO_3),
    .FIFO_4(FIFO_4),
    .FIFO_5(FIFO_5),
    .FIFO_6(FIFO_6),
    .FIFO_7(FIFO_7),
    .FIFO_8(FIFO_8),
    .FIFO_9(FIFO_9),
    .FIFO_10(FIFO_10),
    .FIFO_11(FIFO_11),
    .onflag_0(onflag_0),
    .onflag_1(onflag_1),
    .onflag_2(onflag_2),
    .onflag_3(onflag_3),
    .onflag_4(onflag_4),
    .onflag_5(onflag_5),
    .onflag_6(onflag_6),
    .onflag_7(onflag_7),
    .onflag_8(onflag_8),
    .onflag_9(onflag_9),
    .onflag_10(onflag_10),
    .onflag_11(onflag_11),
    .amplitude_0(amplitude_0),
    .amplitude_1(amplitude_1),
    .amplitude_2(amplitude_2),
    .amplitude_3(amplitude_3),
    .amplitude_4(amplitude_4),
    .amplitude_5(amplitude_5),
    .amplitude_6(amplitude_6),
    .amplitude_7(amplitude_7),
    .amplitude_8(amplitude_8),
    .amplitude_9(amplitude_9),
    .amplitude_10(amplitude_10),
    .amplitude_11(amplitude_11)
  );
endmodule
