-------------------------------------------------------------------------------
-- Title      : ROR Data Delay
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Delays data by readout request latency
-- dataOut updates with rising edge of fcBus.bunchStrobe once aligned.
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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

entity RorDaqDataDelay is

   generic (
      TPD_G         : time    := 1 ns;
      DATA_WIDTH_G  : integer := 16;
      MEMORY_TYPE_G : string  := "distributed");
   port (
      fcClk185    : in  sl;
      fcRst185    : in  sl;
      fcBus       : in  FcBusType;
      timestampIn : in  FcTimestampType;
      dataIn      : in  slv(DATA_WIDTH_G-1 downto 0);
      aligned     : out sl;
      dataOut     : out slv(DATA_WIDTH_G-1 downto 0));
end entity RorDaqDataDelay;

architecture rtl of RorDaqDataDelay is

   type StateType is (
      INIT_S,
      WAIT_BC0_ID_S,
      WAIT_BC0_DATA_S,
      WAIT_ROR_S,
      ALIGNED_S);

   -- fcClk185 signals
   type RegType is record
      state    : StateType;
      bc0Id     : slv(63 downto 0);
      fifoWrEn : sl;
      fifoRdEn : sl;
      fifoRst  : sl;
      aligned  : sl;
   end record;

   constant REG_INIT_C : RegType := (
      state    => INIT_S,
      bc0Id     => (others => '0'),
      fifoWrEn => '0',
      fifoRdEn => '0',
      fifoRst  => '0',
      aligned  => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   U_Fifo_1 : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         FWFT_EN_G       => true,
         SYNTH_MODE_G    => "inferred",
         MEMORY_TYPE_G   => MEMORY_TYPE_G,
         DATA_WIDTH_G    => DATA_WIDTH_G,
         ADDR_WIDTH_G    => 8)
      port map (
         rst    => r.fifoRst,           -- [in]
         wr_clk => fcClk185,            -- [in]
         wr_en  => rin.fifoWrEn,        -- [in]
         din    => dataIn,              -- [in]
         rd_clk => fcClk185,            -- [in]
         rd_en  => rin.fifoRdEn,        -- [in]
         dout   => dataOut,             -- [out]
         valid  => open);               -- [out]

   comb : process (fcBus, fcRst185, r, timestampIn) is
      variable v : RegType := REG_INIT_C;
   begin
      v := r;

      v.fifoWrEn := '0';
      v.fifoRdEn := '0';
      v.fifoRst  := '0';

      case r.state is
         when INIT_S =>
            v.aligned := '0';
            v.fifoRst := '1';
            v.state   := WAIT_BC0_ID_S;

         when WAIT_BC0_ID_S =>
            if (fcBus.pulseStrobe = '1' and
                fcBus.stateChanged = '1') then
               if (fcBus.runState = RUN_STATE_BC0_C) then
                  v.bc0Id  := fcBus.pulseID;
                  v.state := WAIT_BC0_DATA_S;
               else
                  v.state := INIT_S;
               end if;
            end if;

         when WAIT_BC0_DATA_S =>
            -- Wait until BC0 data arrives then start writing into FIFO 
            if (timestampIn.valid = '1' and timestampIn.pulseID = r.bc0Id) then
               v.fifoWrEn := '1';
               v.state    := WAIT_ROR_S;
            end if;
            
            if (fcBus.runState /= RUN_STATE_BC0_C) then
               v.state := INIT_S;
            end if;


         when WAIT_ROR_S =>
            -- Write data into fifo as it arrives
            if (timestampIn.valid = '1') then
               v.fifoWrEn := '1';
            end if;

            -- Readout request during alignment is the BC0 RoR
            if (fcBus.readoutRequest.valid = '1') then
               v.state    := ALIGNED_S;
               v.aligned  := '1';
            end if;

            -- Any state change should send it back to unaligned
            if (fcBus.stateChanged = '1') then
               v.state := INIT_S;
            end if;

         when ALIGNED_S =>
            -- Continue writing data as it arrives
            if (timestampIn.valid = '1') then
               v.fifoWrEn := '1';
            end if;

            -- Read data on each bunch strobe
            if (fcBus.bunchStrobePre = '1') then
               v.fifoRdEn := '1';
            end if;

            if (fcBus.stateChanged = '1' and fcBus.runState = RUN_STATE_RESET_C) then
               v.state   := INIT_S;
               v.aligned := '0';
            end if;

         when others => null;
      end case;

      if (fcRst185 = '1') then
         v := REG_INIT_C;
      end if;

      aligned <= r.aligned;

      rin <= v;

   end process;

   seq : process (fcClk185) is
   begin
      if (rising_edge(fcClk185)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
