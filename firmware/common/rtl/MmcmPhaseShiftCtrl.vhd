-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MmcmPhaseShiftCtrl.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-05-20
-- Last update: 2014-04-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Based on XAPP888. Allows the phase of each MMCM output to be
-- dynamically shifted in increments of VCO/8 through the DRP port.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library surf;
use surf.StdRtlPkg.all;

library hps_daq;
use hps_daq.MmcmPhaseShiftPkg.all;

entity MmcmPhaseShiftCtrl is
   generic (
      TPD_G : time := 1 ns);
   port (
      clk  : in sl;
      sRst : in sl;

      -- DRP interface
      drpClk : out sl;                  -- tie to drp dclk on MMCM
      drpIn  : out MmcmDrpInType;
      drpOut : in  MmcmDrpOutType;

      -- User interface
      userIn  : in  MmcmPhaseShiftCtrlInType;
      userOut : out MmcmPhaseShiftCtrlOutType

      );

end entity MmcmPhaseShiftCtrl;

architecture rtl of MmcmPhaseShiftCtrl is

   subtype PHASE_MUX_BIT_RANGE_C is integer range 15 downto 13;
   subtype DELAY_TIME_BIT_RANGE_C is integer range 5 downto 0;

   constant DRP_REG_MAP_C : slv8Array(0 to 15) := (
      0  => X"08",
      1  => X"09",
      2  => X"0A",
      3  => X"0B",
      4  => X"0C",
      5  => X"0D",
      6  => X"0E",
      7  => X"0F",
      8  => X"10",
      9  => X"11",
      10 => X"06",
      11 => X"07",
      12 => X"12",
      13 => X"13",
      14 => X"14",
      15 => X"15");

   type StateType is (WAIT_MMCM_LOCK_S, WAIT_SET_S, ADDR_S, WAIT_DRDY_1_S, WAIT_DRDY_2_S);

   type RegType is record
      state     : StateType;
      counter   : unsigned(3 downto 0);
      donePower : sl;
      drpIn     : MmcmDrpInType;
      userOut   : MmcmPhaseShiftCtrlOutType;
   end record RegType;

   constant REG_RESET_C : RegType := (
      state     => WAIT_MMCM_LOCK_S,
      counter   => (others => '0'),
      donePower => '0',
      drpIn     => MMCM_DRP_RESET_C,
      userOut   => (configDone => '0'));

   signal r, rin : RegType := REG_RESET_C;

   type Slv9Array is array (natural range <>) of slv(8 downto 0);
   signal shiftIn : slv9Array(0 to 7);

   signal mmcmLockedSync : sl;

begin

   shiftIn(0) <= userIn.shift0;
   shiftIn(1) <= userIn.shift1;
   shiftIn(2) <= userIn.shift2;
   shiftIn(3) <= userIn.shift3;
   shiftIn(4) <= userIn.shift4;
   shiftIn(5) <= userIn.shift5;
   shiftIn(6) <= userIn.shift6;
   shiftIn(7) <= userIn.shiftFb;
   drpClk     <= clk;

   Synchronizer_1 : entity surf.Synchronizer
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 2)
      port map (
         clk     => clk,
         rst     => sRst,
         dataIn  => drpOut.locked,
         dataOut => mmcmLockedSync);

   comb : process (drpOut, mmcmLockedSync, r, sRst, shiftIn, userIn) is
      variable v          : RegType;
      variable addrIndex  : integer;
      variable inputIndex : integer;
   begin
      v := r;

      addrIndex  := to_integer(r.counter);
      inputIndex := to_integer(r.counter(3 downto 1));

      v.drpIn.den := '0';
      v.drpIn.dwe := '0';

      case (r.state) is

         when WAIT_MMCM_LOCK_S =>
            v.donePower          := '0';
            v.drpIn.rst          := '0';
            v.userOut.configDone := '0';
            if (mmcmLockedSync = '1') then
               v.state := WAIT_SET_S;
            end if;
            
         when WAIT_SET_S =>
            v.userOut.configDone := '1';
            v.counter            := (others => '0');
            v.donePower          := '0';
            if (userIn.setConfig = '1') then
               v.userOut.configDone := '0';
               v.drpIn.rst          := '1';
               v.state              := ADDR_S;
            end if;

            if (mmcmLockedSync = '0') then
               v.state := WAIT_MMCM_LOCK_S;
            end if;

         when ADDR_S =>
            if (r.donePower = '0') then
               v.drpIn.daddr := "0101000";  -- x28
            else
               v.drpIn.daddr := DRP_REG_MAP_C(addrIndex)(6 downto 0);
            end if;

            v.drpIn.den := '1';
            v.state     := WAIT_DRDY_1_S;

         when WAIT_DRDY_1_S =>
            if (drpOut.drdy = '1') then
               v.drpIn.di := drpOut.do;

               if (r.donePower = '0') then
                  v.drpIn.di := (others => '1');
               elsif (r.drpIn.daddr(0) = '0') then
                  -- PhaseMux (low order shift bits) located in register 1
                  v.drpIn.di(PHASE_MUX_BIT_RANGE_C) := shiftIn(inputIndex)(2 downto 0);
               else
                  -- DelayTime (high order shift bits) located in register 2
                  v.drpIn.di(DELAY_TIME_BIT_RANGE_C) := shiftIn(inputIndex)(8 downto 3);
               end if;


               v.drpIn.den := '1';
               v.drpIn.dwe := '1';
               v.state     := WAIT_DRDY_2_S;
            end if;

         when WAIT_DRDY_2_S =>

            if (drpOut.drdy = '1') then
               -- Start the next DRP register txn
               if (r.donePower = '1') then
                  v.counter := r.counter + 1;
               else
                  v.donePower := '1';
               end if;

               v.state := ADDR_S;

               -- Check that all registers are done
               if (r.counter = 15) then
                  v.state := WAIT_MMCM_LOCK_S;
               end if;
            end if;

         when others => null;
      end case;

      if (sRst = '1') then
         v := REG_RESET_C;
      end if;

      rin <= v;

      drpIn   <= r.drpIn;
      userOut <= r.userOut;
      
   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
