-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
-- Date        : Tue Apr 23 18:39:29 2024
-- Host        : Big-Daddys-Numbering-Machine running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/Rory/AppData/Roaming/Xilinx/Vitis/S30XLhitmakerStream/solution1/impl/vhdl/project.gen/sources_1/bd/bd_0/ip/bd_0_hls_inst_0/bd_0_hls_inst_0_stub.vhdl
-- Design      : bd_0_hls_inst_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flga2577-1-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bd_0_hls_inst_0 is
  Port ( 
    amplitude_0_ap_vld : out STD_LOGIC;
    onflag_0_ap_vld : out STD_LOGIC;
    ap_clk : in STD_LOGIC;
    ap_rst_n : in STD_LOGIC;
    ap_start : in STD_LOGIC;
    ap_done : out STD_LOGIC;
    ap_idle : out STD_LOGIC;
    ap_ready : out STD_LOGIC;
    FIFO_0_TVALID : in STD_LOGIC;
    FIFO_0_TREADY : out STD_LOGIC;
    FIFO_0_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_1_TVALID : in STD_LOGIC;
    FIFO_1_TREADY : out STD_LOGIC;
    FIFO_1_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_2_TVALID : in STD_LOGIC;
    FIFO_2_TREADY : out STD_LOGIC;
    FIFO_2_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_3_TVALID : in STD_LOGIC;
    FIFO_3_TREADY : out STD_LOGIC;
    FIFO_3_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_4_TVALID : in STD_LOGIC;
    FIFO_4_TREADY : out STD_LOGIC;
    FIFO_4_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_5_TVALID : in STD_LOGIC;
    FIFO_5_TREADY : out STD_LOGIC;
    FIFO_5_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_6_TVALID : in STD_LOGIC;
    FIFO_6_TREADY : out STD_LOGIC;
    FIFO_6_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_7_TVALID : in STD_LOGIC;
    FIFO_7_TREADY : out STD_LOGIC;
    FIFO_7_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_8_TVALID : in STD_LOGIC;
    FIFO_8_TREADY : out STD_LOGIC;
    FIFO_8_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_9_TVALID : in STD_LOGIC;
    FIFO_9_TREADY : out STD_LOGIC;
    FIFO_9_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_10_TVALID : in STD_LOGIC;
    FIFO_10_TREADY : out STD_LOGIC;
    FIFO_10_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    FIFO_11_TVALID : in STD_LOGIC;
    FIFO_11_TREADY : out STD_LOGIC;
    FIFO_11_TDATA : in STD_LOGIC_VECTOR ( 15 downto 0 );
    amplitude_1_TVALID : out STD_LOGIC;
    amplitude_1_TREADY : in STD_LOGIC;
    amplitude_1_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_1_TVALID : out STD_LOGIC;
    onflag_1_TREADY : in STD_LOGIC;
    onflag_1_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_2_TVALID : out STD_LOGIC;
    amplitude_2_TREADY : in STD_LOGIC;
    amplitude_2_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_2_TVALID : out STD_LOGIC;
    onflag_2_TREADY : in STD_LOGIC;
    onflag_2_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_3_TVALID : out STD_LOGIC;
    amplitude_3_TREADY : in STD_LOGIC;
    amplitude_3_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_3_TVALID : out STD_LOGIC;
    onflag_3_TREADY : in STD_LOGIC;
    onflag_3_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_4_TVALID : out STD_LOGIC;
    amplitude_4_TREADY : in STD_LOGIC;
    amplitude_4_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_4_TVALID : out STD_LOGIC;
    onflag_4_TREADY : in STD_LOGIC;
    onflag_4_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_5_TVALID : out STD_LOGIC;
    amplitude_5_TREADY : in STD_LOGIC;
    amplitude_5_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_5_TVALID : out STD_LOGIC;
    onflag_5_TREADY : in STD_LOGIC;
    onflag_5_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_6_TVALID : out STD_LOGIC;
    amplitude_6_TREADY : in STD_LOGIC;
    amplitude_6_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_6_TVALID : out STD_LOGIC;
    onflag_6_TREADY : in STD_LOGIC;
    onflag_6_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_7_TVALID : out STD_LOGIC;
    amplitude_7_TREADY : in STD_LOGIC;
    amplitude_7_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_7_TVALID : out STD_LOGIC;
    onflag_7_TREADY : in STD_LOGIC;
    onflag_7_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_8_TVALID : out STD_LOGIC;
    amplitude_8_TREADY : in STD_LOGIC;
    amplitude_8_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_8_TVALID : out STD_LOGIC;
    onflag_8_TREADY : in STD_LOGIC;
    onflag_8_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_9_TVALID : out STD_LOGIC;
    amplitude_9_TREADY : in STD_LOGIC;
    amplitude_9_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_9_TVALID : out STD_LOGIC;
    onflag_9_TREADY : in STD_LOGIC;
    onflag_9_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_10_TVALID : out STD_LOGIC;
    amplitude_10_TREADY : in STD_LOGIC;
    amplitude_10_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_10_TVALID : out STD_LOGIC;
    onflag_10_TREADY : in STD_LOGIC;
    onflag_10_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_11_TVALID : out STD_LOGIC;
    amplitude_11_TREADY : in STD_LOGIC;
    amplitude_11_TDATA : out STD_LOGIC_VECTOR ( 23 downto 0 );
    onflag_11_TVALID : out STD_LOGIC;
    onflag_11_TREADY : in STD_LOGIC;
    onflag_11_TDATA : out STD_LOGIC_VECTOR ( 7 downto 0 );
    amplitude_0 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    onflag_0 : out STD_LOGIC_VECTOR ( 0 to 0 )
  );

end bd_0_hls_inst_0;

architecture stub of bd_0_hls_inst_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "amplitude_0_ap_vld,onflag_0_ap_vld,ap_clk,ap_rst_n,ap_start,ap_done,ap_idle,ap_ready,FIFO_0_TVALID,FIFO_0_TREADY,FIFO_0_TDATA[15:0],FIFO_1_TVALID,FIFO_1_TREADY,FIFO_1_TDATA[15:0],FIFO_2_TVALID,FIFO_2_TREADY,FIFO_2_TDATA[15:0],FIFO_3_TVALID,FIFO_3_TREADY,FIFO_3_TDATA[15:0],FIFO_4_TVALID,FIFO_4_TREADY,FIFO_4_TDATA[15:0],FIFO_5_TVALID,FIFO_5_TREADY,FIFO_5_TDATA[15:0],FIFO_6_TVALID,FIFO_6_TREADY,FIFO_6_TDATA[15:0],FIFO_7_TVALID,FIFO_7_TREADY,FIFO_7_TDATA[15:0],FIFO_8_TVALID,FIFO_8_TREADY,FIFO_8_TDATA[15:0],FIFO_9_TVALID,FIFO_9_TREADY,FIFO_9_TDATA[15:0],FIFO_10_TVALID,FIFO_10_TREADY,FIFO_10_TDATA[15:0],FIFO_11_TVALID,FIFO_11_TREADY,FIFO_11_TDATA[15:0],amplitude_1_TVALID,amplitude_1_TREADY,amplitude_1_TDATA[23:0],onflag_1_TVALID,onflag_1_TREADY,onflag_1_TDATA[7:0],amplitude_2_TVALID,amplitude_2_TREADY,amplitude_2_TDATA[23:0],onflag_2_TVALID,onflag_2_TREADY,onflag_2_TDATA[7:0],amplitude_3_TVALID,amplitude_3_TREADY,amplitude_3_TDATA[23:0],onflag_3_TVALID,onflag_3_TREADY,onflag_3_TDATA[7:0],amplitude_4_TVALID,amplitude_4_TREADY,amplitude_4_TDATA[23:0],onflag_4_TVALID,onflag_4_TREADY,onflag_4_TDATA[7:0],amplitude_5_TVALID,amplitude_5_TREADY,amplitude_5_TDATA[23:0],onflag_5_TVALID,onflag_5_TREADY,onflag_5_TDATA[7:0],amplitude_6_TVALID,amplitude_6_TREADY,amplitude_6_TDATA[23:0],onflag_6_TVALID,onflag_6_TREADY,onflag_6_TDATA[7:0],amplitude_7_TVALID,amplitude_7_TREADY,amplitude_7_TDATA[23:0],onflag_7_TVALID,onflag_7_TREADY,onflag_7_TDATA[7:0],amplitude_8_TVALID,amplitude_8_TREADY,amplitude_8_TDATA[23:0],onflag_8_TVALID,onflag_8_TREADY,onflag_8_TDATA[7:0],amplitude_9_TVALID,amplitude_9_TREADY,amplitude_9_TDATA[23:0],onflag_9_TVALID,onflag_9_TREADY,onflag_9_TDATA[7:0],amplitude_10_TVALID,amplitude_10_TREADY,amplitude_10_TDATA[23:0],onflag_10_TVALID,onflag_10_TREADY,onflag_10_TDATA[7:0],amplitude_11_TVALID,amplitude_11_TREADY,amplitude_11_TDATA[23:0],onflag_11_TVALID,onflag_11_TREADY,onflag_11_TDATA[7:0],amplitude_0[16:0],onflag_0[0:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "hitproducerStream_hw,Vivado 2022.2";
begin
end;
