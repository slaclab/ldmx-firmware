-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : HpsFeb.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-08-22
-- Last update: 2021-06-23
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.I2cPkg.all;

library ldmx;
use ldmx.AdcReadoutPkg.all;
use ldmx.HpsPkg.all;
--use ldmx.FebConfigPkg.all;
use ldmx.HpsFebHwPkg.all;

entity HpsFeb is

   generic (
      TPD_G                 : time                        := 1 ns;
      BUILD_INFO_G          : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G          : boolean                     := false;
      ROGUE_SIM_EN_G        : boolean                     := false;
      ROGUE_SIM_SIMEBAND_G  : boolean                     := false;
      ROGUE_SIM_CTRL_PORT_G : integer range 1024 to 49151 := 9000;
      ROGUE_SIM_DATA_PORT_G : integer range 1024 to 49141 := 9100;
      HYBRIDS_G             : integer                     := 4;
      APVS_PER_HYBRID_G     : integer                     := 5);
   port (
      -- GTP Reference Clocks
      gtRefClk371P : in sl;
      gtRefClk371N : in sl;
      gtRefClk250P : in sl;
      gtRefClk250N : in sl;

      -- Fixed Latency GTP link
      ctrlGtTxP : out sl;
      ctrlGtTxN : out sl;
      ctrlGtRxP : in  sl;
      ctrlGtRxN : in  sl;

--       dataGtTxP : out sl;
--       dataGtTxN : out sl;
--       dataGtRxP : in  sl;
--       dataGtRxN : in  sl;

      -- ADC Data Interface
      adcClkP  : out slv(HYBRIDS_G-1 downto 0);  -- 37 MHz clock to ADC
      adcClkN  : out slv(HYBRIDS_G-1 downto 0);
      adcFClkP : in  slv(HYBRIDS_G-1 downto 0);
      adcFClkN : in  slv(HYBRIDS_G-1 downto 0);
      adcDClkP : in  slv(HYBRIDS_G-1 downto 0);
      adcDClkN : in  slv(HYBRIDS_G-1 downto 0);
      adcDataP : in  slv5Array(HYBRIDS_G-1 downto 0);
      adcDataN : in  slv5Array(HYBRIDS_G-1 downto 0);

      -- ADC Config Interface
      adcCsb  : out   slv(HYBRIDS_G-1 downto 0);
      adcSclk : out   slv(HYBRIDS_G-1 downto 0);
      adcSdio : inout slv(HYBRIDS_G-1 downto 0);

      -- Amp I2C Interface
      ampI2cScl : inout sl;
      ampI2cSda : inout sl;

      -- Board I2C Interface
      boardI2cScl : inout sl;
      boardI2cSda : inout sl;

      -- Board SPI Interface
      boardSpiSclk : out sl;
      boardSpiSdi  : out sl;
      boardSpiSdo  : in  sl;
      boardSpiCsL  : out slv(4 downto 0);

      -- Hybrid power control
      hyPwrEn : out slv(HYBRIDS_G-1 downto 0);

      -- Interface to Hybrids
      hyClkP      : out slv(HYBRIDS_G-1 downto 0);
      hyClkN      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgP      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgN      : out slv(HYBRIDS_G-1 downto 0);
      hyRstL      : out slv(HYBRIDS_G-1 downto 0);
      hyI2cScl    : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaOut : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaIn  : in  slv(HYBRIDS_G-1 downto 0);

      -- XADC Interface
      vAuxP : in slv(15 downto 0);
      vAuxN : in slv(15 downto 0);
      vPIn  : in sl;
      vNIn  : in sl;

      powerGood : in PowerGoodType;

      leds : out slv(7 downto 0);       -- Test outputs

      -- Boot PROM interface
      bootCsL  : out sl;
      bootMosi : out sl;
      bootMiso : in  sl

      );

end entity HpsFeb;

architecture rtl of HpsFeb is


   -------------------------------------------------------------------------------------------------
   -- Clock Signals
   -------------------------------------------------------------------------------------------------
   signal daqRefClk  : sl;
   signal daqRefClkG : sl;

   signal axilClk : sl;
   signal axilRst : sl;

   signal gtRefClk125  : sl;
   signal gtRefClk125G : sl;
   signal gtRefRst125  : sl;

   signal clk200 : sl;
   signal rst200 : sl;

   signal daqClk185   : sl;
   signal daqRst185   : sl;
   signal daqFcWord   : slv(7 downto 0);
   signal daqFcValid  : sl;
   signal daqClk37    : sl;
   signal daqClk37Rst : sl;


   signal fpgaReload     : sl;
   signal fpgaReloadAddr : slv(31 downto 0);


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
         addrBits          => 20,
         connectivity      => X"0001"),
      PGP_AXI_INDEX_C      => (
         baseAddr          => PGP_AXI_BASE_ADDR_C,
         addrBits          => 14,
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
   signal dataClk : sl;
   signal dataRst : sl;

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
   signal hyPwrEnL   : slv(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Hybrid I2c Signals
   -------------------------------------------------------------------------------------------------
   signal hyI2cIn  : i2c_in_array(HYBRIDS_G-1 downto 0);
   signal hyI2cOut : i2c_out_array(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AdcReadout Signals
   -------------------------------------------------------------------------------------------------
   signal adcChips          : AdcChipOutArray(HYBRIDS_G-1 downto 0);
   -------------------------------------------------------------------------------------------------
   -- AdcReadout Signals
   -------------------------------------------------------------------------------------------------
   signal adcReadoutStreams : AdcStreamArray;

   signal sysRxLink  : sl;
   signal sysTxLink  : sl;
   signal dataTxLink : sl;


   signal ledEn   : sl;
   signal ledsInt : slv(7 downto 0);




begin

   leds <= ledsInt when ledEn = '1' else (others => '0');




   -------------------------------------------------------------------------------------------------
   -- Create global clocks from gt ref clocks
   -------------------------------------------------------------------------------------------------
   U_CtrlClockManager7 : entity surf.ClockManager7
      generic map (
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 2,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 8.0,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 8.0,
         CLKOUT0_DIVIDE_F_G => 8.0,
         CLKOUT0_RST_HOLD_G => 100,
         CLKOUT1_DIVIDE_G   => 5,
         CLKOUT1_RST_HOLD_G => 5,
         CLKOUT2_DIVIDE_G   => 10,
         CLKOUT2_RST_HOLD_G => 100)
      port map (
         clkIn     => gtRefClk125G,
         rstIn     => gtRefRst125,
         clkOut(0) => axilClk,
         clkOut(1) => clk200,
         rstOut(0) => axilRst,
         rstOut(1) => rst200);



   -------------------------------------------------------------------------------------------------
   -- LED Test Outputs
   -------------------------------------------------------------------------------------------------
   Heartbeat_1 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.0E-9,
         PERIOD_OUT_G => 0.8)
      port map (
         clk => axilClk,
         o   => ledsInt(0));

   Heartbeat_2 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 5.0E-9,
         PERIOD_OUT_G => 0.5)
      port map (
         clk => gtRefClk125G,
         o   => ledsInt(1));


   Heartbeat_3 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.0E-9,
         PERIOD_OUT_G => 0.8)
      port map (
         clk => daqClk185,
         rst => daqRst185,
         o   => ledsInt(2));

   ledsInt(3) <= daqRst185;

--   ledsInt(2) <= '0';

--   OBUF_LED3 : OBUF
--      port map (
--         i => hyTrgOut(0),
--         o => ledsInt(3));


--   Heartbeat_4 : entity surf.Heartbeat
--      generic map (
--         TPD_G        => TPD_G,
--         PERIOD_IN_G  => 24.0E-9,
--         PERIOD_OUT_G => 3.0)
--      port map (
--         clk => adcClkOut(0),
--         rst => '0',
--         o   => ledsInt(6));

--   Heartbeat_5 : entity surf.Heartbeat
--      generic map (
--         TPD_G        => TPD_G,
--         PERIOD_IN_G  => 24.0E-9,
--         PERIOD_OUT_G => 3.0)
--      port map (
--         clk => hyClkOut(0),
--         rst => '0',
--         o   => ledsInt(7));



   -------------------------------------------------------------------------------------------------
   -- PGP Interface 
   -------------------------------------------------------------------------------------------------
   U_HpsFebPgp_1 : entity ldmx.HpsFebPgp
      generic map (
         TPD_G             => TPD_G,
         ROGUE_SIM_G       => ROGUE_SIM_EN_G,
         ROGUE_CTRL_PORT_G => ROGUE_SIM_CTRL_PORT_G,
         ROGUE_DATA_PORT_G => ROGUE_SIM_DATA_PORT_G,
         AXIL_BASE_ADDR_G  => MAIN_XBAR_CFG_C(PGP_AXI_INDEX_C).baseAddr)
      port map (
         gtRefClk371P     => gtRefClk371P,                          -- [in]
         gtRefClk371N     => gtRefClk371N,                          -- [in]
         gtRefClk250P     => gtRefClk250P,                          -- [in]
         gtRefClk250N     => gtRefClk250N,                          -- [in]
         gtRefClk125      => gtRefClk125G,                          -- [out]
         gtRefRst125      => gtRefRst125,                           -- [out]
         ctrlGtTxP        => ctrlGtTxP,                             -- [out]
         ctrlGtTxN        => ctrlGtTxN,                             -- [out]
         ctrlGtRxP        => ctrlGtRxP,                             -- [in]
         ctrlGtRxN        => ctrlGtRxN,                             -- [in]
--          dataGtTxP        => dataGtTxP,                             -- [out]
--          dataGtTxN        => dataGtTxN,                             -- [out]
--          dataGtRxP        => dataGtRxP,                             -- [in]
--          dataGtRxN        => dataGtRxN,                             -- [in]
         ctrlTxLink       => ledsInt(6),                            -- [out]
         ctrlRxLink       => ledsInt(7),                            -- [out]
         dataTxLink       => open,                                  -- [out]
         daqClk           => daqClk185,                             -- [out]
         daqRst           => daqRst185,                             -- [out]
         daqRxFcWord      => daqFcWord,                             -- [out]
         daqRxFcValid     => daqFcValid,                            -- [out]
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
   hyPwrEn <= hyPwrEnInt;
   U_FebCore_1 : entity ldmx.FebCore
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
         AXI_BASE_ADDR_G   => MAIN_XBAR_CFG_C(FEB_CORE_AXI_INDEX_C).baseAddr)
      port map (
         daqClk185         => daqClk185,                                  -- [in]
         daqRst185         => daqRst185,                                  -- [in]
         daqFcWord         => daqFcWord,                                  -- [in]
         daqFcValid        => daqFcValid,                                 -- [in]
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
   -- HW
   -------------------------------------------------------------------------------------------------
   U_HpsFebHw_1 : entity ldmx.HpsFebHw
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
         AXI_BASE_ADDR_G   => MAIN_XBAR_CFG_C(FEB_HW_AXI_INDEX_C).baseAddr)
      port map (
         adcClkP           => adcClkP,                                  -- [out]
         adcClkN           => adcClkN,                                  -- [out]
         adcFClkP          => adcFClkP,                                 -- [in]
         adcFClkN          => adcFClkN,                                 -- [in]
         adcDClkP          => adcDClkP,                                 -- [in]
         adcDClkN          => adcDClkN,                                 -- [in]
         adcDataP          => adcDataP,                                 -- [in]
         adcDataN          => adcDataN,                                 -- [in]
         adcCsb            => adcCsb,                                   -- [out]
         adcSclk           => adcSclk,                                  -- [out]
         adcSdio           => adcSdio,                                  -- [inout]
         ampI2cScl         => ampI2cScl,                                -- [inout]
         ampI2cSda         => ampI2cSda,                                -- [inout]
         boardI2cScl       => boardI2cScl,                              -- [inout]
         boardI2cSda       => boardI2cSda,                              -- [inout]
         boardSpiSclk      => boardSpiSclk,                             -- [out]
         boardSpiSdi       => boardSpiSdi,                              -- [out]
         boardSpiSdo       => boardSpiSdo,                              -- [in]
         boardSpiCsL       => boardSpiCsL,                              -- [out]
         hyClkP            => hyClkP,                                   -- [out]
         hyClkN            => hyClkN,                                   -- [out]
         hyTrgP            => hyTrgP,                                   -- [out]
         hyTrgN            => hyTrgN,                                   -- [out]
         hyRstL            => hyRstL,                                   -- [out]
         hyI2cScl          => hyI2cScl,                                 -- [out]
         hyI2cSdaOut       => hyI2cSdaOut,                              -- [out]
         hyI2cSdaIn        => hyI2cSdaIn,                               -- [in]
         vPIn              => vPIn,                                     -- [in]
         vNIn              => vNIn,                                     -- [in]
         vAuxP             => vAuxP,                                    -- [in]
         vAuxN             => vAuxN,                                    -- [in]
         powerGood         => powerGood,                                -- [in]
         leds              => leds,                                     -- [out]
         bootCsL           => bootCsL,                                  -- [out]
         bootMosi          => bootMosi,                                 -- [out]
         bootMiso          => bootMiso,                                 -- [in]
         clk200            => clk200,                                   -- [in]
         rst200            => rst200,                                   -- [in]
         axilClk           => axilClk,                                  -- [in]
         axilRst           => axilRst,                                  -- [in]
         sAxilWriteMaster  => locAxilWriteMasters(FEB_HW_AXI_INDEX_C),  -- [in]
         sAxilWriteSlave   => locAxilWriteSlaves(FEB_HW_AXI_INDEX_C),   -- [out]
         sAxilReadMaster   => locAxilReadMasters(FEB_HW_AXI_INDEX_C),   -- [in]
         sAxilReadSlave    => locAxilReadSlaves(FEB_HW_AXI_INDEX_C),    -- [out]
         hyPwrEn           => hyPwrEnInt,                               -- [in]
         hyTrgOut          => hyTrgOut,                                 -- [in]
         hyRstOutL         => hyRstOutL,                                -- [in]
         hyI2cIn           => hyI2cIn,                                  -- [in]
         hyI2cOut          => hyI2cOut,                                 -- [out]
         adcReadoutStreams => adcReadoutStreams,                        -- [out]
         daqClk37          => daqClk37,                                 -- [in]
         daqClk37Rst       => daqClk37Rst,                              -- [in]
         hyClk             => hyClk,
         hyClkRst          => hyClkRst);





end architecture rtl;
