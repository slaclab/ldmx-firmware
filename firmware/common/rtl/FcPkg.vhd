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

   constant FC_LEN_C              : natural := 80;
   subtype MSG_TYPE_RANGE_C is natural range FC_LEN_C-1 downto 76;
   subtype BUNCH_CNT_RANGE_C is natural range 69 downto 64;
   subtype RUN_STATE_RANGE_C is natural range 68 downto 64;
   constant STATE_CHANGED_INDEX_C : natural := 69;
   subtype PULSE_ID_RANGE_C is natural range 63 downto 0;

   constant RUN_STATE_RESET_C       : slv(4 downto 0) := "00000";
   constant RUN_STATE_CLOCK_ALIGN_C : slv(4 downto 0) := "00001";
   constant RUN_STATE_PRESTART_C    : slv(4 downto 0) := "00010";
   constant RUN_STATE_RUNNING_C     : slv(4 downto 0) := "00011";
   constant RUN_STATE_STOPPED_C     : slv(4 downto 0) := "00100";

   constant MSG_TYPE_TIMING_C : slv(3 downto 0) := toSlv(0, 4);
   constant MSG_TYPE_ROR_C    : slv(3 downto 0) := toSlv(1, 4);

   type FastControlMessageType is record
      valid        : sl;
      msgType      : slv(3 downto 0);
      -- reserved : slv(5 downto 0);
      bunchCnt     : slv(5 downto 0);
      runState     : slv(4 downto 0);
      stateChanged : sl;
      pulseID      : slv(63 downto 0);
      message      : slv(FC_LEN_C-1 downto 0);
   end record;

   constant DEFAULT_FC_MSG_C : FastControlMessageType := (
      valid        => '0',
      msgType      => (others => '0'),
      -- reserved => (others => '0'),
      bunchCnt     => (others => '0'),
      runState     => (others => '0'),
      stateChanged => '0',
      pulseID      => (others => '0'),
      message      => (others => '0')
      );

   function FcEncode (fieldsIn : FastControlMessageType) return slv;
   function FcDecode (fcIn     : slv(FC_LEN_C-1 downto 0); valid : in sl := '1') return FastControlMessageType;

end FcPkg;

package body FcPkg is

   function FcEncode (fieldsIn : FastControlMessageType) return slv is
      variable retVar : slv(FC_LEN_C-1 downto 0);
   begin
      retVar                   := (others => '0');
      retVar(MSG_TYPE_RANGE_C) := fieldsIn.msgType;

      if (fieldsIn.msgType = MSG_TYPE_ROR_C) then
         -- if RoR, transmit the bunch counter
         retVar(BUNCH_CNT_RANGE_C) := fieldsIn.bunchCnt;
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
      retVar         := DEFAULT_FC_MSG_C;
      retVar.valid   := valid;
      retVar.msgType := fcIn(MSG_TYPE_RANGE_C);
      -- no latches are inferred because retVar is initialized
      -- right below the 'begin'

      -- check the message type
      if (retVar.msgType = MSG_TYPE_ROR_C) then
         -- if RoR, grab the bunch count
         retVar.bunchCnt := fcIn(BUNCH_CNT_RANGE_C);
      else
         -- if non-RoR, grab the state
         retVar.runState     := fcIn(RUN_STATE_RANGE_C);
         retVar.stateChanged := fcIn(STATE_CHANGED_INDEX_C);
      end if;

      retVar.pulseID := fcIn(PULSE_ID_RANGE_C);

      return retVar;
   end function FcDecode;


end package body FcPkg;
