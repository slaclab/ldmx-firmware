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

library ldmx_ts;
use ldmx_ts.TsPkg.all;


entity TsRxMsgAligner is

   generic (
      TPD_G      : time    := 1 ns;
      TS_LANES_G : integer := 2);
   port (
      tsRecClks : in slv(TS_LANES_G-1 downto 0);
      tsRecRsts : in slv(TS_LANES_G-1 downto 0);
      tsRxMsgs  : in TsData6ChMsgArray(TS_LANES_G-1 downto 0);

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FcBusType;

      -- Output Sync'd to fcClk185
      fcTsRxMsgs : out TsData6ChMsgArray(TS_LANES_G-1 downto 0);
      fcMsgTime  : out FcTimestampType;

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

   type StateType is (
      WAIT_CLOCK_ALIGN_S,
      WAIT_BC0_S,
      ALIGNED_S);

   -- fcClk185 signals
   type RegType is record
      state               : StateType;
      tsMsgFifoRdEn       : slv(TS_LANES_G-1 downto 0);
      timestampFifoRdEn   : sl;
      timestampFifoWrEn   : sl;
      timestampFifoWrData : slv(69 downto 0);
      fcTsRxMsgs          : TsData6ChMsgArray(TS_LANES_G-1 downto 0);
      fcMsgTime           : FcTimestampType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state               => WAIT_CLOCK_ALIGN_S,
      tsMsgFifoRdEn       => (others => '0'),
      timestampFifoRdEn   => '0',
      timestampFifoWrEn   => '0',
      timestampFifoWrData => (others => '0'),
      fcTsRxMsgs          => (others => TS_DATA_6CH_MSG_INIT_C),
      fcMsgTime           => FC_TIMESTAMP_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Ts Msg FIFO
   signal tsMsgFifoWrData : TsData6ChMsgSlvArray(TS_LANES_G-1 downto 0);
   signal tsMsgFifoRdData : TsData6ChMsgSlvArray(TS_LANES_G-1 downto 0);
   signal tsMsgFifoValid  : slv(TS_LANES_G-1 downto 0);
   signal tsMsgFifoMsgs   : TsData6ChMsgArray(TS_LANES_G-1 downto 0);

   -- Timestamp FIFO
   signal timestampFifoRdData : slv(69 downto 0);
   signal timestampFifoValid  : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- Incomming TS messages go into FIFOs
   -- This should always have 0 or 1 entries since it is always read out.
   -- It's purpose is to align TS data to the FC clock
   -------------------------------------------------------------------------------------------------
   GEN_TS_RX_FIFOS : for i in TS_LANES_G-1 downto 0 generate
      U_TsMsgFifo_1 : entity ldmx_ts.TsMsgFifo
         generic map (
            TPD_G           => TPD_G,
            GEN_SYNC_FIFO_G => false,
            SYNTH_MODE_G    => "inferred",
            MEMORY_TYPE_G   => "distributed",
            ADDR_WIDTH_G    => 4)
         port map (
            rst     => tsRecRsts(i),        -- [in]
            wrClk   => tsRecClks(i),        -- [in]
            wrEn    => tsRxMsgs(i).strobe,  -- [in]
            wrFull  => open,                -- [out]
            wrMsg   => tsRxMsgs(i),         -- [in]
            rdClk   => fcClk185,            -- [in]
            rdEn    => r.tsMsgFifoRdEn(i),  -- [in]
            rdMsg   => tsMsgFifoMsgs(i),    -- [out]
            rdValid => open);               -- [out]
   end generate GEN_TS_RX_FIFOS;

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
         rst           => fcRst185,               -- [in]
         wr_clk        => fcClk185,               -- [in]
         wr_en         => r.timestampFifoWrEn,    -- [in]
         din           => r.timestampFifoWrData,  -- [in]
         wr_data_count => open,                   -- [out]
         rd_clk        => fcClk185,               -- [in]
         rd_en         => r.timestampFifoRdEn,    -- [in]
         dout          => timestampFifoRdData,    -- [out]
         rd_data_count => open,                   -- [out]
         valid         => timestampFifoValid);    -- [out]   


   comb : process (fcBus, fcRst185, r, timestampFifoRdData, tsMsgFifoMsgs) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      v.tsMsgFifoRdEn     := (others => '0');
      v.timestampFifoRdEn := '0';
      v.timestampFifoWrEn := '0';

      STB_LOOP : for i in TS_LANES_G-1 downto 0 loop
         v.fcTsRxMsgs(i).strobe := '0';
      end loop STB_LOOP;
      v.fcMsgTime.valid := '0';


      case r.state is
         when WAIT_CLOCK_ALIGN_S =>
            -- Bleed off both fifo's when in reset state
            if (fcBus.runState = RUN_STATE_RESET_C) then
               v.tsMsgFifoRdEn     := (others => '1');
               v.timestampFifoRdEn := '1';
            end if;

            -- Start alignment when FC runState moves to CLOCK_ALIGN state
            if (fcBus.pulseStrobe = '1' and fcBus.stateChanged = '1' and fcBus.runState = RUN_STATE_CLOCK_ALIGN_C) then
               -- Stop bleeding the timestamp fifo
               v.timestampFifoRdEn   := '0';
               -- Start writing timestamps
               v.timestampFifoWrEn   := '1';
               v.timestampFifoWrData := fcBus.pulseId & fcBus.bunchCount;
               v.state               := WAIT_BC0_S;
            end if;

         when WAIT_BC0_S =>
            if (fcBus.bunchStrobe = '1') then
               -- Write a new timestamp with each bunch strobe
               v.timestampFifoWrEn   := '1';
               v.timestampFifoWrData := fcBus.pulseId & fcBus.bunchCount;

               -- Read a message from ts data fifos
               v.tsMsgFifoRdEn := (others => '1');

               -- If current message has BC0 set, then done aligning
               -- Punt on making sure multiple TS fibers are aligned for now
               if (tsMsgFifoMsgs(0).strobe = '1' and tsMsgFifoMsgs(0).bc0 = '1') then
                  -- Read from timestamp fifo and output ts data and fc timestamp together
                  v.timestampFifoRdEn    := '1';
                  v.fcTsRxMsgs           := tsMsgFifoMsgs;
                  v.fcMsgTime.pulseId    := timestampFifoRdData(69 downto 6);
                  v.fcMsgTime.bunchCount := timestampFifoRdData(5 downto 0);
                  v.fcMsgTime.valid      := '1';
                  v.state                := ALIGNED_S;
               end if;
            end if;

            -- Reset alignment if run state transitions before BC0
            if (fcBus.runState /= RUN_STATE_CLOCK_ALIGN_C) then
               v.state := WAIT_CLOCK_ALIGN_S;
            end if;

         when ALIGNED_S =>
            if (fcBus.bunchStrobe = '1') then
               -- Write timestamp each bunch clock
               v.timestampFifoWrEn   := '1';
               v.timestampFifoWrData := fcBus.pulseId & fcBus.bunchCount;

               -- Read timestamp and rs data each bunch clock
               v.tsMsgFifoRdEn        := (others => '1');
               v.timestampFifoRdEn    := '1';
               v.fcTsRxMsgs           := tsMsgFifoMsgs;
               v.fcMsgTime.pulseId    := timestampFifoRdData(69 downto 6);
               v.fcMsgTime.bunchCount := timestampFifoRdData(5 downto 0);
               v.fcMsgTime.valid      := '1';
            end if;

            -- Reset alignment when run state goes to reset
            if (fcBus.runState = RUN_STATE_RESET_C) then
               v.state := WAIT_CLOCK_ALIGN_S;
            end if;


         when others => null;
      end case;

      -- Reset
      if (fcRst185 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      fcTsRxMsgs <= r.fcTsRxMsgs;
      fcMsgTime  <= r.fcMsgTime;

      rin <= v;


   end process comb;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;


