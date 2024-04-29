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
-- IP Revision: 2113534771

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY bd_0_hls_inst_0 IS
  PORT (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    oBus_i : IN STD_LOGIC_VECTOR(286 DOWNTO 0);
    oBus_o : OUT STD_LOGIC_VECTOR(286 DOWNTO 0);
    iBus : IN STD_LOGIC_VECTOR(238 DOWNTO 0)
  );
END bd_0_hls_inst_0;

ARCHITECTURE bd_0_hls_inst_0_arch OF bd_0_hls_inst_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "yes";
  COMPONENT hitproducerStream_hw IS
    PORT (
      ap_clk : IN STD_LOGIC;
      ap_rst : IN STD_LOGIC;
      oBus_i : IN STD_LOGIC_VECTOR(286 DOWNTO 0);
      oBus_o : OUT STD_LOGIC_VECTOR(286 DOWNTO 0);
      iBus : IN STD_LOGIC_VECTOR(238 DOWNTO 0)
    );
  END COMPONENT hitproducerStream_hw;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "hitproducerStream_hw,Vivado 2022.2";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF bd_0_hls_inst_0_arch : ARCHITECTURE IS "bd_0_hls_inst_0,hitproducerStream_hw,{}";
  ATTRIBUTE CORE_GENERATION_INFO : STRING;
  ATTRIBUTE CORE_GENERATION_INFO OF bd_0_hls_inst_0_arch: ARCHITECTURE IS "bd_0_hls_inst_0,hitproducerStream_hw,{x_ipProduct=Vivado 2022.2,x_ipVendor=xilinx.com,x_ipLibrary=hls,x_ipName=hitproducerStream_hw,x_ipVersion=1.0,x_ipCoreRevision=2113534771,x_ipLanguage=VHDL,x_ipSimLanguage=MIXED}";
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
  ATTRIBUTE X_INTERFACE_PARAMETER OF ap_clk: SIGNAL IS "XIL_INTERFACENAME ap_clk, ASSOCIATED_RESET ap_rst, FREQ_HZ 185000000.0, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN bd_0_ap_clk_0, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF ap_clk: SIGNAL IS "xilinx.com:signal:clock:1.0 ap_clk CLK";
  ATTRIBUTE X_INTERFACE_PARAMETER OF ap_rst: SIGNAL IS "XIL_INTERFACENAME ap_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0";
  ATTRIBUTE X_INTERFACE_INFO OF ap_rst: SIGNAL IS "xilinx.com:signal:reset:1.0 ap_rst RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF iBus: SIGNAL IS "XIL_INTERFACENAME iBus, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF iBus: SIGNAL IS "xilinx.com:signal:data:1.0 iBus DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF oBus_i: SIGNAL IS "XIL_INTERFACENAME oBus_i, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF oBus_i: SIGNAL IS "xilinx.com:signal:data:1.0 oBus_i DATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF oBus_o: SIGNAL IS "XIL_INTERFACENAME oBus_o, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF oBus_o: SIGNAL IS "xilinx.com:signal:data:1.0 oBus_o DATA";
BEGIN
  U0 : hitproducerStream_hw
    PORT MAP (
      ap_clk => ap_clk,
      ap_rst => ap_rst,
      oBus_i => oBus_i,
      oBus_o => oBus_o,
      iBus => iBus
    );
END bd_0_hls_inst_0_arch;
