-------------------------------------------------------------------------------
-- File       : TsDaq.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp2fcPkg.all;
use surf.EthMacPkg.all;
use surf.SsiPkg.all;

-- library axi_pcie_core;
-- use axi_pcie_core.AxiPciePkg.all;

library ldmx;
use ldmx.FcPkg.all;
use ldmx.TsPkg.all;

entity TsDaq is

   generic (
      TPD_G      : time    := 1 ns;
      TS_LANES_G : integer := 2);

   port (
      -- TS Raw Data and Timing
      fcClk185   : in sl;
      fcRst185   : in sl;
      fcTsRxMsgs : in TsData6ChMsgArray(TS_LANES_G-1 downto 0);
      fcMsgTime  : in FcTimestampType;

      tsRor : out FcTimestampType;

      -- Streaming interface to ETH
      axisClk         : in  sl;
      axisRst         : in  sl;
      tsDaqAxisMaster : out AxiStreamMasterType;
      tsDaqAxisSlave  : in  AxiStreamSlaveType);

end entity TsDaq;

architecture rtl of TsDaq is

   constant FIFO_WIDTH_C     : integer             := TS_DATA_6CH_MSG_SIZE_C*TS_LANES_G + FC_TIMESTAMP_SIZE_C;
   constant AXIS_BYTES_C     : integer             := wordCount(FIFO_WIDTH_C, 8);
   constant SLAVE_AXIS_CFG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 32, tDestBits => 0);

   signal sAxisMaster : AxiStreamMasterType := axiStreamMasterInit(SLAVE_AXIS_CFG_C);

begin

   sAxisMaster.tData(69 downto 0) <= toSlv(fcMsgTime);
   GEN_DATA : for i in 0 to TS_LANES_G-1 generate
      sAxisMaster.tData(72+((i+1)*TS_DATA_6CH_MSG_SIZE_C)-1 downto 72+(i*TS_DATA_6CH_MSG_SIZE_C)) <= toSlv(fcTsRxMsgs(i));
   end generate GEN_DATA;

   sAxisMaster.tValid <= fcMsgTime.valid or fcTsRxMsgs(0).strobe;
   sAxisMaster.tLast  <= fcMsgTime.valid or fcTsRxMsgs(0).strobe;


   U_AxiStreamFifoV2_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 0,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,
--          VALID_THOLD_G          => VALID_THOLD_G,
--          VALID_BURST_MODE_G     => VALID_BURST_MODE_G,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 8,
--          FIFO_FIXED_THRESH_G    => FIFO_FIXED_THRESH_G,
--          FIFO_PAUSE_THRESH_G    => FIFO_PAUSE_THRESH_G,
         SYNTH_MODE_G        => "inferred",
         MEMORY_TYPE_G       => "block",
--          INT_WIDTH_SELECT_G     => INT_WIDTH_SELECT_G,
--          INT_DATA_WIDTH_G       => INT_DATA_WIDTH_G,
--          LAST_FIFO_ADDR_WIDTH_G => LAST_FIFO_ADDR_WIDTH_G,
--          CASCADE_PAUSE_SEL_G    => CASCADE_PAUSE_SEL_G,
--          CASCADE_SIZE_G         => CASCADE_SIZE_G,
         SLAVE_AXI_CONFIG_G  => SLAVE_AXIS_CFG_C,
         MASTER_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => fcClk185,         -- [in]
         sAxisRst    => fcRst185,         -- [in]
         sAxisMaster => sAxisMaster,      -- [in]
         sAxisSlave  => open,             -- [out]
         sAxisCtrl   => open,             -- [out]
--         fifoWrCnt       => fifoWrCnt,        -- [out]
--         fifoFull        => fifoFull,         -- [out]
         mAxisClk    => axisClk,          -- [in]
         mAxisRst    => axisRst,          -- [in]
         mAxisMaster => tsDaqAxisMaster,  -- [out]
         mAxisSlave  => tsDaqAxisSlave,   -- [in]
         mTLastTUser => open);            -- [out]

   tsRor.valid <= toSl(fcTsRxMsgs(0).strobe = '1' and
                       fcTsRxMsgs(0).adc(0) = X"00" and
                       fcTsRxMsgs(0).adc(1) = X"01" and
                       fcTsRxMsgs(0).adc(2) = X"02" and
                       fcTsRxMsgs(0).adc(3) = X"03" and
                       fcTsRxMsgs(0).adc(4) = X"04" and
                       fcTsRxMsgs(0).adc(5) = X"05" and
                       fcTsRxMsgs(1).strobe = '1' and
                       fcTsRxMsgs(1).adc(0) = X"101010" and
                       fcTsRxMsgs(1).adc(1) = X"101010" and
                       fcTsRxMsgs(1).adc(2) = X"101010" and
                       fcTsRxMsgs(1).adc(3) = X"101010" and
                       fcTsRxMsgs(1).adc(4) = X"101010" and
                       fcTsRxMsgs(1).adc(5) = X"101010");

   tsRor.pulseId    <= fcMsgTime.pulseId;
   tsRor.bunchCount <= fcMsgTime.bunchCount;

end architecture rtl;
