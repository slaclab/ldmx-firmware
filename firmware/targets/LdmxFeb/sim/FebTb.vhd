-------------------------------------------------------------------------------
-- Title      : Testbench for design "FrontEndBoard"
-------------------------------------------------------------------------------
-- File       : FrontEndBoard_tb.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-10-22
-- Last update: 2015-02-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.i2cPkg.all;

library hps_daq;
use hps_daq.FebConfigPkg.all;
use hps_daq.HpsPkg.all;
----------------------------------------------------------------------------------------------------

entity FebTb is

end entity FebTb;

----------------------------------------------------------------------------------------------------

architecture sim of FebTb is

   -- component generics
   constant TPD_C          : time            := 1 ns;
   constant SIMULATION_C   : boolean         := true;
   constant HYBRIDS_C      : integer         := 4;
   constant HYBRID_TYPE_C  : slv(1 downto 0) := NEW_HYBRID_C;
   constant CLK_0_PERIOD_C : time            := 8 ns;
   constant CLK_1_PERIOD_C : time            := 4 ns;


   -- component ports
   signal gtRefClk125P : sl;
   signal gtRefClk125N : sl;
   signal gtRefClk250P : sl;
   signal gtRefClk250N : sl;
   signal sysGtTxP     : sl;
   signal sysGtTxN     : sl;
   signal sysGtRxP     : sl;
   signal sysGtRxN     : sl;
   signal dataGtTxP    : slv(HYBRIDS_C-1 downto 0);
   signal dataGtTxN    : slv(HYBRIDS_C-1 downto 0);
   signal dataGtRxP    : slv(HYBRIDS_C-1 downto 0);
   signal dataGtRxN    : slv(HYBRIDS_C-1 downto 0);
   signal adcClkP      : slv(HYBRIDS_C-1 downto 0);
   signal adcClkN      : slv(HYBRIDS_C-1 downto 0);
   signal adcFClkP     : slv(HYBRIDS_C-1 downto 0);
   signal adcFClkN     : slv(HYBRIDS_C-1 downto 0);
   signal adcDClkP     : slv(HYBRIDS_C-1 downto 0);
   signal adcDClkN     : slv(HYBRIDS_C-1 downto 0);
   signal adcDataP     : slv5Array(HYBRIDS_C-1 downto 0);
   signal adcDataN     : slv5Array(HYBRIDS_C-1 downto 0);
   signal fdSerSdio    : sl;
   signal adcCsb       : slv(HYBRIDS_C-1 downto 0);
   signal adcSclk      : slv(HYBRIDS_C-1 downto 0);
   signal adcSdio      : slv(HYBRIDS_C-1 downto 0);
   signal boardI2cScl  : sl;
   signal boardI2cSda  : sl;
   signal boardSpiSclk : sl;
   signal boardSpiSdi  : sl;
   signal boardSpiSdo  : sl;
   signal boardSpiCsL  : slv(4 downto 0);
   signal hyPwrEn      : slv(HYBRIDS_C-1 downto 0);
   signal hyClkP       : slv(HYBRIDS_C-1 downto 0);
   signal hyClkN       : slv(HYBRIDS_C-1 downto 0);
   signal hyTrgP       : slv(HYBRIDS_C-1 downto 0);
   signal hyTrgN       : slv(HYBRIDS_C-1 downto 0);
   signal hyRstL       : slv(HYBRIDS_C-1 downto 0);
   signal hyI2cScl     : slv(HYBRIDS_C-1 downto 0);
   signal hyI2cSdaOut  : slv(HYBRIDS_C-1 downto 0);
   signal hyI2cSdaIn   : slv(HYBRIDS_C-1 downto 0);
   signal vAuxP        : slv(15 downto 0);
   signal vAuxN        : slv(15 downto 0);
   signal vPIn         : sl;
   signal vNIn         : sl;
   signal flashDq      : slv(15 downto 0);
   signal flashAddr    : slv(25 downto 0);
   signal flashCeL     : sl;
   signal flashOeL     : sl;
   signal flashWeL     : sl;
   signal flashAdv     : sl;
   signal flashWait    : sl;
   signal powerGood    : PowerGoodType;

begin


   FRONT_END_BOARD_INST : entity hps_daq.FrontEndBoardModel
      generic map (
         TPD_G          => TPD_C,
         CLK_0_PERIOD_G => CLK_0_PERIOD_C,
         CLK_1_PERIOD_G => CLK_1_PERIOD_C,
         HYBRID_TYPE_G  => HYBRID_TYPE_C,
         HYBRIDS_G      => HYBRIDS_C)
      port map (
         gtRefClk0P   => gtRefClk125P,
         gtRefClk0N   => gtRefClk125N,
         gtRefClk1P   => gtRefClk250P,
         gtRefClk1N   => gtRefClk250N,
         adcClkP      => adcClkP,
         adcClkN      => adcClkN,
         adcFClkP     => adcFClkP,
         adcFClkN     => adcFClkN,
         adcDClkP     => adcDClkP,
         adcDClkN     => adcDClkN,
         adcDataP     => adcDataP,
         adcDataN     => adcDataN,
         fdSerSdio    => fdSerSdio,
         adcCsb       => adcCsb,
         adcSclk      => adcSclk,
         adcSdio      => adcSdio,
         boardI2cScl  => boardI2cScl,
         boardI2cSda  => boardI2cSda,
         boardSpiSclk => boardSpiSclk,
         boardSpiSdi  => boardSpiSdi,
         boardSpiSdo  => boardSpiSdo,
         boardSpiCsL  => boardSpiCsL,
         hyPwrEn      => hyPwrEn,
         powerGood    => powerGood,
         hyClkP       => hyClkP,
         hyClkN       => hyClkN,
         hyTrgP       => hyTrgP,
         hyTrgN       => hyTrgN,
         hyRstL       => hyRstL,
         hyI2cScl     => hyI2cScl,
         hyI2cSdaOut  => hyI2cSdaOut,
         hyI2cSdaIn   => hyI2cSdaIn);



   vAuxP <= (others => '0');
   vAuxN <= (others => '0');
   vPIn  <= '0';
   vNIn  <= '0';

   --flashWait <= '0';

   FIRMWARE_INST : entity hps_daq.Feb
      generic map (
         TPD_G        => TPD_C,
         SIMULATION_G => true)
      port map (
         gtRefClk125P => gtRefClk125P,
         gtRefClk125N => gtRefClk125N,
         gtRefClk250P => gtRefClk250P,
         gtRefClk250N => gtRefClk250N,
         sysGtTxP     => sysGtTxP,
         sysGtTxN     => sysGtTxN,
         sysGtRxP     => sysGtRxP,
         sysGtRxN     => sysGtRxN,
         dataGtTxP    => dataGtTxP,
         dataGtTxN    => dataGtTxN,
         dataGtRxP    => dataGtRxP,
         dataGtRxN    => dataGtRxN,
         adcClkP      => adcClkP,
         adcClkN      => adcClkN,
         adcFClkP     => adcFClkP,
         adcFClkN     => adcFClkN,
         adcDClkP     => adcDClkP,
         adcDClkN     => adcDClkN,
         adcDataP     => adcDataP,
         adcDataN     => adcDataN,
         fdSerSdio    => fdSerSdio,
         adcCsb       => adcCsb,
         adcSclk      => adcSclk,
         adcSdio      => adcSdio,
         boardI2cScl  => boardI2cScl,
         boardI2cSda  => boardI2cSda,
         boardSpiSclk => boardSpiSclk,
         boardSpiSdi  => boardSpiSdi,
         boardSpiSdo  => boardSpiSdo,
         boardSpiCsL  => boardSpiCsL,
         hyPwrEn      => hyPwrEn,
         hyClkP       => hyClkP,
         hyClkN       => hyClkN,
         hyTrgP       => hyTrgP,
         hyTrgN       => hyTrgN,
         hyRstL       => hyRstL,
         hyI2cScl     => hyI2cScl,
         hyI2cSdaOut  => hyI2cSdaOut,
         hyI2cSdaIn   => hyI2cSdaIn,
         powerGood    => powerGood,
         vAuxP        => vAuxP,
         vAuxN        => vAuxN,
         vPIn         => vPIn,
         vNIn         => vNIn,
         flashDq      => flashDq,
         flashAddr    => flashAddr,
         flashCeL     => flashCeL,
         flashOeL     => flashOeL,
         flashWeL     => flashWeL,
         flashAdv     => flashAdv,
         flashWait    => flashWait);

   flashDq   <= (others => 'Z');
   flashWait <= '0';

   dataGtRxP <= (others => '0');
   dataGtRxN <= (others => '0');
   sysGtRxP  <= '0';
   sysGtRxN  <= '0';

end architecture sim;



