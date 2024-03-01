-------------------------------------------------------------------------------
-- Title      : 
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
use surf.EthMacPkg.all;

entity TenGigEthGtyCore is

   generic (
      TPD_G      : time             := 1 ns;
      MAC_ADDR_G : slv(47 downto 0) := x"010300564400";  -- 00:44:56:00:03:01 (ETH only)
      IP_ADDR_G  : slv(31 downto 0) := x"0A02A8C0";      -- 192.168.2.10 (ETH only)
      DHCP_G     : boolean          := true);

   port (
      bla : in sl);

end entity TenGigEthGtyCore;

architecture rtl of TenGigEthGtyCore is

begin

   -------------------------------------------------------------------------------------------------
   -- Ten Gig Ethernet GT
   -------------------------------------------------------------------------------------------------
   U_TenGigEthGtyUltraScaleWrapper_1 : entity surf.TenGigEthGtyUltraScaleWrapper
      generic map (
         TPD_G             => TPD_G,
         NUM_LANE_G        => 1,
         JUMBO_G           => true,
         PAUSE_EN_G        => true,                               -- Check this
         QPLL_REFCLK_SEL_G => "001",                              -- Check this
         EN_AXI_REG_G      => true,
         AXIS_CONFIG_G     => (others => EMAC_AXIS_CONFIG_C))
      port map (
         localMac            => MAC_ADDR_G,                       -- [in]
         dmaClk              => ethClk,                           -- [in]
         dmaRst              => ethRst,                           -- [in]
         dmaIbMasters(0)     => ethMacIbMaster,                   -- [out]
         dmaIbSlaves(0)      => ethMacIbSlave,                    -- [in]
         dmaObMasters(0)     => ethMacObMaster,                   -- [in]
         dmaObSlaves(0)      => ethMacObSlave,                    -- [out]
         axiLiteClk          => ethClk,                           -- [in]
         axiLiteRst          => ethRst,                           -- [in]
         axiLiteReadMasters  => locAxilReadMasters(AXIL_ETH_C),   -- [in]
         axiLiteReadSlaves   => locAxilReadSlaves(AXIL_ETH_C),    -- [out]
         axiLiteWriteMasters => locAxilWriteMasters(AXIL_ETH_C),  -- [in]
         axiLiteWriteSlaves  => locAxilWriteSlaves(AXIL_ETH_C),   -- [out]
         extRst              => extRst,                           -- [in]
         coreClk             => ethClk,                           -- [out]
         coreRst             => ethRst,                           -- [out]
         phyClk              => open,                             -- [out]
         phyRst              => open,                             -- [out]
         phyReady            => phyReady,                         -- [out]
         gtClk               => open,                             -- [out]
--          gtTxPreCursor       => gtTxPreCursor,        -- [in]
--          gtTxPostCursor      => gtTxPostCursor,       -- [in]
--          gtTxDiffCtrl        => gtTxDiffCtrl,         -- [in]
--          gtRxPolarity        => gtRxPolarity,         -- [in]
--          gtTxPolarity        => gtTxPolarity,         -- [in]
--          gtRefClk            => gtRefClk,             -- [in]
         gtClkP              => mgtEthRefClkP,                    -- [in]
         gtClkN              => mgtEthRefClkN,                    -- [in]
         gtTxP(0)            => ethTxP,                           -- [out]
         gtTxN(0)            => ethTxN,                           -- [out]
         gtRxP(0)            => ethRxP,                           -- [in]
         gtRxN(0)            => ethRxN);                          -- [in]

   -------------------------------------------------------------------------------------------------
   -- UDP Engine
   -------------------------------------------------------------------------------------------------
   U_UdpEngineWrapper_1 : entity surf.UdpEngineWrapper
      generic map (
         TPD_G          => TPD_G,
         SERVER_EN_G    => true,
         SERVER_SIZE_G  => 1,
         SERVER_PORTS_G => (0 => 8193)
         CLIENT_EN_G    => false,
         TX_FLOW_CTRL_G => true,
         DHCP_G         => DHCP_G,
         CLK_FREQ_G     => CLK_FREQ_G,
         COMM_TIMEOUT_G => 30,
--         TTL_G               => TTL_G,
         VLAN_G         => false,
         SYNTH_MODE_G   => "inferred")
      port map (
         localMac        => MAC_ADDR_G,                       -- [in]
         localIp         => IP_ADDR_G,                        -- [in]
         obMacMaster     => ethMacIbMaster,                   -- [in]
         obMacSlave      => ethMacIbSlave,                    -- [out]
         ibMacMaster     => ethMacObMaster,                   -- [out]
         ibMacSlave      => ethMacObSlave,                    -- [in]
         obServerMasters => obServerMaster,                   -- [out]
         obServerSlaves  => obServerSlave,                    -- [in]
         ibServerMasters => ibServerMaster,                   -- [in]
         ibServerSlaves  => ibServerSlave,                    -- [out]
         axilReadMaster  => locAxilReadMasters(AXIL_UDP_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_UDP_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_UDP_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_UDP_C),   -- [out]
         clk             => ethClk,                           -- [in]
         rst             => ethRst);                          -- [in]

   -------------------------------------------------------------------------------------------------
   -- RSSI (rUDP) Engine
   -------------------------------------------------------------------------------------------------
   U_RssiCoreWrapper_1 : entity surf.RssiCoreWrapper
      generic map (
         TPD_G               => TPD_G,
         CLK_FREQUENCY_G     => CLK_FREQ_G,
--         TIMEOUT_UNIT_G        => TIMEOUT_UNIT_G,
         SERVER_G            => true,
         RETRANSMIT_ENABLE_G => true,
         WINDOW_ADDR_SIZE_G  => 4,                               -- default 3
         SEGMENT_ADDR_SIZE_G => 7,                               -- default
         BYPASS_CHUNKER_G    => false,                           -- defualt
         PIPE_STAGES_G       => 0,                               -- default
         APP_STREAMS_G       => 2,
         APP_STREAM_ROUTES_G => (
            0                => X"00",
            1                => X"01"),
--         APP_STREAM_PRIORITY_G => APP_STREAM_PRIORITY_G,
         APP_ILEAVE_EN_G     => true,
--          BYP_TX_BUFFER_G       => BYP_TX_BUFFER_G,
--          BYP_RX_BUFFER_G       => BYP_RX_BUFFER_G,
         SYNTH_MODE_G        => "inferred",
         MEMORY_TYPE_G       => "block",
         APP_AXIS_CONFIG_G   => (others => EMAC_AXIS_CONFIG_C),  -- Maybe change this?
         TSP_AXIS_CONFIG_G   => EMAC_AXIS_CONFIG_C,
         MAX_NUM_OUTS_SEG_G  => 2**4,
         MAX_SEG_SIZE_G      => 8192)
--         ACK_TOUT_G            => ACK_TOUT_G,
--         RETRANS_TOUT_G        => RETRANS_TOUT_G,
--         NULL_TOUT_G           => NULL_TOUT_G,
--         MAX_RETRANS_CNT_G     => MAX_RETRANS_CNT_G,
--         MAX_CUM_ACK_CNT_G     => MAX_CUM_ACK_CNT_G)
      port map (
         clk_i             => ethClk,                            -- [in]
         rst_i             => ethRst,                            -- [in]
         sAppAxisMasters_i => rssiTxAxisMasters,                 -- [in]
         sAppAxisSlaves_o  => rssiTxAxisSlaves,                  -- [out]
         mAppAxisMasters_o => rssiRxAxisMasters,                 -- [out]
         mAppAxisSlaves_i  => rssiRxAxisSlaves,                  -- [in]
         sTspAxisMaster_i  => obServerMaster,                    -- [in]
         sTspAxisSlave_o   => obServerSlave,                     -- [out]
         mTspAxisMaster_o  => ibServerMaster,                    -- [out]
         mTspAxisSlave_i   => obServerSlave,                     -- [in]
         axiClk_i          => ethClk,                            -- [in]
         axiRst_i          => ethRst,                            -- [in]
         axilReadMaster    => locAxilReadMasters(AXIL_RSSI_C),   -- [in]
         axilReadSlave     => locAxilReadSlaves(AXIL_RSSI_C),    -- [out]
         axilWriteMaster   => locAxilWriteMasters(AXIL_RSSI_C),  -- [in]
         axilWriteSlave    => locAxilWriteSlaves(AXIL_RSSI_C),   -- [out]
         statusReg_o       => open);                             -- [out]

end architecture rtl;
