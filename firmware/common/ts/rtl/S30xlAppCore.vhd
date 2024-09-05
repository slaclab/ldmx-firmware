-------------------------------------------------------------------------------
-- Title      : S30XL Application Core
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.TriggerPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity S30xlAppCore is
   generic (
      TPD_G            : time             := 1 ns;
      SIM_SPEEDUP_G    : boolean          := false;
      TS_LANES_G       : integer          := 2;
      TS_REFCLKS_G     : integer          := 1;
      TS_REFCLK_MAP_G  : IntegerArray     := (0 => 0, 1 => 0);  -- Map a refclk index to each fiber
      AXIL_CLK_FREQ_G  : real             := 125.0e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -- FC Receiver
      -- (Looped back from fcHub IO)
      appFcRefClkP : in  sl;
      appFcRefClkN : in  sl;
      appFcRxP     : in  sl;
      appFcRxN     : in  sl;
      appFcTxP     : out sl;
      appFcTxN     : out sl;

      -- TS Interface
      tsRefClk250P : in  slv(TS_REFCLKS_G-1 downto 0);
      tsRefClk250N : in  slv(TS_REFCLKS_G-1 downto 0);
      tsDataRxP    : in  slv(TS_LANES_G-1 downto 0);
      tsDataRxN    : in  slv(TS_LANES_G-1 downto 0);
      tsDataTxP    : out slv(TS_LANES_G-1 downto 0);
      tsDataTxN    : out slv(TS_LANES_G-1 downto 0);

      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- GT Stream
      fcClk185Out          : out sl;
      fcRst185Out          : out sl;
      thresholdTriggerData : out TriggerDataType;

      -- DAQ Stream
      axisClk             : in  sl;
      axisRst             : in  sl;
      tsDaqRawAxisMaster  : out AxiStreamMasterType;
      tsDaqRawAxisSlave   : in  AxiStreamSlaveType;
      tsDaqTrigAxisMaster : out AxiStreamMasterType;
      tsDaqTrigAxisSlave  : in  AxiStreamSlaveType);

end entity S30xlAppCore;

architecture rtl of S30xlAppCore is

   -- AXI Lite
   constant AXIL_NUM_C     : integer := 4;
   constant AXIL_FC_RX_C   : integer := 0;
   constant AXIL_TS_RX_C   : integer := 1;
   constant AXIL_TS_DAQ_C  : integer := 2;
   constant AXIL_TS_TRIG_C : integer := 3;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(AXIL_NUM_C-1 downto 0) := (
      AXIL_FC_RX_C    => (
         baseAddr     => AXIL_BASE_ADDR_G + X"0000_0000",
         addrBits     => 20,
         connectivity => X"FFFF"),
      AXIL_TS_RX_C    => (
         baseAddr     => AXIL_BASE_ADDR_G + X"2000_0000",
         addrBits     => 29,
         connectivity => X"FFFF"),
      AXIL_TS_DAQ_C   => (
         baseAddr     => AXIL_BASE_ADDR_G + X"00100000",
         addrBits     => 8,
         connectivity => X"FFFF"),
      AXIL_TS_TRIG_C  => (
         baseAddr     => AXIL_BASE_ADDR_G + X"00100100",
         addrBits     => 8,
         connectivity => X"FFFF"));

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_NUM_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_NUM_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   -----------------------------
   -- Fast Control clock and bus
   -----------------------------
   signal fcClk185 : sl;
   signal fcRst185 : sl;
   signal fcBus    : FcBusType;

   ----------
   -- TS Raw Data
   ----------
   signal fcTsRxMsgs : TsData6ChMsgArray(TS_LANES_G-1 downto 0);
   signal fcMsgTime  : FcTimestampType;

   signal tsTrigDaqData : TsS30xlThresholdTriggerDaqType;

   ------------------------
   -- Trigger logic outputs
   ------------------------
   signal tsTrigValid      : sl;
   signal tsTrigTimestamp  : FcTimestampType;
   signal tsTrigHits       : slv(11 downto 0);
   signal tsTrigAmplitudes : slv17Array(11 downto 0);


begin

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_NUM_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- Fast Control Receiver
   -------------------------------------------------------------------------------------------------
   U_FcReceiver_1 : entity ldmx_tdaq.FcReceiver
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(AXIL_FC_RX_C).baseAddr)
      port map (
         fcRefClk185P    => appFcRefClkP,                       -- [in]
         fcRefClk185N    => appFcRefClkN,                       -- [in]
         fcRecClkP       => open,                               -- [out]
         fcRecClkN       => open,                               -- [out]
         fcTxP           => appFcTxP,                           -- [out]
         fcTxN           => appFcTxN,                           -- [out]
         fcRxP           => appFcRxP,                           -- [in]
         fcRxN           => appFcRxN,                           -- [in]
         fcClk185        => fcClk185,                           -- [out]
         fcRst185        => fcRst185,                           -- [out]
         fcBus           => fcBus,                              -- [out]
--         fcFb            => FC_FB_INIT_C,                       -- [in]
         fcBunchClk37    => open,                               -- [out]
         fcBunchRst37    => open,                               -- [out]
         axilClk         => axilClk,                            -- [in]
         axilRst         => axilRst,                            -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_FC_RX_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_FC_RX_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_FC_RX_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_FC_RX_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- TS Data Receiver
   -- (Data Receiver to APX)
   -------------------------------------------------------------------------------------------------
   U_TsDataRx_1 : entity ldmx_ts.TsDataRx
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIM_SPEEDUP_G,
         TS_LANES_G       => TS_LANES_G,
         TS_REFCLKS_G     => TS_REFCLKS_G,
         TS_REFCLK_MAP_G  => TS_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(AXIL_TS_RX_C).baseAddr)
      port map (
         tsRefClk250P    => tsRefClk250P,                       -- [in]
         tsRefClk250N    => tsRefClk250N,                       -- [in]
         tsDataRxP       => tsDataRxP,                          -- [in]
         tsDataRxN       => tsDataRxN,                          -- [in]
         tsDataTxP       => tsDataTxP,                          -- [out]
         tsDataTxN       => tsDataTxN,                          -- [out]
         fcClk185        => fcClk185,                           -- [in]
         fcRst185        => fcRst185,                           -- [in]
         fcBus           => fcBus,                              -- [in]
         fcTsRxMsgs      => fcTsRxMsgs,                         -- [out]
         fcMsgTime       => fcMsgTime,                          -- [out]
         axilClk         => axilClk,                            -- [in]
         axilRst         => axilRst,                            -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_TS_RX_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_TS_RX_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_TS_RX_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_TS_RX_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- DAQ Block Shell
   -- (Probably includes Data to DAQ sender and Common block for LDMX event header/trailer)
   -------------------------------------------------------------------------------------------------
   U_TsRawDaq_1 : entity ldmx_ts.TsRawDaq
      generic map (
         TPD_G      => TPD_G,
         TS_LANES_G => TS_LANES_G)
      port map (
         fcClk185        => fcClk185,            -- [in]
         fcRst185        => fcRst185,            -- [in]
         fcBus           => fcBus,               -- [in]
         fcTsRxMsgs      => fcTsRxMsgs,          -- [in]
         fcMsgTime       => fcMsgTime,           -- [in]
         axisClk         => axisClk,             -- [in]
         axisRst         => axisRst,             -- [in]
         eventAxisMaster => tsDaqRawAxisMaster,  -- [out]
         eventAxisSlave  => tsDaqRawAxisSlave);  -- [in]

   -------------------------------------------------------------------------------------------------
   -- Trigger algorithm block
   -------------------------------------------------------------------------------------------------
   U_TsS30xlThresholdTriggerWrapper_1 : entity ldmx_ts.TsS30xlThresholdTriggerWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         fcClk185  => fcClk185,                 -- [in]
         fcRst185  => fcRst185,                 -- [in]
         fcTsMsg   => fcTsRxMsgs,               -- [in]
         fcMsgTime => fcMsgTime,                -- [in]
         daqData   => tsTrigDaqData,            -- [out]
         gtData    => thresholdTriggerData);  -- [out]

   -------------------------------------------------------------------------------------------------
   -- Trigger DAQ block
   -------------------------------------------------------------------------------------------------
   U_TsTrigDaq_1 : entity ldmx_ts.TsTrigDaq
      
      generic map (
         TPD_G      => TPD_G,
         TS_LANES_G => TS_LANES_G)
      port map (
         fcClk185         => fcClk185,             -- [in]
         fcRst185         => fcRst185,             -- [in]
         fcBus            => fcBus,                -- [in]
         tsTrigDaqData    => tsTrigDaqData,        -- [in]
         axisClk          => axisClk,              -- [in]
         axisRst          => axisRst,              -- [in]
         eventAxisMaster => tsDaqTrigAxisMaster,  -- [out]
         eventAxisSlave  => tsDaqTrigAxisSlave);  -- [in]


   -------------------------------------------------------------------------------------------------
   -- Data to GT Sender
   -- (Encodes trigger data for transmission to GT)
   -------------------------------------------------------------------------------------------------
   fcClk185Out <= fcClk185;
   fcRst185Out <= fcRst185;


end architecture rtl;



