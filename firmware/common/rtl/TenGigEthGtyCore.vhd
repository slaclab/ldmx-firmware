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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.EthMacPkg.all;

entity TenGigEthGtyCore is
   generic(
      TPD_G               : time             := 1 ns;
      SIMULATION_G        : boolean          := false;
      SIM_SRP_PORT_NUM_G  : integer          := 9000;
      SIM_DATA_PORT_NUM_G : integer          := 9100;
      AXIL_BASE_ADDR_G    : slv(31 downto 0) := X"00000000";
      DHCP_G              : boolean          := false;        -- true = DHCP, false = static address
      IP_ADDR_G           : slv(31 downto 0) := x"0A01A8C0";  -- 192.168.1.10 (before DHCP)
      MAC_ADDR_G          : slv(47 downto 0) := x"00_00_16_56_00_08");
   port (
      extRst              : in  sl                    := '0';
      -- GT ports and clock
      ethGtRefClkP        : in  sl;                           -- GT Ref Clock 156.25 MHz
      ethGtRefClkN        : in  sl;
      ethRxP              : in  sl;
      ethRxN              : in  sl;
      ethTxP              : out sl;
      ethTxN              : out sl;
      -- Eth/RSSI Status
      phyReady            : out sl;
      rssiStatus          : out slv7Array(1 downto 0);
      -- AXI-Lite Interface for local register access
      axilClk             : out sl;
      axilRst             : out sl;
      mAxilReadMaster     : out AxiLiteReadMasterType;
      mAxilReadSlave      : in  AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      mAxilWriteMaster    : out AxiLiteWriteMasterType;
      mAxilWriteSlave     : in  AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      sAxilReadMaster     : in  AxiLiteReadMasterType;
      sAxilReadSlave      : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      sAxilWriteMaster    : in  AxiLiteWriteMasterType;
      sAxilWriteSlave     : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;
      -- IO Streams
      axisClk             : in  sl;
      axisRst             : in  sl;
      tsDaqRawAxisMaster  : in  AxiStreamMasterType;
      tsDaqRawAxisSlave   : out AxiStreamSlaveType;
      tsDaqTrigAxisMaster : in  AxiStreamMasterType;
      tsDaqTrigAxisSlave  : out AxiStreamSlaveType);

end entity TenGigEthGtyCore;

architecture rtl of TenGigEthGtyCore is
   constant ETH_CLK_FREQ_C : real := 156.25e6;

   constant SERVER_SIZE_C          : natural := 3;
   constant SRP_RSSI_INDEX_C       : natural := 0;
   constant RAW_DATA_RSSI_INDEX_C  : natural := 1;
   constant TRIG_DATA_RSSI_INDEX_C : natural := 2;
   constant SERVER_PORTS_C : PositiveArray(2 downto 0) := (
      SRP_RSSI_INDEX_C       => 8192,
      RAW_DATA_RSSI_INDEX_C  => 8193,
      TRIG_DATA_RSSI_INDEX_C => 8194);

   -- Both RSSI ports use the same TDEST and stream config
   constant RSSI_SIZE_C   : positive            := 1;
   constant AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 8, tDestBits => 8, tUserBits => 8);

   constant RSSI_AXIS_CONFIG_C : AxiStreamConfigArray(RSSI_SIZE_C-1 downto 0) := (others => AXIS_CONFIG_C);

   constant DEST_LOCAL_SRP_DATA_C : integer := 0;

   constant RSSI_ROUTES_C : Slv8Array(RSSI_SIZE_C-1 downto 0) := (0 => X"00");

   constant AXIL_NUM_C            : integer := 5;
   constant AXIL_ETH_C            : integer := 0;
   constant AXIL_UDP_C            : integer := 1;
   constant AXIL_RSSI_SRP_C       : integer := 2;
   constant AXIL_RSSI_RAW_DATA_C  : integer := 3;
   constant AXIL_RSSI_TRIG_DATA_C : integer := 4;

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_NUM_C-1 downto 0) := (
      AXIL_ETH_C            => (
         baseAddr           => AXIL_BASE_ADDR_G + X"000000",
         addrBits           => 16,
         connectivity       => X"FFFF"),
      AXIL_UDP_C            => (
         baseAddr           => AXIL_BASE_ADDR_G + X"010000",
         addrBits           => 12,
         connectivity       => X"FFFF"),
      AXIL_RSSI_SRP_C       => (
         baseAddr           => AXIL_BASE_ADDR_G + X"011000",
         addrBits           => 12,
         connectivity       => X"FFFF"),
      AXIL_RSSI_RAW_DATA_C  => (
         baseAddr           => AXIL_BASE_ADDR_G + X"012000",
         addrBits           => 12,
         connectivity       => X"FFFF"),
      AXIL_RSSI_TRIG_DATA_C => (
         baseAddr           => AXIL_BASE_ADDR_G + X"013000",
         addrBits           => 12,
         connectivity       => X"FFFF"));

   signal ethClk : sl;
   signal ethRst : sl;

   signal efuse    : slv(31 downto 0);
   signal localMac : slv(47 downto 0);

   signal ethMacIbMaster : AxiStreamMasterType;
   signal ethMacIbSlave  : AxiStreamSlaveType;
   signal ethMacObMaster : AxiStreamMasterType;
   signal ethMacObSlave  : AxiStreamSlaveType;


   signal ibServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal ibServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);
   signal obServerMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal obServerSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);

   signal srpRssiIbMasters : AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal srpRssiIbSlaves  : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);
   signal srpRssiObMasters : AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal srpRssiObSlaves  : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);

   signal rawDataRssiIbMasters : AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal rawDataRssiIbSlaves  : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);
   signal rawDataRssiObMasters : AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal rawDataRssiObSlaves  : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);

   signal trigDataRssiIbMasters : AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal trigDataRssiIbSlaves  : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);
   signal trigDataRssiObMasters : AxiStreamMasterArray(RSSI_SIZE_C-1 downto 0);
   signal trigDataRssiObSlaves  : AxiStreamSlaveArray(RSSI_SIZE_C-1 downto 0);


   signal rogueIbMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal rogueIbSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
   signal rogueObMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal rogueObSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);

   signal rogueDemuxAxisMasters : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal rogueDemuxAxisSlaves  : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);
   signal rogueMuxAxisMasters   : AxiStreamMasterArray(SERVER_SIZE_C-1 downto 0);
   signal rogueMuxAxisSlaves    : AxiStreamSlaveArray(SERVER_SIZE_C-1 downto 0);

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_NUM_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_NUM_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);


begin

   axilClk <= ethClk;
   axilRst <= ethRst;
   --------------------
   -- Local MAC Address
   --------------------
--    U_EFuse : EFUSE_USR
--       port map (
--          EFUSEUSR => efuse);

--    localMac(23 downto 0)  <= x"56_00_08";  -- 08:00:56:XX:XX:XX (big endian SLV)   
--    localMac(47 downto 24) <= efuse(31 downto 8);

   localMac(47 downto 0) <= MAC_ADDR_G;  --x"00_00_16_56_00_08";

   ----------------------------------------------------------------------------------------------
   -- AXIL Crossbar
   ----------------------------------------------------------------------------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_NUM_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
      port map (
         axiClk              => ethClk,
         axiClkRst           => ethRst,
         sAxiWriteMasters(0) => sAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   REAL_ETH_GEN : if (not SIMULATION_G) generate

      -------------------------------------------------------------------------------------------------
      -- Ten Gig Ethernet GT
      -------------------------------------------------------------------------------------------------
      U_TenGigEthGtyUltraScaleWrapper_1 : entity surf.TenGigEthGtyUltraScaleWrapper
         generic map (
            TPD_G             => TPD_G,
            NUM_LANE_G        => 1,
            JUMBO_G           => true,
            PAUSE_EN_G        => true,                                  -- Check this
            QPLL_REFCLK_SEL_G => "001",                                 -- Check this
            EN_AXI_REG_G      => true,
            AXIS_CONFIG_G     => (others => EMAC_AXIS_CONFIG_C))
         port map (
            localMac(0)            => localMac,                         -- [in]
            dmaClk(0)              => ethClk,                           -- [in]
            dmaRst(0)              => ethRst,                           -- [in]
            dmaIbMasters(0)        => ethMacIbMaster,                   -- [out]
            dmaIbSlaves(0)         => ethMacIbSlave,                    -- [in]
            dmaObMasters(0)        => ethMacObMaster,                   -- [in]
            dmaObSlaves(0)         => ethMacObSlave,                    -- [out]
            axiLiteClk(0)          => ethClk,                           -- [in]
            axiLiteRst(0)          => ethRst,                           -- [in]
            axiLiteReadMasters(0)  => locAxilReadMasters(AXIL_ETH_C),   -- [in]
            axiLiteReadSlaves(0)   => locAxilReadSlaves(AXIL_ETH_C),    -- [out]
            axiLiteWriteMasters(0) => locAxilWriteMasters(AXIL_ETH_C),  -- [in]
            axiLiteWriteSlaves(0)  => locAxilWriteSlaves(AXIL_ETH_C),   -- [out]
            extRst                 => extRst,                           -- [in]
            coreClk                => ethClk,                           -- [out]
            coreRst                => ethRst,                           -- [out]
            phyClk                 => open,                             -- [out]
            phyRst                 => open,                             -- [out]
            phyReady(0)            => phyReady,                         -- [out]
            gtClk                  => open,                             -- [out]
--          gtTxPreCursor       => gtTxPreCursor,        -- [in]
--          gtTxPostCursor      => gtTxPostCursor,       -- [in]
--          gtTxDiffCtrl        => gtTxDiffCtrl,         -- [in]
--          gtRxPolarity        => gtRxPolarity,         -- [in]
--          gtTxPolarity        => gtTxPolarity,         -- [in]
--          gtRefClk            => gtRefClk,             -- [in]
            gtClkP                 => ethGtRefClkP,                     -- [in]
            gtClkN                 => ethGtRefClkN,                     -- [in]
            gtTxP(0)               => ethTxP,                           -- [out]
            gtTxN(0)               => ethTxN,                           -- [out]
            gtRxP(0)               => ethRxP,                           -- [in]
            gtRxN(0)               => ethRxN);                          -- [in]      


      ----------------------
      -- IPv4/ARP/UDP Engine
      ----------------------
      U_UDP : entity surf.UdpEngineWrapper
         generic map (
            -- Simulation Generics
            TPD_G          => TPD_G,
            -- UDP Server Generics
            SERVER_EN_G    => true,
            SERVER_SIZE_G  => SERVER_SIZE_C,
            SERVER_PORTS_G => SERVER_PORTS_C,
            -- UDP Client Generics
            CLIENT_EN_G    => false,
            -- General IPv4/ARP/DHCP Generics
            DHCP_G         => DHCP_G,
            CLK_FREQ_G     => ETH_CLK_FREQ_C,
            COMM_TIMEOUT_G => 30)
         port map (
            -- Local Configurations
            localMac        => localMac,
            localIp         => IP_ADDR_G,
            -- Interface to Ethernet Media Access Controller (MAC)
            obMacMaster     => ethMacIbMaster,
            obMacSlave      => ethMacIbSlave,
            ibMacMaster     => ethMacObMaster,
            ibMacSlave      => ethMacObSlave,
            -- Interface to UDP Server engine(s)
            obServerMasters => obServerMasters,
            obServerSlaves  => obServerSlaves,
            ibServerMasters => ibServerMasters,
            ibServerSlaves  => ibServerSlaves,
            -- AXI Lite debug interface
            axilReadMaster  => locAxilReadMasters(AXIL_UDP_C),
            axilReadSlave   => locAxilReadSlaves(AXIL_UDP_C),
            axilWriteMaster => locAxilWriteMasters(AXIL_UDP_C),
            axilWriteSlave  => locAxilWriteSlaves(AXIL_UDP_C),
            -- Clock and Reset
            clk             => ethClk,
            rst             => ethRst);

      ------------------------------------------
      -- Software's RSSI Server Interface @ 8192
      ------------------------------------------
      U_RssiServer_SRP : entity surf.RssiCoreWrapper
         generic map (
            TPD_G                => TPD_G,
            APP_ILEAVE_EN_G      => true,
            ILEAVE_ON_NOTVALID_G => true,
            MAX_SEG_SIZE_G       => 1024,
            SEGMENT_ADDR_SIZE_G  => 7,
            APP_STREAMS_G        => RSSI_SIZE_C,
            APP_STREAM_ROUTES_G  => RSSI_ROUTES_C,
--            APP_STREAM_PRIORITY_G => RSSI_PRIORITY_C,
            APP_AXIS_CONFIG_G    => RSSI_AXIS_CONFIG_C,
            CLK_FREQUENCY_G      => ETH_CLK_FREQ_C,
            TIMEOUT_UNIT_G       => 1.0E-3,  -- In units of seconds
            SERVER_G             => true,
            RETRANSMIT_ENABLE_G  => true,
            BYPASS_CHUNKER_G     => false,
            WINDOW_ADDR_SIZE_G   => 3,
            PIPE_STAGES_G        => 0,
            TSP_AXIS_CONFIG_G    => EMAC_AXIS_CONFIG_C,
            INIT_SEQ_N_G         => 16#80#)
         port map (
            clk_i             => ethClk,
            rst_i             => ethRst,
            openRq_i          => '1',
            -- Application Layer Interface
            sAppAxisMasters_i => srpRssiIbMasters,
            sAppAxisSlaves_o  => srpRssiIbSlaves,
            mAppAxisMasters_o => srpRssiObMasters,
            mAppAxisSlaves_i  => srpRssiObSlaves,
            -- Transport Layer Interface
            sTspAxisMaster_i  => obServerMasters(SRP_RSSI_INDEX_C),
            sTspAxisSlave_o   => obServerSlaves(SRP_RSSI_INDEX_C),
            mTspAxisMaster_o  => ibServerMasters(SRP_RSSI_INDEX_C),
            mTspAxisSlave_i   => ibServerSlaves(SRP_RSSI_INDEX_C),
            -- AXI-Lite Interface
            axiClk_i          => ethClk,
            axiRst_i          => ethRst,
            axilReadMaster    => locAxilReadMasters(AXIL_RSSI_SRP_C),
            axilReadSlave     => locAxilReadSlaves(AXIL_RSSI_SRP_C),
            axilWriteMaster   => locAxilWriteMasters(AXIL_RSSI_SRP_C),
            axilWriteSlave    => locAxilWriteSlaves(AXIL_RSSI_SRP_C),
            -- Internal statuses
            statusReg_o       => rssiStatus(SRP_RSSI_INDEX_C));

      U_RssiServer_RAW_DATA : entity surf.RssiCoreWrapper
         generic map (
            TPD_G                => TPD_G,
            APP_ILEAVE_EN_G      => true,
            ILEAVE_ON_NOTVALID_G => true,
            MAX_SEG_SIZE_G       => 1024,
            SEGMENT_ADDR_SIZE_G  => 7,
            APP_STREAMS_G        => RSSI_SIZE_C,
            APP_STREAM_ROUTES_G  => RSSI_ROUTES_C,
--            APP_STREAM_PRIORITY_G => RSSI_PRIORITY_C,
            APP_AXIS_CONFIG_G    => RSSI_AXIS_CONFIG_C,
            CLK_FREQUENCY_G      => ETH_CLK_FREQ_C,
            TIMEOUT_UNIT_G       => 1.0E-3,  -- In units of seconds
            SERVER_G             => true,
            RETRANSMIT_ENABLE_G  => true,
            BYPASS_CHUNKER_G     => false,
            WINDOW_ADDR_SIZE_G   => 3,
            PIPE_STAGES_G        => 0,
            TSP_AXIS_CONFIG_G    => EMAC_AXIS_CONFIG_C,
            INIT_SEQ_N_G         => 16#80#)
         port map (
            clk_i             => ethClk,
            rst_i             => ethRst,
            openRq_i          => '1',
            -- Application Layer Interface
            sAppAxisMasters_i => rawDataRssiIbMasters,
            sAppAxisSlaves_o  => rawDataRssiIbSlaves,
            mAppAxisMasters_o => rawDataRssiObMasters,
            mAppAxisSlaves_i  => rawDataRssiObSlaves,
            -- Transport Layer Interface
            sTspAxisMaster_i  => obServerMasters(RAW_DATA_RSSI_INDEX_C),
            sTspAxisSlave_o   => obServerSlaves(RAW_DATA_RSSI_INDEX_C),
            mTspAxisMaster_o  => ibServerMasters(RAW_DATA_RSSI_INDEX_C),
            mTspAxisSlave_i   => ibServerSlaves(RAW_DATA_RSSI_INDEX_C),
            -- AXI-Lite Interface
            axiClk_i          => ethClk,
            axiRst_i          => ethRst,
            axilReadMaster    => locAxilReadMasters(AXIL_RSSI_RAW_DATA_C),
            axilReadSlave     => locAxilReadSlaves(AXIL_RSSI_RAW_DATA_C),
            axilWriteMaster   => locAxilWriteMasters(AXIL_RSSI_RAW_DATA_C),
            axilWriteSlave    => locAxilWriteSlaves(AXIL_RSSI_RAW_DATA_C),
            -- Internal statuses
            statusReg_o       => rssiStatus(RAW_DATA_RSSI_INDEX_C));

--       U_RssiServer_TRIG_DATA : entity surf.RssiCoreWrapper
--          generic map (
--             TPD_G                => TPD_G,
--             APP_ILEAVE_EN_G      => true,
--             ILEAVE_ON_NOTVALID_G => true,
--             MAX_SEG_SIZE_G       => 1024,
--             SEGMENT_ADDR_SIZE_G  => 7,
--             APP_STREAMS_G        => RSSI_SIZE_C,
--             APP_STREAM_ROUTES_G  => RSSI_ROUTES_C,
-- --            APP_STREAM_PRIORITY_G => RSSI_PRIORITY_C,
--             APP_AXIS_CONFIG_G    => RSSI_AXIS_CONFIG_C,
--             CLK_FREQUENCY_G      => ETH_CLK_FREQ_C,
--             TIMEOUT_UNIT_G       => 1.0E-3,  -- In units of seconds
--             SERVER_G             => true,
--             RETRANSMIT_ENABLE_G  => true,
--             BYPASS_CHUNKER_G     => false,
--             WINDOW_ADDR_SIZE_G   => 3,
--             PIPE_STAGES_G        => 0,
--             TSP_AXIS_CONFIG_G    => EMAC_AXIS_CONFIG_C,
--             INIT_SEQ_N_G         => 16#80#)
--          port map (
--             clk_i             => ethClk,
--             rst_i             => ethRst,
--             openRq_i          => '1',
--             -- Application Layer Interface
--             sAppAxisMasters_i => trigDataRssiIbMasters,
--             sAppAxisSlaves_o  => trigDataRssiIbSlaves,
--             mAppAxisMasters_o => trigDataRssiObMasters,
--             mAppAxisSlaves_i  => trigDataRssiObSlaves,
--             -- Transport Layer Interface
--             sTspAxisMaster_i  => obServerMasters(TRIG_DATA_RSSI_INDEX_C),
--             sTspAxisSlave_o   => obServerSlaves(TRIG_DATA_RSSI_INDEX_C),
--             mTspAxisMaster_o  => ibServerMasters(TRIG_DATA_RSSI_INDEX_C),
--             mTspAxisSlave_i   => ibServerSlaves(TRIG_DATA_RSSI_INDEX_C),
--             -- AXI-Lite Interface
--             axiClk_i          => ethClk,
--             axiRst_i          => ethRst,
--             axilReadMaster    => locAxilReadMasters(AXIL_RSSI_TRIG_DATA_C),
--             axilReadSlave     => locAxilReadSlaves(AXIL_RSSI_TRIG_DATA_C),
--             axilWriteMaster   => locAxilWriteMasters(AXIL_RSSI_TRIG_DATA_C),
--             axilWriteSlave    => locAxilWriteSlaves(AXIL_RSSI_TRIG_DATA_C),
--             -- Internal statuses
--             statusReg_o       => rssiStatus(TRIG_DATA_RSSI_INDEX_C));



   end generate REAL_ETH_GEN;

   SIM_GEN : if (SIMULATION_G) generate

      IBUFDS_GTE3_Inst : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => ethGtRefClkP,
            IB    => ethGtRefClkP,
            CEB   => '0',
            ODIV2 => ethClkTmp,
            O     => open);

      BUFG_GT_Inst : BUFG_GT
         port map (
            I       => ethClkTmp,
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",
            O       => ethClk);

      PwrUpRst_Inst : entity surf.PwrUpRst
         generic map (
            TPD_G         => TPD_G,
            SIM_SPEEDUP_G => true)
         port map (
            arst   => extRst,
            clk    => ethClk,
            rstOut => ethRst);

      -- SRP
--       U_RogueTcpStreamWrap_SRP : entity surf.RogueTcpStreamWrap
--          generic map (
--             TPD_G         => TPD_G,
--             PORT_NUM_G    => SIM_SRP_PORT_NUM_G,
--             SSI_EN_G      => true,
--             CHAN_COUNT_G  => 1,
--             AXIS_CONFIG_G => AXIS_CONFIG_C)
--          port map (
--             axisClk     => ethClk,                            -- [in]
--             axisRst     => ethRst,                            -- [in]
--             sAxisMaster => srpRssiObMasters(SRP_RSSI_INDEX_C),  -- [in]
--             sAxisSlave  => srpRssiObSlaves(SRP_RSSI_INDEX_C),   -- [out]
--             mAxisMaster => srpRssiIbMasters(SRP_RSSI_INDEX_C),  -- [out]
--             mAxisSlave  => srpRssiIbSlaves(SRP_RSSI_INDEX_C));  -- [in]

--       -- No resize to throttle to 1G
--       rogueDemuxAxisMasters(SRP_RSSI_INDEX_C) <= rogueObMasters(SRP_RSSI_INDEX_C);
--       rogueObSlaves(SRP_RSSI_INDEX_C)         <= rogueDemuxAxisSlaves(SRP_RSSI_INDEX_C);
--       rogueIbMasters(SRP_RSSI_INDEX_C)        <= rogueMuxAxisMasters(SRP_RSSI_INDEX_C);
--       rogueMuxAxisSlaves(SRP_RSSI_INDEX_C)    <= rogueIbSlaves(SRP_RSSI_INDEX_C);

--       -- Only using 1 TDEST for now but might expand later
--       U_AxiStreamDeMux_SRP : entity surf.AxiStreamDeMux
--          generic map (
--             TPD_G          => TPD_G,
--             NUM_MASTERS_G  => RSSI_ROUTES_C'length,
--             MODE_G         => "ROUTED",
--             TDEST_ROUTES_G => RSSI_ROUTES_C)
--          port map (
--             axisClk      => ethClk,                                   -- [in]
--             axisRst      => ethRst,                                   -- [in]
--             sAxisMaster  => rogueDemuxAxisMasters(SRP_RSSI_INDEX_C),  -- [in]
--             sAxisSlave   => rogueDemuxAxisSlaves(SRP_RSSI_INDEX_C),   -- [out]
--             mAxisMasters => srpRssiObMasters,                         -- [out]
--             mAxisSlaves  => srpRssiObSlaves);                         -- [in]

--       U_AxiStreamMux_SRP : entity surf.AxiStreamMux
--          generic map (
--             TPD_G                => TPD_G,
--             NUM_SLAVES_G         => RSSI_ROUTES_C'length,
--             MODE_G               => "ROUTED",
--             TDEST_ROUTES_G       => RSSI_ROUTES_C,
-- --            PRIORITY_G           => RSSI_PRIORITY_C,
--             ILEAVE_EN_G          => true,
--             ILEAVE_ON_NOTVALID_G => true,
--             ILEAVE_REARB_G       => (512/8)-3)
--          port map (
--             axisClk      => ethClk,                                 -- [in]
--             axisRst      => ethRst,                                 -- [in]
--             sAxisMasters => srpRssiIbMasters,                       -- [in]
--             sAxisSlaves  => srpRssiIbSlaves,                        -- [out]
--             mAxisMaster  => rogueMuxAxisMasters(SRP_RSSI_INDEX_C),  -- [out]
--             mAxisSlave   => rogueMuxAxisSlaves(SRP_RSSI_INDEX_C));  -- [in]

--       -- RAW Data
--       U_RogueTcpStreamWrap_RAW_DATA : entity surf.RogueTcpStreamWrap
--          generic map (
--             TPD_G         => TPD_G,
--             PORT_NUM_G    => SIM_DATA_PORT_NUM_G,
--             SSI_EN_G      => true,
--             CHAN_MASK_G   => CHAN_MASK_C,
--             AXIS_CONFIG_G => AXIS_CONFIG_C)
--          port map (
--             axisClk     => ethClk,                                 -- [in]
--             axisRst     => ethRst,                                 -- [in]
--             sAxisMaster => rogueIbMasters(RAW_DATA_RSSI_INDEX_C),  -- [in]
--             sAxisSlave  => rogueIbSlaves(RAW_DATA_RSSI_INDEX_C),   -- [out]
--             mAxisMaster => rogueObMasters(RAW_DATA_RSSI_INDEX_C),  -- [out]
--             mAxisSlave  => rogueObSlaves(RAW_DATA_RSSI_INDEX_C));  -- [in]

--       rogueDemuxAxisMasters(RAW_DATA_RSSI_INDEX_C) <= rogueObMasters(RAW_DATA_RSSI_INDEX_C);
--       rogueObSlaves(RAW_DATA_RSSI_INDEX_C)         <= rogueDemuxAxisSlaves(RAW_DATA_RSSI_INDEX_C);
--       rogueIbMasters(RAW_DATA_RSSI_INDEX_C)        <= rogueMuxAxisMasters(RAW_DATA_RSSI_INDEX_C);
--       rogueMuxAxisSlaves(RAW_DATA_RSSI_INDEX_C)    <= rogueIbSlaves(RAW_DATA_RSSI_INDEX_C);

--       U_AxiStreamDeMux_RAW_DATA : entity surf.AxiStreamDeMux
--          generic map (
--             TPD_G          => TPD_G,
--             NUM_MASTERS_G  => RSSI_ROUTES_C'length,
--             MODE_G         => "ROUTED",
--             TDEST_ROUTES_G => RSSI_ROUTES_C)
--          port map (
--             axisClk      => ethClk,                                        -- [in]
--             axisRst      => ethRst,                                        -- [in]
--             sAxisMaster  => rogueDemuxAxisMasters(RAW_DATA_RSSI_INDEX_C),  -- [in]
--             sAxisSlave   => rogueDemuxAxisSlaves(RAW_DATA_RSSI_INDEX_C),   -- [out]
--             mAxisMasters => rawDataRssiObMasters,                          -- [out]
--             mAxisSlaves  => rawDataRssiObSlaves);                          -- [in]

--       U_AxiStreamMux_RAW_DATA : entity surf.AxiStreamMux
--          generic map (
--             TPD_G                => TPD_G,
--             NUM_SLAVES_G         => RSSI_ROUTES_C'length,
--             MODE_G               => "ROUTED",
--             TDEST_ROUTES_G       => RSSI_ROUTES_C,
-- --            PRIORITY_G           => RSSI_PRIORITY_C,
--             ILEAVE_EN_G          => true,
--             ILEAVE_ON_NOTVALID_G => true,
--             ILEAVE_REARB_G       => (512/8)-3)
--          port map (
--             axisClk      => ethClk,                                      -- [in]
--             axisRst      => ethRst,                                      -- [in]
--             sAxisMasters => rawDataRssiIbMasters,                        -- [in]
--             sAxisSlaves  => rawDataRssiIbSlaves,                         -- [out]
--             mAxisMaster  => rogueMuxAxisMasters(RAW_DATA_RSSI_INDEX_C),  -- [out]
--             mAxisSlave   => rogueMuxAxisSlaves(RAW_DATA_RSSI_INDEX_C));  -- [in]
--                                                                          --
--       -- TRIG Data
--       U_RogueTcpStreamWrap_TRIG_DATA : entity surf.RogueTcpStreamWrap
--          generic map (
--             TPD_G         => TPD_G,
--             PORT_NUM_G    => SIM_DATA_PORT_NUM_G,
--             SSI_EN_G      => true,
--             CHAN_MASK_G   => CHAN_MASK_C,
--             AXIS_CONFIG_G => AXIS_CONFIG_C)
--          port map (
--             axisClk     => ethClk,                                       -- [in]
--             axisRst     => ethRst,                                       -- [in]
--             sAxisMaster => rogueIbMasters(TRIG_DATA_RSSI_INDEX_C),       -- [in]
--             sAxisSlave  => rogueIbSlaves(TRIG_DATA_RSSI_INDEX_C),        -- [out]
--             mAxisMaster => rogueObMasters(TRIG_DATA_RSSI_INDEX_C),       -- [out]
--             mAxisSlave  => rogueObSlaves(TRIG_DATA_RSSI_INDEX_C));       -- [in]

--       rogueDemuxAxisMasters(TRIG_DATA_RSSI_INDEX_C) <= rogueObMasters(TRIG_DATA_RSSI_INDEX_C);
--       rogueObSlaves(TRIG_DATA_RSSI_INDEX_C)         <= rogueDemuxAxisSlaves(TRIG_DATA_RSSI_INDEX_C);
--       rogueIbMasters(TRIG_DATA_RSSI_INDEX_C)        <= rogueMuxAxisMasters(TRIG_DATA_RSSI_INDEX_C);
--       rogueMuxAxisSlaves(TRIG_DATA_RSSI_INDEX_C)    <= rogueIbSlaves(TRIG_DATA_RSSI_INDEX_C);

--       U_AxiStreamDeMux_TRIG_DATA : entity surf.AxiStreamDeMux
--          generic map (
--             TPD_G          => TPD_G,
--             NUM_MASTERS_G  => RSSI_ROUTES_C'length,
--             MODE_G         => "ROUTED",
--             TDEST_ROUTES_G => RSSI_ROUTES_C)
--          port map (
--             axisClk      => ethClk,                                         -- [in]
--             axisRst      => ethRst,                                         -- [in]
--             sAxisMaster  => rogueDemuxAxisMasters(TRIG_DATA_RSSI_INDEX_C),  -- [in]
--             sAxisSlave   => rogueDemuxAxisSlaves(TRIG_DATA_RSSI_INDEX_C),   -- [out]
--             mAxisMasters => trigDataRssiObMasters,                          -- [out]
--             mAxisSlaves  => trigDataRssiObSlaves);                          -- [in]

--       U_AxiStreamMux_TRIG_DATA : entity surf.AxiStreamMux
--          generic map (
--             TPD_G                => TPD_G,
--             NUM_SLAVES_G         => RSSI_ROUTES_C'length,
--             MODE_G               => "ROUTED",
--             TDEST_ROUTES_G       => RSSI_ROUTES_C,
-- --            PRIORITY_G           => RSSI_PRIORITY_C,
--             ILEAVE_EN_G          => true,
--             ILEAVE_ON_NOTVALID_G => true,
--             ILEAVE_REARB_G       => (512/8)-3)
--          port map (
--             axisClk      => ethClk,     -- [in]
--             axisRst      => ethRst,     -- [in]
--             sAxisMasters => trigDataRssiIbMasters,                        -- [in]
--             sAxisSlaves  => trigDataRssiIbSlaves,                         -- [out]
--             mAxisMaster  => rogueMuxAxisMasters(TRIG_DATA_RSSI_INDEX_C),  -- [out]
--             mAxisSlave   => rogueMuxAxisSlaves(TRIG_DATA_RSSI_INDEX_C));  -- [in]                                                                           --

   end generate SIM_GEN;

   ---------------------------------------
   -- SRP RSSI TDEST = 0x00 - Local register access control   
   ---------------------------------------
   U_SRPv3 : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         GEN_SYNC_FIFO_G     => true,
         AXIL_CLK_FREQ_G     => ETH_CLK_FREQ_C,
         AXI_STREAM_CONFIG_G => AXIS_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk         => ethClk,
         sAxisRst         => ethRst,
         sAxisMaster      => srpRssiObMasters(DEST_LOCAL_SRP_DATA_C),
         sAxisSlave       => srpRssiObSlaves(DEST_LOCAL_SRP_DATA_C),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => ethClk,
         mAxisRst         => ethRst,
         mAxisMaster      => srpRssiIbMasters(DEST_LOCAL_SRP_DATA_C),
         mAxisSlave       => srpRssiIbSlaves(DEST_LOCAL_SRP_DATA_C),
         -- AXI Lite Bus (axilClk domain)
         axilClk          => ethClk,
         axilRst          => ethRst,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave);

   -----------------------------------------------------
   -- RAW DATA RSSI TDEST 0x00 - Local Streaming Data TX buffer
   -- For clock transition
   -----------------------------------------------------
   U_AxiStreamFifoV2_RAW_DATA : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         VALID_BURST_MODE_G  => false,
         SYNTH_MODE_G        => "inferred",
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
--         FIFO_PAUSE_THRESH_G => 2**9-32,
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,  -- Change this to some package constant?
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_C)
      port map (
         sAxisClk    => axisClk,        -- [in]
         sAxisRst    => axisRst,        -- [in]
         sAxisMaster => tsDaqRawAxisMaster,     -- [in]
         sAxisSlave  => tsDaqRawAxisSlave,      -- [out]
--         sAxisCtrl   => localTxAxisCtrl,                   -- [out]
         mAxisClk    => ethClk,         -- [in]
         mAxisRst    => ethRst,         -- [in]
         mAxisMaster => rawDataRssiIbMasters(DEST_LOCAL_SRP_DATA_C),  -- [out]
         mAxisSlave  => rawDataRssiIbSlaves(DEST_LOCAL_SRP_DATA_C));  -- [in]

   -----------------------------------------------------
   -- TRIG DATA RSSI TDEST 0x00 - Local Streaming Data TX buffer
   -- For clock transition
   -----------------------------------------------------
   U_AxiStreamFifoV2_TRIG_DATA : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         VALID_BURST_MODE_G  => false,
         SYNTH_MODE_G        => "inferred",
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
--         FIFO_PAUSE_THRESH_G => 2**9-32,
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,  -- Change this to some package constant?
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_C)
      port map (
         sAxisClk    => axisClk,        -- [in]
         sAxisRst    => axisRst,        -- [in]
         sAxisMaster => tsDaqTrigAxisMaster,    -- [in]
         sAxisSlave  => tsDaqTrigAxisSlave,     -- [out]
--         sAxisCtrl   => localTxAxisCtrl,                   -- [out]
         mAxisClk    => ethClk,         -- [in]
         mAxisRst    => ethRst,         -- [in]
         mAxisMaster => trigDataRssiIbMasters(DEST_LOCAL_SRP_DATA_C),  -- [out]
         mAxisSlave  => trigDataRssiIbSlaves(DEST_LOCAL_SRP_DATA_C));  -- [in]


end architecture rtl;
