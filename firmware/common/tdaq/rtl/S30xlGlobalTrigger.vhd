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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

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


entity S30xlGlobalTrigger is

   generic (
      TPD_G            : time             := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -------------------------------
      -- Input from threshold trigger
      -------------------------------
      fcClk185             : in sl;
      fcRst185             : in sl;
      thresholdTriggerData : in TriggerDataType;

      -----------------------------
      -- Prime FC messages
      -----------------------------
      lclsTimingClk     : in sl;
      lclsTimingRst     : in sl;
      lclsTimingFcTxMsg : in FcMessageType;
      lclsTimingBus     : in TimingBusType;

      --------
      -- Outut
      --------
      gtRor           : out FcTimestampType;
      gtDaqAxisMaster : out AxiStreamMasterType;
      gtDaqAxisSlave  : in  AxiStreamSlaveType;

      ---------------------------
      -- AXIL inteface
      ---------------------------      
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity S30xlGlobalTrigger;

architecture rtl of S30xlGlobalTrigger is

   -- AXI Lite
   constant NUM_AXIL_MASTERS_C       : natural := 4;
--   constant PGP_FC_LANE_AXIL_C : natural := 0;
   constant FC_RX_LOGIC_AXIL_C       : natural := 0;
   constant SYNTHETIC_TRIGGER_AXIL_C : natural := 1;
   constant BC0_ALIGNER_AXIL_C       : natural := 2;
   constant TRIGGER_LOGIC_AXIL_C     : natural := 3;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      FC_RX_LOGIC_AXIL_C       => (
         baseAddr              => AXIL_BASE_ADDR_G + X"0000",
         addrBits              => 8,
         connectivity          => X"FFFF"),
      SYNTHETIC_TRIGGER_AXIL_C => (
         baseAddr              => AXIL_BASE_ADDR_G + X"0100",
         addrBits              => 8,
         connectivity          => X"FFFF"),
      BC0_ALIGNER_AXIL_C       => (
         baseAddr              => AXIL_BASE_ADDR_G + X"0200",
         addrBits              => 8,
         connectivity          => X"FFFF"),
      TRIGGER_LOGIC_AXIL_C     => (
         baseAddr              => AXIL_BASE_ADDR_G + X"0300",
         addrBits              => 8,
         connectivity          => X"FFFF"));

   signal syncAxilReadMaster  : AxiLiteReadMasterType;
   signal syncAxilReadSlave   : AxiLiteReadSlaveType;
   signal syncAxilWriteMaster : AxiLiteWriteMasterType;
   signal syncAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal synFcMsg       : FcMessageType;
   signal synTriggerData : TriggerDataType;
   signal fcBus          : FcBusType;

   signal triggerData      : TriggerDataArray(1 downto 0);
   signal triggerTimestamp : FcTimestampType;

begin
   U_AxiLiteAsync_1 : entity surf.AxiLiteAsync
      generic map (
         TPD_G         => TPD_G,
         COMMON_CLK_G  => false,
         PIPE_STAGES_G => 0)
      port map (
         sAxiClk         => axilClk,              -- [in]
         sAxiClkRst      => axilRst,              -- [in]
         sAxiReadMaster  => axilReadMaster,       -- [in]
         sAxiReadSlave   => axilReadSlave,        -- [out]
         sAxiWriteMaster => axilWriteMaster,      -- [in]
         sAxiWriteSlave  => axilWriteSlave,       -- [out]
         mAxiClk         => lclsTimingClk,        -- [in]
         mAxiClkRst      => lclsTimingRst,        -- [in]
         mAxiReadMaster  => syncAxilReadMaster,   -- [out]
         mAxiReadSlave   => syncAxilReadSlave,    -- [in]
         mAxiWriteMaster => syncAxilWriteMaster,  -- [out]
         mAxiWriteSlave  => syncAxilWriteSlave);  -- [in]

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => lclsTimingClk,
         axiClkRst           => lclsTimingRst,
         sAxiWriteMasters(0) => syncAxilWriteMaster,
         sAxiWriteSlaves(0)  => syncAxilWriteSlave,
         sAxiReadMasters(0)  => syncAxilReadMaster,
         sAxiReadSlaves(0)   => syncAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   -- Convert FC Messages to FC Bus for BC0 alignment
   U_FcRxLogic_1 : entity ldmx_tdaq.FcRxLogic
      generic map (
         TPD_G                => TPD_G,
         AXIL_CLK_IS_FC_CLK_G => true)
      port map (
         fcClk185        => lclsTimingClk,                            -- [in]
         fcRst185        => lclsTimingRst,                            -- [in]
         fcValid         => lclsTimingFcTxMsg.valid,                  -- [in]
         fcWord          => lclsTimingFcTxMsg.message,                -- [in]
         fcBus           => fcBus,                                    -- [out]
         axilClk         => lclsTimingClk,                            -- [in]
         axilRst         => lclsTimingRst,                            -- [in]
         axilReadMaster  => locAxilReadMasters(FC_RX_LOGIC_AXIL_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(FC_RX_LOGIC_AXIL_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(FC_RX_LOGIC_AXIL_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(FC_RX_LOGIC_AXIL_C));  -- [out]

   U_SyntheticTrigger_1 : entity ldmx_tdaq.SyntheticTrigger
      generic map (
         TPD_G                => TPD_G,
         AXIL_CLK_IS_FC_CLK_G => true)
      port map (
         fcClk           => lclsTimingClk,                                  -- [in]
         fcRst           => lclsTimingRst,                                  -- [in]
         fcBus           => fcBus,                                          -- [in]
         lclsTimingBus   => lclsTimingBus,                                  -- [in]
         triggerData     => synTriggerData,                                 -- [out]
         axilClk         => lclsTimingClk,                                  -- [in]
         axilRst         => lclsTimingRst,                                  -- [in]
         axilReadMaster  => locAxilReadMasters(SYNTHETIC_TRIGGER_AXIL_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(SYNTHETIC_TRIGGER_AXIL_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(SYNTHETIC_TRIGGER_AXIL_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(SYNTHETIC_TRIGGER_AXIL_C));  -- [out]


   -- Align all the trigger data based on bc0
   U_Bc0Aligner_1 : entity ldmx_tdaq.Bc0Aligner
      generic map (
         TPD_G       => TPD_G,
         CHANNELS_G  => 2,
         WORD_SIZE_G => TRIGGER_WORD_SIZE_C)
      port map (
         triggerClks(0)   => lclsTimingClk,                            -- [in]
         triggerClks(1)   => fcClk185,                                 -- [in]
         triggerRsts(0)   => lclsTimingRst,                            --[in]
         triggerRsts(1)   => fcRst185,                                 -- [in]
         triggerDataIn(0) => synTriggerData,                           -- [in]
         triggerDataIn(1) => thresholdTriggerData,                     -- [in]
         fcClk185         => lclsTimingClk,                            -- [in]
         fcRst185         => lclsTimingRst,                            -- [in]
         fcBus            => fcBus,                                    -- [in]
         triggerDataOut   => triggerData,                              -- [out]
         triggerTimestamp => triggerTimestamp,                         -- [out]
--          axilClk          => axilClk,                                  -- [in]
--          axilRst          => axilRst,                                  -- [in]
         axilReadMaster   => locAxilReadMasters(BC0_ALIGNER_AXIL_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(BC0_ALIGNER_AXIL_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(BC0_ALIGNER_AXIL_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(BC0_ALIGNER_AXIL_C));  -- [out]

   U_S30xlGlobalTriggerLogic_1 : entity ldmx_tdaq.S30xlGlobalTriggerLogic
      generic map (
         TPD_G => TPD_G)
      port map (
         lclsTimingClk          => lclsTimingClk,                              -- [in]
         lclsTimingRst          => lclsTimingRst,                              -- [in]
         tsThresholdTriggerData => triggerData(1),                             -- [in]
         synTriggerData         => triggerData(0),                             -- [in]
         triggerTimestamp       => triggerTimestamp,                           -- [in]
         fcBus                  => fcBus,                                      -- [in]
         gtRor                  => gtRor,
         gtDaqAxisMaster        => gtDaqAxisMaster,
         gtDaqAxisSlave         => gtDaqAxisSlave,
--          axilClk                => axilClk,                                    -- [in]
--          axilRst                => axilRst,                                    -- [in]
         axilReadMaster         => locAxilReadMasters(TRIGGER_LOGIC_AXIL_C),   -- [in]
         axilReadSlave          => locAxilReadSlaves(TRIGGER_LOGIC_AXIL_C),    -- [out]
         axilWriteMaster        => locAxilWriteMasters(TRIGGER_LOGIC_AXIL_C),  -- [in]
         axilWriteSlave         => locAxilWriteSlaves(TRIGGER_LOGIC_AXIL_C));  -- [out]


end architecture rtl;
