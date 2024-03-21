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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library ldmx;
use ldmx.FcPkg.all;

entity S30xlAPx is

   generic (
      TPD_G                    : time                 := 1 ns;
      BUILD_INFO_G             : BuildInfoType        := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G             : boolean              := false;
      SIM_SRP_PORT_NUM_G       : integer              := 9000;
      SIM_DATA_PORT_NUM_G      : integer              := 9100;
      DHCP_G                   : boolean              := false;  -- true = DHCP, false = static address
      IP_ADDR_G                : slv(31 downto 0)     := x"0A01A8C0";  -- 192.168.1.10 (before DHCP)
      MAC_ADDR_G               : slv(47 downto 0)     := x"00_00_16_56_00_08";
      TS_LANES_G               : integer              := 2;
      TS_REFCLKS_G             : integer              := 1;
      TS_REFCLK_MAP_G          : IntegerArray         := (0 => 0, 1 => 0);  -- Map a refclk index to each fiber
      FC_HUB_REFCLKS_G         : integer range 1 to 4 := 2;
      FC_HUB_QUADS_G           : integer range 1 to 4 := 4;
      FC_HUB_QUAD_REFCLK_MAP_G : IntegerArray         := (0 => 0, 1 => 0, 2 => 1, 3 => 1));  -- Map a refclk for each quad


   port (
      ----------------------------------------------------------------------------------------------
      -- LCLS Timing Interface
      ----------------------------------------------------------------------------------------------
      -- 185 MHz Ref Clk for LCLS timing recovery
      lclsTimingRefClk185P : in  sl;
      lclsTimingRefClk185N : in  sl;
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
      lclsTimingRecClkInP : in  slv(FC_HUB_REFCLKS_G-1 downto 0);
      lclsTimingRecClkInN : in  slv(FC_HUB_REFCLKS_G-1 downto 0);
      fcHubTxP            : out slv(FC_HUB_QUADS_G*4-1 downto 0);
      fcHubTxN            : out slv(FC_HUB_QUADS_G*4-1 downto 0);
      fcHubRxP            : in  slv(FC_HUB_QUADS_G*4-1 downto 0);
      fcHubRxN            : in  slv(FC_HUB_QUADS_G*4-1 downto 0);

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
      tsRefClk250P : in slv(TS_REFCLKS_G-1 downto 0);
      tsRefClk250N : in slv(TS_REFCLKS_G-1 downto 0);
      tsDataRxP    : in slv(TS_LANES_G-1 downto 0);
      tsDataRxN    : in slv(TS_LANES_G-1 downto 0);

      ----------------------------------------------------------------------------------------------
      -- Ethernet refclk and interface
      ----------------------------------------------------------------------------------------------
      ethRefClk156P : in  sl;
      ethRefClk156N : in  sl;
      ethTxP        : out sl;
      ethTxN        : out sl;
      ethRxP        : in  sl;
      ethRxN        : in  sl

      );

end entity S30xlAPx;

architecture rtl of S30xlAPx is

   constant AXIL_CLK_FREQ_C : real := 156.25e6;

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
         addrBits           => 16,
         connectivity       => X"FFFF"),
      AXIL_FC_HUB_C         => (
         baseAddr           => X"20000000",
         addrBits           => 28,
         connectivity       => X"FFFF"),
      AXIL_GLOBAL_TRIGGER_C => (
         baseAddr           => X"30000000",
         addrBits           => 8,
         connectivity       => X"FFFF"),
      AXIL_APP_CORE_C       => (
         baseAddr           => X"40000000",
         addrBits           => 28,
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

   signal daqDataMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal daqDataSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- Timing hub
   signal lclsTimingClk : sl;
   signal lclsTimingRst : sl;

   -- Gloabl Trigger
   signal globalTriggerRor : FcTimestampType := FC_TIMESTAMP_INIT_C;


begin

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
   U_TenGigEthGtyCore_1 : entity ldmx.TenGigEthGtyCore
      generic map (
         TPD_G               => TPD_G,
         SIMULATION_G        => SIMULATION_G,
         SIM_SRP_PORT_NUM_G  => SIM_SRP_PORT_NUM_G,
         SIM_DATA_PORT_NUM_G => SIM_DATA_PORT_NUM_G,
         AXIL_BASE_ADDR_G    => AXIL_XBAR_CONFIG_C(AXIL_ETH_C).baseAddr,
         DHCP_G              => DHCP_G,
         IP_ADDR_G           => IP_ADDR_G,
         MAC_ADDR_G          => MAC_ADDR_G)
      port map (
         extRst           => '0',                              -- [in] -- might need PwrUpRst here
         ethGtRefClkP     => ethRefClk156P,                    -- [in]
         ethGtRefClkN     => ethRefClk156N,                    -- [in]
         ethRxP           => ethRxP,                           -- [in]
         ethRxN           => ethRxN,                           -- [in]
         ethTxP           => ethTxP,                           -- [out]
         ethTxN           => ethTxN,                           -- [out]
         phyReady         => open,                             -- [out]
         rssiStatus       => open,                             -- [out]
         axilClk          => axilClk,                          -- [out]
         axilRst          => axilRst,                          -- [out]
         mAxilReadMaster  => ethAxilReadMaster,                -- [out]
         mAxilReadSlave   => ethAxilReadSlave,                 -- [in]
         mAxilWriteMaster => ethAxilWriteMaster,               -- [out]
         mAxilWriteSlave  => ethAxilWriteSlave,                -- [in]
         sAxilReadMaster  => locAxilReadMasters(AXIL_ETH_C),   -- [in]
         sAxilReadSlave   => locAxilReadSlaves(AXIL_ETH_C),    -- [out]
         sAxilWriteMaster => locAxilWriteMasters(AXIL_ETH_C),  -- [in]
         sAxilWriteSlave  => locAxilWriteSlaves(AXIL_ETH_C),   -- [out]
         axisClk          => axilClk,                          -- [in]
         axisRst          => axilRst,                          -- [in]
         dataTxAxisMaster => daqDataMaster,                    -- [in]
         dataTxAxisSlave  => daqDataSlave);                    -- [out]

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


   -------------------------------------------------------------------------------------------------
   -- Timing Hub
   -------------------------------------------------------------------------------------------------
   U_FcHub_1 : entity ldmx.FcHub
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIMULATION_G,
         REFCLKS_G         => FC_HUB_REFCLKS_G,
         QUADS_G           => FC_HUB_QUADS_G,
         QUAD_REFCLK_MAP_G => FC_HUB_QUAD_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(AXIL_FC_HUB_C).baseAddr)
      port map (
         lclsTimingRefClk185P => lclsTimingRefClk185P,                -- [in]
         lclsTimingRefClk185N => lclsTimingRefClk185N,                -- [in]
         lclsTimingRxP        => lclsTimingRxP,                       -- [in]
         lclsTimingRxN        => lclsTimingRxN,                       -- [in]
         lclsTimingTxP        => lclsTimingTxP,                       -- [out]
         lclsTimingTxN        => lclsTimingTxN,                       -- [out]
         lclsTimingClkOut     => lclsTimingClk,                       -- [out]
         lclsTimingRstOut     => lclsTimingRst,                       -- [out]
         globalTriggerRor     => globalTriggerRor,
         lclsTimingRecClkInP  => lclsTimingRecClkInP,                 -- [in]
         lclsTimingRecClkInN  => lclsTimingRecClkInN,                 -- [in]
         fcHubTxP             => fcHubTxP,                            -- [out]
         fcHubTxN             => fcHubTxN,                            -- [out]
         fcHubRxP             => fcHubRxP,                            -- [in]
         fcHubRxN             => fcHubRxN,                            -- [in]
         axilClk              => axilClk,                             -- [in]
         axilRst              => axilRst,                             -- [in]
         axilReadMaster       => locAxilReadMasters(AXIL_FC_HUB_C),   -- [in]
         axilReadSlave        => locAxilReadSlaves(AXIL_FC_HUB_C),    -- [out]
         axilWriteMaster      => locAxilWriteMasters(AXIL_FC_HUB_C),  -- [in]
         axilWriteSlave       => locAxilWriteSlaves(AXIL_FC_HUB_C));  -- [out]


   -------------------------------------------------------------------------------------------------
   -- S30XL Application Core
   -------------------------------------------------------------------------------------------------
   U_S30xlAppCore_1 : entity ldmx.S30xlAppCore
      generic map (
         TPD_G            => TPD_G,
         TS_LANES_G       => TS_LANES_G,
         TS_REFCLKS_G     => TS_REFCLKS_G,
         TS_REFCLK_MAP_G  => TS_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CONFIG_C(AXIL_APP_CORE_C).baseAddr)
      port map (
         appFcRefClkP    => appFcRefClkP,                          -- [in]
         appFcRefClkN    => appFcRefClkN,                          -- [in]
         appFcRxP        => appFcRxP,                              -- [in]
         appFcRxN        => appFcRxN,                              -- [in]
         appFcTxP        => appFcTxP,                              -- [out]
         appFcTxN        => appFcTxN,                              -- [out]
         tsRefClk250P    => tsRefClk250P,                          -- [in]
         tsRefClk250N    => tsRefClk250N,                          -- [in]
         tsDataRxP       => tsDataRxP,                             -- [in]
         tsDataRxN       => tsDataRxN,                             -- [in]
         axilClk         => axilClk,                               -- [in]
         axilRst         => axilRst,                               -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_APP_CORE_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_APP_CORE_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_APP_CORE_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_APP_CORE_C),   -- [out]
         axisClk         => axilClk,                               -- [in]
         axisRst         => axilRst,                               -- [in]
         daqDataMaster   => daqDataMaster,                         -- [out]
         daqDataSlave    => daqDataSlave);                         -- [in]


end architecture rtl;
