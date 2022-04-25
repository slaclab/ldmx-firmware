-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : MmcmPhaseShifterPkg.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-05-20
-- Last update: 2013-09-21
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

package MmcmPhaseShiftPkg is

   -- DRP IO from perspective of MMCM
   type MmcmDrpInType is record
      rst   : sl;
      daddr : slv(6 downto 0);
      den   : sl;
      dwe   : sl;
      di    : slv(15 downto 0);
   end record MmcmDrpInType;

   constant MMCM_DRP_RESET_C : MmcmDrpInType := (
      rst   => '0',
      daddr => (others => '0'),
      den   => '0',
      dwe   => '0',
      di    => (others => '0'));

   type MmcmDrpOutType is record
      locked : sl;
      do     : slv(15 downto 0);
      drdy   : sl;
   end record MmcmDrpOutType;

   -- User IO from MmcmPhaseShift prespective
   type MmcmPhaseShiftCtrlOutType is record
      configDone : sl;
   end record;

   type MmcmPhaseShiftCtrlInType is record
      shift0    : slv(8 downto 0);
      shift1    : slv(8 downto 0);
      shift2    : slv(8 downto 0);
      shift3    : slv(8 downto 0);
      shift4    : slv(8 downto 0);
      shift5    : slv(8 downto 0);
      shift6    : slv(8 downto 0);
      shiftFb   : slv(8 downto 0);
      setConfig : sl;
   end record;

   constant MMCM_PHASE_SHIFT_CTRL_IN_INIT_C : MmcmPhaseShiftCtrlInType := (
      shift0 => (others => '0'),
      shift1 => (others => '0'),
      shift2 => (others => '0'),
      shift3 => (others => '0'),
      shift4 => (others => '0'),
      shift5 => (others => '0'),
      shift6 => (others => '0'),
      shiftFb => (others => '0'),
      setConfig => '0');

end package MmcmPhaseShiftPkg;
