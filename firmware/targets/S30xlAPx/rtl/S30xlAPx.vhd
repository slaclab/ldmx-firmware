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
      TPD_G               : time             := 1 ns;
      BUILD_INFO_G        : BuildInfoType    := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G        : boolean          := false;
      SIM_SRP_PORT_NUM_G  : integer          := 9000;
      SIM_DATA_PORT_NUM_G : integer          := 9100;
      DHCP_G              : boolean          := false;        -- true = DHCP, false = static address
      IP_ADDR_G           : slv(31 downto 0) := x"0A01A8C0";  -- 192.168.1.10 (before DHCP)
      MAC_ADDR_G          : slv(47 downto 0) := x"00_00_16_56_00_08";
      TIMING_HUB_QUADS_G  : integer          := 1);

   port (
      -- 185 MHz Ref Clk for timing recovery
      timingGtRefClk185P : in sl;
      timingGtRefClk185N : in sl;

      -- LCLS-II timing interface
      lclsTimingRxP : in  sl;
      lclsTimingRxN : in  sl;
      lclsTimingTxP : out sl;           -- Tx is not used
      lclsTimingTxN : out sl;


      -- Recovered LCLS clock jitter cleaning
      lclsRecClkOutP : out sl;
      lclsRecClkOutN : out sl;
      lclsGtRefClkP  : in  slv(TIMING_HUB_QUADS_G-1 downto 0);
      lclsGtRefClkN  : in  slv(TIMING_HUB_QUADS_G-1 downto 0);

      -- Timing Hub PGP FC Ports
      fcHubTxP : out slv(TIMING_HUB_QUADS_G*4-1 downto 0);
      fcHubTxN : out slv(TIMING_HUB_QUADS_G*4-1 downto 0);
      fcHubRxP : in  slv(TIMING_HUB_QUADS_G*4-1 downto 0);
      fcHubRxN : in  slv(TIMING_HUB_QUADS_G*4-1 downto 0);

      -- FC Receiver
      -- (Looped back from fcHub IO)
      appFcRxP : in  sl;
      appFcRxN : in  sl;
      appFcTxP : out sl;
      appFcTxN : out sl;

      -- TS Interface
      tsRefClkP : in sl;
      tsRefClkN : in sl;
      tsRxP     : in sl;
      tsRxN     : in sl;

      -- Ethernet refclk and interface
      ethGtRefClkP : in  sl;
      ethGtRefClkN : in  sl;
      ethTxP       : out sl;
      ethTxN       : out sl;
      ethRxP       : in  sl;
      ethRxN       : in  sl

      );

end entity S30xlAPx;

architecture rtl of S30xlAPx is

   constant AXIL_CLK_FREQ_C : real := 156.25e6;

   constant AXIL_NUM_C         : integer := 3;
   constant AXIL_VERSION_C     : integer := 0;
   constant AXIL_ETH_C         : integer := 1;
   constant AXIL_LCLS_TIMING_C : integer := 2;
--   constant AXIL_RSSI_DATA_C : integer := 3;

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_NUM_C-1 downto 0) := (
      AXIL_VERSION_C     => (
         baseAddr        => X"00000000",
         addrBits        => 12,
         connectivity    => X"FFFF"),
      AXIL_ETH_C         => (
         baseAddr        => X"00010000",
         addrBits        => 16,
         connectivity    => X"FFFF"),
      AXIL_LCLS_TIMING_C => (
         baseAddr        => X"01000000",
         addrBits        => 24,
         connectivity    => X"FFFF"));

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

   signal dataTxAxisMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dataTxAxisSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;

   -- Timing hub
   signal lclsTimingClk : sl;
   signal lclsTimingRst : sl;
   signal lclsTimingBus : TimingBusType;


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
         ethGtRefClkP     => ethGtRefClkP,                     -- [in]
         ethGtRefClkN     => ethGtRefClkN,                     -- [in]
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
         dataTxAxisMaster => dataTxAxisMaster,                 -- [in]
         dataTxAxisSlave  => dataTxAxisSlave);                 -- [out]

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
   -- LCLS TIMING RX
   -- This goes in timing hub?
   -------------------------------------------------------------------------------------------------
   U_Lcls2TimingRx_1 : entity ldmx.Lcls2TimingRx
      generic map (
         TPD_G             => TPD_G,
         TIME_GEN_EXTREF_G => true,
         RX_CLK_MMCM_G     => false,
         USE_TPGMINI_G     => true,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(AXIL_LCLS_TIMING_C).baseAddr)
      port map (
         stableClk        => axilClk,   -- [in] -- axilClk from TenGigEth core is not mmcm
         stableRst        => axilRst,   -- [in]
         axilClk          => axilClk,   -- [in]
         axilRst          => axilRst,   -- [in]
         axilReadMaster   => locAxilReadMasters(AXIL_LCLS_TIMING_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(AXIL_LCLS_TIMING_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(AXIL_LCLS_TIMING_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(AXIL_LCLS_TIMING_C),   -- [out]
         recTimingClk     => lclsTimingClk,                            -- [out]
         recTimingRst     => lclsTimingRst,                            -- [out]
         appTimingBus     => lclsTimingBus,                            -- [out]
         timingRxP        => lclsTimingRxP,                            -- [in]
         timingRxN        => lclsTimingRxN,                            -- [in]
         timingTxP        => lclsTimingTxP,                            -- [out]
         timingTxN        => lclsTimingTxN,                            -- [out]
         timingRefClkInP  => timingGtRefClk185P,                       -- [in]
         timingRefClkInN  => timingGtRefClk185N,                       -- [in]
         timingRecClkOutP => lclsRecClkOutP,                           -- [out]
         timingRecClkOutN => lclsRecClkOutN);                          -- [out]


   -------------------------------------------------------------------------------------------------
   -- Timing Hub
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- Global Trigger
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- S30XL Application
   -------------------------------------------------------------------------------------------------

end architecture rtl;
