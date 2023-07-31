-------------------------------------------------------------------------------
-- Title      : LdmxFeb
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: LDMX FEB top level
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;
use surf.I2cPkg.all;
use surf.Pgp2bPkg.all;
use surf.Ad9249Pkg.all;

library ldmx;
use ldmx.HpsPkg.all;

entity LdmxFeb is

   generic (
      TPD_G                : time                        := 1 ns;
      BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G         : boolean                     := false;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_SIDEBAND_G : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : integer range 1024 to 49151 := 9000;
      ADCS_G               : integer                     := 4;
      HYBRIDS_G            : integer                     := 8;
      APVS_PER_HYBRID_G    : integer                     := 6);

   port (
      -- Reference clocks for PGP MGTs
      gtRefClk185P : in sl;
      gtRefClk185N : in sl;
      gtRefClk250P : in sl;
      gtRefClk250N : in sl;

      -- MGT IO
      sasGtTxP : out slv(3 downto 0);
      sasGtTxN : out slv(3 downto 0);
      sasGtRxP : in  slv(3 downto 0);
      sasGtRxN : in  slv(3 downto 0);

      qsfpGtTxP : out slv(3 downto 0);
      qsfpGtTxN : out slv(3 downto 0);
      qsfpGtRxP : in  slv(3 downto 0);
      qsfpGtRxN : in  slv(3 downto 0);

      sfpGtTxP : out sl;
      sfpGtTxN : out sl;
      sfpGtRxP : in  sl;
      sfpGtRxN : in  sl;

      -- ADC DDR Interface 
      adcFClkP : in slv(HYBRIDS_G-1 downto 0);
      adcFClkN : in slv(HYBRIDS_G-1 downto 0);
      adcDClkP : in slv(HYBRIDS_G-1 downto 0);
      adcDClkN : in slv(HYBRIDS_G-1 downto 0);
      adcDataP : in slv6Array(HYBRIDS_G-1 downto 0);
      adcDataN : in slv6Array(HYBRIDS_G-1 downto 0);

      -- ADC Clock
      adcClkP : out slv(ADCS_G-1 downto 0);  -- 37 MHz clock to ADC
      adcClkN : out slv(ADCS_G-1 downto 0);

      -- ADC Config Interface
      adcCsb  : out   slv(ADCS_G*2-1 downto 0);
      adcSclk : out   slv(ADCS_G-1 downto 0);
      adcSdio : inout slv(ADCS_G-1 downto 0);
      adcPdwn : out   slv(ADCS_G-1 downto 0);

      -- I2C Interfaces
      locI2cScl : inout sl;
      locI2cSda : inout sl;

      sfpI2cScl : inout sl;
      sfpI2cSda : inout sl;

      qsfpI2cScl    : inout sl;
      qsfpI2cSda    : inout sl;
      qsfpI2cResetL : inout sl := '1';

      digPmBusScl    : inout sl;
      digPmBusSda    : inout sl;
      digPmBusAlertL : in    sl;

      anaPmBusScl    : inout sl;
      anaPmBusSda    : inout sl;
      anaPmBusAlertL : in    sl;

      hyPwrI2cScl : inout slv(HYBRIDS_G-1 downto 0);
      hyPwrI2cSda : inout slv(HYBRIDS_G-1 downto 0);

      hyPwrEnOut : out slv(HYBRIDS_G-1 downto 0);

      -- Interface to Hybrids
      hyClkP      : out slv(HYBRIDS_G-1 downto 0);
      hyClkN      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgP      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgN      : out slv(HYBRIDS_G-1 downto 0);
      hyRstL      : out slv(HYBRIDS_G-1 downto 0);
      hyI2cScl    : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaOut : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaIn  : in  slv(HYBRIDS_G-1 downto 0);

      vauxp : in slv(3 downto 0);
      vauxn : in slv(3 downto 0);

      leds : out slv(7 downto 0) := "01010101");  -- Test outputs

end entity LdmxFeb;

architecture rtl of LdmxFeb is

   -------------------------------------------------------------------------------------------------
   -- Clock Signals
   -------------------------------------------------------------------------------------------------
   signal userRefClk125 : sl;
   signal userRefRst125 : sl;
--    signal clk250        : sl;
--    signal rst250        : sl;

   signal axilClk : sl;
   signal axilRst : sl;

   signal daqClk185    : sl;
   signal daqRst185    : sl;
   signal daqRxFcWord  : slv(79 downto 0);
   signal daqRxFcValid : sl;
   signal daqClk37     : sl;
   signal daqClk37Rst  : sl;

   -------------------------------------------------------------------------------------------------
   -- PGP Remap
   -------------------------------------------------------------------------------------------------
   signal pgpGtTxP : slv(1 downto 0);
   signal pgpGtTxN : slv(1 downto 0);
   signal pgpGtRxP : slv(1 downto 0);
   signal pgpGtRxN : slv(1 downto 0);


--    signal fpgaReload     : sl;
--    signal fpgaReloadAddr : slv(31 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AXI Signals
   -------------------------------------------------------------------------------------------------
   constant NUM_AXI_MASTERS_C : natural := 3;

   constant FEB_CORE_AXI_INDEX_C : natural := 0;
   constant FEB_HW_AXI_INDEX_C   : natural := 1;
   constant PGP_AXI_INDEX_C      : natural := 2;

   constant FEB_CORE_AXI_BASE_ADDR_C : slv(31 downto 0) := X"00000000";
   constant FEB_HW_AXI_BASE_ADDR_C   : slv(31 downto 0) := X"10000000";
   constant PGP_AXI_BASE_ADDR_C      : slv(31 downto 0) := X"20000000";


   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      FEB_CORE_AXI_INDEX_C => (         -- Front End IO Core
         baseAddr          => FEB_CORE_AXI_BASE_ADDR_C,
         addrBits          => 28,
         connectivity      => X"0001"),
      FEB_HW_AXI_INDEX_C   => (         -- Front End IO Core
         baseAddr          => FEB_HW_AXI_BASE_ADDR_C,
         addrBits          => 28,
         connectivity      => X"0001"),
      PGP_AXI_INDEX_C      => (
         baseAddr          => PGP_AXI_BASE_ADDR_C,
         addrBits          => 28,
         connectivity      => X"0001"));

   signal extAxilWriteMaster : AxiLiteWriteMasterType;
   signal extAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal extAxilReadMaster  : AxiLiteReadMasterType;
   signal extAxilReadSlave   : AxiLiteReadSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   -------------------------------------------------------------------------------------------------
   -- Data Streams
   -------------------------------------------------------------------------------------------------
--    signal dataClk             : sl;
--    signal dataRst             : sl;

   signal eventAxisMaster : AxiStreamMasterType;
   signal eventAxisSlave  : AxiStreamSlaveType;
   signal eventAxisCtrl   : AxiStreamCtrlType;

   -------------------------------------------------------------------------------------------------
   -- Shifted Clocks
   -------------------------------------------------------------------------------------------------
   signal hyClk      : slv(HYBRIDS_G-1 downto 0);
   signal hyClkRst   : slv(HYBRIDS_G-1 downto 0);
   signal hyTrgOut   : slv(HYBRIDS_G-1 downto 0);
   signal hyRstOutL  : slv(HYBRIDS_G-1 downto 0);
   signal hyPwrEnInt : slv(HYBRIDS_G-1 downto 0);


   -------------------------------------------------------------------------------------------------
   -- Hybrid I2c Signals
   -------------------------------------------------------------------------------------------------
   signal hyI2cIn  : i2c_in_array(HYBRIDS_G-1 downto 0);
   signal hyI2cOut : i2c_out_array(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AdcReadout Signals
   -------------------------------------------------------------------------------------------------
   signal adcReadoutStreams : AdcStreamArray;


   signal ledEn   : sl;
   signal ledsInt : slv(7 downto 0);

begin

--    leds <= ledsInt when ledEn = '1' else (others => '0');
--    sfpGtTxP    <= pgpGtTxP(0);
--    sfpGtTxN    <= pgpGtTxN(0);
--    pgpGtRxP(0) <= sfpGtRxP;
--    pgpGtRxN(0) <= sfpGtRxN;

--    sasGtTxP    <= pgpGtTxP(0);
--    sasGtTxN    <= pgpGtTxN(0);
--    pgpGtRxP(0) <= sasGtRxP;
--    pgpGtRxN(0) <= sasGtRxN;



   -------------------------------------------------------------------------------------------------
   -- Create local clocks
   -------------------------------------------------------------------------------------------------
   axilClk <= userRefClk125;
   axilRst <= userRefRst125;
--    U_ClockManager1 : entity surf.ClockManagerUltrascale
--       generic map (
--          TPD_G            => TPD_G,
--          TYPE_G           => "PLL",
--          INPUT_BUFG_G     => false,
--          FB_BUFG_G        => true,
--          NUM_CLOCKS_G     => 2,
--          BANDWIDTH_G      => "OPTIMIZED",
--          CLKIN_PERIOD_G   => 4.0,
--          DIVCLK_DIVIDE_G  => 1,
--          CLKFBOUT_MULT_G  => 3,
--          CLKOUT0_DIVIDE_G => 3,
--          CLKOUT1_DIVIDE_G => 6)
-- --         CLKOUT0_RST_HOLD_G => 100,
-- --         CLKOUT1_DIVIDE_G   => 10,
-- --         CLKOUT1_RST_HOLD_G => 5,
-- --         CLKOUT2_DIVIDE_G   => 8)
-- --         CLKOUT2_RST_HOLD_G => 100)
--       port map (
--          clkIn     => userRefClk250,
--          rstIn     => userRefRst250,
--          clkOut(0) => clk250,
--          clkOut(1) => axilClk,
-- --         clkOut(2) => clk156,
--          rstOut(0) => rst250,
--          rstOut(1) => axilRst);
-- --         rstOut(2) => rst156);


   -------------------------------------------------------------------------------------------------
   -- LED Test Outputs
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- PGP Interface
   -------------------------------------------------------------------------------------------------
   U_LdmxFebPgp_1 : entity ldmx.LdmxFebPgp
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_SIDEBAND_G => ROGUE_SIM_SIDEBAND_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         AXIL_BASE_ADDR_G     => MAIN_XBAR_CFG_C(PGP_AXI_INDEX_C).baseAddr,
         AXIL_CLK_FREQ_G      => 125.0e6)
      port map (
         gtRefClk185P     => gtRefClk185P,                          -- [in]
         gtRefClk185N     => gtRefClk185N,                          -- [in]
         gtRefClk250P     => gtRefClk250P,                          -- [in]
         gtRefClk250N     => gtRefClk250N,                          -- [in]
         pgpGtRxP(0)      => sfpGtRxP,                              -- [in]
         pgpGtRxP(1)      => sasGtRxP(0),                           -- [in]
         pgpGtRxP(2)      => qsfpGtRxP(0),                          -- [in]         
         pgpGtRxN(0)      => sfpGtRxN,                              -- [in]
         pgpGtRxN(1)      => sasGtRxN(0),                           -- [in]
         pgpGtRxN(2)      => qsfpGtRxN(0),                          -- [in]
         pgpGtTxP(0)      => sfpGtTxP,                              -- [out]
         pgpGtTxP(1)      => sasGtTxP(0),                           -- [out]
         pgpGtTxP(2)      => qsfpGtTxP(0),                          -- [out]
         pgpGtTxN(0)      => sfpGtTxN,                              -- [out]
         pgpGtTxN(1)      => sasGtTxN(0),                           -- [out]
         pgpGtTxN(2)      => qsfpGtTxN(0),                          -- [out]
         userRefClk125    => userRefClk125,                         -- [out]
         userRefRst125    => userRefRst125,                         -- [out]         
         pgpTxLink        => open,                                  -- [out]
         pgpRxLink        => open,                                  -- [out]
         daqClk           => daqClk185,                             -- [in]
         daqRst           => daqRst185,                             -- [in]
         daqRxFcWord      => daqRxFcWord,                           -- [out]
         daqRxFcValid     => daqRxFcValid,                          -- [out]
         axilClk          => axilClk,                               -- [in]
         axilRst          => axilRst,                               -- [in]
         mAxilReadMaster  => extAxilReadMaster,                     -- [out]
         mAxilReadSlave   => extAxilReadSlave,                      -- [in]
         mAxilWriteMaster => extAxilWriteMaster,                    -- [out]
         mAxilWriteSlave  => extAxilWriteSlave,                     -- [in]
         sAxilReadMaster  => locAxilReadMasters(PGP_AXI_INDEX_C),   -- [in]
         sAxilReadSlave   => locAxilReadSlaves(PGP_AXI_INDEX_C),    -- [out]
         sAxilWriteMaster => locAxilWriteMasters(PGP_AXI_INDEX_C),  -- [in]
         sAxilWriteSlave  => locAxilWriteSlaves(PGP_AXI_INDEX_C),   -- [out]
         dataClk          => axilClk,                               -- [in]
         dataRst          => axilRst,                               -- [in]
         dataAxisMaster   => eventAxisMaster,                       -- [in]
         dataAxisSlave    => eventAxisSlave,                        -- [out]
         dataAxisCtrl     => eventAxisCtrl);                        -- [out]



   -------------------------------------------------------------------------------------------------
   -- Top Axi Crossbar
   -------------------------------------------------------------------------------------------------
   TopAxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => MAIN_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => extAxilWriteMaster,
         sAxiWriteSlaves(0)  => extAxilWriteSlave,
         sAxiReadMasters(0)  => extAxilReadMaster,
         sAxiReadSlaves(0)   => extAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Front End Core
   -------------------------------------------------------------------------------------------------
   U_FebCore_1 : entity ldmx.FebCore
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         XIL_DEVICE_G      => "ULTRASCALE_PLUS",
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
         AXI_BASE_ADDR_G   => MAIN_XBAR_CFG_C(FEB_CORE_AXI_INDEX_C).baseAddr)
      port map (
         daqClk185         => daqClk185,                                  -- [in]
         daqRst185         => daqRst185,                                  -- [in]
         daqFcWord         => daqRxFcWord,                                -- [in]
         daqFcValid        => daqRxFcValid,                               -- [in]
         axilClk           => axilClk,                                    -- [in]
         axilRst           => axilRst,                                    -- [in]
         sAxilWriteMaster  => locAxilWriteMasters(FEB_CORE_AXI_INDEX_C),  -- [in]
         sAxilWriteSlave   => locAxilWriteSlaves(FEB_CORE_AXI_INDEX_C),   -- [out]
         sAxilReadMaster   => locAxilReadMasters(FEB_CORE_AXI_INDEX_C),   -- [in]
         sAxilReadSlave    => locAxilReadSlaves(FEB_CORE_AXI_INDEX_C),    -- [out]
         eventAxisMaster   => eventAxisMaster,                            -- [out]
         eventAxisSlave    => eventAxisSlave,                             -- [in]
         eventAxisCtrl     => eventAxisCtrl,                              -- [in]
         hyPwrEn           => hyPwrEnInt,                                 -- [out]
         hyTrgOut          => hyTrgOut,                                   -- [out]
         hyRstOutL         => hyRstOutL,                                  -- [out]
         hyI2cIn           => hyI2cIn,                                    -- [in]
         hyI2cOut          => hyI2cOut,                                   -- [out]
         daqClk37          => daqClk37,                                   -- [out]
         daqClk37Rst       => daqClk37Rst,                                -- [out]
         hyClk             => hyClk,                                      -- [in]
         hyClkRst          => hyClkRst,                                   -- [in]
         adcReadoutStreams => adcReadoutStreams);                         -- [in]

   -------------------------------------------------------------------------------------------------
   -- FEB Hardware
   -------------------------------------------------------------------------------------------------
   U_LdmxFebHw_1 : entity ldmx.LdmxFebHw
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         ADCS_G            => ADCS_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
         AXIL_CLK_FREQ_G   => 125.0e6,
         AXIL_BASE_ADDR_G  => MAIN_XBAR_CFG_C(FEB_HW_AXI_INDEX_C).baseAddr)
      port map (
         adcFClkP          => adcFClkP,                                 -- [in]
         adcFClkN          => adcFClkN,                                 -- [in]
         adcDClkP          => adcDClkP,                                 -- [in]
         adcDClkN          => adcDClkN,                                 -- [in]
         adcDataP          => adcDataP,                                 -- [in]
         adcDataN          => adcDataN,                                 -- [in]
         adcClkP           => adcClkP,                                  -- [out]
         adcClkN           => adcClkN,                                  -- [out]
         adcCsb            => adcCsb,                                   -- [out]
         adcSclk           => adcSclk,                                  -- [out]
         adcSdio           => adcSdio,                                  -- [inout]
         locI2cScl         => locI2cScl,                                -- [inout]
         locI2cSda         => locI2cSda,                                -- [inout]
         sfpI2cScl         => sfpI2cScl,                                -- [inout]
         sfpI2cSda         => sfpI2cSda,                                -- [inout]
         qsfpI2cScl        => qsfpI2cScl,                               -- [inout]
         qsfpI2cSda        => qsfpI2cSda,                               -- [inout]
         qsfpI2cResetL     => qsfpI2cResetL,                            -- [out]
         digPmBusScl       => digPmBusScl,                              -- [inout]
         digPmBusSda       => digPmBusSda,                              -- [inout]
         digPmBusAlertL    => digPmBusAlertL,                           -- [inout]
         anaPmBusScl       => anaPmBusScl,                              -- [inout]
         anaPmBusSda       => anaPmBusSda,                              -- [inout]
         anaPmBusAlertL    => anaPmBusAlertL,                           -- [inout]
         hyPwrI2cScl       => hyPwrI2cScl,                              -- [inout]
         hyPwrI2cSda       => hyPwrI2cSda,                              -- [inout]
         hyPwrEnOut        => hyPwrEnOut,                               -- [out]
         hyClkP            => hyClkP,                                   -- [out]
         hyClkN            => hyClkN,                                   -- [out]
         hyTrgP            => hyTrgP,                                   -- [out]
         hyTrgN            => hyTrgN,                                   -- [out]
         hyRstL            => hyRstL,                                   -- [out]
         hyI2cScl          => hyI2cScl,                                 -- [out]
         hyI2cSdaOut       => hyI2cSdaOut,                              -- [out]
         hyI2cSdaIn        => hyI2cSdaIn,                               -- [in]
--         leds              => leds,                                     -- [out]
         vauxp             => vauxp,                                    -- [in]
         vauxn             => vauxn,                                    -- [in]
         axilClk           => axilClk,                                  -- [in]
         axilRst           => axilRst,                                  -- [in]
         sAxilWriteMaster  => locAxilWriteMasters(FEB_HW_AXI_INDEX_C),  -- [in]
         sAxilWriteSlave   => locAxilWriteSlaves(FEB_HW_AXI_INDEX_C),   -- [out]
         sAxilReadMaster   => locAxilReadMasters(FEB_HW_AXI_INDEX_C),   -- [in]
         sAxilReadSlave    => locAxilReadSlaves(FEB_HW_AXI_INDEX_C),    -- [out]
         hyPwrEn           => hyPwrEnInt,                               -- [in]
         hyTrgOut          => hyTrgOut,                                 -- [in]
         hyRstOutL         => hyRstOutL,                                -- [in]
         hyI2cIn           => hyI2cIn,                                  -- [out]
         hyI2cOut          => hyI2cOut,                                 -- [in]
         adcReadoutStreams => adcReadoutStreams,                        -- [out]
         daqClk37          => daqClk37,                                 -- [in]
         daqClk37Rst       => daqClk37Rst,                              -- [in]
         hyClk             => hyClk,                                    -- [out]
         hyClkRst          => hyClkRst);                                -- [out]

end architecture rtl;
