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

library ldmx_tdaq;
use ldmx_tdaq.TriggerPkg.all;

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

   function toSlv128 (
      tsData : TsData6ChMsgType)
      return slv;

   function toTsData6ChMsg (
      vector : slv(TS_DATA_6CH_MSG_SIZE_C-1 downto 0);
      strobe : sl := '0')
      return TsData6ChMsgType;

   function toTsData6ChMsg128 (
      vector : slv(127 downto 0);
      strobe : sl := '0')
      return TsData6ChMsgType;

   type TsS30xlThresholdTriggerDaqType is record
      valid      : sl;
      bc0        : sl;
      timestamp  : FcTimestampType;
      hits       : slv(11 downto 0);
      amplitudes : slv17Array(11 downto 0);
   end record TsS30xlThresholdTriggerOutType;

   constant TS_S30XL_THRESHOLD_TRIGGER_DAQ_INIT_C : TsS30xlThresholdTriggerDaqType := (
      valid      => '0',
      bc0        => '0',
      timestamp  => FC_TIMESTAMP_INIT_C,
      hits       => (others => '0'),
      amplitudes => (others => (others => '0')));

   function toTriggerData (daqData : TsS30xlThresholdTriggerDaqType) return TriggerDataType;

   function toThresholdTriggerDaq (triggerData : TriggerDataType) return TsS30xlThresholdTriggerDaqType;


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

   function toSlv128 (
      tsData : TsData6ChMsgType)
      return slv
   is
      variable ret : slv(127 downto 0);
   begin
      ret               := (others => '0');
      ret(7 downto 0)   := tsData.adc(0);
      ret(15 downto 8)  := tsData.adc(1);
      ret(23 downto 16) := tsData.adc(2);
      ret(31 downto 24) := tsData.adc(3);
      ret(39 downto 32) := tsData.adc(4);
      ret(47 downto 40) := tsData.adc(5);

      ret(69 downto 64)   := tsData.tdc(0);
      ret(85 downto 80)   := tsData.tdc(1);
      ret(93 downto 88)   := tsData.tdc(2);
      ret(101 downto 96)  := tsData.tdc(3);
      ret(109 downto 104) := tsData.tdc(4);

      ret(113 downto 112) := tsData.capId;
      ret(114)            := tsData.ce;
      ret(115)            := tsData.bc0;
      return ret;
   end function toSlv128;

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

   function toTsData6ChMsg128 (
      vector : slv(127 downto 0);
      strobe : sl := '0')
      return TsData6ChMsgType
   is
      variable ret : TsData6ChMsgType;
   begin
      ret        := TS_DATA_6CH_MSG_INIT_C;
      ret.adc(0) := vector(7 downto 0);

      ret.adc(1) := vector(15 downto 8);
      ret.adc(2) := vector(23 downto 16);
      ret.adc(3) := vector(31 downto 24);
      ret.adc(4) := vector(39 downto 32);
      ret.adc(5) := vector(47 downto 40);

      ret.tdc(0) := vector(69 downto 64);
      ret.tdc(1) := vector(85 downto 80);
      ret.tdc(2) := vector(93 downto 88);
      ret.tdc(3) := vector(101 downto 96);
      ret.tdc(4) := vector(109 downto 104);

      ret.capId := vector(113 downto 112);
      ret.ce    := vector(114);
      ret.bc0   := vector(115);
      return ret;

   end function toTsData6ChMsg128;

   function toTriggerData (daqData : TsS30xlThresholdTriggerDaqType) return TriggerDataType is
      variable ret : TriggerDataType := TRIGGER_DATA_INIT_C;
   begin
      ret.valid             <= daqData.valid;
      ret.bc0               <= daqData.bc0;
      ret.data(11 downto 0) <= daqData.channelHits;
      return ret;
   end function toTriggerData;

   function toThresholdTriggerDaq (triggerData : TriggerDataType; timestamp : FcTimestampType:= FC_TIMESTAMP_INIT_C) return TsS30xlThresholdTriggerDaqType is
      variable ret : TsS30xlThresholdTriggerDaqType := TS_S30XL_THRESHOLD_TRIGGER_DAQ_INIT_C;
   begin
      ret.valid <= triggerData.valid;
      ret.bc0 <= triggerData.bc0;
      ret.timestamp <= timestamp;
      ret.hits <= triggerData.data(11 downto 0);
      return ret;
   end function toThresholdTriggerDaq;


end package body TsPkg;
