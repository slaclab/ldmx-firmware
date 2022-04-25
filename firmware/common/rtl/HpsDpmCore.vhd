-------------------------------------------------------------------------------
-- Title      : HPS DPM Core
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for DpmCore and user ethernet blocks
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
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


library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

entity HpsDpmCore is
   generic (
      TPD_G                : time                     := 1 ns;
      BUILD_INFO_G         : BuildInfoType;
      SIMULATION_G         : boolean                  := false;
      SIM_MEM_PORT_NUM_G   : natural range 0 to 65535 := 1;
      SIM_DMA_PORT_NUM_G   : natural range 0 to 65535 := 1;
      SIM_DMA_TDESTS_G     : natural range 1 to 256   := 256;
      ETH_TYPE_G           : string                   := "10GBASE-KX4";
      RSSI_EN_G            : boolean                  := true;
      RSSI_BYP_TX_BUFFER_G : boolean                  := false;
      RSSI_BYP_RX_BUFFER_G : boolean                  := false;
      RSSI_AXIS_CONFIG_G   : AxiStreamConfigType      := RCEG3_AXIS_DMA_CONFIG_C);
   port (
      -- I2C
      i2cSda          : inout sl;
      i2cScl          : inout sl;
      -- Ethernet
      ethRxP          : in    slv(3 downto 0);
      ethRxM          : in    slv(3 downto 0);
      ethTxP          : out   slv(3 downto 0);
      ethTxM          : out   slv(3 downto 0);
      ethRefClkP      : in    sl;
      ethRefClkM      : in    sl;
      -- Clock Select
      clkSelA         : out   slv(1 downto 0);
      clkSelB         : out   slv(1 downto 0);
      -- Clocks and Resets
      sysClk125       : out   sl;
      sysClk125Rst    : out   sl;
      sysClk200       : out   sl;
      sysClk200Rst    : out   sl;
      -- External AXI-Lite Interface [0xA0000000:0xAEFFFFFF]
      axilClk         : out   sl;
      axilRst         : out   sl;
      axilReadMaster  : out   AxiLiteReadMasterType;
      axilReadSlave   : in    AxiLiteReadSlaveType;
      axilWriteMaster : out   AxiLiteWriteMasterType;
      axilWriteSlave  : in    AxiLiteWriteSlaveType;
      -- DMA Interface (1 Stream on DMA0) -- 64 bits wide (RCEG3_AXIS_DMA_CONFIG_C)
      dmaClk          : out   sl;       -- User provides clock
      dmaRst          : out   sl;
      dmaObMaster     : out   AxiStreamMasterType;
      dmaObSlave      : in    AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
      dmaIbMaster     : in    AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dmaIbSlave      : out   AxiStreamSlaveType;
      -- RSSI Interface -- RSSI_AXIS_CONFIG_G
      rssiClk         : out   sl;
      rssiRst         : out   sl;
      rssiObMaster    : out   AxiStreamMasterType;
      rssiObSlave     : in    AxiStreamSlaveType;
      rssiIbMaster    : in    AxiStreamMasterType;
      rssiIbSlave     : out   AxiStreamSlaveType

      );

end HpsDpmCore;

architecture rtl of HpsDpmCore is


   -- Local clocks
   signal iSysClk125    : sl;
   signal iSysClk125Rst : sl;
   signal iSysClk200    : sl;
   signal iSysClk200Rst : sl;

   -- DMA
   signal iDmaClk      : slv(2 downto 0);
   signal iDmaRst      : slv(2 downto 0);
   signal dmaState     : RceDmaStateArray(2 downto 0);
   signal dmaObMasters : AxiStreamMasterArray(2 downto 0);
   signal dmaObSlaves  : AxiStreamSlaveArray(2 downto 0);
   signal dmaIbMasters : AxiStreamMasterArray(2 downto 0);
   signal dmaIbSlaves  : AxiStreamSlaveArray(2 downto 0);

   -- User ETH interface (userEthClk domain)
   constant UDP_SERVER_SIZE_C  : integer       := 1;
   constant UDP_SERVER_PORTS_C : PositiveArray := (0 => 8192);
   constant ETH_CLK_FREQ_C     : real          := ite(ETH_TYPE_G = "10GBASE-KX4", 156.25E6, 125.0E6);

   signal ethClk   : sl;
   signal ethRst   : sl;
   signal localIp  : slv(31 downto 0);
   signal localMac : slv(47 downto 0);

   signal dpmEthIbMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal dpmEthIbSlave  : AxiStreamSlaveType;
   signal dpmEthObMaster : AxiStreamMasterType;
   signal dpmEthObSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

   signal udpObServerMaster : AxiStreamMasterType;
   signal udpObServerSlave  : AxiStreamSlaveType;
   signal udpIbServerMaster : AxiStreamMasterType;
   signal udpIbServerSlave  : AxiStreamSlaveType;

   -- AXI-Lite
   constant AXIL_XBAR_MASTERS_C : integer := 3;
   constant EXT_AXIL_INDEX_C    : integer := 0;
   constant UDP_AXIL_INDEX_C    : integer := 1;
   constant RSSI_AXIL_INDEX_C   : integer := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(AXIL_XBAR_MASTERS_C-1 downto 0) := (
      EXT_AXIL_INDEX_C  => (
         baseAddr       => X"A0000000",
         addrBits       => 27,
         connectivity   => X"FFFF"),
      UDP_AXIL_INDEX_C  => (
         baseAddr       => X"A8000000",
         addrBits       => 12,
         connectivity   => X"FFFF"),
      RSSI_AXIL_INDEX_C => (
         baseAddr       => X"A8001000",
         addrBits       => 10,
         connectivity   => X"FFFF"));

   signal iAxilClk : sl;
   signal iAxilRst : sl;

   signal zynqAxilReadMaster  : AxiLiteReadMasterType;
   signal zynqAxilReadSlave   : AxiLiteReadSlaveType;
   signal zynqAxilWriteMaster : AxiLiteWriteMasterType;
   signal zynqAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_XBAR_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_XBAR_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_XBAR_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal udpAxilReadMaster  : AxiLiteReadMasterType;
   signal udpAxilReadSlave   : AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
   signal udpAxilWriteMaster : AxiLiteWriteMasterType;
   signal udpAxilWriteSlave  : AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;


begin

   -- Output local clocks
   sysClk125    <= iSysClk125;
   sysClk125Rst <= iSysClk125Rst;
   sysClk200    <= iSysClk200;
   sysClk200Rst <= iSysClk200Rst;
   axilClk      <= iAxilClk;            -- identical to sysClk125
   axilRst      <= iAxilRst;
   rssiClk      <= ethClk;
   rssiRst      <= ethRst;

   -------------------------------------------------------------------------------------------------
   -- DPM Core
   -------------------------------------------------------------------------------------------------
   U_DpmCore_1 : entity rce_gen3_fw_lib.DpmCore
      generic map (
         TPD_G              => TPD_G,
         BUILD_INFO_G       => BUILD_INFO_G,
         SIMULATION_G       => SIMULATION_G,
         SIM_MEM_PORT_NUM_G => SIM_MEM_PORT_NUM_G,
         SIM_DMA_PORT_NUM_G => SIM_DMA_PORT_NUM_G,
         SIM_DMA_CHANNELS_G => 1,
         SIM_DMA_TDESTS_G   => SIM_DMA_TDESTS_G,
         ETH_TYPE_G         => ETH_TYPE_G,
         RCE_DMA_MODE_G     => RCE_DMA_AXISV2_C,
         UDP_SERVER_EN_G    => RSSI_EN_G,
         UDP_SERVER_SIZE_G  => UDP_SERVER_SIZE_C,
         UDP_SERVER_PORTS_G => UDP_SERVER_PORTS_C)
      port map (
         i2cSda             => i2cSda,               -- [inout]
         i2cScl             => i2cScl,               -- [inout]
         ethRxP             => ethRxP,               -- [in]
         ethRxM             => ethRxM,               -- [in]
         ethTxP             => ethTxP,               -- [out]
         ethTxM             => ethTxM,               -- [out]
         ethRefClkP         => ethRefClkP,           -- [in]
         ethRefClkM         => ethRefClkM,           -- [in]
         clkSelA            => clkSelA,              -- [out]
         clkSelB            => clkSelB,              -- [out]
         sysClk125          => iSysClk125,           -- [out]
         sysClk125Rst       => iSysClk125Rst,        -- [out]
         sysClk200          => iSysClk200,           -- [out]
         sysClk200Rst       => iSysClk200Rst,        -- [out]
         axiClk             => iAxilClk,             -- [out]
         axiClkRst          => iAxilRst,             -- [out]
         extAxilReadMaster  => zynqAxilReadMaster,   -- [out]
         extAxilReadSlave   => zynqAxilReadSlave,    -- [in]
         extAxilWriteMaster => zynqAxilWriteMaster,  -- [out]
         extAxilWriteSlave  => zynqAxilWriteSlave,   -- [in]
         dmaClk             => iDmaClk,              -- [in]
         dmaClkRst          => iDmaRst,              -- [in]
         dmaState           => open,                 -- [out]
         dmaObMaster        => dmaObMasters,         -- [out]
         dmaObSlave         => dmaObSlaves,          -- [in]
         dmaIbMaster        => dmaIbMasters,         -- [in]
         dmaIbSlave         => dmaIbSlaves,          -- [out]
         userEthClk         => ethClk,               -- [out]
         userEthClkRst      => ethRst,               -- [out]
         userEthIpAddr      => localIp,              -- [out]
         userEthMacAddr     => localMac,             -- [out]
         userEthUdpIbMaster => dpmEthIbMaster,       -- [in]
         userEthUdpIbSlave  => dpmEthIbSlave,        -- [out]
         userEthUdpObMaster => dpmEthObMaster,       -- [out]
         userEthUdpObSlave  => dpmEthObSlave);       -- [in]


   iDmaClk(0)      <= iSysClk125;
   iDmaRst(0)      <= iSysClk125Rst;
   dmaClk          <= iDmaClk(0);
   dmaRst          <= iDmaRst(0);
   dmaObMaster     <= dmaObMasters(0);
   dmaObSlaves(0)  <= dmaObSlave;
   dmaIbMasters(0) <= dmaIbMaster;
   dmaIbSlave      <= dmaIbSlaves(0);

   DMA_STUB : for i in 2 downto 1 generate
      -- Terminate unused DMA channels
      idmaClk(i)      <= iSysClk125;
      iDmaRst(i)      <= iSysClk125Rst;
      dmaIbMasters(i) <= AXI_STREAM_MASTER_INIT_C;
      dmaObSlaves(i)  <= AXI_STREAM_SLAVE_FORCE_C;
   end generate;

   -------------------------------------------------------------------------------------------------
   -- AXI Lite Crossbar
   -------------------------------------------------------------------------------------------------
   U_AxiLiteCrossbar_1 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_XBAR_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C,
         DEBUG_G            => false)
      port map (
         axiClk              => iAxilClk,             -- [in]
         axiClkRst           => iAxilRst,             -- [in]
         sAxiWriteMasters(0) => zynqAxilWriteMaster,  -- [in]
         sAxiWriteSlaves(0)  => zynqAxilWriteSlave,   -- [out]
         sAxiReadMasters(0)  => zynqAxilReadMaster,   -- [in]
         sAxiReadSlaves(0)   => zynqAxilReadSlave,    -- [out]
         mAxiWriteMasters    => locAxilWriteMasters,  -- [out]
         mAxiWriteSlaves     => locAxilWriteSlavEs,   -- [in]
         mAxiReadMasters     => locAxilReadMasters,   -- [out]
         mAxiReadSlaves      => locAxilReadSlaves);   -- [in]

   -------------------------------------------------------------------------------------------------
   -- Output AXIL bus
   -------------------------------------------------------------------------------------------------
   axilReadMaster                       <= locAxilReadMasters(EXT_AXIL_INDEX_C);
   locAxilReadSlaves(EXT_AXIL_INDEX_C)  <= axilReadSlave;
   axilWriteMaster                      <= locAxilWriteMasters(EXT_AXIL_INDEX_C);
   locAxilWriteSlaves(EXT_AXIL_INDEX_C) <= axilWriteSlave;

   RSSI_GEN : if (RSSI_EN_G) generate

      -------------------------------------------------------------------------------------------------
      -- UDP Engine AXIL runs at stream rate, so need to sychronize it
      -------------------------------------------------------------------------------------------------
      U_AxiLiteAsync_1 : entity surf.AxiLiteAsync
         generic map (
            TPD_G => TPD_G)
         port map (
            sAxiClk         => iAxilClk,                               -- [in]
            sAxiClkRst      => iAxilRst,                               -- [in]
            sAxiReadMaster  => locAxilReadMasters(UDP_AXIL_INDEX_C),   -- [in]
            sAxiReadSlave   => locAxilReadSlaves(UDP_AXIL_INDEX_C),    -- [out]
            sAxiWriteMaster => locAxilWriteMasters(UDP_AXIL_INDEX_C),  -- [in]
            sAxiWriteSlave  => locAxilWriteSlaves(UDP_AXIL_INDEX_C),   -- [out]
            mAxiClk         => ethClk,                                 -- [in]
            mAxiClkRst      => ethRst,                                 -- [in]
            mAxiReadMaster  => udpAxilReadMaster,                      -- [out]
            mAxiReadSlave   => udpAxilReadSlave,                       -- [in]
            mAxiWriteMaster => udpAxilWriteMaster,                     -- [out]
            mAxiWriteSlave  => udpAxilWriteSlave);                     -- [in]

      -------------------------------------------------------------------------------------------------
      -- UDP Engine
      -------------------------------------------------------------------------------------------------
      U_UdpEngineWrapper_1 : entity surf.UdpEngineWrapper
         generic map (
            TPD_G          => TPD_G,
            SERVER_EN_G    => true,
            SERVER_SIZE_G  => UDP_SERVER_SIZE_C,
            SERVER_PORTS_G => UDP_SERVER_PORTS_C,
            CLIENT_EN_G    => false,
            DHCP_G         => false,
            CLK_FREQ_G     => ETH_CLK_FREQ_C)
         port map (
            localMac           => localMac,            -- [in]
            localIp            => localIp,             -- [in]
            obMacMaster        => dpmEthObMaster,      -- [in]
            obMacSlave         => dpmEthObSlave,       -- [out]
            ibMacMaster        => dpmEthIbMaster,      -- [out]
            ibMacSlave         => dpmEthIbSlave,       -- [in]
            obServerMasters(0) => udpObServerMaster,   -- [out]
            obServerSlaves(0)  => udpObServerSlave,    -- [in]
            ibServerMasters(0) => udpIbServerMaster,   -- [in]
            ibServerSlaves(0)  => udpIbServerSlave,    -- [out]
            axilReadMaster     => udpAxilReadMaster,   -- [in]
            axilReadSlave      => udpAxilReadSlave,    -- [out]
            axilWriteMaster    => udpAxilWriteMaster,  -- [in]
            axilWriteSlave     => udpAxilWriteSlave,   -- [out]
            clk                => ethClk,              -- [in]
            rst                => ethRst);             -- [in]

      -------------------------------------------------------------------------------------------------
      -- RSSI Engines
      -------------------------------------------------------------------------------------------------
      U_RssiCoreWrapper_1 : entity surf.RssiCoreWrapper
         generic map (
            TPD_G                => TPD_G,
            CLK_FREQUENCY_G      => ETH_CLK_FREQ_C,
            WINDOW_ADDR_SIZE_G   => 4,
            SEGMENT_ADDR_SIZE_G  => 7,
            BYPASS_CHUNKER_G     => false,
            PIPE_STAGES_G        => 1,
            APP_STREAMS_G        => 1,
--            APP_STREAM_ROUTES_G  => APP_STREAM_ROUTES_G,
            TIMEOUT_UNIT_G       => 1.0e-3,
            SERVER_G             => true,
            RETRANSMIT_ENABLE_G  => true,
            MAX_NUM_OUTS_SEG_G   => 16,
            INIT_SEQ_N_G         => 16#80#,
            APP_ILEAVE_EN_G      => true,
            BYP_TX_BUFFER_G      => RSSI_BYP_TX_BUFFER_G,
            BYP_RX_BUFFER_G      => RSSI_BYP_RX_BUFFER_G,
            ILEAVE_ON_NOTVALID_G => true,
            APP_AXIS_CONFIG_G    => (0 => RSSI_AXIS_CONFIG_G),
            TSP_AXIS_CONFIG_G    => EMAC_AXIS_CONFIG_C,
            MAX_SEG_SIZE_G       => 1024)
         port map (
            clk_i                => ethClk,                                  -- [in]
            rst_i                => ethRst,                                  -- [in]
            sAppAxisMasters_i(0) => rssiIbMaster,                            -- [in]
            sAppAxisSlaves_o(0)  => rssiIbSlave,                             -- [out]
            mAppAxisMasters_o(0) => rssiObMaster,                            -- [out]
            mAppAxisSlaves_i(0)  => rssiObSlave,                             -- [in]
            sTspAxisMaster_i     => udpObServerMaster,                       -- [in]
            sTspAxisSlave_o      => udpObServerSlave,                        -- [out]
            mTspAxisMaster_o     => udpIbServerMaster,                       -- [out]
            mTspAxisSlave_i      => udpIbServerSlave,                        -- [in]
            openRq_i             => '1',                                     -- [in]
            axiClk_i             => iAxilClk,                                -- [in]
            axiRst_i             => iAxilRst,                                -- [in]
            axilReadMaster       => locAxilReadMasters(RSSI_AXIL_INDEX_C),   -- [in]
            axilReadSlave        => locAxilReadSlaves(RSSI_AXIL_INDEX_C),    -- [out]
            axilWriteMaster      => locAxilWriteMasters(RSSI_AXIL_INDEX_C),  -- [in]
            axilWriteSlave       => locAxilWriteSlaves(RSSI_AXIL_INDEX_C),   -- [out]
            statusReg_o          => open);                                   -- [out]
   end generate RSSI_GEN;

end architecture rtl;
