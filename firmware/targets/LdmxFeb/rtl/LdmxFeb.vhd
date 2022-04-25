-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Feb.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-08-22
-- Last update: 2022-01-10
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
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;
use surf.I2cPkg.all;
use surf.Pgp2bPkg.all;
use surf.Ad9249Pkg.all;


library hps_daq;

use hps_daq.XilCoresPkg.all;
use hps_daq.HpsPkg.all;
use hps_daq.FebConfigPkg.all;

entity LdmxFeb is

   generic (
      TPD_G                : time                        := 1 ns;
      BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G         : boolean                     := false;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_SIDEBAND_G : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : integer range 1024 to 49151 := 9000;
      HYBRIDS_G            : integer                     := 4;
      APVS_PER_HYBRID_G    : integer                     := 6);

   port (
      -- GT Timing Interface
      timingRefClkP : in  sl;
      timingRefClkN : in  sl;
      timingGtTxP   : out sl;
      timingGtTxN   : out sl;
      timingGtRxP   : in  sl;
      timingGtRxN   : in  sl;

      -- GT Data Interface
      pgpRefClkP : in  sl;
      pgpRefClkN : in  sl;
      pgpGtTxP   : out sl;
      pgpGtTxN   : out sl;
      pgpGtRxP   : in  sl;
      pgpGtRxN   : in  sl;

      -- ADC Data Interface
      adcClkP  : out slv(HYBRIDS_G-1 downto 0);  -- 41 MHz clock to ADC
      adcClkN  : out slv(HYBRIDS_G-1 downto 0);
      adcFClkP : in  slv(HYBRIDS_G-1 downto 0);
      adcFClkN : in  slv(HYBRIDS_G-1 downto 0);
      adcDClkP : in  slv(HYBRIDS_G-1 downto 0);
      adcDClkN : in  slv(HYBRIDS_G-1 downto 0);
      adcDataP : in  slv6Array(HYBRIDS_G-1 downto 0);
      adcDataN : in  slv6Array(HYBRIDS_G-1 downto 0);

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
      powerGood : in PowerGoodType;

      leds : out slv(7 downto 0);       -- Test outputs

      -- Boot PROM interface
      bootCsL  : out sl;
      bootMosi : out sl;
      bootMiso : in  sl

      );

end entity LdmxFeb;

architecture rtl of LdmxFeb is

   signal vauxp : slv(15 downto 0);
   signal vauxn : slv(15 downto 0);

   attribute keep_hierarchy        : string;
   attribute keep_hierarchy of rtl : architecture is "yes";


   -------------------------------------------------------------------------------------------------
   -- Clock Signals
   -------------------------------------------------------------------------------------------------
   signal pgpRefClk : sl;
   signal pgpRefRst : sl;

   -- Base clocks
   signal clk250 : sl;
   signal rst250 : sl;
   signal clk125 : sl;
   signal rst125 : sl;
   signal clk156 : sl;
   signal rst156 : sl;
   signal clk112 : sl;
   signal rst112 : sl;

--    attribute IODELAY_GROUP                 : string;
--    attribute IODELAY_GROUP of IDELAYCTRL_0 : label is "IDELAYCTRL0";
--    attribute IODELAY_GROUP of IDELAYCTRL_1 : label is "IDELAYCTRL1";


   -------------------------------------------------------------------------------------------------
   -- AXI Lite
   -------------------------------------------------------------------------------------------------

   constant NUM_AXI_MASTERS_C : natural := 5;

   constant FEB_CORE_AXI_INDEX_C : natural := 0;
   constant RCE_CORE_AXI_INDEX_C : natural := 1;
   constant VERSION_AXI_INDEX_C  : natural := 2;
   constant PGP_AXI_INDEX_C      : natural := 3;
   constant PROM_AXI_INDEX_C     : natural := 4;
   constant SEM_AXI_INDEX_C      : natural := 5;

   constant FEB_CORE_AXI_BASE_ADDR_C : slv(31 downto 0) := X"00000000";
   constant RCE_CORE_AXI_BASE_ADDR_C : slv(31 downto 0) := X"10000000";
   constant VERSION_AXI_BASE_ADDR_C  : slv(31 downto 0) := X"00200000";
   constant PGP_AXI_BASE_ADDR_C      : slv(31 downto 0) := X"00210000";
   constant PROM_AXI_BASE_ADDR_C     : slv(31 downto 0) := X"00800000";
   constant SEM_AXI_BASE_ADDR_C      : slv(31 downto 0) := X"00801000";

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      FEB_CORE_AXI_INDEX_C => (         -- Front End IO Core
         baseAddr          => FEB_CORE_AXI_BASE_ADDR_C,
         addrBits          => 21,
         connectivity      => X"0001"),
      RCE_CORE_AXI_INDEX_C => (
         baseAddr          => FEB_CORE_AXI_BASE_ADDR_C,
         addrBits          => 20,
         connectivity      => X"0001"),
      VERSION_AXI_INDEX_C  => (
         baseAddr          => VERSION_AXI_BASE_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      PGP_AXI_INDEX_C      => (
         baseAddr          => PGP_AXI_BASE_ADDR_C,
         addrBits          => 14,
         connectivity      => X"0001"),
      PROM_AXI_INDEX_C     => (
         baseAddr          => PROM_AXI_BASE_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"));
--       SEM_AXI_INDEX_C      => (
--          baseAddr          => SEM_AXI_BASE_ADDR_C,
--          addrBits          => 8,
--          connectivity      => X"0001"));


   signal axilClk : sl;
   signal axilRst : sl;

   signal extAxilWriteMaster : AxiLiteWriteMasterType;
   signal extAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal extAxilReadMaster  : AxiLiteReadMasterType;
   signal extAxilReadSlave   : AxiLiteReadSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal febConfig : FebConfigType;

   signal trigger          : sl;
   signal triggerFifoValid : sl;
   signal triggerFifoData  : slv(63 downto 0);
   signal triggerFifoRdEn  : sl;



   -------------------------------------------------------------------------------------------------
   -- DAQ timing and triggers
   -------------------------------------------------------------------------------------------------
   signal daqClk : sl;
   signal daqRst : sl;

   signal daqOpCode     : slv(7 downto 0);
   signal daqOpCodeLong : slv(9 downto 0);
   signal daqOpCodeEn   : sl;


   -------------------------------------------------------------------------------------------------
   -- Data Streams
   -------------------------------------------------------------------------------------------------
   signal dataClk : sl;
   signal dataRst : sl;

   signal hybridDataAxisMasters : AxiStreamQuadMasterArray(HYBRIDS_G-1 downto 0);
   signal hybridDataAxisSlaves  : AxiStreamQuadSlaveArray(HYBRIDS_G-1 downto 0);
   signal hybridDataAxisCtrl    : AxiStreamQuadCtrlArray(HYBRIDS_G-1 downto 0);
   signal syncStatuses          : slv8Array(HYBRIDS_G-1 downto 0);

   signal eventAxisMaster : AxiStreamMasterType;
   signal eventAxisSlave  : AxiStreamSlaveType;
   signal eventAxisCtrl   : AxiStreamCtrlType;


   -------------------------------------------------------------------------------------------------
   -- Shifted Clocks
   -------------------------------------------------------------------------------------------------
   signal adcClkOut   : slv(HYBRIDS_G-1 downto 0);
   signal hyClkOut    : slv(HYBRIDS_G-1 downto 0);
   signal hyTrgOut    : slv(HYBRIDS_G-1 downto 0);
   signal hyRstOutL   : slv(HYBRIDS_G-1 downto 0);
   signal hyPwrEnInt  : slv(HYBRIDS_G-1 downto 0);
   signal hyPwrEnIntL : slv(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Board I2C Signals
   -------------------------------------------------------------------------------------------------
   signal boardI2cIn  : i2c_in_type;
   signal boardI2cOut : i2c_out_type;

   -------------------------------------------------------------------------------------------------
   -- Hybrid I2c Signals
   -------------------------------------------------------------------------------------------------
   signal hyI2cIn  : i2c_in_array(HYBRIDS_G-1 downto 0);
   signal hyI2cOut : i2c_out_array(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AdcReadout Signals
   -------------------------------------------------------------------------------------------------
   signal adcChips : Ad9249SerialGroupArray(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- LEDS
   -------------------------------------------------------------------------------------------------
   signal ledEn   : sl;
   signal ledsInt : slv(7 downto 0) := (others => '0');

   -------------------------------------------------------------------------------------------------
   -- Flash prom 
   -------------------------------------------------------------------------------------------------
   signal bootSck : sl;

begin

   leds <= ledsInt when ledEn = '1' else (others => '0');

   -------------------------------------------------------------------------------------------------
   -- PGP Interface
   -- Outputs reference clock at 156.25 MHz for creation of local clocks
   -------------------------------------------------------------------------------------------------
   U_LdmxFebPgp_1 : entity hps_daq.LdmxFebPgp
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_SIDEBAND_G => ROGUE_SIM_SIDEBAND_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         AXIL_BASE_ADDR_G     => AXI_CROSSBAR_MASTERS_CONFIG_C(PGP_AXI_INDEX_C).baseAddr,
         AXIL_CLK_FREQ_G      => 125.0e6)
      port map (
         gtClkP           => pgpRefClkP,                            -- [in]
         gtClkN           => pgpRefClkN,                            -- [in]
         gtRxP            => pgpGtRxP,                              -- [in]
         gtRxN            => pgpGtRxN,                              -- [in]
         gtTxP            => pgpGtTxP,                              -- [out]
         gtTxN            => pgpGtTxN,                              -- [out]
         refClkOut        => pgpRefClk,                             -- [out]
         refRstOut        => pgpRefRst,                             -- [out]
         rxLinkReady      => open,                                  -- [out]
         txLinkReady      => open,                                  -- [out]
         distClk          => daqClk,                                -- [in]
         distRst          => daqRst,                                -- [in]
         distOpCodeEn     => daqOpCodeEn,                           -- [out]
         distOpCode       => daqOpCode,                             -- [out]
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
   -- Create local clocks
   -------------------------------------------------------------------------------------------------
   U_ClockManager1 : entity surf.ClockManagerUltrascale
      generic map (
         TPD_G            => TPD_G,
         TYPE_G           => "PLL",
         INPUT_BUFG_G     => false,
         FB_BUFG_G        => true,
         NUM_CLOCKS_G     => 1,
         BANDWIDTH_G      => "OPTIMIZED",
         CLKIN_PERIOD_G   => 6.4,
         DIVCLK_DIVIDE_G  => 1,
         CLKFBOUT_MULT_G  => 8,
         CLKOUT0_DIVIDE_G => 10)
--         CLKOUT0_RST_HOLD_G => 100,
--         CLKOUT1_DIVIDE_G   => 10,
--         CLKOUT1_RST_HOLD_G => 5,
--         CLKOUT2_DIVIDE_G   => 8)
--         CLKOUT2_RST_HOLD_G => 100)
      port map (
         clkIn     => pgpRefClk,
         rstIn     => pgpRefRst,        -- Might need pwrUpRst
         clkOut(0) => clk125,
--         clkOut(1) => clk125,
--         clkOut(2) => clk156,
         rstOut(0) => rst125);
--         rstOut(1) => rst125);
--         rstOut(2) => rst156);

   U_ClockManager2 : entity surf.ClockManagerUltrascale
      generic map (
         TPD_G            => TPD_G,
         TYPE_G           => "PLL",
         INPUT_BUFG_G     => false,
         FB_BUFG_G        => true,
         NUM_CLOCKS_G     => 1,
         BANDWIDTH_G      => "OPTIMIZED",
         CLKIN_PERIOD_G   => 8.0,
         DIVCLK_DIVIDE_G  => 1,
         CLKFBOUT_MULT_G  => 9,
         CLKOUT0_DIVIDE_G => 10)
      port map (
         clkIn     => clk125,
         rstIn     => rst125,           -- Might need pwrUpRst
         clkOut(0) => clk112,
         rstOut(0) => rst112);


   axilClk <= clk125;                   --clk156;
   axilRst <= rst125;                   --rst156;
--    dataClk <= clk125;
--    dataRst <= rst125;
   daqClk  <= clk112;
   daqRst  <= rst112;

   -------------------------------------------------------------------------------------------------
   -- LED Test Outputs
   -------------------------------------------------------------------------------------------------
   Heartbeat_1 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 4.0E-9,
         PERIOD_OUT_G => 0.4)
      port map (
         clk => clk250,
         o   => ledsInt(0));

   Heartbeat_2 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.0E-9,
         PERIOD_OUT_G => 0.8)
      port map (
         clk => clk125,
         o   => ledsInt(1));


   Heartbeat_3 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 6.4E-9,
         PERIOD_OUT_G => 0.64)
      port map (
         clk => clk156,
         o   => ledsInt(2));

   Heartbeat_4 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.8889e-9,
         PERIOD_OUT_G => 0.8889)
      port map (
         clk => clk112,
         o   => ledsInt(3));


   -------------------------------------------------------------------------------------------------
   -- Top Axi Crossbar
   -------------------------------------------------------------------------------------------------
   TopAxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
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
   -- Put version info on AXI Bus
   -------------------------------------------------------------------------------------------------
   AxiVersion_1 : entity surf.AxiVersion
      generic map (
         TPD_G           => TPD_G,
         BUILD_INFO_G    => BUILD_INFO_G,
         DEVICE_ID_G     => X"FEB00000",
         EN_DEVICE_DNA_G => true,
         EN_DS2411_G     => false,
         EN_ICAP_G       => true)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => locAxilReadMasters(VERSION_AXI_INDEX_C),
         axiReadSlave   => locAxilReadSlaves(VERSION_AXI_INDEX_C),
         axiWriteMaster => locAxilWriteMasters(VERSION_AXI_INDEX_C),
         axiWriteSlave  => locAxilWriteSlaves(VERSION_AXI_INDEX_C),
         fpgaReload     => open,        --fpgaReload,
         fpgaReloadAddr => open,        --fpgaReloadAddr,
         fdSerSdio      => open);

   -------------------------------------------------------------------------------------------------
   -- HPS Front End Core
   -------------------------------------------------------------------------------------------------
   hyPwrEn <= hyPwrEnInt;
   FebCore_1 : entity hps_daq.FebCore
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
         AXI_BASE_ADDR_G   => FEB_CORE_AXI_BASE_ADDR_C)
      port map (
         daqClk             => daqClk,
         daqRst             => daqRst,
         daqOpCode          => daqOpCode,
         daqOpCodeEn        => daqOpCodeEn,
         axilClk            => axilClk,
         axilRst            => axilRst,
         extAxilWriteMaster => locAxilWriteMasters(FEB_CORE_AXI_INDEX_C),
         extAxilWriteSlave  => locAxilWriteSlaves(FEB_CORE_AXI_INDEX_C),
         extAxilReadMaster  => locAxilReadMasters(FEB_CORE_AXI_INDEX_C),
         extAxilReadSlave   => locAxilReadSlaves(FEB_CORE_AXI_INDEX_C),
         adcChips           => adcChips,
         adcClkOut          => adcClkOut,
         eventAxisMaster    => eventAxisMaster,
         eventAxisSlave     => eventAxisSlave,
         eventAxisCtrl      => eventAxisCtrl,
         adcCsb             => adcCsb,
         adcSclk            => adcSclk,
         adcSdio            => adcSdio,
         ampI2cScl          => ampI2cScl,
         ampI2cSda          => ampI2cSda,
         boardI2cIn         => boardI2cIn,
         boardI2cOut        => boardI2cOut,
         boardSpiSclk       => boardSpiSclk,
         boardSpiSdi        => boardSpiSdi,
         boardSpiSdo        => boardSpiSdo,
         boardSpiCsL        => boardSpiCsL,
         hyPwrEn            => hyPwrEnInt,
         hyClkOut           => hyClkOut,
         hyTrgOut           => hyTrgOut,
         hyRstOutL          => hyRstOutL,
         hyI2cIn            => hyI2cIn,
         hyI2cOut           => hyI2cOut,
         vAuxP              => vAuxP,
         vAuxN              => vAuxN,
         powerGood          => powerGood,
         ledEn              => ledEn);

   -------------------------------------------------------------------------------------------------
   -- Data Processing
   -------------------------------------------------------------------------------------------------

--    U_RceCore_1 : entity hps_Daq.RceCore
--       generic map (
--          TPD_G             => TPD_G,
--          HYBRIDS_G         => 8,
--          APVS_PER_HYBRID_G => 6,
--          AXI_BASE_ADDR_G   => RCE_CORE_AXI_BASE_ADDR_C,
--          THRESHOLD_EN_G    => true,
--          ADF_DEBUG_EN_G    => true,
--          PACK_APV_DATA_G   => false)
--       port map (
--          dataClk               => dataClk,                                    -- [in]
--          dataClkRst            => dataRst,                                    -- [in]
--          syncStatuses          => syncStatuses,                               -- [in]
--          hybridDataAxisMasters => hybridDataAxisMasters,                      -- [in]
--          hybridDataAxisSlaves  => hybridDataAxisSlaves,                       -- [out]
--          sysClk                => axilClk,                                    -- [in]
--          sysRst                => axilRst,                                    -- [in]
--          sAxiReadMaster        => locAxilReadMasters(RCE_CORE_AXI_INDEX_C),   -- [in]
--          sAxiReadSlave         => locAxilReadSlaves(RCE_CORE_AXI_INDEX_C),    -- [out]
--          sAxiWriteMaster       => locAxilWriteMasters(RCE_CORE_AXI_INDEX_C),  -- [in]
--          sAxiWriteSlave        => locAxilWriteSlaves(RCE_CORE_AXI_INDEX_C),   -- [out]
--          trigger               => trigger,                                    -- [in]
--          triggerFifoValid      => triggerFifoValid,                           -- [in]
--          triggerFifoData       => triggerFifoData,                            -- [in]
--          triggerFifoRdEn       => triggerFifoRdEn,                            -- [out]
--          eventAxisMaster       => eventAxisMaster,                            -- [out]
--          eventAxisSlave        => eventAxisSlave,                             -- [in]
--          eventAxisCtrl         => eventAxisCtrl);                             -- [in]


   -------------------------------------------------------------------------------------------------
   -- IO Buffers for Shifted hybrid and ADC clocks, and triggers
   -------------------------------------------------------------------------------------------------
   DIFF_BUFF_GEN : for i in HYBRIDS_G-1 downto 0 generate
      hyRstL(i)      <= hyRstOutL(i) when hyPwrEnInt(i) = '1' else 'Z';
      hyPwrEnIntL(i) <= not hyPwrEnInt(i);

      HY_TRG_BUFF_DIFF : OBUFTDS
         port map (
            I  => hyTrgOut(i),
            T  => hyPwrEnIntL(i),
            O  => hyTrgP(i),
            OB => hyTrgN(i));

      HY_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
         generic map (
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            outEnL  => hyPwrEnIntL(i),
            clkIn   => hyClkOut(i),
            clkOutP => hyClkP(i),
            clkOutN => hyClkN(i));

      ADC_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
         generic map (
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            clkIn   => adcClkOut(i),
            clkOutP => adcClkP(i),
            clkOutN => adcClkN(i));
   end generate;



   -------------------------------------------------------------------------------------------------
   -- Board I2C Buffers
   -------------------------------------------------------------------------------------------------
   BOARD_SDA_IOBUFT : IOBUF
      port map (
         I  => boardI2cOut.sda,
         O  => boardI2cIn.sda,
         IO => boardI2cSda,
         T  => boardI2cOut.sdaoen);

   BOARD_SCL_IOBUFT : IOBUF
      port map (
         I  => boardI2cOut.scl,
         O  => boardI2cIn.scl,
         IO => boardI2cScl,
         T  => boardI2cOut.scloen);


   -------------------------------------------------------------------------------------------------
   -- Hybrid Axi Crossbars and attached devices
   -------------------------------------------------------------------------------------------------
   HY_AXI_GEN : for i in HYBRIDS_G-1 downto 0 generate

      -- IO Assignment to records
      adcChips(i).fClkP <= adcFClkP(i);
      adcChips(i).fClkN <= adcFClkN(i);
      adcChips(i).dClkP <= adcDClkP(i);
      adcChips(i).dClkN <= adcDClkN(i);
      adcChips(i).chP   <= "00" & adcDataP(i);
      adcChips(i).chN   <= "00" & adcDataN(i);

      -- Board has special I2C buffers needed to drive APV25 I2C, so do this wierd thing
      -- Output enable signals are active high
      hyI2cIn(i).scl <= hyI2cOut(i).scl when hyI2cOut(i).scloen = '1' else '1';
      hyI2cIn(i).sda <= to_x01z(hyI2cSdaIn(i));
      hyI2cSdaOut(i) <= hyI2cOut(i).sdaoen;
      hyI2cScl(i)    <= hyI2cOut(i).scloen;

   end generate HY_AXI_GEN;

   -------------------------------------------------------------------------------------------------
   -- FLASH Interface
   -------------------------------------------------------------------------------------------------
   U_SpiProm : entity surf.AxiMicronN25QCore
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => 125.0E+6,
         SPI_CLK_FREQ_G => (125.0E+6/12.0))
      port map (
         -- FLASH Memory Ports
         csL            => bootCsL,
         sck            => bootSck,
         mosi           => bootMosi,
         miso           => bootMiso,
         -- AXI-Lite Register Interface
         axiReadMaster  => locAxilReadMasters(PROM_AXI_INDEX_C),
         axiReadSlave   => locAxilReadSlaves(PROM_AXI_INDEX_C),
         axiWriteMaster => locAxilWriteMasters(PROM_AXI_INDEX_C),
         axiWriteSlave  => locAxilWriteSlaves(PROM_AXI_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   -----------------------------------------------------
   -- Using the STARTUPE2 to access the FPGA's CCLK port
   -----------------------------------------------------
   U_STARTUPE2 : STARTUPE2
      port map (
         CFGCLK    => open,             -- 1-bit output: Configuration main clock output
         CFGMCLK   => open,  -- 1-bit output: Configuration internal oscillator clock output
         EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,             -- 1-bit output: PROGRAM request to fabric output
         CLK       => '0',              -- 1-bit input: User start-up clock input
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',              -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => bootSck,          -- 1-bit input: User CCLK input
         USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => '1',              -- 1-bit input: User DONE pin output control
         USRDONETS => '1');             -- 1-bit input: User DONE 3-state enable output

-------------------------------------------------------------------------------------------------
-- SEM
-------------------------------------------------------------------------------------------------
--    FebSemWrapper_1 : entity hps_daq.FebSemWrapper
--       generic map (
--          TPD_G => TPD_G)
--       port map (
--          semClk          => semClk,
--          semClkRst       => semClkRst,
--          axilClk         => axilClk,
--          axilRst         => axilRst,
--          axilReadMaster  => locAxilReadMasters(SEM_AXI_INDEX_C),
--          axilReadSlave   => locAxilReadSlaves(SEM_AXI_INDEX_C),
--          axilWriteMaster => locAxilWriteMasters(SEM_AXI_INDEX_C),
--          axilWriteSlave  => locAxilWriteSlaves(SEM_AXI_INDEX_C),
--          febConfig       => febConfig,
--          fpgaReload      => fpgaReload,
--          fpgaReloadAddr  => fpgaReloadAddr,
--          axisClk         => axilClk,
--          axisRst         => axilRst,
--          semTxAxisMaster => semTxAxisMaster,
--          semTxAxisSlave  => semTxAxisSlave,
--          semRxAxisMaster => semRxAxisMaster,
--          semRxAxisSlave  => semRxAxisSlave);
end architecture rtl;
