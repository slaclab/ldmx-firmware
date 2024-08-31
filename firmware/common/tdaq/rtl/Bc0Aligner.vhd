------------------------------------------------------------------------------
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

entity Bc0Aligner is

   generic (
      TPD_G       : time    := 1 ns;
      CHANNELS_G  : integer := 2;
      WORD_SIZE_G : integer := 128);
   port (
      --------------------------------------
      -- Input From Subsystem Trigger Blocks
      --------------------------------------
      triggerClks   : in slv(CHANNELS_G-1 downto 0);
      triggerRsts   : in slv(CHANNELS_G-1 downto 0);
      triggerDataIn : in TriggerDataArray(CHANNELS_G-1 downto 0);

      -----------------------------
      -- Fast Control clock and bus
      -----------------------------
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus    : in FcBusType;

      -- Output Sync'd to fcClk185
      triggerDataOut   : out TriggerDataArray(CHANNELS_G-1 downto 0);
      triggerTimestamp : out FcTimestampType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity Bc0Aligner;

architecture rtl of Bc0Aligner is

   type StateType is (
      WAIT_BC0_STATE_S,
      WAIT_BC0_DATA_S,
      ALIGNED_S);

   -- fcClk185 signals
   type RegType is record
      state               : StateType;
      dataFifoRdEn        : slv(CHANNELS_G-1 downto 0);
      timestampFifoRdEn   : sl;
      timestampFifoWrEn   : sl;
      timestampFifoWrData : FcTimestampType;
      triggerDataOut      : TriggerDataArray(CHANNELS_G-1 downto 0);
      triggerTimestamp    : FcTimestampType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state               => WAIT_BC0_STATE_S,
      dataFifoRdEn        => (others => '0'),
      timestampFifoRdEn   => '0',
      timestampFifoWrEn   => '0',
      timestampFifoWrData => FC_TIMESTAMP_INIT_C,
      triggerDataOut      => (others => TRIGGER_DATA_INIT_C),
      triggerTimestamp    => FC_TIMESTAMP_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal dataFifoRdData : TriggerDataArray(CHANNELS_G-1 downto 0);
   signal dataFifoValid  : slv(CHANNELS_G-1 downto 0);

   -- Timestamp FIFO
   signal timestampFifoRdData : FcTimestampType;
   signal timestampFifoValid  : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- Incomming TS messages go into FIFOs
   -- This should always have 0 or 1 entries since it is always read out.
   -- It's purpose is to align TS data to the FC clock
   -------------------------------------------------------------------------------------------------
   GEN_TS_RX_FIFOS : for i in CHANNELS_G-1 downto 0 generate
      U_TriggerDataFifo_1 : entity ldmx_tdaq.TriggerDataFifo
         generic map (
            TPD_G           => TPD_G,
            GEN_SYNC_FIFO_G => false,
            SYNTH_MODE_G    => "inferred",
            MEMORY_TYPE_G   => "distributed",
            ADDR_WIDTH_G    => 4)
         port map (
            rst     => triggerRsts(i),          -- [in]
            wrClk   => triggerClks(i),          -- [in]
            wrEn    => triggerDataIn(i).valid,  -- [in]
            wrData  => triggerDataIn(i),        -- [in]
            rdClk   => fcClk185,                -- [in]
            rdEn    => r.dataFifoRdEn(i),       -- [in]
            rdData  => dataFifoRdData(i),       -- [out]
            rdValid => dataFifoValid(i));       -- [out]
   end generate GEN_TS_RX_FIFOS;

   -------------------------------------------------------------------------------------------------
   -- Timestamp FIFO
   -- Once alignment begins, timestamps are written to the fifo every bunch clock
   -- Depth depends on BC0 latency
   -------------------------------------------------------------------------------------------------
   U_Fifo_FcTimestampFifo : entity ldmx_tdaq.FcTimestampFifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => "block",
         ADDR_WIDTH_G    => 8)
      port map (
         rst         => fcRst185,               -- [in]
         wrClk       => fcClk185,               -- [in]
         wrEn        => r.timestampFifoWrEn,    -- [in]
         wrTimestamp => r.timestampFifoWrData,  -- [in]
         rdClk       => fcClk185,               -- [in]
         rdEn        => r.timestampFifoRdEn,    -- [in]
         rdTimestamp => timestampFifoRdData,    -- [out]
         rdValid     => timestampFifoValid);    -- [out]   


   comb : process (dataFifoRdData, fcBus, fcRst185, r, timestampFifoRdData) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      v.dataFifoRdEn      := (others => '0');
      v.timestampFifoRdEn := '0';
      v.timestampFifoWrEn := '0';

      STB_LOOP : for i in CHANNELS_G-1 downto 0 loop
         v.triggerDataOut(i).valid := '0';
      end loop STB_LOOP;
      v.triggerTimestamp.valid := '0';


      case r.state is
         when WAIT_BC0_STATE_S =>
            -- Bleed off both fifo's when in reset state
            if (fcBus.runState = RUN_STATE_RESET_C) then
               v.dataFifoRdEn      := (others => '1');
               v.timestampFifoRdEn := '1';
            end if;

            -- Start alignment when FC runState moves to CLOCK_ALIGN state
            if (fcBus.bc0 = '1') then
               -- Stop bleeding the timestamp fifo
               v.timestampFifoRdEn              := '0';
               -- Start writing timestamps
               v.timestampFifoWrEn              := '1';
               v.timestampFifoWrData.pulseId    := fcBus.pulseId;
               v.timestampFifoWrData.bunchCount := fcBus.bunchCount;
               v.state                          := WAIT_BC0_DATA_S;
            end if;

         when WAIT_BC0_DATA_S =>
            if (fcBus.bunchStrobe = '1') then
               -- Write a new timestamp with each bunch strobe
               v.timestampFifoWrEn              := '1';
               v.timestampFifoWrData.bunchCount := fcBus.bunchCount;
               v.timestampFifoWrData.pulseId    := fcBus.pulseId;
            end if;

            if (fcBus.bunchStrobePre = '1') then
               -- Burn data from the data fifos unless bc0 has arrived
               for i in CHANNELS_G-1 downto 0 loop
                  v.dataFifoRdEn(i) := '1';
                  if (dataFifoRdData(i).bc0 = '1') then
                     v.dataFifoRdEn(i) := '0';
                  end if;
               end loop;

               -- If all channels have bc0 data, we are aligned
               if (v.dataFifoRdEn = 0) then
                  -- Read from timestamp fifo and output trigger data and fc timestamp together
                  v.timestampFifoRdEn      := '1';
                  v.dataFifoRdEn           := (others => '1');
                  v.triggerDataOut         := dataFifoRdData;
                  v.triggerTimestamp       := timestampFifoRdData;
                  v.triggerTimestamp.valid := '1';
                  v.state                  := ALIGNED_S;
               end if;
            end if;               


            -- Reset alignment if run state transitions before BC0
            if (fcBus.runState /= RUN_STATE_BC0_C) then
               v.state := WAIT_BC0_STATE_S;
            end if;

         when ALIGNED_S =>
            if (fcBus.bunchStrobe = '1') then
               -- Write timestamp each bunch clock
               v.timestampFifoWrEn              := '1';
               v.timestampFifoWrData.bunchCount := fcBus.bunchCount;
               v.timestampFifoWrData.pulseId    := fcBus.pulseId;
            end if;

            if (fcBus.bunchStrobePre = '1') then
               -- Read timestamp and data each bunch clock
               v.timestampFifoRdEn      := '1';
               v.dataFifoRdEn           := (others => '1');
               v.triggerDataOut         := dataFifoRdData;
               v.triggerTimestamp       := timestampFifoRdData;
               v.triggerTimestamp.valid := '1';
            end if;

            -- Reset alignment when run state goes to reset
            if (fcBus.runState = RUN_STATE_RESET_C) then
               v.state := WAIT_BC0_STATE_S;
            end if;


         when others => null;
      end case;

      -- Reset
      if (fcRst185 = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
      triggerDataOut   <= r.triggerDataOut;
      triggerTimestamp <= r.triggerTimestamp;

      rin <= v;


   end process comb;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;


