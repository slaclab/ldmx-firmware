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
// IP Revision: 2113527336

`timescale 1ns/1ps

(* IP_DEFINITION_SOURCE = "HLS" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module bd_0_hls_inst_0 (
  amplitude_0_ap_vld,
  onflag_0_ap_vld,
  ap_clk,
  ap_rst_n,
  ap_start,
  ap_done,
  ap_idle,
  ap_ready,
  FIFO_0_TVALID,
  FIFO_0_TREADY,
  FIFO_0_TDATA,
  FIFO_1_TVALID,
  FIFO_1_TREADY,
  FIFO_1_TDATA,
  FIFO_2_TVALID,
  FIFO_2_TREADY,
  FIFO_2_TDATA,
  FIFO_3_TVALID,
  FIFO_3_TREADY,
  FIFO_3_TDATA,
  FIFO_4_TVALID,
  FIFO_4_TREADY,
  FIFO_4_TDATA,
  FIFO_5_TVALID,
  FIFO_5_TREADY,
  FIFO_5_TDATA,
  FIFO_6_TVALID,
  FIFO_6_TREADY,
  FIFO_6_TDATA,
  FIFO_7_TVALID,
  FIFO_7_TREADY,
  FIFO_7_TDATA,
  FIFO_8_TVALID,
  FIFO_8_TREADY,
  FIFO_8_TDATA,
  FIFO_9_TVALID,
  FIFO_9_TREADY,
  FIFO_9_TDATA,
  FIFO_10_TVALID,
  FIFO_10_TREADY,
  FIFO_10_TDATA,
  FIFO_11_TVALID,
  FIFO_11_TREADY,
  FIFO_11_TDATA,
  amplitude_1_TVALID,
  amplitude_1_TREADY,
  amplitude_1_TDATA,
  onflag_1_TVALID,
  onflag_1_TREADY,
  onflag_1_TDATA,
  amplitude_2_TVALID,
  amplitude_2_TREADY,
  amplitude_2_TDATA,
  onflag_2_TVALID,
  onflag_2_TREADY,
  onflag_2_TDATA,
  amplitude_3_TVALID,
  amplitude_3_TREADY,
  amplitude_3_TDATA,
  onflag_3_TVALID,
  onflag_3_TREADY,
  onflag_3_TDATA,
  amplitude_4_TVALID,
  amplitude_4_TREADY,
  amplitude_4_TDATA,
  onflag_4_TVALID,
  onflag_4_TREADY,
  onflag_4_TDATA,
  amplitude_5_TVALID,
  amplitude_5_TREADY,
  amplitude_5_TDATA,
  onflag_5_TVALID,
  onflag_5_TREADY,
  onflag_5_TDATA,
  amplitude_6_TVALID,
  amplitude_6_TREADY,
  amplitude_6_TDATA,
  onflag_6_TVALID,
  onflag_6_TREADY,
  onflag_6_TDATA,
  amplitude_7_TVALID,
  amplitude_7_TREADY,
  amplitude_7_TDATA,
  onflag_7_TVALID,
  onflag_7_TREADY,
  onflag_7_TDATA,
  amplitude_8_TVALID,
  amplitude_8_TREADY,
  amplitude_8_TDATA,
  onflag_8_TVALID,
  onflag_8_TREADY,
  onflag_8_TDATA,
  amplitude_9_TVALID,
  amplitude_9_TREADY,
  amplitude_9_TDATA,
  onflag_9_TVALID,
  onflag_9_TREADY,
  onflag_9_TDATA,
  amplitude_10_TVALID,
  amplitude_10_TREADY,
  amplitude_10_TDATA,
  onflag_10_TVALID,
  onflag_10_TREADY,
  onflag_10_TDATA,
  amplitude_11_TVALID,
  amplitude_11_TREADY,
  amplitude_11_TDATA,
  onflag_11_TVALID,
  onflag_11_TREADY,
  onflag_11_TDATA,
  amplitude_0,
  onflag_0
);

output wire amplitude_0_ap_vld;
output wire onflag_0_ap_vld;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ap_clk, ASSOCIATED_BUSIF FIFO_0:FIFO_1:FIFO_2:FIFO_3:FIFO_4:FIFO_5:FIFO_6:FIFO_7:FIFO_8:FIFO_9:FIFO_10:FIFO_11:amplitude_1:onflag_1:amplitude_2:onflag_2:amplitude_3:onflag_3:amplitude_4:onflag_4:amplitude_5:onflag_5:amplitude_6:onflag_6:amplitude_7:onflag_7:amplitude_8:onflag_8:amplitude_9:onflag_9:amplitude_10:onflag_10:amplitude_11:onflag_11, ASSOCIATED_RESET ap_rst_n, FREQ_HZ 40000000.0, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 ap_clk CLK" *)
input wire ap_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME ap_rst_n, POLARITY ACTIVE_LOW, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 ap_rst_n RST" *)
input wire ap_rst_n;
(* X_INTERFACE_INFO = "xilinx.com:interface:acc_handshake:1.0 ap_ctrl start" *)
input wire ap_start;
(* X_INTERFACE_INFO = "xilinx.com:interface:acc_handshake:1.0 ap_ctrl done" *)
output wire ap_done;
(* X_INTERFACE_INFO = "xilinx.com:interface:acc_handshake:1.0 ap_ctrl idle" *)
output wire ap_idle;
(* X_INTERFACE_INFO = "xilinx.com:interface:acc_handshake:1.0 ap_ctrl ready" *)
output wire ap_ready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_0 TVALID" *)
input wire FIFO_0_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_0 TREADY" *)
output wire FIFO_0_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_0, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_0 TDATA" *)
input wire [15 : 0] FIFO_0_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_1 TVALID" *)
input wire FIFO_1_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_1 TREADY" *)
output wire FIFO_1_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_1, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_1 TDATA" *)
input wire [15 : 0] FIFO_1_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_2 TVALID" *)
input wire FIFO_2_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_2 TREADY" *)
output wire FIFO_2_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_2, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_2 TDATA" *)
input wire [15 : 0] FIFO_2_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_3 TVALID" *)
input wire FIFO_3_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_3 TREADY" *)
output wire FIFO_3_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_3, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_3 TDATA" *)
input wire [15 : 0] FIFO_3_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_4 TVALID" *)
input wire FIFO_4_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_4 TREADY" *)
output wire FIFO_4_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_4, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_4 TDATA" *)
input wire [15 : 0] FIFO_4_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_5 TVALID" *)
input wire FIFO_5_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_5 TREADY" *)
output wire FIFO_5_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_5, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_5 TDATA" *)
input wire [15 : 0] FIFO_5_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_6 TVALID" *)
input wire FIFO_6_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_6 TREADY" *)
output wire FIFO_6_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_6, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_6 TDATA" *)
input wire [15 : 0] FIFO_6_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_7 TVALID" *)
input wire FIFO_7_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_7 TREADY" *)
output wire FIFO_7_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_7, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_7 TDATA" *)
input wire [15 : 0] FIFO_7_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_8 TVALID" *)
input wire FIFO_8_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_8 TREADY" *)
output wire FIFO_8_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_8, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_8 TDATA" *)
input wire [15 : 0] FIFO_8_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_9 TVALID" *)
input wire FIFO_9_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_9 TREADY" *)
output wire FIFO_9_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_9, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_9 TDATA" *)
input wire [15 : 0] FIFO_9_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_10 TVALID" *)
input wire FIFO_10_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_10 TREADY" *)
output wire FIFO_10_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_10, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_10 TDATA" *)
input wire [15 : 0] FIFO_10_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_11 TVALID" *)
input wire FIFO_11_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_11 TREADY" *)
output wire FIFO_11_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME FIFO_11, TDATA_NUM_BYTES 2, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 FIFO_11 TDATA" *)
input wire [15 : 0] FIFO_11_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_1 TVALID" *)
output wire amplitude_1_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_1 TREADY" *)
input wire amplitude_1_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_1, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_1 TDATA" *)
output wire [23 : 0] amplitude_1_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_1 TVALID" *)
output wire onflag_1_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_1 TREADY" *)
input wire onflag_1_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_1, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_1 TDATA" *)
output wire [7 : 0] onflag_1_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_2 TVALID" *)
output wire amplitude_2_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_2 TREADY" *)
input wire amplitude_2_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_2, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_2 TDATA" *)
output wire [23 : 0] amplitude_2_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_2 TVALID" *)
output wire onflag_2_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_2 TREADY" *)
input wire onflag_2_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_2, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_2 TDATA" *)
output wire [7 : 0] onflag_2_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_3 TVALID" *)
output wire amplitude_3_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_3 TREADY" *)
input wire amplitude_3_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_3, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_3 TDATA" *)
output wire [23 : 0] amplitude_3_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_3 TVALID" *)
output wire onflag_3_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_3 TREADY" *)
input wire onflag_3_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_3, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_3 TDATA" *)
output wire [7 : 0] onflag_3_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_4 TVALID" *)
output wire amplitude_4_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_4 TREADY" *)
input wire amplitude_4_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_4, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_4 TDATA" *)
output wire [23 : 0] amplitude_4_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_4 TVALID" *)
output wire onflag_4_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_4 TREADY" *)
input wire onflag_4_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_4, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_4 TDATA" *)
output wire [7 : 0] onflag_4_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_5 TVALID" *)
output wire amplitude_5_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_5 TREADY" *)
input wire amplitude_5_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_5, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_5 TDATA" *)
output wire [23 : 0] amplitude_5_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_5 TVALID" *)
output wire onflag_5_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_5 TREADY" *)
input wire onflag_5_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_5, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_5 TDATA" *)
output wire [7 : 0] onflag_5_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_6 TVALID" *)
output wire amplitude_6_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_6 TREADY" *)
input wire amplitude_6_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_6, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_6 TDATA" *)
output wire [23 : 0] amplitude_6_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_6 TVALID" *)
output wire onflag_6_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_6 TREADY" *)
input wire onflag_6_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_6, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_6 TDATA" *)
output wire [7 : 0] onflag_6_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_7 TVALID" *)
output wire amplitude_7_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_7 TREADY" *)
input wire amplitude_7_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_7, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_7 TDATA" *)
output wire [23 : 0] amplitude_7_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_7 TVALID" *)
output wire onflag_7_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_7 TREADY" *)
input wire onflag_7_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_7, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_7 TDATA" *)
output wire [7 : 0] onflag_7_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_8 TVALID" *)
output wire amplitude_8_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_8 TREADY" *)
input wire amplitude_8_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_8, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_8 TDATA" *)
output wire [23 : 0] amplitude_8_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_8 TVALID" *)
output wire onflag_8_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_8 TREADY" *)
input wire onflag_8_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_8, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_8 TDATA" *)
output wire [7 : 0] onflag_8_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_9 TVALID" *)
output wire amplitude_9_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_9 TREADY" *)
input wire amplitude_9_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_9, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_9 TDATA" *)
output wire [23 : 0] amplitude_9_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_9 TVALID" *)
output wire onflag_9_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_9 TREADY" *)
input wire onflag_9_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_9, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_9 TDATA" *)
output wire [7 : 0] onflag_9_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_10 TVALID" *)
output wire amplitude_10_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_10 TREADY" *)
input wire amplitude_10_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_10, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_10 TDATA" *)
output wire [23 : 0] amplitude_10_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_10 TVALID" *)
output wire onflag_10_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_10 TREADY" *)
input wire onflag_10_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_10, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_10 TDATA" *)
output wire [7 : 0] onflag_10_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_11 TVALID" *)
output wire amplitude_11_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_11 TREADY" *)
input wire amplitude_11_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_11, TDATA_NUM_BYTES 3, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 amplitude_11 TDATA" *)
output wire [23 : 0] amplitude_11_TDATA;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_11 TVALID" *)
output wire onflag_11_TVALID;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_11 TREADY" *)
input wire onflag_11_TREADY;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_11, TDATA_NUM_BYTES 1, TUSER_WIDTH 0, TDEST_WIDTH 0, TID_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 0, HAS_TLAST 0, FREQ_HZ 40000000.0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 onflag_11 TDATA" *)
output wire [7 : 0] onflag_11_TDATA;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME amplitude_0, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 amplitude_0 DATA" *)
output wire [16 : 0] amplitude_0;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME onflag_0, LAYERED_METADATA undef" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 onflag_0 DATA" *)
output wire [0 : 0] onflag_0;

(* SDX_KERNEL = "true" *)
(* SDX_KERNEL_TYPE = "hls" *)
(* SDX_KERNEL_SIM_INST = "" *)
  hitproducerStream_hw inst (
    .amplitude_0_ap_vld(amplitude_0_ap_vld),
    .onflag_0_ap_vld(onflag_0_ap_vld),
    .ap_clk(ap_clk),
    .ap_rst_n(ap_rst_n),
    .ap_start(ap_start),
    .ap_done(ap_done),
    .ap_idle(ap_idle),
    .ap_ready(ap_ready),
    .FIFO_0_TVALID(FIFO_0_TVALID),
    .FIFO_0_TREADY(FIFO_0_TREADY),
    .FIFO_0_TDATA(FIFO_0_TDATA),
    .FIFO_1_TVALID(FIFO_1_TVALID),
    .FIFO_1_TREADY(FIFO_1_TREADY),
    .FIFO_1_TDATA(FIFO_1_TDATA),
    .FIFO_2_TVALID(FIFO_2_TVALID),
    .FIFO_2_TREADY(FIFO_2_TREADY),
    .FIFO_2_TDATA(FIFO_2_TDATA),
    .FIFO_3_TVALID(FIFO_3_TVALID),
    .FIFO_3_TREADY(FIFO_3_TREADY),
    .FIFO_3_TDATA(FIFO_3_TDATA),
    .FIFO_4_TVALID(FIFO_4_TVALID),
    .FIFO_4_TREADY(FIFO_4_TREADY),
    .FIFO_4_TDATA(FIFO_4_TDATA),
    .FIFO_5_TVALID(FIFO_5_TVALID),
    .FIFO_5_TREADY(FIFO_5_TREADY),
    .FIFO_5_TDATA(FIFO_5_TDATA),
    .FIFO_6_TVALID(FIFO_6_TVALID),
    .FIFO_6_TREADY(FIFO_6_TREADY),
    .FIFO_6_TDATA(FIFO_6_TDATA),
    .FIFO_7_TVALID(FIFO_7_TVALID),
    .FIFO_7_TREADY(FIFO_7_TREADY),
    .FIFO_7_TDATA(FIFO_7_TDATA),
    .FIFO_8_TVALID(FIFO_8_TVALID),
    .FIFO_8_TREADY(FIFO_8_TREADY),
    .FIFO_8_TDATA(FIFO_8_TDATA),
    .FIFO_9_TVALID(FIFO_9_TVALID),
    .FIFO_9_TREADY(FIFO_9_TREADY),
    .FIFO_9_TDATA(FIFO_9_TDATA),
    .FIFO_10_TVALID(FIFO_10_TVALID),
    .FIFO_10_TREADY(FIFO_10_TREADY),
    .FIFO_10_TDATA(FIFO_10_TDATA),
    .FIFO_11_TVALID(FIFO_11_TVALID),
    .FIFO_11_TREADY(FIFO_11_TREADY),
    .FIFO_11_TDATA(FIFO_11_TDATA),
    .amplitude_1_TVALID(amplitude_1_TVALID),
    .amplitude_1_TREADY(amplitude_1_TREADY),
    .amplitude_1_TDATA(amplitude_1_TDATA),
    .onflag_1_TVALID(onflag_1_TVALID),
    .onflag_1_TREADY(onflag_1_TREADY),
    .onflag_1_TDATA(onflag_1_TDATA),
    .amplitude_2_TVALID(amplitude_2_TVALID),
    .amplitude_2_TREADY(amplitude_2_TREADY),
    .amplitude_2_TDATA(amplitude_2_TDATA),
    .onflag_2_TVALID(onflag_2_TVALID),
    .onflag_2_TREADY(onflag_2_TREADY),
    .onflag_2_TDATA(onflag_2_TDATA),
    .amplitude_3_TVALID(amplitude_3_TVALID),
    .amplitude_3_TREADY(amplitude_3_TREADY),
    .amplitude_3_TDATA(amplitude_3_TDATA),
    .onflag_3_TVALID(onflag_3_TVALID),
    .onflag_3_TREADY(onflag_3_TREADY),
    .onflag_3_TDATA(onflag_3_TDATA),
    .amplitude_4_TVALID(amplitude_4_TVALID),
    .amplitude_4_TREADY(amplitude_4_TREADY),
    .amplitude_4_TDATA(amplitude_4_TDATA),
    .onflag_4_TVALID(onflag_4_TVALID),
    .onflag_4_TREADY(onflag_4_TREADY),
    .onflag_4_TDATA(onflag_4_TDATA),
    .amplitude_5_TVALID(amplitude_5_TVALID),
    .amplitude_5_TREADY(amplitude_5_TREADY),
    .amplitude_5_TDATA(amplitude_5_TDATA),
    .onflag_5_TVALID(onflag_5_TVALID),
    .onflag_5_TREADY(onflag_5_TREADY),
    .onflag_5_TDATA(onflag_5_TDATA),
    .amplitude_6_TVALID(amplitude_6_TVALID),
    .amplitude_6_TREADY(amplitude_6_TREADY),
    .amplitude_6_TDATA(amplitude_6_TDATA),
    .onflag_6_TVALID(onflag_6_TVALID),
    .onflag_6_TREADY(onflag_6_TREADY),
    .onflag_6_TDATA(onflag_6_TDATA),
    .amplitude_7_TVALID(amplitude_7_TVALID),
    .amplitude_7_TREADY(amplitude_7_TREADY),
    .amplitude_7_TDATA(amplitude_7_TDATA),
    .onflag_7_TVALID(onflag_7_TVALID),
    .onflag_7_TREADY(onflag_7_TREADY),
    .onflag_7_TDATA(onflag_7_TDATA),
    .amplitude_8_TVALID(amplitude_8_TVALID),
    .amplitude_8_TREADY(amplitude_8_TREADY),
    .amplitude_8_TDATA(amplitude_8_TDATA),
    .onflag_8_TVALID(onflag_8_TVALID),
    .onflag_8_TREADY(onflag_8_TREADY),
    .onflag_8_TDATA(onflag_8_TDATA),
    .amplitude_9_TVALID(amplitude_9_TVALID),
    .amplitude_9_TREADY(amplitude_9_TREADY),
    .amplitude_9_TDATA(amplitude_9_TDATA),
    .onflag_9_TVALID(onflag_9_TVALID),
    .onflag_9_TREADY(onflag_9_TREADY),
    .onflag_9_TDATA(onflag_9_TDATA),
    .amplitude_10_TVALID(amplitude_10_TVALID),
    .amplitude_10_TREADY(amplitude_10_TREADY),
    .amplitude_10_TDATA(amplitude_10_TDATA),
    .onflag_10_TVALID(onflag_10_TVALID),
    .onflag_10_TREADY(onflag_10_TREADY),
    .onflag_10_TDATA(onflag_10_TDATA),
    .amplitude_11_TVALID(amplitude_11_TVALID),
    .amplitude_11_TREADY(amplitude_11_TREADY),
    .amplitude_11_TDATA(amplitude_11_TDATA),
    .onflag_11_TVALID(onflag_11_TVALID),
    .onflag_11_TREADY(onflag_11_TREADY),
    .onflag_11_TDATA(onflag_11_TDATA),
    .amplitude_0(amplitude_0),
    .onflag_0(onflag_0)
  );
endmodule
