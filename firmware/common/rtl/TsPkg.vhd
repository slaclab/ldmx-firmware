-------------------------------------------------------------------------------
-- Title      : Trigger Scintillator Support Package
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

package TsPkg is

   type TsData8ChMsgType is record
      strobe : sl;                      -- Indicates new data
      capId  : slv(1 downto 0);
      ce     : sl;
      bc0    : sl;
      adc    : Slv8Array(7 downto 0);
      tdc    : Slv2Array(7 downto 0);
   end record;

   constant TS_DATA_8CH_MSG_INIT_C : TsData8ChMsgType := (
      strobe => '0',
      capId  => (others => '0'),
      ce     => '0',
      bc0    => '0',
      adc    => (others => (others => '0')),
      tdc    => (others => (others => '0')));

   type TsData8ChMsgArray is array (natural range <>) of TsData8ChMsgType;


   type TsData6ChMsgType is record
      strobe : sl;                      -- Indicates new data
      capId  : slv(1 downto 0);
      ce     : sl;
      bc0    : sl;
      adc    : Slv8Array(5 downto 0);
      tdc    : Slv6Array(5 downto 0);
   end record;

   constant TS_DATA_6CH_MSG_INIT_C : TsData6ChMsgType := (
      strobe => '0',
      capId  => (others => '0'),
      ce     => '0',
      bc0    => '0',
      adc    => (others => (others => '0')),
      tdc    => (others => (others => '0')));

   type TsData6ChMsgArray is array (natural range <>) of TsData6ChMsgType;

   constant TS_DATA_6CH_MSG_SIZE_C : integer := 88;

   subtype TsData6ChMsgSlvType is slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
   type TsData6ChMsgSlvArray is array (natural range <>) of TsData6ChMsgSlvType;

   function toSlv (
      tsData : TsData6ChMsgType)
      return slv;

   function toTsData6ChMsg (
      vector : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
      strobe : sl := '0')
      return TsData6ChMsgType;


end package TsPkg;

package body TsPkg is

   function toSlv (
      tsData : TsData6ChMsgType)
      return slv
   is
      variable ret : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0) := (others => '0');
      variable i   : integer                                := 0;
   begin
      i := 0;
      assignSlv(i, ret, tsData.capId);
      assignSlv(i, ret, tsData.ce);
      assignSlv(i, ret, tsData.bc0);
      for j in 5 downto 0 loop
         assignSlv(i, ret, tsData.adc(j));
      end loop;
      for j in 5 downto 0 loop
         assignSlv(i, ret, tsData.tdc(j));
      end loop;
      return ret;
   end function toSlv;

   function toTsData6ChMsg (
      vector : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
      strobe : sl := '0')
      return TsData6ChMsgType
   is
      variable ret : TsData6ChMsgType;
      variable i   : integer := 0;
   begin
      i := 0;
      assignRecord(i, vector, ret.capId);
      assignRecord(i, vector, ret.ce);
      assignRecord(i, vector, ret.bc0);
      for j in 5 downto 0 loop
         assignRecord(i, vector, ret.adc(j));
      end loop;
      for j in 5 downto 0 loop
         assignRecord(i, vector, ret.tdc(j));
      end loop;
      ret.strobe := strobe;
      return ret;

   end function toTsData6ChMsg;

end package body TsPkg;
