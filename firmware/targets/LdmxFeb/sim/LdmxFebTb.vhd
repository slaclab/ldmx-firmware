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

library surf;
use surf.StdRtlPkg.all;

library ldmx;

----------------------------------------------------------------------------------------------------

entity FebTb is

end entity FebTb;

----------------------------------------------------------------------------------------------------

architecture sim of FebTb is

   constant TPD_G                : time                        := 1 ns;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
   constant SIMULATION_G         : boolean                     := false;
   constant ROGUE_SIM_EN_G       : boolean                     := false;
   constant ROGUE_SIM_SIDEBAND_G : boolean                     := false;
   constant ROGUE_SIM_PORT_NUM_G : integer range 1024 to 49151 := 9000;
   constant ADCS_G               : integer                     := 4;
   constant HYBRIDS_G            : integer                     := 8;
   constant APVS_PER_HYBRID_G    : integer                     := 6);


   signal gtRefClk185P   : sl;                               -- [in]
   signal gtRefClk185N   : sl;                               -- [in]
   signal gtRefClk250P   : sl;                               -- [in]
   signal gtRefClk250N   : sl;                               -- [in]
   signal sasGtTxP       : slv(3 downto 0);                  -- [out]
   signal sasGtTxN       : slv(3 downto 0);                  -- [out]
   signal sasGtRxP       : slv(3 downto 0);                  -- [in]
   signal sasGtRxN       : slv(3 downto 0);                  -- [in]
   signal qsfpGtTxP      : slv(3 downto 0);                  -- [out]
   signal qsfpGtTxN      : slv(3 downto 0);                  -- [out]
   signal qsfpGtRxP      : slv(3 downto 0);                  -- [in]
   signal qsfpGtRxN      : slv(3 downto 0);                  -- [in]
   signal sfpGtTxP       : sl;                               -- [out]
   signal sfpGtTxN       : sl;                               -- [out]
   signal sfpGtRxP       : sl;                               -- [in]
   signal sfpGtRxN       : sl;                               -- [in]
   signal adcFClkP       : slv(HYBRIDS_G-1 downto 0);        -- [in]
   signal adcFClkN       : slv(HYBRIDS_G-1 downto 0);        -- [in]
   signal adcDClkP       : slv(HYBRIDS_G-1 downto 0);        -- [in]
   signal adcDClkN       : slv(HYBRIDS_G-1 downto 0);        -- [in]
   signal adcDataP       : slv6Array(HYBRIDS_G-1 downto 0);  -- [in]
   signal adcDataN       : slv6Array(HYBRIDS_G-1 downto 0);  -- [in]
   signal adcClkP        : slv(ADCS_G-1 downto 0);           -- [out]
   signal adcClkN        : slv(ADCS_G-1 downto 0);           -- [out]
   signal adcCsb         : slv(ADCS_G*2-1 downto 0);         -- [out]
   signal adcSclk        : slv(ADCS_G-1 downto 0);           -- [out]
   signal adcSdio        : slv(ADCS_G-1 downto 0);           -- [inout]
   signal adcPdwn        : slv(ADCS_G-1 downto 0);           -- [out]
   signal locI2cScl      : sl;                               -- [inout]
   signal locI2cSda      : sl;                               -- [inout]
   signal sfpI2cScl      : sl;                               -- [inout]
   signal sfpI2cSda      : sl;                               -- [inout]
   signal qsfpI2cScl     : sl;                               -- [inout]
   signal qsfpI2cSda     : sl;                               -- [inout]
   signal qsfpI2cResetL  : sl;                               -- [inout]
   signal digPmBusScl    : sl;                               -- [inout]
   signal digPmBusSda    : sl;                               -- [inout]
   signal digPmBusAlertL : sl;                               -- [in]
   signal anaPmBusScl    : sl;                               -- [inout]
   signal anaPmBusSda    : sl;                               -- [inout]
   signal anaPmBusAlertL : sl;                               -- [in]
   signal hyPwrI2cScl    : slv(HYBRIDS_G-1 downto 0);        -- [inout]
   signal hyPwrI2cSda    : slv(HYBRIDS_G-1 downto 0);        -- [inout]
   signal hyPwrEnOut     : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyClkP         : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyClkN         : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyTrgP         : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyTrgN         : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyRstL         : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyI2cScl       : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyI2cSdaOut    : slv(HYBRIDS_G-1 downto 0);        -- [out]
   signal hyI2cSdaIn     : slv(HYBRIDS_G-1 downto 0);        -- [in]
   signal vauxp          : slv(3 downto 0);                  -- [in]
   signal vauxn          : slv(3 downto 0);                  -- [in]
   signal leds           : slv(7 downto 0);                  -- [out]

begin


   U_LdmxFeb_1 : entity ldmx.LdmxFeb
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         SIMULATION_G         => SIMULATION_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_SIDEBAND_G => ROGUE_SIM_SIDEBAND_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         ADCS_G               => ADCS_G,
         HYBRIDS_G            => HYBRIDS_G,
         APVS_PER_HYBRID_G    => APVS_PER_HYBRID_G)
      port map (
         gtRefClk185P   => gtRefClk185P,    -- [in]
         gtRefClk185N   => gtRefClk185N,    -- [in]
         gtRefClk250P   => gtRefClk250P,    -- [in]
         gtRefClk250N   => gtRefClk250N,    -- [in]
         sasGtTxP       => sasGtTxP,        -- [out]
         sasGtTxN       => sasGtTxN,        -- [out]
         sasGtRxP       => sasGtRxP,        -- [in]
         sasGtRxN       => sasGtRxN,        -- [in]
         qsfpGtTxP      => qsfpGtTxP,       -- [out]
         qsfpGtTxN      => qsfpGtTxN,       -- [out]
         qsfpGtRxP      => qsfpGtRxP,       -- [in]
         qsfpGtRxN      => qsfpGtRxN,       -- [in]
         sfpGtTxP       => sfpGtTxP,        -- [out]
         sfpGtTxN       => sfpGtTxN,        -- [out]
         sfpGtRxP       => sfpGtRxP,        -- [in]
         sfpGtRxN       => sfpGtRxN,        -- [in]
         adcFClkP       => adcFClkP,        -- [in]
         adcFClkN       => adcFClkN,        -- [in]
         adcDClkP       => adcDClkP,        -- [in]
         adcDClkN       => adcDClkN,        -- [in]
         adcDataP       => adcDataP,        -- [in]
         adcDataN       => adcDataN,        -- [in]
         adcClkP        => adcClkP,         -- [out]
         adcClkN        => adcClkN,         -- [out]
         adcCsb         => adcCsb,          -- [out]
         adcSclk        => adcSclk,         -- [out]
         adcSdio        => adcSdio,         -- [inout]
         adcPdwn        => adcPdwn,         -- [out]
         locI2cScl      => locI2cScl,       -- [inout]
         locI2cSda      => locI2cSda,       -- [inout]
         sfpI2cScl      => sfpI2cScl,       -- [inout]
         sfpI2cSda      => sfpI2cSda,       -- [inout]
         qsfpI2cScl     => qsfpI2cScl,      -- [inout]
         qsfpI2cSda     => qsfpI2cSda,      -- [inout]
         qsfpI2cResetL  => qsfpI2cResetL,   -- [inout]
         digPmBusScl    => digPmBusScl,     -- [inout]
         digPmBusSda    => digPmBusSda,     -- [inout]
         digPmBusAlertL => digPmBusAlertL,  -- [in]
         anaPmBusScl    => anaPmBusScl,     -- [inout]
         anaPmBusSda    => anaPmBusSda,     -- [inout]
         anaPmBusAlertL => anaPmBusAlertL,  -- [in]
         hyPwrI2cScl    => hyPwrI2cScl,     -- [inout]
         hyPwrI2cSda    => hyPwrI2cSda,     -- [inout]
         hyPwrEnOut     => hyPwrEnOut,      -- [out]
         hyClkP         => hyClkP,          -- [out]
         hyClkN         => hyClkN,          -- [out]
         hyTrgP         => hyTrgP,          -- [out]
         hyTrgN         => hyTrgN,          -- [out]
         hyRstL         => hyRstL,          -- [out]
         hyI2cScl       => hyI2cScl,        -- [out]
         hyI2cSdaOut    => hyI2cSdaOut,     -- [out]
         hyI2cSdaIn     => hyI2cSdaIn,      -- [in]
         vauxp          => vauxp,           -- [in]
         vauxn          => vauxn,           -- [in]
         leds           => leds);           -- [out]


   U_LdmxFebBoardModel_1 : entity ldmx.LdmxFebBoardModel
      generic map (
         TPD_G             => TPD_G,
         ADCS_G            => ADCS_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         gtRefClk185P   => gtRefClk185P,    -- [out]
         gtRefClk185N   => gtRefClk185N,    -- [out]
         gtRefClk250P   => gtRefClk250P,    -- [out]
         gtRefClk250N   => gtRefClk250N,    -- [out]
         sasGtTxP       => sasGtTxP,        -- [in]
         sasGtTxN       => sasGtTxN,        -- [in]
         sasGtRxP       => sasGtRxP,        -- [out]
         sasGtRxN       => sasGtRxN,        -- [out]
         qsfpGtTxP      => qsfpGtTxP,       -- [in]
         qsfpGtTxN      => qsfpGtTxN,       -- [in]
         qsfpGtRxP      => qsfpGtRxP,       -- [out]
         qsfpGtRxN      => qsfpGtRxN,       -- [out]
         sfpGtTxP       => sfpGtTxP,        -- [in]
         sfpGtTxN       => sfpGtTxN,        -- [in]
         sfpGtRxP       => sfpGtRxP,        -- [out]
         sfpGtRxN       => sfpGtRxN,        -- [out]
         adcFClkP       => adcFClkP,        -- [out]
         adcFClkN       => adcFClkN,        -- [out]
         adcDClkP       => adcDClkP,        -- [out]
         adcDClkN       => adcDClkN,        -- [out]
         adcDataP       => adcDataP,        -- [out]
         adcDataN       => adcDataN,        -- [out]
         adcClkP        => adcClkP,         -- [in]
         adcClkN        => adcClkN,         -- [in]
         adcCsb         => adcCsb,          -- [in]
         adcSclk        => adcSclk,         -- [in]
         adcSdio        => adcSdio,         -- [inout]
         adcPdwn        => adcPdwn,         -- [in]
         locI2cScl      => locI2cScl,       -- [inout]
         locI2cSda      => locI2cSda,       -- [inout]
         sfpI2cScl      => sfpI2cScl,       -- [inout]
         sfpI2cSda      => sfpI2cSda,       -- [inout]
         qsfpI2cScl     => qsfpI2cScl,      -- [inout]
         qsfpI2cSda     => qsfpI2cSda,      -- [inout]
         qsfpI2cResetL  => qsfpI2cResetL,   -- [inout]
         digPmBusScl    => digPmBusScl,     -- [inout]
         digPmBusSda    => digPmBusSda,     -- [inout]
         digPmBusAlertL => digPmBusAlertL,  -- [out]
         anaPmBusScl    => anaPmBusScl,     -- [inout]
         anaPmBusSda    => anaPmBusSda,     -- [inout]
         anaPmBusAlertL => anaPmBusAlertL,  -- [out]
         hyPwrI2cScl    => hyPwrI2cScl,     -- [inout]
         hyPwrI2cSda    => hyPwrI2cSda,     -- [inout]
         hyPwrEnOut     => hyPwrEnOut,      -- [in]
         hyClkP         => hyClkP,          -- [in]
         hyClkN         => hyClkN,          -- [in]
         hyTrgP         => hyTrgP,          -- [in]
         hyTrgN         => hyTrgN,          -- [in]
         hyRstL         => hyRstL,          -- [in]
         hyI2cScl       => hyI2cScl,        -- [in]
         hyI2cSdaOut    => hyI2cSdaOut,     -- [in]
         hyI2cSdaIn     => hyI2cSdaIn,      -- [out]
         vauxp          => vauxp,           -- [out]
         vauxn          => vauxn,           -- [out]
         leds           => leds);           -- [in]


end architecture sim;



