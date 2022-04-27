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

library ldmx;
use ldmx.AdcReadoutPkg.all;
use ldmx.HpsPkg.all;
use ldmx.HpsFebConfigPkg.all;


entity HpsFeb is

   generic (
      TPD_G                 : time                        := 1 ns;
      BUILD_INFO_G          : BuildInfoType               := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G          : boolean                     := false;
      ROGUE_SIM_EN_G        : boolean                     := false;
      ROGUE_SIM_SIMEBAND_G  : boolean                     := false;
      ROGUE_SIM_CTRL_PORT_G : integer range 1024 to 49151 := 9000;
      ROGUE_SIM_DATA_PORT_G : integer range 1024 to 49141 := 9100;
      HYBRIDS_G             : integer                     := 1;
      APVS_PER_HYBRID_G                                   := 5);
   port (
      -- GTP Reference Clocks
      gtRefClk186P : in sl;
      gtRefClk186N : in sl;
      gtRefClk250P : in sl;
      gtRefClk250N : in sl;

      -- Fixed Latency GTP link
      sysGtTxP : out sl;
      sysGtTxN : out sl;
      sysGtRxP : in  sl;
      sysGtRxN : in  sl;

      dataGtTxP : out sl;
      dataGtTxN : out sl;
      dataGtRxP : in  sl;
      dataGtRxN : in  sl;

      -- ADC Data Interface
      adcClkP  : out slv(HYBRIDS_G-1 downto 0);   -- 37 MHz clock to ADC
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
   signal gtRefClk186  : sl;
   signal gtRefClk186G : sl;
   signal gtRefClk250  : sl;
   signal daqRefClk    : sl;
   signal daqRefClkG   : sl;

   signal axiClk        : sl;
   signal axiRst        : sl;
   signal axiClkMmcmRst : sl;
   signal semClk        : sl;
   signal semClkRst     : sl;

   signal daqClk186     : sl;
   signal daqClk186Rst  : sl;
   signal daqOpCode     : slv(7 downto 0);
   signal daqOpCodeEn   : sl;
   signal clk250MmcmRst : sl;
   signal clk200        : sl;
   signal clk200Rst     : sl;
   signal pgpDataClk    : sl;
   signal pgpDataClkRst : sl;
   signal clk250        : sl;
   signal clk250Rst     : sl;

   signal powerOnReset   : sl;
   signal fpgaReload     : sl;
   signal fpgaReloadAddr : slv(31 downto 0);

   attribute IODELAY_GROUP                 : string;
   attribute IODELAY_GROUP of IDELAYCTRL_0 : label is "IDELAYCTRL0";
   attribute IODELAY_GROUP of IDELAYCTRL_1 : label is "IDELAYCTRL1";

   -------------------------------------------------------------------------------------------------
   -- AXI Signals
   -------------------------------------------------------------------------------------------------

   constant NUM_AXI_MASTERS_C : natural := 4;

   constant FEB_CORE_AXI_INDEX_C : natural := 0;
   constant VERSION_AXI_INDEX_C  : natural := 1;
   constant PGP_AXI_INDEX_C      : natural := 2;
   constant PROM_AXI_INDEX_C     : natural := 3;
   constant SEM_AXI_INDEX_C      : natural := 4;

   constant FEB_CORE_AXI_BASE_ADDR_C : slv(31 downto 0) := X"00000000";
   constant VERSION_AXI_BASE_ADDR_C  : slv(31 downto 0) := X"00200000";
   constant PGP_AXI_BASE_ADDR_C      : slv(31 downto 0) := X"00210000";
   constant PROM_AXI_BASE_ADDR_C     : slv(31 downto 0) := X"00800000";
   constant SEM_AXI_BASE_ADDR_C      : slv(31 downto 0) := X"00801000";

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      FEB_CORE_AXI_INDEX_C => (         -- Front End IO Core
         baseAddr          => FEB_CORE_AXI_BASE_ADDR_C,
         addrBits          => 21,
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
   signal adcChips : AdcChipOutArray(HYBRIDS_G-1 downto 0);

   signal sysRxLink  : sl;
   signal sysTxLink  : sl;
   signal dataTxLink : sl);


   signal ledEn   : sl;
   signal ledsInt : slv(7 downto 0);

   signal febConfig : HpsFebConfigType;

   signal bootSck : sl;

begin

   leds <= ledsInt when ledEn = '1' else (others => '0');




   -------------------------------------------------------------------------------------------------
   -- Create global clocks from gt ref clocks
   -------------------------------------------------------------------------------------------------
   axiClkMmcmRst <= powerOnReset;

   U_CtrlClockManager7 : entity surf.ClockManager7
      generic map (
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 3,
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
         rstIn     => axiClkMmcmRst,
         clkOut(0) => axiClk,
         clkOut(1) => clk200,
         clkOut(2) => semClk,
         rstOut(0) => axiRst,
         rstOut(1) => clk200Rst,
         rstOut(2) => semClkRst);


   clk250MmcmRst <= powerOnReset;

   U_DataClockManager7 : entity surf.ClockManager7
      generic map (
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => true,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 2,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 4.0,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => DATA_MMCM_CFG_C.CLKFBOUT_MULT_F_G,
         CLKOUT0_DIVIDE_F_G => DATA_MMCM_CFG_C.CLKOUT0_DIVIDE_F_G,
         CLKOUT0_RST_HOLD_G => DATA_MMCM_CFG_C.CLKOUT0_RST_HOLD_G,
         CLKOUT1_DIVIDE_G   => DATA_MMCM_CFG_C.CLKOUT1_DIVIDE_G,
         CLKOUT1_RST_HOLD_G => DATA_MMCM_CFG_C.CLKOUT1_RST_HOLD_G)
      port map (
         clkIn     => gtRefClk250,
         rstIn     => clk250MmcmRst,
         clkOut(0) => clk250,
         clkOut(1) => pgpDataClk,
         rstOut(0) => clk250Rst,
         rstOut(1) => pgpDataClkRst);


   -------------------------------------------------------------------------------------------------
   -- LED Test Outputs
   -------------------------------------------------------------------------------------------------
   Heartbeat_1 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.0E-9,
         PERIOD_OUT_G => 0.8)
      port map (
         clk => axiClk,
         o   => ledsInt(0));

   Heartbeat_2 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 5.0E-9,
         PERIOD_OUT_G => 0.5)
      port map (
         clk => pgpDataClk,
         o   => ledsInt(1));


   Heartbeat_3 : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.0E-9,
         PERIOD_OUT_G => 0.8)
      port map (
         clk => daqClk125,
         rst => daqClk125Rst,
         o   => ledsInt(2));

   ledsInt(3) <= daqClk125Rst;

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
   -- 2 IDELAYCTRL Instances Needed
   -------------------------------------------------------------------------------------------------
   IDELAYCTRL_0 : IDELAYCTRL
      port map (
         RDY    => open,
         REFCLK => clk200,
         RST    => clk200Rst);

   IDELAYCTRL_1 : IDELAYCTRL
      port map (
         RDY    => open,
         REFCLK => clk200,
         RST    => clk200Rst);

   -------------------------------------------------------------------------------------------------
   -- PGP Interface 
   -------------------------------------------------------------------------------------------------
   U_HpsFebPgp_1: entity work.HpsFebPgp
      generic map (
         TPD_G             => TPD_G,
         ROGUE_SIM_G       => ROGUE_SIM_G,
         ROGUE_CTRL_PORT_G => ROGUE_CTRL_PORT_G,
         ROGUE_DATA_PORT_G => ROGUE_DATA_PORT_G,
         AXI_BASE_ADDR_G   => AXI_BASE_ADDR_G)
      port map (
         gtRefClk186P     => gtRefClk186P,      -- [in]
         gtRefClk186N     => gtRefClk186N,      -- [in]
         gtRefClk250P     => gtRefClk250P,      -- [in]
         gtRefClk250N     => gtRefClk250N,      -- [in]
         gtRefClk125      => gtRefClk125,       -- [out]
         gtRefRst125      => gtRefRst125,       -- [out]
         ctrlGtTxP        => ctrlGtTxP,         -- [out]
         ctrlGtTxN        => ctrlGtTxN,         -- [out]
         ctrlGtRxP        => ctrlGtRxP,         -- [in]
         ctrlGtRxN        => ctrlGtRxN,         -- [in]
         dataGtTxP        => dataGtTxP,         -- [out]
         dataGtTxN        => dataGtTxN,         -- [out]
         dataGtRxP        => dataGtRxP,         -- [in]
         dataGtRxN        => dataGtRxN,         -- [in]
         ctrlTxLink       => ledsInt(6),        -- [out]
         ctrlRxLink       => ledsInt(7),        -- [out]
         dataTxLink       => open,        -- [out]
         distClk          => daqClk,           -- [out]
         distRst          => daqRst,           -- [out]
         distRxFcWord     => daqOpCode,      -- [out]
         distRxFcValid    => daqOpCodeValid,     -- [out]
         axilClk          => axilClk,           -- [in]
         axilClkRst       => axilClkRst,        -- [in]
         mAxilReadMaster  => extAxilReadMaster,   -- [out]
         mAxilReadSlave   => extAxilReadSlave,    -- [in]
         mAxilWriteMaster => extAxilWriteMaster,  -- [out]
         mAxilWriteSlave  => extAxilWriteSlave,   -- [in]
         sAxilReadMaster       => locAxilReadMasters(PGP_AXI_INDEX_C),
         sAxilReadSlave        => locAxilReadSlaves(PGP_AXI_INDEX_C),
         sAxilWriteMaster      => locAxilWriteMasters(PGP_AXI_INDEX_C),
         sAxilWriteSlave       => locAxilWriteSlaves(PGP_AXI_INDEX_C),
         dataClk          => dataClk,           -- [in]
         dataRst          => dataRst,           -- [in]
         dataAxisMaster   => dataAxisMaster,    -- [in]
         dataAxisSlave    => dataAxisSlave,     -- [out]
         dataAxisCtrl     => dataAxisCtrl);     -- [out]
   


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
         axiClk              => axiClk,
         axiClkRst           => axiRst,
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
         EN_ICAP_G       => false)
      port map (
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => locAxilReadMasters(VERSION_AXI_INDEX_C),
         axiReadSlave   => locAxilReadSlaves(VERSION_AXI_INDEX_C),
         axiWriteMaster => locAxilWriteMasters(VERSION_AXI_INDEX_C),
         axiWriteSlave  => locAxilWriteSlaves(VERSION_AXI_INDEX_C),
         fpgaReload     => fpgaReload,
         fpgaReloadAddr => fpgaReloadAddr,
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
         port map (
            outEnL  => hyPwrEnIntL(i),
            clkIn   => hyClkOut(i),
            clkOutP => hyClkP(i),
            clkOutN => hyClkN(i));

      ADC_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
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
      adcChips(i).chP   <= "000" & adcDataP(i);
      adcChips(i).chN   <= "000" & adcDataN(i);

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
         axiClk         => axiClk,
         axiRst         => axiRst);

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


end architecture rtl;
