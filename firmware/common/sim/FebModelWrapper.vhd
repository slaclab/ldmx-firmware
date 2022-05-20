-------------------------------------------------------------------------------
-- Title      : FebModelWrapper
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


library surf;
use surf.StdRtlPkg.all;

library ldmx;
use ldmx.HpsPkg.all;
use ldmx.HpsFebHwPkg.all;

entity FebModelWrapper is

   generic (
      TPD_G                 : time                        := 1 ns;
      BUILD_INFO_G          : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
      ROGUE_TCP_SIM_G       : boolean                     := true;
      ROGUE_TCP_CTRL_PORT_G : integer range 1024 to 49151 := 9000;
      HYBRID_TYPE_G         : slv(1 downto 0)             := OLD_HYBRID_C);
   port (
      sysGtTxP : out sl;
      sysGtTxN : out sl;
      sysGtRxP : in  sl;
      sysGtRxN : in  sl;

      dataGtTxP : out slv(3 downto 0);
      dataGtTxN : out slv(3 downto 0);
      dataGtRxP : in  slv(3 downto 0);
      dataGtRxN : in  slv(3 downto 0));

end entity FebModelWrapper;

architecture sim of FebModelWrapper is

   signal gtRefClk371P : sl;                     -- [in]
   signal gtRefClk371N : sl;                     -- [in]
   signal gtRefClk250P : sl;                     -- [in]
   signal gtRefClk250N : sl;                     -- [in]
   signal adcClkP      : slv(3 downto 0);        -- [out]
   signal adcClkN      : slv(3 downto 0);        -- [out]
   signal adcFClkP     : slv(3 downto 0);        -- [in]
   signal adcFClkN     : slv(3 downto 0);        -- [in]
   signal adcDClkP     : slv(3 downto 0);        -- [in]
   signal adcDClkN     : slv(3 downto 0);        -- [in]
   signal adcDataP     : slv5Array(3 downto 0);  -- [in]
   signal adcDataN     : slv5Array(3 downto 0);  -- [in]
   signal adcCsb       : slv(3 downto 0);        -- [out]
   signal adcSclk      : slv(3 downto 0);        -- [out]
   signal adcSdio      : slv(3 downto 0);        -- [inout]
   signal ampI2cScl    : sl;                     -- [inout]
   signal ampI2cSda    : sl;                     -- [inout]
   signal boardI2cScl  : sl;                     -- [inout]
   signal boardI2cSda  : sl;                     -- [inout]
   signal boardSpiSclk : sl;                     -- [out]
   signal boardSpiSdi  : sl;                     -- [out]
   signal boardSpiSdo  : sl;                     -- [in]
   signal boardSpiCsL  : slv(4 downto 0);        -- [out]
   signal hyPwrEn      : slv(3 downto 0);        -- [out]
   signal hyClkP       : slv(3 downto 0);        -- [out]
   signal hyClkN       : slv(3 downto 0);        -- [out]
   signal hyTrgP       : slv(3 downto 0);        -- [out]
   signal hyTrgN       : slv(3 downto 0);        -- [out]
   signal hyRstL       : slv(3 downto 0);        -- [out]
   signal hyI2cScl     : slv(3 downto 0);        -- [out]
   signal hyI2cSdaOut  : slv(3 downto 0);        -- [out]
   signal hyI2cSdaIn   : slv(3 downto 0);        -- [in]
   signal vAuxP        : slv(15 downto 0);       -- [in]
   signal vAuxN        : slv(15 downto 0);       -- [in]
   signal vPIn         : sl;                     -- [in]
   signal vNIn         : sl;                     -- [in]
   signal powerGood    : PowerGoodType;          -- [in]
   signal leds         : slv(7 downto 0);        -- [out]
   signal bootCsL      : sl;
   signal bootMosi     : sl;
   signal bootMiso     : sl;

begin


   -------------------------------------------------------------------------------------------------
   -- Board model
   -------------------------------------------------------------------------------------------------
   U_FrontEndBoardModel_1 : entity ldmx.FrontEndBoardModel
      generic map (
         TPD_G          => TPD_G,
         CLK_0_PERIOD_G => 2.692 ns,
         CLK_1_PERIOD_G => 4 ns,
         HYBRIDS_G      => 4,
         HYBRID_TYPE_G  => HYBRID_TYPE_G)
      port map (
         gtRefClk0P   => gtRefClk371P,  -- [out]
         gtRefClk0N   => gtRefClk371N,  -- [out]
         gtRefClk1P   => gtRefClk250P,  -- [out]
         gtRefClk1N   => gtRefClk250N,  -- [out]
         adcClkP      => adcClkP,       -- [in]
         adcClkN      => adcClkN,       -- [in]
         adcFClkP     => adcFClkP,      -- [out]
         adcFClkN     => adcFClkN,      -- [out]
         adcDClkP     => adcDClkP,      -- [out]
         adcDClkN     => adcDClkN,      -- [out]
         adcDataP     => adcDataP,      -- [out]
         adcDataN     => adcDataN,      -- [out]
         adcCsb       => adcCsb,        -- [inout]
         adcSclk      => adcSclk,       -- [inout]
         adcSdio      => adcSdio,       -- [inout]
         ampI2cScl    => ampI2cScl,     -- [inout]
         ampI2cSda    => ampI2cSda,     -- [inout]
         boardI2cScl  => boardI2cScl,   -- [inout]
         boardI2cSda  => boardI2cSda,   -- [inout]
         boardSpiSclk => boardSpiSclk,  -- [in]
         boardSpiSdi  => boardSpiSdi,   -- [in]
         boardSpiSdo  => boardSpiSdo,   -- [out]
         boardSpiCsL  => boardSpiCsL,   -- [in]
         hyPwrEn      => hyPwrEn,       -- [in]
         powerGood    => powerGood,     -- [out]
         hyClkP       => hyClkP,        -- [in]
         hyClkN       => hyClkN,        -- [in]
         hyTrgP       => hyTrgP,        -- [in]
         hyTrgN       => hyTrgN,        -- [in]
         hyRstL       => hyRstL,        -- [in]
         hyI2cScl     => hyI2cScl,      -- [in]
         hyI2cSdaOut  => hyI2cSdaOut,   -- [in]
         hyI2cSdaIn   => hyI2cSdaIn);   -- [out]

   U_HpsFeb_1: entity ldmx.HpsFeb
      generic map (
         TPD_G                 => TPD_G,
         BUILD_INFO_G          => BUILD_INFO_G,
         SIMULATION_G          => true,
         ROGUE_SIM_EN_G        => true,
         ROGUE_SIM_CTRL_PORT_G => 9000,
         HYBRIDS_G             => 4,
         APVS_PER_HYBRID_G     => 5)
      port map (
         gtRefClk371P => gtRefClk371P,  -- [in]
         gtRefClk371N => gtRefClk371N,  -- [in]
         gtRefClk250P => gtRefClk250P,  -- [in]
         gtRefClk250N => gtRefClk250N,  -- [in]
--          ctrlGtTxP    => ctrlGtTxP,     -- [out]
--          ctrlGtTxN    => ctrlGtTxN,     -- [out]
--          ctrlGtRxP    => ctrlGtRxP,     -- [in]
--          ctrlGtRxN    => ctrlGtRxN,     -- [in]
         adcClkP      => adcClkP,       -- [out]
         adcClkN      => adcClkN,       -- [out]
         adcFClkP     => adcFClkP,      -- [in]
         adcFClkN     => adcFClkN,      -- [in]
         adcDClkP     => adcDClkP,      -- [in]
         adcDClkN     => adcDClkN,      -- [in]
         adcDataP     => adcDataP,      -- [in]
         adcDataN     => adcDataN,      -- [in]
         adcCsb       => adcCsb,        -- [out]
         adcSclk      => adcSclk,       -- [out]
         adcSdio      => adcSdio,       -- [inout]
         ampI2cScl    => ampI2cScl,     -- [inout]
         ampI2cSda    => ampI2cSda,     -- [inout]
         boardI2cScl  => boardI2cScl,   -- [inout]
         boardI2cSda  => boardI2cSda,   -- [inout]
         boardSpiSclk => boardSpiSclk,  -- [out]
         boardSpiSdi  => boardSpiSdi,   -- [out]
         boardSpiSdo  => boardSpiSdo,   -- [in]
         boardSpiCsL  => boardSpiCsL,   -- [out]
         hyPwrEn      => hyPwrEn,       -- [out]
         hyClkP       => hyClkP,        -- [out]
         hyClkN       => hyClkN,        -- [out]
         hyTrgP       => hyTrgP,        -- [out]
         hyTrgN       => hyTrgN,        -- [out]
         hyRstL       => hyRstL,        -- [out]
         hyI2cScl     => hyI2cScl,      -- [out]
         hyI2cSdaOut  => hyI2cSdaOut,   -- [out]
         hyI2cSdaIn   => hyI2cSdaIn,    -- [in]
         vAuxP        => vAuxP,         -- [in]
         vAuxN        => vAuxN,         -- [in]
         vPIn         => vPIn,          -- [in]
         vNIn         => vNIn,          -- [in]
         powerGood    => powerGood,     -- [in]
         leds         => leds,          -- [out]
         bootCsL      => bootCsL,       -- [out]
         bootMosi     => bootMosi,      -- [out]
         bootMiso     => bootMiso);     -- [in]


end architecture sim;
