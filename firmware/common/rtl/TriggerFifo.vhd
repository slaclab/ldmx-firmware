-------------------------------------------------------------------------------
-- Title      : Trigger FIFO
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Attaches a timestamp to each incomming trigger
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;

library hps_daq;
use hps_daq.HpsTiPkg.all;

entity TriggerFifo is

   generic (
      TPD_G : time := 1 ns);

   port (
      distClk    : in  sl;
      distClkRst : in  sl;
      rxData     : in  slv(9 downto 0);
      rxDataEn   : in  sl;
      sysClk     : in  sl;
      sysRst     : in  sl;
      trigger    : out sl;
      valid      : out sl;
      data       : out slv(63 downto 0);
      rdEn       : in  sl);

end entity TriggerFifo;

architecture rtl of TriggerFifo is

   type RegType is record
      counter : slv(63 downto 0);
      wrEn    : sl;
      fifoRst : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      counter => (others => '0'),
      wrEn    => '0',
      fifoRst => '1');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   -- Pulse trigger for 1 sysClk cycle in response to each trigger code
   TRIGGER_SYNC_FIFO : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         DATA_WIDTH_G  => 1,
         ADDR_WIDTH_G  => 4)
      port map (
         rst    => r.fifoRst,
         wr_clk => distClk,
         wr_en  => r.wrEn,
         din(0) => '0',
         rd_clk => sysClk,
         valid  => trigger);

   -- Log the timestamp of each trigger
   TRIGGER_TIMESTAMP_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => false,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 64,
         ADDR_WIDTH_G    => 6)
      port map (
         rst           => r.fifoRst,
         wr_clk        => distClk,
         wr_en         => r.wrEn,
         wr_data_count => open,
         din           => r.counter,
         rd_clk        => sysClk,
         rd_en         => rdEn,
         dout          => data,
         valid         => valid);

   comb : process (distClkRst, r, rxData, rxDataEn) is
      variable v : RegType;
   begin
      v := r;

      v.wrEn    := '0';
      v.fifoRst := '0';
      v.counter := r.counter + 1;

      if (rxDataEn = '1') then
         if (rxData = TI_START_CODE_C) then
            v.counter := (others => '0');
            v.fifoRst := '1';
         elsif (rxData = TI_TRIG_CODE_C) then
            v.wrEn := '1';
         end if;
      end if;

      rin <= v;

      if (distClkRst = '1') then
         v := REG_INIT_C;
      end if;

   end process comb;

   seq : process (distClk) is
   begin
      if (rising_edge(distClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
