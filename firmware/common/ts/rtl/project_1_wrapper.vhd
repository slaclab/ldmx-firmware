--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.2.1 (lin64) Build 4081461 Thu Dec 14 12:22:04 MST 2023
--Date        : Mon Jun  3 18:12:04 2024
--Host        : correlator8.fnal.gov running 64-bit unknown
--Command     : generate_target project_1_wrapper.bd
--Design      : project_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity project_1_wrapper is
  port (
    fast_command_config_BCR_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    fast_command_config_LED_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    gpio_PLtoPS_rtl : in STD_LOGIC_VECTOR ( 31 downto 0 );
    gpio_PStoPL_rtl : out STD_LOGIC_VECTOR ( 31 downto 0 );
    gpio_rtl_CLK0_tri_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gpio_rtl_CLK1_tri_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gpio_rtl_RM0_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_RM1_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP0_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP1_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP2_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP3_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    iic_CLK0_rtl_scl_io : inout STD_LOGIC;
    iic_CLK0_rtl_sda_io : inout STD_LOGIC;
    iic_CLK1_rtl_scl_io : inout STD_LOGIC;
    iic_CLK1_rtl_sda_io : inout STD_LOGIC;
    iic_RM0_rtl_scl_io : inout STD_LOGIC;
    iic_RM0_rtl_sda_io : inout STD_LOGIC;
    iic_RM1_rtl_scl_io : inout STD_LOGIC;
    iic_RM1_rtl_sda_io : inout STD_LOGIC;
    iic_RM2_rtl_scl_io : inout STD_LOGIC;
    iic_RM2_rtl_sda_io : inout STD_LOGIC;
    iic_RM3_rtl_scl_io : inout STD_LOGIC;
    iic_RM3_rtl_sda_io : inout STD_LOGIC;
    iic_RM4_rtl_scl_io : inout STD_LOGIC;
    iic_RM4_rtl_sda_io : inout STD_LOGIC;
    iic_RM5_rtl_scl_io : inout STD_LOGIC;
    iic_RM5_rtl_sda_io : inout STD_LOGIC;
    iic_SFP0_rtl_scl_io : inout STD_LOGIC;
    iic_SFP0_rtl_sda_io : inout STD_LOGIC;
    iic_SFP1_rtl_scl_io : inout STD_LOGIC;
    iic_SFP1_rtl_sda_io : inout STD_LOGIC;
    iic_SFP2_rtl_scl_io : inout STD_LOGIC;
    iic_SFP2_rtl_sda_io : inout STD_LOGIC;
    iic_SFP3_rtl_scl_io : inout STD_LOGIC;
    iic_SFP3_rtl_sda_io : inout STD_LOGIC
  );
end project_1_wrapper;

architecture STRUCTURE of project_1_wrapper is
  component project_1 is
  port (
    iic_RM0_rtl_scl_i : in STD_LOGIC;
    iic_RM0_rtl_scl_o : out STD_LOGIC;
    iic_RM0_rtl_scl_t : out STD_LOGIC;
    iic_RM0_rtl_sda_i : in STD_LOGIC;
    iic_RM0_rtl_sda_o : out STD_LOGIC;
    iic_RM0_rtl_sda_t : out STD_LOGIC;
    iic_RM1_rtl_scl_i : in STD_LOGIC;
    iic_RM1_rtl_scl_o : out STD_LOGIC;
    iic_RM1_rtl_scl_t : out STD_LOGIC;
    iic_RM1_rtl_sda_i : in STD_LOGIC;
    iic_RM1_rtl_sda_o : out STD_LOGIC;
    iic_RM1_rtl_sda_t : out STD_LOGIC;
    iic_RM2_rtl_scl_i : in STD_LOGIC;
    iic_RM2_rtl_scl_o : out STD_LOGIC;
    iic_RM2_rtl_scl_t : out STD_LOGIC;
    iic_RM2_rtl_sda_i : in STD_LOGIC;
    iic_RM2_rtl_sda_o : out STD_LOGIC;
    iic_RM2_rtl_sda_t : out STD_LOGIC;
    iic_RM3_rtl_scl_i : in STD_LOGIC;
    iic_RM3_rtl_scl_o : out STD_LOGIC;
    iic_RM3_rtl_scl_t : out STD_LOGIC;
    iic_RM3_rtl_sda_i : in STD_LOGIC;
    iic_RM3_rtl_sda_o : out STD_LOGIC;
    iic_RM3_rtl_sda_t : out STD_LOGIC;
    iic_RM4_rtl_scl_i : in STD_LOGIC;
    iic_RM4_rtl_scl_o : out STD_LOGIC;
    iic_RM4_rtl_scl_t : out STD_LOGIC;
    iic_RM4_rtl_sda_i : in STD_LOGIC;
    iic_RM4_rtl_sda_o : out STD_LOGIC;
    iic_RM4_rtl_sda_t : out STD_LOGIC;
    iic_RM5_rtl_scl_i : in STD_LOGIC;
    iic_RM5_rtl_scl_o : out STD_LOGIC;
    iic_RM5_rtl_scl_t : out STD_LOGIC;
    iic_RM5_rtl_sda_i : in STD_LOGIC;
    iic_RM5_rtl_sda_o : out STD_LOGIC;
    iic_RM5_rtl_sda_t : out STD_LOGIC;
    iic_SFP0_rtl_scl_i : in STD_LOGIC;
    iic_SFP0_rtl_scl_o : out STD_LOGIC;
    iic_SFP0_rtl_scl_t : out STD_LOGIC;
    iic_SFP0_rtl_sda_i : in STD_LOGIC;
    iic_SFP0_rtl_sda_o : out STD_LOGIC;
    iic_SFP0_rtl_sda_t : out STD_LOGIC;
    iic_SFP1_rtl_scl_i : in STD_LOGIC;
    iic_SFP1_rtl_scl_o : out STD_LOGIC;
    iic_SFP1_rtl_scl_t : out STD_LOGIC;
    iic_SFP1_rtl_sda_i : in STD_LOGIC;
    iic_SFP1_rtl_sda_o : out STD_LOGIC;
    iic_SFP1_rtl_sda_t : out STD_LOGIC;
    iic_SFP2_rtl_scl_i : in STD_LOGIC;
    iic_SFP2_rtl_scl_o : out STD_LOGIC;
    iic_SFP2_rtl_scl_t : out STD_LOGIC;
    iic_SFP2_rtl_sda_i : in STD_LOGIC;
    iic_SFP2_rtl_sda_o : out STD_LOGIC;
    iic_SFP2_rtl_sda_t : out STD_LOGIC;
    iic_SFP3_rtl_scl_i : in STD_LOGIC;
    iic_SFP3_rtl_scl_o : out STD_LOGIC;
    iic_SFP3_rtl_scl_t : out STD_LOGIC;
    iic_SFP3_rtl_sda_i : in STD_LOGIC;
    iic_SFP3_rtl_sda_o : out STD_LOGIC;
    iic_SFP3_rtl_sda_t : out STD_LOGIC;
    iic_CLK0_rtl_scl_i : in STD_LOGIC;
    iic_CLK0_rtl_scl_o : out STD_LOGIC;
    iic_CLK0_rtl_scl_t : out STD_LOGIC;
    iic_CLK0_rtl_sda_i : in STD_LOGIC;
    iic_CLK0_rtl_sda_o : out STD_LOGIC;
    iic_CLK0_rtl_sda_t : out STD_LOGIC;
    iic_CLK1_rtl_scl_i : in STD_LOGIC;
    iic_CLK1_rtl_scl_o : out STD_LOGIC;
    iic_CLK1_rtl_scl_t : out STD_LOGIC;
    iic_CLK1_rtl_sda_i : in STD_LOGIC;
    iic_CLK1_rtl_sda_o : out STD_LOGIC;
    iic_CLK1_rtl_sda_t : out STD_LOGIC;
    gpio_rtl_RM1_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_RM0_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP1_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP0_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP3_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_SFP2_tri_i : in STD_LOGIC_VECTOR ( 23 downto 0 );
    gpio_rtl_CLK1_tri_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gpio_rtl_CLK0_tri_i : in STD_LOGIC_VECTOR ( 15 downto 0 );
    gpio_PStoPL_rtl : out STD_LOGIC_VECTOR ( 31 downto 0 );
    gpio_PLtoPS_rtl : in STD_LOGIC_VECTOR ( 31 downto 0 );
    fast_command_config_LED_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 );
    fast_command_config_BCR_tri_o : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component project_1;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal iic_CLK0_rtl_scl_i : STD_LOGIC;
  signal iic_CLK0_rtl_scl_o : STD_LOGIC;
  signal iic_CLK0_rtl_scl_t : STD_LOGIC;
  signal iic_CLK0_rtl_sda_i : STD_LOGIC;
  signal iic_CLK0_rtl_sda_o : STD_LOGIC;
  signal iic_CLK0_rtl_sda_t : STD_LOGIC;
  signal iic_CLK1_rtl_scl_i : STD_LOGIC;
  signal iic_CLK1_rtl_scl_o : STD_LOGIC;
  signal iic_CLK1_rtl_scl_t : STD_LOGIC;
  signal iic_CLK1_rtl_sda_i : STD_LOGIC;
  signal iic_CLK1_rtl_sda_o : STD_LOGIC;
  signal iic_CLK1_rtl_sda_t : STD_LOGIC;
  signal iic_RM0_rtl_scl_i : STD_LOGIC;
  signal iic_RM0_rtl_scl_o : STD_LOGIC;
  signal iic_RM0_rtl_scl_t : STD_LOGIC;
  signal iic_RM0_rtl_sda_i : STD_LOGIC;
  signal iic_RM0_rtl_sda_o : STD_LOGIC;
  signal iic_RM0_rtl_sda_t : STD_LOGIC;
  signal iic_RM1_rtl_scl_i : STD_LOGIC;
  signal iic_RM1_rtl_scl_o : STD_LOGIC;
  signal iic_RM1_rtl_scl_t : STD_LOGIC;
  signal iic_RM1_rtl_sda_i : STD_LOGIC;
  signal iic_RM1_rtl_sda_o : STD_LOGIC;
  signal iic_RM1_rtl_sda_t : STD_LOGIC;
  signal iic_RM2_rtl_scl_i : STD_LOGIC;
  signal iic_RM2_rtl_scl_o : STD_LOGIC;
  signal iic_RM2_rtl_scl_t : STD_LOGIC;
  signal iic_RM2_rtl_sda_i : STD_LOGIC;
  signal iic_RM2_rtl_sda_o : STD_LOGIC;
  signal iic_RM2_rtl_sda_t : STD_LOGIC;
  signal iic_RM3_rtl_scl_i : STD_LOGIC;
  signal iic_RM3_rtl_scl_o : STD_LOGIC;
  signal iic_RM3_rtl_scl_t : STD_LOGIC;
  signal iic_RM3_rtl_sda_i : STD_LOGIC;
  signal iic_RM3_rtl_sda_o : STD_LOGIC;
  signal iic_RM3_rtl_sda_t : STD_LOGIC;
  signal iic_RM4_rtl_scl_i : STD_LOGIC;
  signal iic_RM4_rtl_scl_o : STD_LOGIC;
  signal iic_RM4_rtl_scl_t : STD_LOGIC;
  signal iic_RM4_rtl_sda_i : STD_LOGIC;
  signal iic_RM4_rtl_sda_o : STD_LOGIC;
  signal iic_RM4_rtl_sda_t : STD_LOGIC;
  signal iic_RM5_rtl_scl_i : STD_LOGIC;
  signal iic_RM5_rtl_scl_o : STD_LOGIC;
  signal iic_RM5_rtl_scl_t : STD_LOGIC;
  signal iic_RM5_rtl_sda_i : STD_LOGIC;
  signal iic_RM5_rtl_sda_o : STD_LOGIC;
  signal iic_RM5_rtl_sda_t : STD_LOGIC;
  signal iic_SFP0_rtl_scl_i : STD_LOGIC;
  signal iic_SFP0_rtl_scl_o : STD_LOGIC;
  signal iic_SFP0_rtl_scl_t : STD_LOGIC;
  signal iic_SFP0_rtl_sda_i : STD_LOGIC;
  signal iic_SFP0_rtl_sda_o : STD_LOGIC;
  signal iic_SFP0_rtl_sda_t : STD_LOGIC;
  signal iic_SFP1_rtl_scl_i : STD_LOGIC;
  signal iic_SFP1_rtl_scl_o : STD_LOGIC;
  signal iic_SFP1_rtl_scl_t : STD_LOGIC;
  signal iic_SFP1_rtl_sda_i : STD_LOGIC;
  signal iic_SFP1_rtl_sda_o : STD_LOGIC;
  signal iic_SFP1_rtl_sda_t : STD_LOGIC;
  signal iic_SFP2_rtl_scl_i : STD_LOGIC;
  signal iic_SFP2_rtl_scl_o : STD_LOGIC;
  signal iic_SFP2_rtl_scl_t : STD_LOGIC;
  signal iic_SFP2_rtl_sda_i : STD_LOGIC;
  signal iic_SFP2_rtl_sda_o : STD_LOGIC;
  signal iic_SFP2_rtl_sda_t : STD_LOGIC;
  signal iic_SFP3_rtl_scl_i : STD_LOGIC;
  signal iic_SFP3_rtl_scl_o : STD_LOGIC;
  signal iic_SFP3_rtl_scl_t : STD_LOGIC;
  signal iic_SFP3_rtl_sda_i : STD_LOGIC;
  signal iic_SFP3_rtl_sda_o : STD_LOGIC;
  signal iic_SFP3_rtl_sda_t : STD_LOGIC;
begin
iic_CLK0_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_CLK0_rtl_scl_o,
      IO => iic_CLK0_rtl_scl_io,
      O => iic_CLK0_rtl_scl_i,
      T => iic_CLK0_rtl_scl_t
    );
iic_CLK0_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_CLK0_rtl_sda_o,
      IO => iic_CLK0_rtl_sda_io,
      O => iic_CLK0_rtl_sda_i,
      T => iic_CLK0_rtl_sda_t
    );
iic_CLK1_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_CLK1_rtl_scl_o,
      IO => iic_CLK1_rtl_scl_io,
      O => iic_CLK1_rtl_scl_i,
      T => iic_CLK1_rtl_scl_t
    );
iic_CLK1_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_CLK1_rtl_sda_o,
      IO => iic_CLK1_rtl_sda_io,
      O => iic_CLK1_rtl_sda_i,
      T => iic_CLK1_rtl_sda_t
    );
iic_RM0_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_RM0_rtl_scl_o,
      IO => iic_RM0_rtl_scl_io,
      O => iic_RM0_rtl_scl_i,
      T => iic_RM0_rtl_scl_t
    );
iic_RM0_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_RM0_rtl_sda_o,
      IO => iic_RM0_rtl_sda_io,
      O => iic_RM0_rtl_sda_i,
      T => iic_RM0_rtl_sda_t
    );
iic_RM1_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_RM1_rtl_scl_o,
      IO => iic_RM1_rtl_scl_io,
      O => iic_RM1_rtl_scl_i,
      T => iic_RM1_rtl_scl_t
    );
iic_RM1_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_RM1_rtl_sda_o,
      IO => iic_RM1_rtl_sda_io,
      O => iic_RM1_rtl_sda_i,
      T => iic_RM1_rtl_sda_t
    );
iic_RM2_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_RM2_rtl_scl_o,
      IO => iic_RM2_rtl_scl_io,
      O => iic_RM2_rtl_scl_i,
      T => iic_RM2_rtl_scl_t
    );
iic_RM2_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_RM2_rtl_sda_o,
      IO => iic_RM2_rtl_sda_io,
      O => iic_RM2_rtl_sda_i,
      T => iic_RM2_rtl_sda_t
    );
iic_RM3_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_RM3_rtl_scl_o,
      IO => iic_RM3_rtl_scl_io,
      O => iic_RM3_rtl_scl_i,
      T => iic_RM3_rtl_scl_t
    );
iic_RM3_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_RM3_rtl_sda_o,
      IO => iic_RM3_rtl_sda_io,
      O => iic_RM3_rtl_sda_i,
      T => iic_RM3_rtl_sda_t
    );
iic_RM4_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_RM4_rtl_scl_o,
      IO => iic_RM4_rtl_scl_io,
      O => iic_RM4_rtl_scl_i,
      T => iic_RM4_rtl_scl_t
    );
iic_RM4_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_RM4_rtl_sda_o,
      IO => iic_RM4_rtl_sda_io,
      O => iic_RM4_rtl_sda_i,
      T => iic_RM4_rtl_sda_t
    );
iic_RM5_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_RM5_rtl_scl_o,
      IO => iic_RM5_rtl_scl_io,
      O => iic_RM5_rtl_scl_i,
      T => iic_RM5_rtl_scl_t
    );
iic_RM5_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_RM5_rtl_sda_o,
      IO => iic_RM5_rtl_sda_io,
      O => iic_RM5_rtl_sda_i,
      T => iic_RM5_rtl_sda_t
    );
iic_SFP0_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_SFP0_rtl_scl_o,
      IO => iic_SFP0_rtl_scl_io,
      O => iic_SFP0_rtl_scl_i,
      T => iic_SFP0_rtl_scl_t
    );
iic_SFP0_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_SFP0_rtl_sda_o,
      IO => iic_SFP0_rtl_sda_io,
      O => iic_SFP0_rtl_sda_i,
      T => iic_SFP0_rtl_sda_t
    );
iic_SFP1_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_SFP1_rtl_scl_o,
      IO => iic_SFP1_rtl_scl_io,
      O => iic_SFP1_rtl_scl_i,
      T => iic_SFP1_rtl_scl_t
    );
iic_SFP1_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_SFP1_rtl_sda_o,
      IO => iic_SFP1_rtl_sda_io,
      O => iic_SFP1_rtl_sda_i,
      T => iic_SFP1_rtl_sda_t
    );
iic_SFP2_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_SFP2_rtl_scl_o,
      IO => iic_SFP2_rtl_scl_io,
      O => iic_SFP2_rtl_scl_i,
      T => iic_SFP2_rtl_scl_t
    );
iic_SFP2_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_SFP2_rtl_sda_o,
      IO => iic_SFP2_rtl_sda_io,
      O => iic_SFP2_rtl_sda_i,
      T => iic_SFP2_rtl_sda_t
    );
iic_SFP3_rtl_scl_iobuf: component IOBUF
     port map (
      I => iic_SFP3_rtl_scl_o,
      IO => iic_SFP3_rtl_scl_io,
      O => iic_SFP3_rtl_scl_i,
      T => iic_SFP3_rtl_scl_t
    );
iic_SFP3_rtl_sda_iobuf: component IOBUF
     port map (
      I => iic_SFP3_rtl_sda_o,
      IO => iic_SFP3_rtl_sda_io,
      O => iic_SFP3_rtl_sda_i,
      T => iic_SFP3_rtl_sda_t
    );
project_1_i: component project_1
     port map (
      fast_command_config_BCR_tri_o(31 downto 0) => fast_command_config_BCR_tri_o(31 downto 0),
      fast_command_config_LED_tri_o(31 downto 0) => fast_command_config_LED_tri_o(31 downto 0),
      gpio_PLtoPS_rtl(31 downto 0) => gpio_PLtoPS_rtl(31 downto 0),
      gpio_PStoPL_rtl(31 downto 0) => gpio_PStoPL_rtl(31 downto 0),
      gpio_rtl_CLK0_tri_i(15 downto 0) => gpio_rtl_CLK0_tri_i(15 downto 0),
      gpio_rtl_CLK1_tri_i(15 downto 0) => gpio_rtl_CLK1_tri_i(15 downto 0),
      gpio_rtl_RM0_tri_i(23 downto 0) => gpio_rtl_RM0_tri_i(23 downto 0),
      gpio_rtl_RM1_tri_i(23 downto 0) => gpio_rtl_RM1_tri_i(23 downto 0),
      gpio_rtl_SFP0_tri_i(23 downto 0) => gpio_rtl_SFP0_tri_i(23 downto 0),
      gpio_rtl_SFP1_tri_i(23 downto 0) => gpio_rtl_SFP1_tri_i(23 downto 0),
      gpio_rtl_SFP2_tri_i(23 downto 0) => gpio_rtl_SFP2_tri_i(23 downto 0),
      gpio_rtl_SFP3_tri_i(23 downto 0) => gpio_rtl_SFP3_tri_i(23 downto 0),
      iic_CLK0_rtl_scl_i => iic_CLK0_rtl_scl_i,
      iic_CLK0_rtl_scl_o => iic_CLK0_rtl_scl_o,
      iic_CLK0_rtl_scl_t => iic_CLK0_rtl_scl_t,
      iic_CLK0_rtl_sda_i => iic_CLK0_rtl_sda_i,
      iic_CLK0_rtl_sda_o => iic_CLK0_rtl_sda_o,
      iic_CLK0_rtl_sda_t => iic_CLK0_rtl_sda_t,
      iic_CLK1_rtl_scl_i => iic_CLK1_rtl_scl_i,
      iic_CLK1_rtl_scl_o => iic_CLK1_rtl_scl_o,
      iic_CLK1_rtl_scl_t => iic_CLK1_rtl_scl_t,
      iic_CLK1_rtl_sda_i => iic_CLK1_rtl_sda_i,
      iic_CLK1_rtl_sda_o => iic_CLK1_rtl_sda_o,
      iic_CLK1_rtl_sda_t => iic_CLK1_rtl_sda_t,
      iic_RM0_rtl_scl_i => iic_RM0_rtl_scl_i,
      iic_RM0_rtl_scl_o => iic_RM0_rtl_scl_o,
      iic_RM0_rtl_scl_t => iic_RM0_rtl_scl_t,
      iic_RM0_rtl_sda_i => iic_RM0_rtl_sda_i,
      iic_RM0_rtl_sda_o => iic_RM0_rtl_sda_o,
      iic_RM0_rtl_sda_t => iic_RM0_rtl_sda_t,
      iic_RM1_rtl_scl_i => iic_RM1_rtl_scl_i,
      iic_RM1_rtl_scl_o => iic_RM1_rtl_scl_o,
      iic_RM1_rtl_scl_t => iic_RM1_rtl_scl_t,
      iic_RM1_rtl_sda_i => iic_RM1_rtl_sda_i,
      iic_RM1_rtl_sda_o => iic_RM1_rtl_sda_o,
      iic_RM1_rtl_sda_t => iic_RM1_rtl_sda_t,
      iic_RM2_rtl_scl_i => iic_RM2_rtl_scl_i,
      iic_RM2_rtl_scl_o => iic_RM2_rtl_scl_o,
      iic_RM2_rtl_scl_t => iic_RM2_rtl_scl_t,
      iic_RM2_rtl_sda_i => iic_RM2_rtl_sda_i,
      iic_RM2_rtl_sda_o => iic_RM2_rtl_sda_o,
      iic_RM2_rtl_sda_t => iic_RM2_rtl_sda_t,
      iic_RM3_rtl_scl_i => iic_RM3_rtl_scl_i,
      iic_RM3_rtl_scl_o => iic_RM3_rtl_scl_o,
      iic_RM3_rtl_scl_t => iic_RM3_rtl_scl_t,
      iic_RM3_rtl_sda_i => iic_RM3_rtl_sda_i,
      iic_RM3_rtl_sda_o => iic_RM3_rtl_sda_o,
      iic_RM3_rtl_sda_t => iic_RM3_rtl_sda_t,
      iic_RM4_rtl_scl_i => iic_RM4_rtl_scl_i,
      iic_RM4_rtl_scl_o => iic_RM4_rtl_scl_o,
      iic_RM4_rtl_scl_t => iic_RM4_rtl_scl_t,
      iic_RM4_rtl_sda_i => iic_RM4_rtl_sda_i,
      iic_RM4_rtl_sda_o => iic_RM4_rtl_sda_o,
      iic_RM4_rtl_sda_t => iic_RM4_rtl_sda_t,
      iic_RM5_rtl_scl_i => iic_RM5_rtl_scl_i,
      iic_RM5_rtl_scl_o => iic_RM5_rtl_scl_o,
      iic_RM5_rtl_scl_t => iic_RM5_rtl_scl_t,
      iic_RM5_rtl_sda_i => iic_RM5_rtl_sda_i,
      iic_RM5_rtl_sda_o => iic_RM5_rtl_sda_o,
      iic_RM5_rtl_sda_t => iic_RM5_rtl_sda_t,
      iic_SFP0_rtl_scl_i => iic_SFP0_rtl_scl_i,
      iic_SFP0_rtl_scl_o => iic_SFP0_rtl_scl_o,
      iic_SFP0_rtl_scl_t => iic_SFP0_rtl_scl_t,
      iic_SFP0_rtl_sda_i => iic_SFP0_rtl_sda_i,
      iic_SFP0_rtl_sda_o => iic_SFP0_rtl_sda_o,
      iic_SFP0_rtl_sda_t => iic_SFP0_rtl_sda_t,
      iic_SFP1_rtl_scl_i => iic_SFP1_rtl_scl_i,
      iic_SFP1_rtl_scl_o => iic_SFP1_rtl_scl_o,
      iic_SFP1_rtl_scl_t => iic_SFP1_rtl_scl_t,
      iic_SFP1_rtl_sda_i => iic_SFP1_rtl_sda_i,
      iic_SFP1_rtl_sda_o => iic_SFP1_rtl_sda_o,
      iic_SFP1_rtl_sda_t => iic_SFP1_rtl_sda_t,
      iic_SFP2_rtl_scl_i => iic_SFP2_rtl_scl_i,
      iic_SFP2_rtl_scl_o => iic_SFP2_rtl_scl_o,
      iic_SFP2_rtl_scl_t => iic_SFP2_rtl_scl_t,
      iic_SFP2_rtl_sda_i => iic_SFP2_rtl_sda_i,
      iic_SFP2_rtl_sda_o => iic_SFP2_rtl_sda_o,
      iic_SFP2_rtl_sda_t => iic_SFP2_rtl_sda_t,
      iic_SFP3_rtl_scl_i => iic_SFP3_rtl_scl_i,
      iic_SFP3_rtl_scl_o => iic_SFP3_rtl_scl_o,
      iic_SFP3_rtl_scl_t => iic_SFP3_rtl_scl_t,
      iic_SFP3_rtl_sda_i => iic_SFP3_rtl_sda_i,
      iic_SFP3_rtl_sda_o => iic_SFP3_rtl_sda_o,
      iic_SFP3_rtl_sda_t => iic_SFP3_rtl_sda_t
    );
end STRUCTURE;
