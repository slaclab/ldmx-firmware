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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.TriggerPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;


entity S30xlGlobalTrigger is

   generic (
      TPD_G : time := 1 ns);
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

      --------
      -- Outut
      --------
      gtRor           : FcTimestampType;
      gtDaqAxisMaster : AxiStreamMasterType;
      gtDaqAxisSlave  : AxiStreamSlaveType;


      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity S30xlGlobalTrigger;

architecture rtl of S30xlGlobalTrigger is

   -- AXI Lite
   constant NUM_AXIL_MASTERS_C : natural := 3;
--   constant PGP_FC_LANE_AXIL_C : natural := 0;
   constant FC_RX_LOGIC_AXIL_C : natural := 0;
   constant FC_EMU_AXIL_C      : natural := 1;
   constant BC0_ALIGNER_AXIL_C : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      FC_RX_LOGIC_AXIL_C => (
         baseAddr        => AXIL_BASE_ADDR_G + X"0000",
         addrBits        => 8,
         connectivity    => X"FFFF"),
      FC_EMU_AXIL_C      => (
         baseAddr        => AXIL_BASE_ADDR_G + X"0100",
         addrBits        => 8,
         connectivity    => X"FFFF"),
      BC0_ALIGNER_AXIL_C => (
         baseAddr        => AXIL_BASE_ADDR_G + X"0200",
         addrBits        => 8,
         connectivity    => X"FFFF"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal emuFcMsg       : FcMessageType;
   signal emuTriggerData : TriggerDataType;
   signal fcBus          : FcBusType;

begin

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
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

   -- Convert FC Messages to FC Bus for BC0 alignment
   U_FcRxLogic_1 : entity ldmx_tdaq.FcRxLogic
      generic map (
         TPD_G => TPD_G)
      port map (
         fcClk185        => lclsTimingClk,                            -- [in]
         fcRst185        => lclsTimingRst,                            -- [in]
         fcValid         => lclsTimingFcTxMsg.valid,                  -- [in]
         fcWord          => lclsTimingFcTxMsg.message,                -- [in]
         fcBus           => fcBus,                                    -- [out]
         axilClk         => axilClk,                                  -- [in]
         axilRst         => axilRst,                                  -- [in]
         axilReadMaster  => locAxilReadMasters(FC_RX_LOGIC_AXIL_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(FC_RX_LOGIC_AXIL_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(FC_RX_LOGIC_AXIL_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(FC_RX_LOGIC_AXIL_C));  -- [out]

   -- Use FcEmu for synthetic triggers
   U_FcEmu_1 : entity ldmx_tdaq.FcEmu
      generic map (
         TPD_G                => TPD_G,
         AXIL_CLK_IS_FC_CLK_G => false)
      port map (
         fcClk           => lclsTimingClk,                       -- [in]
         fcRst           => lclsTimingRst,                       -- [in]
         enabled         => open,                                -- [out]
         fcMsg           => emuFcMsg,                            -- [out]
         bunchClk        => open,                                -- [out]
         bunchStrobe     => open,                                -- [out]
         axilClk         => axilClk,                             -- [in]
         axilRst         => axilRst,                             -- [in]
         axilReadMaster  => locAxilReadMasters(FC_EMU_AXIL_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(FC_EMU_AXIL_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(FC_EMU_AXIL_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(FC_EMU_AXIL_C));  -- [out]

   emuTriggerData.valid                     <= emuFcMsg.valid;
   emuTriggerData.bc0                       <= fcBus.bc0;
   emuTriggerData.data(FC_LEN_C-1 downto 0) <= emuFcMsg.message;


   -- Align all the trigger data based on bc0
   U_Bc0Aligner_1 : entity ldmx_tdaq.Bc0Aligner
      generic map (
         TPD_G       => TPD_G,
         CHANNELS_G  => 1,
         WORD_SIZE_G => TRIGGER_WORD_SIZE_C)
      port map (
         triggerClks(0)   => lclsTimingClk,                            -- [in]
         triggerClks(1)   => fcClk186,                                 -- [in]
         triggerRsts(1)   => lclsTimingRst,                            --[in]
         triggerRsts(1)   => fcRst185,                                 -- [in]
         triggerDataIn(0) => emuTriggerData,                           -- [in]
         triggerDataIn(1) => thresholdTriggerData,                     -- [in]
         fcClk185         => lclsTimingClk,                            -- [in]
         fcRst185         => lclsTimingRst,                            -- [in]
         fcBus            => fcBus,                                    -- [in]
         triggerDataOut   => triggerDataOut,                           -- [out]
         triggerTimestamp => triggerTimestamp,                         -- [out]
         axilClk          => axilClk,                                  -- [in]
         axilRst          => axilRst,                                  -- [in]
         axilReadMaster   => locAxilReadMasters(BC0_ALIGNER_AXIL_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(BC0_ALIGNER_AXIL_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(BC0_ALIGNER_AXIL_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(BC0_ALIGNER_AXIL_C));  -- [out]


end architecture rtl;
