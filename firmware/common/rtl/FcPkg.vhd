-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Fast Control Package
--
-------------------------------------------------------------------------------
-- This file is part of 'LDMX'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LDMX', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

package FcPkg is

   -------------------------------------------------------------------------------------------------
   -- Fast Control Messages sent on PGPFC are 80 bits, with fields defined here
   -- FastControlMessageType encodes the fields into a record
   -------------------------------------------------------------------------------------------------
   constant FC_LEN_C              : natural := 80;
   subtype MSG_TYPE_RANGE_C is natural range FC_LEN_C-1 downto 76;
   subtype BUNCH_CNT_RANGE_C is natural range 69 downto 64;
   subtype RUN_STATE_RANGE_C is natural range 68 downto 64;
   constant STATE_CHANGED_INDEX_C : natural := 69;
   subtype PULSE_ID_RANGE_C is natural range 63 downto 0;

   constant RUN_STATE_RESET_C       : slv(4 downto 0) := "00000";
   constant RUN_STATE_CLOCK_ALIGN_C : slv(4 downto 0) := "00001";  -- T0
   constant RUN_STATE_PRESTART_C    : slv(4 downto 0) := "00010";
   constant RUN_STATE_RUNNING_C     : slv(4 downto 0) := "00011";
   constant RUN_STATE_STOPPED_C     : slv(4 downto 0) := "00100";

   constant MSG_TYPE_TIMING_C : slv(3 downto 0) := toSlv(0, 4);
   constant MSG_TYPE_ROR_C    : slv(3 downto 0) := toSlv(1, 4);

   type FastControlMessageType is record
      valid        : sl;
      msgType      : slv(3 downto 0);
      -- reserxved : slv(5 downto 0);
      bunchCount   : slv(5 downto 0);
      runState     : slv(4 downto 0);
      stateChanged : sl;
      pulseID      : slv(63 downto 0);
      message      : slv(FC_LEN_C-1 downto 0);
   end record;

   constant FC_MSG_INIT_C : FastControlMessageType := (
      valid        => '0',
      msgType      => (others => '0'),
      -- reserved => (others => '0'),
      bunchCount   => (others => '0'),
      runState     => (others => '0'),
      stateChanged => '0',
      pulseID      => (others => '0'),
      message      => (others => '0')
      );

   function FcEncode (fieldsIn : FastControlMessageType) return slv;
   function FcDecode (fcIn     : slv(FC_LEN_C-1 downto 0); valid : in sl := '1') return FastControlMessageType;

   -------------------------------------------------------------------------------------------------
   -- Readout Request Fields
   -------------------------------------------------------------------------------------------------
   type FcTimestampType is record
      valid      : sl;
      bunchCount : slv(5 downto 0);
      pulseId    : slv(63 downto 0);
   end record FcTimestampType;

   constant FC_TIMESTAMP_INIT_C : FcTimestampType := (
      valid      => '0',
      bunchCount => (others => '0'),
      pulseId    => (others => '0'));

   function toSlv (
      fcTimestamp : FcTimestampType)
      return slv;

   -------------------------------------------------------------------------------------------------
   -- The Fast control receiver block outputs a bus of fast control data on this record
   -------------------------------------------------------------------------------------------------
   type FastControlBusType is record
      -- FC Rx status
      rxLinkStatus : sl;

      -- Placed on bus with each TM received
      pulseStrobe  : sl;
      pulseId      : slv(63 downto 0);
      runState     : slv(4 downto 0);
      stateChanged : sl;

      -- These are counted based on Timing messages
      bunchStrobePre  : sl;             -- Pulsed 1 cycle before bunchCount increments
      bunchStrobe     : sl;             -- Pulsed on cycle that bunchCount increments
      bunchCount      : slv(5 downto 0);
      bunchClkAligned : sl;

      -- 185 MHz counter from T0
      runTime : slv(63 downto 0);

      -- Readout request data placed on this bus as received
      readoutRequest : FcTimestampType;

      -- All FC messages placed on this bus as they are received
      -- Might not be useful
      fcMsg : FastControlMessageType;
   end record FastControlBusType;

   constant FC_BUS_INIT_C : FastControlBusType := (
      rxLinkStatus    => '0',
      pulseStrobe     => '0',
      pulseId         => (others => '0'),
      runState        => (others => '0'),
      stateChanged    => '0',
      bunchStrobePre  => '0',
      bunchStrobe     => '0',
      bunchCount      => (others => '0'),
      bunchClkAligned => '0',
      runTime         => (others => '0'),
      readoutRequest  => FC_TIMESTAMP_INIT_C,
      fcMsg           => FC_MSG_INIT_C);


   -------------------------------------------------------------------------------------------------
   -- Fast control feedback
   -- Only busy for now but more could be added
   -------------------------------------------------------------------------------------------------
   type FastControlFeedbackType is record
      busy : sl;
   end record FastControlFeedbackType;

   constant FC_FB_INIT_C : FastControlFeedbackType := (
      busy => '0');


end FcPkg;

package body FcPkg is

   function FcEncode (fieldsIn : FastControlMessageType) return slv is
      variable retVar : slv(FC_LEN_C-1 downto 0);
   begin
      retVar                   := (others => '0');
      retVar(MSG_TYPE_RANGE_C) := fieldsIn.msgType;

      if (fieldsIn.msgType = MSG_TYPE_ROR_C) then
         -- if RoR, transmit the bunch counter
         retVar(BUNCH_CNT_RANGE_C) := fieldsIn.bunchCount;
      else
         -- if non-RoR, transmit the state
         retVar(RUN_STATE_RANGE_C)     := fieldsIn.runState;
         retVar(STATE_CHANGED_INDEX_C) := fieldsIn.stateChanged;
      end if;

      retVar(PULSE_ID_RANGE_C) := fieldsIn.pulseID;

      return retVar;
   end function FcEncode;

   function FcDecode (fcIn : slv(FC_LEN_C-1 downto 0); valid : in sl := '1') return FastControlMessageType is
      variable retVar : FastControlMessageType;
   begin
      retVar         := FC_MSG_INIT_C;
      retVar.valid   := valid;
      retVar.msgType := fcIn(MSG_TYPE_RANGE_C);
      -- no latches are inferred because retVar is initialized
      -- right below the 'begin'

      -- check the message type
      if (retVar.msgType = MSG_TYPE_ROR_C) then
         -- if RoR, grab the bunch count
         retVar.bunchCount := fcIn(BUNCH_CNT_RANGE_C);
      else
         -- if non-RoR, grab the state
         retVar.runState     := fcIn(RUN_STATE_RANGE_C);
         retVar.stateChanged := fcIn(STATE_CHANGED_INDEX_C);
      end if;

      retVar.pulseID := fcIn(PULSE_ID_RANGE_C);

      return retVar;
   end function FcDecode;

   function toSlv (
      fcTimestamp : FcTimestampType)
      return slv is
      variable ret : slv(69 downto 0);
   begin
      ret(69 downto 6) := fcTimestamp.pulseId;
      ret(5 downto 0)  := fcTimestamp.bunchCount;
      return ret;
   end function toSlv;


end package body FcPkg;
