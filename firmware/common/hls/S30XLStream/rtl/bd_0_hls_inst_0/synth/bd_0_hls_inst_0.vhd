-- (c) Copyright 1995-2024 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: xilinx.com:hls:hitproducerStream_hw:1.0
-- IP Revision: 2113539192

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY bd_0_hls_inst_0 IS
  PORT (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    timestamp_in : IN STD_LOGIC_VECTOR(69 DOWNTO 0);
    timestamp_out : OUT STD_LOGIC_VECTOR(69 DOWNTO 0);
    dataReady_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    dataReady_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    FIFO_0 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_1 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_2 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_3 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_4 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_5 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_6 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_7 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_8 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_9 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_10 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    FIFO_11 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    onflag_0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_4 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_6 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_7 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_8 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_9 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_10 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    onflag_11 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    amplitude_0 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_1 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_2 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_3 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_4 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_5 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_6 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_7 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_8 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_9 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_10 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
    amplitude_11 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
  );
END bd_0_hls_inst_0;

ARCHITECTURE bd_0_hls_inst_0_arch OF bd_0_hls_inst_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "yes";
  COMPONENT hitproducerStream_hw IS
    PORT (
      ap_clk : IN STD_LOGIC;
      ap_rst : IN STD_LOGIC;
      timestamp_in : IN STD_LOGIC_VECTOR(69 DOWNTO 0);
      timestamp_out : OUT STD_LOGIC_VECTOR(69 DOWNTO 0);
      dataReady_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      dataReady_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      FIFO_0 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_1 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_2 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_3 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_4 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_5 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_6 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_7 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_8 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_9 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_10 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      FIFO_11 : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
      onflag_0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_4 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_6 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_7 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_8 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_9 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_10 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      onflag_11 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      amplitude_0 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_1 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_2 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_3 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_4 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_5 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_6 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_7 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_8 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_9 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_10 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0);
      amplitude_11 : OUT STD_LOGIC_VECTOR(16 DOWNTO 0)
    );
  END COMPONENT hitproducerStream_hw;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "hitproducerStream_hw,Vivado 2022.2";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF bd_0_hls_inst_0_arch : ARCHITECTURE IS "bd_0_hls_inst_0,hitproducerStream_hw,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "bd_0_hls_inst_0,hitproducerStream_hw,{x_ipProduct=Vivado 2022.2,x_ipVendor=xilinx.com,x_ipLibrary=hls,x_ipName=hitproducerStream_hw,x_ipVersion=1.0,x_ipCoreRevision=2113539192,x_ipLanguage=VHDL,x_ipSimLanguage=MIXED}";
  ATTRIBUTE SDX_KERNEL : STRING;
  ATTRIBUTE SDX_KERNEL OF hitproducerStream_hw: COMPONENT IS "true";
  ATTRIBUTE SDX_KERNEL_TYPE : STRING;
  ATTRIBUTE SDX_KERNEL_TYPE OF hitproducerStream_hw: COMPONENT IS "hls";
  ATTRIBUTE SDX_KERNEL_SYNTH_INST : STRING;
  ATTRIBUTE SDX_KERNEL_SYNTH_INST OF hitproducerStream_hw: COMPONENT IS "U0";
  ATTRIBUTE IP_DEFINITION_SOURCE : STRING;
  ATTRIBUTE IP_DEFINITION_SOURCE OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "HLS";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_0: SIGNAL IS "XIL_INTERFACENAME FIFO_0, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_0: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_0 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_1: SIGNAL IS "XIL_INTERFACENAME FIFO_1, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_1: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_1 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_10: SIGNAL IS "XIL_INTERFACENAME FIFO_10, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_10: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_10 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_11: SIGNAL IS "XIL_INTERFACENAME FIFO_11, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_11: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_11 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_2: SIGNAL IS "XIL_INTERFACENAME FIFO_2, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_2: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_2 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_3: SIGNAL IS "XIL_INTERFACENAME FIFO_3, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_3: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_3 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_4: SIGNAL IS "XIL_INTERFACENAME FIFO_4, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_4: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_4 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_5: SIGNAL IS "XIL_INTERFACENAME FIFO_5, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_5: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_5 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_6: SIGNAL IS "XIL_INTERFACENAME FIFO_6, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_6: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_6 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_7: SIGNAL IS "XIL_INTERFACENAME FIFO_7, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_7: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_7 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_8: SIGNAL IS "XIL_INTERFACENAME FIFO_8, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_8: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_8 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF FIFO_9: SIGNAL IS "XIL_INTERFACENAME FIFO_9, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF FIFO_9: SIGNAL IS "xilinx.com:signal:data:1.0 FIFO_9 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_0: SIGNAL IS "XIL_INTERFACENAME amplitude_0, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_0: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_0 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_1: SIGNAL IS "XIL_INTERFACENAME amplitude_1, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_1: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_1 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_10: SIGNAL IS "XIL_INTERFACENAME amplitude_10, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_10: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_10 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_11: SIGNAL IS "XIL_INTERFACENAME amplitude_11, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_11: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_11 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_2: SIGNAL IS "XIL_INTERFACENAME amplitude_2, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_2: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_2 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_3: SIGNAL IS "XIL_INTERFACENAME amplitude_3, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_3: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_3 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_4: SIGNAL IS "XIL_INTERFACENAME amplitude_4, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_4: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_4 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_5: SIGNAL IS "XIL_INTERFACENAME amplitude_5, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_5: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_5 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_6: SIGNAL IS "XIL_INTERFACENAME amplitude_6, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_6: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_6 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_7: SIGNAL IS "XIL_INTERFACENAME amplitude_7, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_7: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_7 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_8: SIGNAL IS "XIL_INTERFACENAME amplitude_8, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_8: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_8 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF amplitude_9: SIGNAL IS "XIL_INTERFACENAME amplitude_9, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF amplitude_9: SIGNAL IS "xilinx.com:signal:data:1.0 amplitude_9 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF ap_clk: SIGNAL IS "XIL_INTERFACENAME ap_clk, ASSOCIATED_RESET ap_rst, FREQ_HZ 185000000.0, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF ap_clk: SIGNAL IS "xilinx.com:signal:clock:1.0 ap_clk CLK";
  ATTRIBUTE X_INTERFACE_PARAMETER OF ap_rst: SIGNAL IS "XIL_INTERFACENAME ap_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF ap_rst: SIGNAL IS "xilinx.com:signal:reset:1.0 ap_rst RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF dataReady_in: SIGNAL IS "XIL_INTERFACENAME dataReady_in, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF dataReady_in: SIGNAL IS "xilinx.com:signal:data:1.0 dataReady_in DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF dataReady_out: SIGNAL IS "XIL_INTERFACENAME dataReady_out, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF dataReady_out: SIGNAL IS "xilinx.com:signal:data:1.0 dataReady_out DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_0: SIGNAL IS "XIL_INTERFACENAME onflag_0, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_0: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_0 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_1: SIGNAL IS "XIL_INTERFACENAME onflag_1, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_1: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_1 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_10: SIGNAL IS "XIL_INTERFACENAME onflag_10, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_10: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_10 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_11: SIGNAL IS "XIL_INTERFACENAME onflag_11, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_11: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_11 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_2: SIGNAL IS "XIL_INTERFACENAME onflag_2, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_2: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_2 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_3: SIGNAL IS "XIL_INTERFACENAME onflag_3, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_3: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_3 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_4: SIGNAL IS "XIL_INTERFACENAME onflag_4, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_4: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_4 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_5: SIGNAL IS "XIL_INTERFACENAME onflag_5, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_5: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_5 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_6: SIGNAL IS "XIL_INTERFACENAME onflag_6, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_6: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_6 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_7: SIGNAL IS "XIL_INTERFACENAME onflag_7, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_7: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_7 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_8: SIGNAL IS "XIL_INTERFACENAME onflag_8, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_8: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_8 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF onflag_9: SIGNAL IS "XIL_INTERFACENAME onflag_9, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF onflag_9: SIGNAL IS "xilinx.com:signal:data:1.0 onflag_9 DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF timestamp_in: SIGNAL IS "XIL_INTERFACENAME timestamp_in, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF timestamp_in: SIGNAL IS "xilinx.com:signal:data:1.0 timestamp_in DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF timestamp_out: SIGNAL IS "XIL_INTERFACENAME timestamp_out, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF timestamp_out: SIGNAL IS "xilinx.com:signal:data:1.0 timestamp_out DATA";
BEGIN
  U0 : hitproducerStream_hw
    PORT MAP (
      ap_clk => ap_clk,
      ap_rst => ap_rst,
      timestamp_in => timestamp_in,
      timestamp_out => timestamp_out,
      dataReady_in => dataReady_in,
      dataReady_out => dataReady_out,
      FIFO_0 => FIFO_0,
      FIFO_1 => FIFO_1,
      FIFO_2 => FIFO_2,
      FIFO_3 => FIFO_3,
      FIFO_4 => FIFO_4,
      FIFO_5 => FIFO_5,
      FIFO_6 => FIFO_6,
      FIFO_7 => FIFO_7,
      FIFO_8 => FIFO_8,
      FIFO_9 => FIFO_9,
      FIFO_10 => FIFO_10,
      FIFO_11 => FIFO_11,
      onflag_0 => onflag_0,
      onflag_1 => onflag_1,
      onflag_2 => onflag_2,
      onflag_3 => onflag_3,
      onflag_4 => onflag_4,
      onflag_5 => onflag_5,
      onflag_6 => onflag_6,
      onflag_7 => onflag_7,
      onflag_8 => onflag_8,
      onflag_9 => onflag_9,
      onflag_10 => onflag_10,
      onflag_11 => onflag_11,
      amplitude_0 => amplitude_0,
      amplitude_1 => amplitude_1,
      amplitude_2 => amplitude_2,
      amplitude_3 => amplitude_3,
      amplitude_4 => amplitude_4,
      amplitude_5 => amplitude_5,
      amplitude_6 => amplitude_6,
      amplitude_7 => amplitude_7,
      amplitude_8 => amplitude_8,
      amplitude_9 => amplitude_9,
      amplitude_10 => amplitude_10,
      amplitude_11 => amplitude_11
    );
END bd_0_hls_inst_0_arch;
