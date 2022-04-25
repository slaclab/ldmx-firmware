-------------------------------------------------------------------------------
-- Title         : Tigger Control
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : TrigControl.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 06/27/2011
-------------------------------------------------------------------------------
-- Description:
-- This block control the TRIG signal sent to the PAV25
-------------------------------------------------------------------------------
-- Copyright (c) 2011 by SLAC. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 06/27/2011: created.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library UNISIM;
use UNISIM.vcomponents.all;

library surf;
use surf.StdRtlPkg.all;

library hps_daq;
use hps_daq.FebConfigPkg.all;

entity TrigControl is
   generic (
      TPD_G : time := 1 ns);
   port (
      axiClk    : in sl;
      axiRst    : in sl;
      febConfig : in FebConfigType;     -- Contains trigger config

      -- Trigger inputs (sync'd to daqClk125)
      daqTrigger : in sl;
      hySoftRst  : in sl;

      -- Hybrid Clock and reset (phase adjusted daqClk41)
      hyClk    : in sl;
      hyClkRst : in sl;

      -- Trigger output to APVs
      hyTrigOut : out sl
      );
end TrigControl;

architecture rtl of TrigControl is

   type StateType is (WAIT_TRIGGER_S, WAIT_SHIFT_S, WAIT_CAL_S);

   type RegType is record
      state    : StateType;
      active   : sl;
      counter  : slv(7 downto 0);
      shiftOut : slv(5 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      state    => WAIT_TRIGGER_S,
      active   => '0',
      counter  => (others => '0'),
      shiftOut => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Synchronized trigger signals
   signal hySoftRstRise  : sl;
   signal daqTriggerRise : sl;

   -- Synchronized febConfig signals
   signal hyTrigEn : sl;
   signal calEn    : sl;
   signal calDelay : slv(7 downto 0);


begin

   Synchronizer_hySoftRst : entity surf.SynchronizerOneShot
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         RST_ASYNC_G    => false)
      port map (
         clk     => hyClk,
         rst     => hyClkRst,
         dataIn  => hySoftRst,
         dataOut => hySoftRstRise);

   Synchronizer_daqTrigger : entity surf.SynchronizerOneShot
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         RST_ASYNC_G    => false)
      port map (
         clk     => hyClk,
         rst     => hyClkRst,
         dataIn  => daqTrigger,
         dataOut => daqTriggerRise);

   SynchronizerFifo_febConfig : entity surf.SynchronizerFifo
      generic map (
         TPD_G         => TPD_G,
         MEMORY_TYPE_G => "distributed",
         DATA_WIDTH_G  => 10,
         ADDR_WIDTH_G  => 4)
      port map (
         rst              => axiRst,
         wr_clk           => axiClk,
         din(0)           => febConfig.hyTrigEn,
         din(1)           => febConfig.calEn,
         din(9 downto 2)  => febConfig.calDelay,
         rd_clk           => hyClk,
         dout(0)          => hyTrigEn,
         dout(1)          => calEn,
         dout(9 downto 2) => calDelay);

   comb : process (calDelay, calEn, daqTriggerRise, hyClkRst, hySoftRstRise, hyTrigEn, r) is
      variable v : RegType;
   begin
      v := r;

      v.shiftOut := r.shiftOut(4 downto 0) & '0';

      case (r.state) is
         when WAIT_TRIGGER_S =>
            v.counter := (others => '0');
            if (hySoftRstRise = '1') then
               v.shiftOut := "101000";
               v.state    := WAIT_SHIFT_S;
            elsif (daqTriggerRise = '1' and hyTrigEn = '1') then
               if (calEn = '1') then
                  v.shiftOut := "110000";
                  v.state    := WAIT_CAL_S;
               else
                  v.shiftOut := "100100";
                  v.state    := WAIT_SHIFT_S;
               end if;
            end if;

         when WAIT_SHIFT_S =>
            -- Wait until enough of the trigger sequence has shifted out that
            -- a new trigger can be processed.
            if (r.shiftOut = "000000") then
               v.state := WAIT_TRIGGER_S;
            end if;

         when WAIT_CAL_S =>
            v.counter := r.counter + 1;
            if (r.counter = calDelay) then
               v.shiftOut := "100100";
               v.state    := WAIT_SHIFT_S;
            end if;

      end case;

      if (hyClkRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      hyTrigOut <= r.shiftOut(5);

   end process comb;

   seq : process (hyClk) is
   begin
      if (rising_edge(hyClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;

