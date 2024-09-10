-------------------------------------------------------------------------------
-- File       : TsRawDaq.vhd
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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.DaqPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;

entity TsRawDaq is

   generic (
      TPD_G      : time    := 1 ns;
      TS_LANES_G : integer := 2);

   port (
      -- TS Raw Data and Timing
      fcClk185   : in sl;
      fcRst185   : in sl;
      fcBus      : in FcBusType;
      fcTsRxMsgs : in TsData6ChMsgArray(TS_LANES_G-1 downto 0);
      fcMsgTimestamp  : in FcTimestampType;

      -- Streaming interface to ETH
      axisClk         : in  sl;
      axisRst         : in  sl;
      eventAxisMaster : out AxiStreamMasterType;
      eventAxisSlave  : in  AxiStreamSlaveType);

end entity TsRawDaq;

architecture rtl of TsRawDaq is

   constant AXIS_CFG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => 16, tDestBits => 0);

   type StateType is (WAIT_ROR_S, DO_DATA_S, TAIL_S);

   type RegType is record
      state       : StateType;
      fifoRdEn    : sl;
      laneCounter : integer range 0 to TS_LANES_G-1;
      axisMaster  : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state       => WAIT_ROR_S,
      fifoRdEn    => '0',
      laneCounter => 0,
      axisMaster  => axiStreamMasterInit(AXIS_CFG_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal tsRxMsgsSlvDelayIn     : TsData6ChMsgSlvArray(TS_LANES_G-1 downto 0);
   signal tsRxMsgsSlvDelayOut    : TsData6ChMsgSlvArray(TS_LANES_G-1 downto 0);
   signal tsRxMsgsSlvFifoOut     : TsData6ChMsgSlvArray(TS_LANES_G-1 downto 0);
   signal tsRxMsgsFifoValid      : slv(TS_LANES_G-1 downto 0);
   signal tsRxMsgsFifoOut        : TsData6ChMsgArray(TS_LANES_G-1 downto 0);
--    signal rorTimestampFifoInSlv  : slv(FC_TIMESTAMP_SIZE_C-1 downto 0);
--    signal rorTimestampFifoOutSlv : slv(FC_TIMESTAMP_SIZE_C-1 downto 0);
--    signal rorTimestampFifoValid  : sl;
--    signal rorTimestampFifoOut    : FcTimestampType;
   signal aligned                : slv(TS_LANES_G-1 downto 0);
   signal axisCtrl               : AxiStreamCtrlType;

begin

   GEN_LANES : for i in TS_LANES_G-1 downto 0 generate
      tsRxMsgsSlvDelayIn(i) <= toSlv(fcTsRxMsgs(i));
      -- Buffer and delay incoming data to ROR
      U_RorDaqDataDelay_1 : entity ldmx_tdaq.RorDaqDataDelay
         generic map (
            TPD_G         => TPD_G,
            DATA_WIDTH_G  => TS_DATA_6CH_MSG_SIZE_C,
            MEMORY_TYPE_G => "block")
         port map (
            fcClk185    => fcClk185,                 -- [in]
            fcRst185    => fcRst185,                 -- [in]
            fcBus       => fcBus,                    -- [in]
            timestampIn => fcMsgTimestamp,                -- [in]
            dataIn      => tsRxMsgsSlvDelayIn(i),    -- [in]
            aligned     => aligned(i),               -- [out]
            dataOut     => tsRxMsgsSlvDelayOut(i));  -- [out]


      -- Buffer delayed data in fifos upon each ROR
      -- Will be read out into AXI Stream frame
      ROR_DATA_FIFO : entity surf.Fifo
         generic map (
            TPD_G           => TPD_G,
            GEN_SYNC_FIFO_G => false,
            FWFT_EN_G       => true,
            SYNTH_MODE_G    => "inferred",
            MEMORY_TYPE_G   => "distributed",
            DATA_WIDTH_G    => TS_DATA_6CH_MSG_SIZE_C,
            ADDR_WIDTH_G    => 5)
         port map (
            rst    => fcRst185,                    -- [in]
            wr_clk => fcClk185,                    -- [in]
            wr_en  => fcBus.readoutRequest.valid,  -- [in]
            din    => tsRxMsgsSlvDelayOut(i),      -- [in]
            rd_clk => axisClk,                     -- [in]
            rd_en  => r.fifoRdEn,                  -- [in]
            dout   => tsRxMsgsSlvFifoOut(i),       -- [out]
            valid  => tsRxMsgsFifoValid(i));       -- [out]

      -- For debugging
      tsRxMsgsFifoOut(i) <= toTsData6ChMsg(tsRxMsgsSlvFifoOut(i), tsRxMsgsFifoValid(i));
   end generate;

--    rorTimestampFifoInSlv <= toSlv(fcMsgTimestamp);
--    ROR_TIMESTAMP_FIFO : entity surf.Fifo
--       generic map (
--          TPD_G           => TPD_G,
--          GEN_SYNC_FIFO_G => false,
--          FWFT_EN_G       => true,
--          SYNTH_MODE_G    => "inferred",
--          MEMORY_TYPE_G   => "distributed",
--          DATA_WIDTH_G    => FC_TIMESTAMP_SIZE_C,
--          ADDR_WIDTH_G    => 5)
--       port map (
--          rst    => fcRst185,                    -- [in]
--          wr_clk => fcClk185,                    -- [in]
--          wr_en  => fcBus.readoutRequest.valid,  -- [in]
--          din    => rorTimestampFifoInSlv,       -- [in]
--          rd_clk => axisClk,                     -- [in]
--          rd_en  => r.fifoRdEn,                  -- [in]
--          dout   => rorTimestampFifoOutSlv,      -- [out]
--          valid  => rorTimestampFifoValid);      -- [out]

   -- For debugging
--   rorTimestampFifoOut <= toFcTimestamp(rorTimestampFifoOutSlv, rorTimestampFifoValid);

   comb : process (r, tsRxMsgsFifoValid, tsRxMsgsSlvFifoOut) is
      variable v : RegType;
   begin
      v := r;

      v.axisMaster := axiStreamMasterInit(AXIS_CFG_C);
      v.fifoRdEn   := '0';

      case r.state is
         when WAIT_ROR_S =>
            -- Got a ROR, write the header
            if (tsRxMsgsFifoValid(0) = '1') then
               v.laneCounter                  := 0;
               v.axisMaster.tValid            := '1';
               v.axisMaster.tData(7 downto 0) := toSlv(TS_LANES_G, 8);
               v.state                        := DO_DATA_S;
            end if;

         when DO_DATA_S =>
            v.axisMaster.tValid                                   := '1';
            v.axisMaster.tData(TS_DATA_6CH_MSG_SIZE_C-1 downto 0) := tsRxMsgsSlvFifoOut(r.laneCounter);

            if (r.laneCounter = TS_LANES_G-1) then
               v.laneCounter      := 0;
               v.axisMaster.tLast := '1';
               v.fifoRdEn         := '1';
               v.state            := TAIL_S;
            else
               v.laneCounter := r.laneCounter + 1;
            end if;

         when TAIL_S =>
            v.state := WAIT_ROR_S;

      end case;

      rin <= v;

   end process comb;

   seq : process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_DaqEventFormatter_1 : entity ldmx_tdaq.DaqEventFormatter
      generic map (
         TPD_G                     => TPD_G,
         SUBSYSTEM_ID_G            => TS_SUBSYSTEM_ID_C,
         CONTRIBUTOR_ID_G          => TS_RAW_DATA_DAQ_ID_C,
         RAW_AXIS_CFG_G            => AXIS_CFG_C,
         EVENT_FIFO_PAUSE_THRESH_G => 2**7-16,
         EVENT_FIFO_ADDR_WIDTH_G   => 7,
         EVENT_FIFO_SYNTH_MODE_G   => "inferred",
         EVENT_FIFO_MEMORY_TYPE_G  => "block")
      port map (
         fcClk185        => fcClk185,         -- [in]
         fcRst185        => fcRst185,         -- [in]
         fcBus           => fcBus,            -- [in]
         axisClk         => axisClk,          -- [in]
         axisRst         => axisRst,          -- [in]
         rawAxisMaster   => r.axisMaster,     -- [in]
         rawAxisCtrl     => open,             -- [out]
         eventAxisMaster => eventAxisMaster,  -- [out]
         eventAxisSlave  => eventAxisSlave);  -- [in]   

end architecture rtl;
