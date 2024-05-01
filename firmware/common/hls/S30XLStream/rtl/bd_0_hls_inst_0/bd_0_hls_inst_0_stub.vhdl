-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
-- Date        : Wed May  1 09:51:06 2024
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
    ap_clk : in STD_LOGIC;
    ap_rst : in STD_LOGIC;
    timestamp_in : in STD_LOGIC_VECTOR ( 69 downto 0 );
    timestamp_out : in STD_LOGIC_VECTOR ( 69 downto 0 );
    dataReady_in : in STD_LOGIC_VECTOR ( 0 to 0 );
    dataReady_out : in STD_LOGIC_VECTOR ( 0 to 0 );
    FIFO_0 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_1 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_2 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_3 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_4 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_5 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_6 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_7 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_8 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_9 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_10 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    FIFO_11 : in STD_LOGIC_VECTOR ( 13 downto 0 );
    onflag_0 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_1 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_2 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_3 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_4 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_5 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_6 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_7 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_8 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_9 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_10 : out STD_LOGIC_VECTOR ( 0 to 0 );
    onflag_11 : out STD_LOGIC_VECTOR ( 0 to 0 );
    amplitude_0 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_1 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_2 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_3 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_4 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_5 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_6 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_7 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_8 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_9 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_10 : out STD_LOGIC_VECTOR ( 16 downto 0 );
    amplitude_11 : out STD_LOGIC_VECTOR ( 16 downto 0 )
  );

end bd_0_hls_inst_0;

architecture stub of bd_0_hls_inst_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "ap_clk,ap_rst,timestamp_in[69:0],timestamp_out[69:0],dataReady_in[0:0],dataReady_out[0:0],FIFO_0[13:0],FIFO_1[13:0],FIFO_2[13:0],FIFO_3[13:0],FIFO_4[13:0],FIFO_5[13:0],FIFO_6[13:0],FIFO_7[13:0],FIFO_8[13:0],FIFO_9[13:0],FIFO_10[13:0],FIFO_11[13:0],onflag_0[0:0],onflag_1[0:0],onflag_2[0:0],onflag_3[0:0],onflag_4[0:0],onflag_5[0:0],onflag_6[0:0],onflag_7[0:0],onflag_8[0:0],onflag_9[0:0],onflag_10[0:0],onflag_11[0:0],amplitude_0[16:0],amplitude_1[16:0],amplitude_2[16:0],amplitude_3[16:0],amplitude_4[16:0],amplitude_5[16:0],amplitude_6[16:0],amplitude_7[16:0],amplitude_8[16:0],amplitude_9[16:0],amplitude_10[16:0],amplitude_11[16:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "hitproducerStream_hw,Vivado 2022.2";
begin
end;
