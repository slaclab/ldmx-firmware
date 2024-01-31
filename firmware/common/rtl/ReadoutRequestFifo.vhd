-------------------------------------------------------------------------------
-- Title      : ReadoutRequest FIFO
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

library ldmx;
use ldmx.HpsPkg.all;

entity ReadoutRequestFifo is

   generic (
      TPD_G : time := 1 ns);

   port (
      daqClk   : in sl;
      daqRst   : in sl;
      daqFcMsg : in FastControlMessageType;
      
      sysClk    : in  sl;
      sysRst    : in  sl;
      sysRoR    : out sl;
      fifoFcMsg : out    FastControlMessageType;
      fifoRdEn  : in  sl);

end entity ReadoutRequestFifo;

architecture rtl of ReadoutRequestFifo is

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


   comb : process (distClkRst, r, rxData, rxDataEn) is
      variable v : RegType;
   begin
      v := r;

      v.wrEn    := '0';
      v.fifoRst := '0';
      v.counter := r.counter + 1;

      if (rxDataEn = '1') then
         if (rxData(7 downto 0) = X"F0") then
            v.counter := (others => '0');
            v.fifoRst := '1';
         elsif (rxData = DAQ_TRIGGER_CODE_C) then
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
