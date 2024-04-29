-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
-- Date        : Sun Apr 28 22:35:25 2024
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
    oBus_i : in STD_LOGIC_VECTOR ( 286 downto 0 );
    oBus_o : out STD_LOGIC_VECTOR ( 286 downto 0 );
    iBus : in STD_LOGIC_VECTOR ( 238 downto 0 )
  );

end bd_0_hls_inst_0;

architecture stub of bd_0_hls_inst_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "ap_clk,ap_rst,oBus_i[286:0],oBus_o[286:0],iBus[238:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "hitproducerStream_hw,Vivado 2022.2";
begin
end;
