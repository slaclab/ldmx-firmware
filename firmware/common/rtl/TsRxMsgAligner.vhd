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

library ldmx;
use ldmx.TsPkg.all;
use ldmx.FcPkg.all;

entity TsRxMsgAligner is

   generic (
      TPD_G : time := 1 ns);
   port (
      tsClk250 : in sl;
      tsRst250 : in sl;
      tsRxMsg  : in TsData6ChMsgType;

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FastControlBusType;

      -- Output Sync'd to fcClk185
      fcTsRxMsg : TsData6ChMsgType;
      fcMsgTime : FcReadoutRequestType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity TsRxMsgAligner;

architecture rtl of TsRxMsgAligner is

   -- tsClk250 signals
   signal tsRxMsgSlv : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);

   -- fcClk185 signals
   type TsRegType is record
      tsMsgFifoRdEn       : sl;
      timestampFifoRdEn   : sl;
      timestampFifoWrEn   : sl;
      timestampFifoWrData : slv(69 downto 0);
   end record RegType;

   constant TS_REG_INIT_C : TsRegType := (
      msgFifoWrEn => '0');

   signal tsR   : TsRegType := REG_INIT_C;
   signal tsRin : TsRegType;

   -- Ts Msg FIFO
   signal tsMsgFifoRdData : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
   signal tsMsgFifoValid  : sl;
   signal tsMsgFifoMsg    : TsData6ChMsgType;

   -- Timestamp FIFO
   signal timestampFifoRdData : slv(69 downto 0);
   signal timestampFifoValid  : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- Incomming TS messages go into FIFO
   -- This should always have 0 or 1 entries since it is always read out.
   -- It's purpose is to align TS data to the FC clock
   -------------------------------------------------------------------------------------------------
   tsRxMsgSlv <= toSlv(tsRxMsg);
   U_Fifo_TsData : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         FWFT_EN_G       => true,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "distributed",
         PIPE_STAGES_G   => 0,
         DATA_WIDTH_G    => TS_DATA_6CH_MSG_SIZE_C,
         ADDR_WIDTH_G    => 4)
      port map (
         rst           => rst,              -- [in]
         wr_clk        => tsClk250,         -- [in]
         wr_en         => tsRxMsg.strobe,   -- [in]
         din           => txRxMsgSlv,       -- [in]
         wr_data_count => open,             -- [out]
         rd_clk        => fcClk185,         -- [in]
         rd_en         => r.tsMsgFifoRdEn,  -- [in]
         dout          => tsMsgFifoRdData,  -- [out]
         rd_data_count => open,             -- [out]
         valid         => tsMsgFifoValid);  -- [out]

   tsMsgFifoMsg <= toTsData6ChMsg(tsMsgFifoRdData, tsMsgFifoValid);

   -------------------------------------------------------------------------------------------------
   -- Timestamp FIFO
   -- Once alignment begins, timestamps are written to the fifo every bunch clock
   -- Depth depends on BC0 latency
   -------------------------------------------------------------------------------------------------
   U_Fifo_FcTimestampFifo : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         FWFT_EN_G       => true,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "block",
         PIPE_STAGES_G   => 0,
         DATA_WIDTH_G    => 70,
         ADDR_WIDTH_G    => 8)
      port map (
         rst           => rst,                    -- [in]
         wr_clk        => fcClk185,               -- [in]
         wr_en         => r.timestampFifoWrEn,    -- [in]
         din           => r.timestampFifoWrData,  -- [in]
         wr_data_count => open,                   -- [out]
         rd_clk        => fcClk185,               -- [in]
         rd_en         => r.timestampFifoRdEn,    -- [in]
         dout          => timstampFifoRdData,     -- [out]
         rd_data_count => open,                   -- [out]
         valid         => timestampFifoValid);    -- [out]   


   comb : process (r, tsRst250, tsRxData, tsRxDataK) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      v.tsMsgFifoRdEn     := '0';
      v.timestampFifoRdEn := '0';
      v.timestampFifoWrEn := '0';

      v.fcTsRxMsg.strobe := '0';
      v.fcMsgTime.valid  := '0';


      case r.state is
         when WAIT_CLOCK_ALIGN_S =>
            -- Bleed off both fifo's when in reset state
            if (fcBus.runState = RUN_STATE_RESET_C) then
               v.tsMsgFifoRdEn     := '1';
               v.timestampFifoRdEn := '1';
            end if;

            -- Start alignment when FC runState moves to CLOCK_ALIGN state
            if (fcBus.pulseStrobe = '1' and fcBus.stateChange = '1' and fcBus.runState = RUN_STATE_CLOCK_ALIGN_C) then
               -- Stop bleeding the timestamp fifo
               v.timestampFifoRdEn   := '0';
               -- Start writing timestamps
               v.timestampFifoWrEn   := '1';
               v.timestampFifoWrData := fcBus.pulseId & fcBus.bunchClk;
               v.state               := WAIT_BC0_S
            end if;

         when WAIT_BC0_S =>
            if (fcBus.bunchStrobe = '1') then
               -- Write a new timestamp with each bunch strobe
               v.timestampFifoWrEn   := '1';
               v.timestampFifoWrData := fcBus.pulseId & fcBus.bunchClk;

               -- Read a message from ts data fifo
               v.tsMsgFifoRdEn := '1';

               -- If current message has BC0 set, then done aligning
               if (fcTsRxMsg.valid = '1' and fcTsRxMsg.bc0 = '1') then
                  -- Read from timestamp fifo and output ts data and fc timestamp together
                  v.timestampFifoRdEn    := '1';
                  v.fcTsRxMsg            := fcTsRxMsg;
                  v.fcMsgTime.pulseId    := timestampFifoRdData(70 downto 6);
                  v.fcMsgTime.bunchCount := timestampFifoRdData(5 downto 0);
                  v.state                := ALIGNED_S;
               end if;
            end if;

            -- Reset alignment if run state transitions before BC0
            if (fcBus.runState /= RUN_STATE_CLOCK_ALIGN_C) then
               v.runState := WAIT_CLOCK_ALIGN_S;
            end if;

         when ALIGNED_S =>
            if (fcBus.bunchStrobe = '1') then
               -- Write timestamp each bunch clock
               v.timestampFifoWrEn   := '1';
               v.timestampFifoWrData := fcBus.pulseId & fcBus.bunchClk;

               -- Read timestamp and rs data each bunch clock
               v.tsMsgFifoRdEn        := '1';
               v.timestampFifoRdEn    := '1';
               v.fcTsRxMsg            := fcTsRxMsg;
               v.fcMsgTime.pulseId    := timestampFifoRdData(70 downto 6);
               v.fcMsgTime.bunchCount := timestampFifoRdData(5 downto 0);
            end if;

            -- Reset alignment when run state goes to reset
            if (fcBus.runState = RUN_STATE_RESET_C) then
               v.state := WAIT_CLOCK_ALIGN_S;
            end if;


         when others => null;
      end case;

      -- Reset
      if (fcClk185 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      fcTsRxMsg <= r.fcTsRxMsg;
      fcMsgTime <= r.fcMsgTime;

      rin <= v;


   end process comb;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;


