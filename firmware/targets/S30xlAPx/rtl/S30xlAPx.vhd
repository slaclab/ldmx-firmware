-------------------------------------------------------------------------------
-- Title      : S30XL APx Top Level
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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

library unisim;
use unisim.vcomponents.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.TriggerPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity S30xlAPx is

   generic (
      TPD_G                    : time                 := 1 ns;
      BUILD_INFO_G             : BuildInfoType        := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G             : boolean              := false;
      SIM_SRP_PORT_NUM_G       : integer              := 9000;
      SIM_RAW_DATA_PORT_NUM_G  : integer              := 9100;
      SIM_TRIG_DATA_PORT_NUM_G : integer              := 9200;
      DHCP_G                   : boolean              := false;  -- true = DHCP, false = static address
      IP_ADDR_G                : slv(31 downto 0)     := x"0A0AA8C0";  -- 192.168.10.10 (before DHCP)
      MAC_ADDR_G               : slv(47 downto 0)     := x"00_00_16_56_00_08";
      TS_LANES_G               : integer              := 2;
      TS_REFCLKS_G             : integer              := 1;
      TS_REFCLK_MAP_G          : IntegerArray         := (0 => 0, 1 => 0);  -- Map a refclk index to each fiber
      FC_HUB_REFCLKS_G         : integer range 1 to 4 := 1;
      FC_HUB_QUADS_G           : integer range 1 to 4 := 1;
      FC_HUB_QUAD_REFCLK_MAP_G : IntegerArray         := (0 => 0));  --, 1 => 0, 2 => 1, 3 => 1));  -- Map a refclk for each quad


   port (
      ----------------------------------------------------------------------------------------------
      -- Clock 125MHz Passthrough
      ----------------------------------------------------------------------------------------------
      clk125InP  : in  sl;
      clk125InN  : in  sl;
      clk125OutP : out slv(1 downto 0);
      clk125OutN : out slv(1 downto 0);

      ----------------------------------------------------------------------------------------------
      -- LCLS Timing Interface
      ----------------------------------------------------------------------------------------------
      -- 185 MHz Ref Clk for LCLS timing recovery
      lclsTimingRefClkP    : in  sl;
      lclsTimingRefClkN    : in  sl;
      -- LCLS-II timing interface
      lclsTimingRxP        : in  sl;
      lclsTimingRxN        : in  sl;
      lclsTimingTxP        : out sl;
      lclsTimingTxN        : out sl;
      -- Recovered Clock output for jitter cleaning
      lclsTimingRecClkOutP : out slv(1 downto 0);
      lclsTimingRecClkOutN : out slv(1 downto 0);

      ----------------------------------------------------------------------------------------------
      -- FC HUB Interface
      -- Refclks are jitter cleaned lclsTimingRefClkOut
      ----------------------------------------------------------------------------------------------
      fcHubRefClkP : in  slv(FC_HUB_REFCLKS_G-1 downto 0);
      fcHubRefClkN : in  slv(FC_HUB_REFCLKS_G-1 downto 0);
      fcHubTxP     : out slv(FC_HUB_QUADS_G*4-1 downto 0);
      fcHubTxN     : out slv(FC_HUB_QUADS_G*4-1 downto 0);
      fcHubRxP     : in  slv(FC_HUB_QUADS_G*4-1 downto 0);
      fcHubRxN     : in  slv(FC_HUB_QUADS_G*4-1 downto 0);

      ----------------------------------------------------------------------------------------------
      -- App FC Interface
      -- FC Receiver
      -- (Looped back from fcHub IO)
      -- Could use lclsTimingRefClk185 if QUAD is close enough
      ----------------------------------------------------------------------------------------------
      appFcRefClkP : in  sl;
      appFcRefClkN : in  sl;
      appFcRxP     : in  sl;
      appFcRxN     : in  sl;
      appFcTxP     : out sl;
      appFcTxN     : out sl;

      ----------------------------------------------------------------------------------------------
      -- App TS Interface
      ----------------------------------------------------------------------------------------------
      tsRefClk250P : in  slv(TS_REFCLKS_G-1 downto 0);
      tsRefClk250N : in  slv(TS_REFCLKS_G-1 downto 0);
      tsDataRxP    : in  slv(TS_LANES_G-1 downto 0);
      tsDataRxN    : in  slv(TS_LANES_G-1 downto 0);
      tsDataTxP    : out slv(TS_LANES_G-1 downto 0);
      tsDataTxN    : out slv(TS_LANES_G-1 downto 0);

      ----------------------------------------------------------------------------------------------
      -- Ethernet refclk and interface
      ----------------------------------------------------------------------------------------------
      ethRefClk156P : in  sl;
      ethRefClk156N : in  sl;
      ethTxP        : out sl;
      ethTxN        : out sl;
      ethRxP        : in  sl;
      ethRxN        : in  sl;

      ----------------------------------------------------------------------------------------------
      -- LEDS
      ----------------------------------------------------------------------------------------------
      rgbGreenLed : out sl := '0';
      rgbRedLed   : out sl := '0';
      rgbBlueLed  : out sl := '0';

      organgeLed : out sl := '0';
      greenLed   : out sl := '0'

      );

end entity S30xlAPx;

architecture rtl of S30xlAPx is

   constant AXIL_CLK_FREQ_C : real := 125.0e6;  --156.25e6;

   constant AXIL_NUM_C            : integer := 5;
   constant AXIL_VERSION_C        : integer := 0;
   constant AXIL_ETH_C            : integer := 1;
   constant AXIL_FC_HUB_C         : integer := 2;
   constant AXIL_GLOBAL_TRIGGER_C : integer := 3;
   constant AXIL_APP_CORE_C       : integer := 4;


   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_NUM_C-1 downto 0) := (
      AXIL_VERSION_C        => (
         baseAddr           => X"00000000",
         addrBits           => 12,
         connectivity       => X"FFFF"),
      AXIL_ETH_C            => (
         baseAddr           => X"10000000",
         addrBits           => 24,
         connectivity       => X"FFFF"),
      AXIL_FC_HUB_C         => (
         baseAddr           => X"20000000",
         addrBits           => 28,
         connectivity       => X"FFFF"),
      AXIL_GLOBAL_TRIGGER_C => (
         baseAddr           => X"30000000",
         addrBits           => 16,
         connectivity       => X"FFFF"),
      AXIL_APP_CORE_C       => (
         baseAddr           => X"80000000",
         addrBits           => 31,
         connectivity       => X"FFFF"));

   signal axilClk : sl;
   signal axilRst : sl;

   signal ethAxilReadMaster  : AxiLiteReadMasterType;
   signal ethAxilReadSlave   : AxiLiteReadSlaveType;
   signal ethAxilWriteMaster : AxiLiteWriteMasterType;
   signal ethAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_NUM_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_NUM_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal tsDaqRawAxisMaster  : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal tsDaqRawAxisSlave   : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
   signal tsDaqTrigAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal tsDaqTrigAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- Timing hub
   signal lclsTimingClk     : sl;
   signal lclsTimingRst     : sl;
   signal lclsTimingFcTxMsg : FcMessageType;
   signal lclsTimingBus     : TimingBusType;

   -- TS Trigger
   signal tsFcClk185             : sl;
   signal tsFcRst185             : sl;
   signal tsThresholdTriggerData : TriggerDataType;

   -- Gloabl Trigger
   signal gtRor           : FcTimestampType := FC_TIMESTAMP_INIT_C;
   signal gtDaqAxisMaster : AxiStreamMasterType;
   signal gtDaqAxisSlave  : AxiStreamSlaveType;

   signal clk125In        : sl;
   signal ethGtRefClk156G : sl;
   signal ethGtRefClk78G  : sl;
   signal ethGtRefRst78   : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- Clock 125MHz Passthrough
   -------------------------------------------------------------------------------------------------
   U_IBUFGDS_1 : IBUFGDS
      port map (
         i  => clk125InP,
         ib => clk125InN,
         o  => clk125In);

   GEN_CLKOUT_125 : for i in 1 downto 0 generate
      U_ClkOutBufDiff_1 : entity surf.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            clkIn   => clk125In,        -- [in]
            clkOutP => clk125OutP(i),   -- [out]
            clkOutN => clk125OutN(i));  -- [out]
   end generate GEN_CLKOUT_125;

   -------------------------------------------------------------------------------------------------
   -- Select AXIL Clock
   -------------------------------------------------------------------------------------------------
   axilClk <= clk125In;                 --ethGtRefClk156G;

   U_RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G         => TPD_G,
         OUT_REG_RST_G => true)
      port map (
         clk      => axilClk,           -- [in]
         asyncRst => '0',               -- [in]
         syncRst  => axilRst);          -- [out]

   -------------------------------------------------------------------------------------------------
   -- LED
   -------------------------------------------------------------------------------------------------
   Heartbeat_axilClk : entity surf.Heartbeat
      generic map (
         TPD_G        => TPD_G,
         PERIOD_IN_G  => 8.0E-9,
         PERIOD_OUT_G => 0.8)
      port map (
         clk => axilClk,
         o   => rgbGreenLed);

   -------------------------------------------------------------------------------------------------
   -- Top Level AXI-Lite crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_NUM_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => ethAxilWriteMaster,
         sAxiWriteSlaves(0)  => ethAxilWriteSlave,
         sAxiReadMasters(0)  => ethAxilReadMaster,
         sAxiReadSlaves(0)   => ethAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Ethernet Interface
   -- Provides AXI-Lite for register access
   -- Provides AXI-Stream for DAQ data
   -- Outputs AXIL clock
   -------------------------------------------------------------------------------------------------
   U_TenGigEthGtyCore_1 : entity ldmx_ts.S30xlEthCore
      generic map (
         TPD_G                    => TPD_G,
         SIMULATION_G             => SIMULATION_G,
         SIM_SRP_PORT_NUM_G       => SIM_SRP_PORT_NUM_G,
         SIM_RAW_DATA_PORT_NUM_G  => SIM_RAW_DATA_PORT_NUM_G,
         SIM_TRIG_DATA_PORT_NUM_G => SIM_TRIG_DATA_PORT_NUM_G,
         AXIL_BASE_ADDR_G         => AXIL_XBAR_CONFIG_C(AXIL_ETH_C).baseAddr,
         DHCP_G                   => DHCP_G,
         IP_ADDR_G                => IP_ADDR_G,
         MAC_ADDR_G               => MAC_ADDR_G)
      port map (
         extRst              => '0',    -- [in] -- might need PwrUpRst here
         ethGtRefClkP        => ethRefClk156P,                    -- [in]
         ethGtRefClkN        => ethRefClk156N,                    -- [in]
         ethGtRefClk156G     => ethGtRefClk156G,                  -- [out]
         ethGtRefClk78G      => ethGtRefClk78G,                   -- [out]
         ethRxP              => ethRxP,                           -- [in]
         ethRxN              => ethRxN,                           -- [in]
         ethTxP              => ethTxP,                           -- [out]
         ethTxN              => ethTxN,                           -- [out]
         phyReady            => open,   -- [out]
         rssiStatus          => open,   -- [out]
         axilClk             => axilClk,                          -- [in]
         axilRst             => axilRst,                          -- [in]
         mAxilReadMaster     => ethAxilReadMaster,                -- [out]
         mAxilReadSlave      => ethAxilReadSlave,                 -- [in]
         mAxilWriteMaster    => ethAxilWriteMaster,               -- [out]
         mAxilWriteSlave     => ethAxilWriteSlave,                -- [in]
         sAxilReadMaster     => locAxilReadMasters(AXIL_ETH_C),   -- [in]
         sAxilReadSlave      => locAxilReadSlaves(AXIL_ETH_C),    -- [out]
         sAxilWriteMaster    => locAxilWriteMasters(AXIL_ETH_C),  -- [in]
         sAxilWriteSlave     => locAxilWriteSlaves(AXIL_ETH_C),   -- [out]
         axisClk             => axilClk,                          -- [in]
         axisRst             => axilRst,                          -- [in]
         tsDaqRawAxisMaster  => tsDaqRawAxisMaster,               -- [in]
         tsDaqRawAxisSlave   => tsDaqRawAxisSlave,                -- [out]
         tsDaqTrigAxisMaster => tsDaqTrigAxisMaster,              -- [in]
         tsDaqTrigAxisSlave  => tsDaqTrigAxisSlave);              -- [out]

   -------------------------------------------------------------------------------------------------
   -- Create stableclk reset
   -------------------------------------------------------------------------------------------------
   U_RstSync_2 : entity surf.RstSync
      generic map (
         TPD_G         => TPD_G,
         OUT_REG_RST_G => true)
      port map (
         clk      => ethGtRefClk78G,    -- [in]
         asyncRst => '0',               -- [in]
         syncRst  => ethGtRefRst78);    -- [out]

   -------------------------------------------------------------------------------------------------
   -- AXI Version
   -------------------------------------------------------------------------------------------------
   U_AxiVersion_1 : entity surf.AxiVersion
      generic map (
         TPD_G           => TPD_G,
         BUILD_INFO_G    => BUILD_INFO_G,
         CLK_PERIOD_G    => (1.0/AXIL_CLK_FREQ_C),               --6.4E-9,
         XIL_DEVICE_G    => "ULTRASCALE_PLUS",
         EN_DEVICE_DNA_G => true,
         EN_DS2411_G     => false,
         EN_ICAP_G       => false,
         USE_SLOWCLK_G   => false,
         BUFR_CLK_DIV_G  => 8)
      port map (
         axiClk         => axilClk,                              -- [in]
         axiRst         => axilRst,                              -- [in]
         axiReadMaster  => locAxilReadMasters(AXIL_VERSION_C),   -- [in]
         axiReadSlave   => locAxilReadSlaves(AXIL_VERSION_C),    -- [out]
         axiWriteMaster => locAxilWriteMasters(AXIL_VERSION_C),  -- [in]
         axiWriteSlave  => locAxilWriteSlaves(AXIL_VERSION_C));  -- [out] 

   -------------------------------------------------------------------------------------------------
   -- Global Trigger
   -------------------------------------------------------------------------------------------------
   U_S30xlGlobalTrigger_1 : entity ldmx_tdaq.S30xlGlobalTrigger
      generic map (
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CONFIG_C(AXIL_GLOBAL_TRIGGER_C).baseAddr)
      port map (
         fcClk185             => tsFcClk185,                                  -- [in]
         fcRst185             => tsFcRst185,                                  -- [in]
         thresholdTriggerData => tsThresholdTriggerData,                      -- [in]
         lclsTimingClk        => lclsTimingClk,                               -- [in]
         lclsTimingRst        => lclsTimingRst,                               -- [in]
         lclsTimingFcTxMsg    => lclsTimingFcTxMsg,                           -- [in]
         lclsTimingBus        => lclsTimingBus,                               -- [in]
         gtRor                => gtRor,                                       -- [out]
         gtDaqAxisMaster      => gtDaqAxisMaster,                             -- [out]
         gtDaqAxisSlave       => gtDaqAxisSlave,                              -- [in]
         axilClk              => axilClk,                                     -- [in]
         axilRst              => axilRst,                                     -- [in]
         axilReadMaster       => locAxilReadMasters(AXIL_GLOBAL_TRIGGER_C),   -- [in]
         axilReadSlave        => locAxilReadSlaves(AXIL_GLOBAL_TRIGGER_C),    -- [out]
         axilWriteMaster      => locAxilWriteMasters(AXIL_GLOBAL_TRIGGER_C),  -- [in]
         axilWriteSlave       => locAxilWriteSlaves(AXIL_GLOBAL_TRIGGER_C));  -- [out]


   -------------------------------------------------------------------------------------------------
   -- Timing Hub
   -------------------------------------------------------------------------------------------------
   U_FcHub_1 : entity ldmx_tdaq.FcHub
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIMULATION_G,
         REFCLKS_G         => FC_HUB_REFCLKS_G,
         QUADS_G           => FC_HUB_QUADS_G,
         QUAD_REFCLK_MAP_G => FC_HUB_QUAD_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(AXIL_FC_HUB_C).baseAddr)
      port map (
         lclsTimingStableClk78 => ethGtRefClk78G,                      -- [in]
         lclsTimingStableRst   => ethGtRefRst78,                       -- [in]
         lclsTimingRefClkP     => lclsTimingRefClkP,                   -- [in]
         lclsTimingRefClkN     => lclsTimingRefClkN,                   -- [in]
         lclsTimingRxP         => lclsTimingRxP,                       -- [in]
         lclsTimingRxN         => lclsTimingRxN,                       -- [in]
         lclsTimingTxP         => lclsTimingTxP,                       -- [out]
         lclsTimingTxN         => lclsTimingTxN,                       -- [out]
         lclsTimingClkOut      => lclsTimingClk,                       -- [out]
         lclsTimingRstOut      => lclsTimingRst,                       -- [out]
         lclsTimingFcTxMsg     => lclsTimingFcTxMsg,                   -- [out]
         lclsTimingBus         => lclsTimingBus,                       -- [out]
         globalTriggerRor      => gtRor,                               -- [in]
         fcHubRefClkP          => fcHubRefClkP,                        -- [in]
         fcHubRefClkN          => fcHubRefClkN,                        -- [in]
         fcHubTxP              => fcHubTxP,                            -- [out]
         fcHubTxN              => fcHubTxN,                            -- [out]
         fcHubRxP              => fcHubRxP,                            -- [in]
         fcHubRxN              => fcHubRxN,                            -- [in]
         axilClk               => axilClk,                             -- [in]
         axilRst               => axilRst,                             -- [in]
         axilReadMaster        => locAxilReadMasters(AXIL_FC_HUB_C),   -- [in]
         axilReadSlave         => locAxilReadSlaves(AXIL_FC_HUB_C),    -- [out]
         axilWriteMaster       => locAxilWriteMasters(AXIL_FC_HUB_C),  -- [in]
         axilWriteSlave        => locAxilWriteSlaves(AXIL_FC_HUB_C));  -- [out]

   GEN_LCLS_CLK_OUT : for i in 1 downto 0 generate
      U_ClkOutBufDiff_2 : entity surf.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            clkIn   => lclsTimingClk,             -- [in]
            clkOutP => lclsTimingRecClkOutP(i),   -- [out]
            clkOutN => lclsTimingRecClkOutN(i));  -- [out]
   end generate GEN_LCLS_CLK_OUT;

   -------------------------------------------------------------------------------------------------
   -- S30XL Application Core
   -------------------------------------------------------------------------------------------------
   U_S30xlAppCore_1 : entity ldmx_ts.S30xlAppCore
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIMULATION_G,
         TS_LANES_G       => TS_LANES_G,
         TS_REFCLKS_G     => TS_REFCLKS_G,
         TS_REFCLK_MAP_G  => TS_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CONFIG_C(AXIL_APP_CORE_C).baseAddr)
      port map (
         appFcRefClkP         => appFcRefClkP,                          -- [in]
         appFcRefClkN         => appFcRefClkN,                          -- [in]
         appFcRxP             => appFcRxP,                              -- [in]
         appFcRxN             => appFcRxN,                              -- [in]
         appFcTxP             => appFcTxP,                              -- [out]
         appFcTxN             => appFcTxN,                              -- [out]
         tsRefClk250P         => tsRefClk250P,                          -- [in]
         tsRefClk250N         => tsRefClk250N,                          -- [in]
         tsDataRxP            => tsDataRxP,                             -- [in]
         tsDataRxN            => tsDataRxN,                             -- [in]
         tsDataTxP            => tsDataTxP,                             -- [out]
         tsDataTxN            => tsDataTxN,                             -- [out]
         axilClk              => axilClk,                               -- [in]
         axilRst              => axilRst,                               -- [in]
         axilReadMaster       => locAxilReadMasters(AXIL_APP_CORE_C),   -- [in]
         axilReadSlave        => locAxilReadSlaves(AXIL_APP_CORE_C),    -- [out]
         axilWriteMaster      => locAxilWriteMasters(AXIL_APP_CORE_C),  -- [in]
         axilWriteSlave       => locAxilWriteSlaves(AXIL_APP_CORE_C),   -- [out]
         fcClk185Out          => tsFcClk185,                            -- [out]
         fcRst185Out          => tsFcRst185,                            -- [out]
         thresholdTriggerData => tsThresholdTriggerData,                -- [out]
         axisClk              => axilClk,                               -- [in]
         axisRst              => axilRst,                               -- [in]
         tsDaqRawAxisMaster   => tsDaqRawAxisMaster,                    -- [out]
         tsDaqRawAxisSlave    => tsDaqRawAxisSlave,                     -- [in]
         tsDaqTrigAxisMaster  => tsDaqTrigAxisMaster,                   -- [out]
         tsDaqTrigAxisSlave   => tsDaqTrigAxisSlave);                   -- [in]

end architecture rtl;
