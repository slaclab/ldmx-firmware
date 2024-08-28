-------------------------------------------------------------------------------
-- Title      : 
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.TriggerPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;


entity S30xlGlobalTriggerLogic is

   generic (
      TPD_G      : time    := 1 ns;
      CHANNELS_G : integer := 2);
   port (
      -----------------------------
      -- Raw Trigger Data In
      -----------------------------
      lclsTimingClk          : in sl;
      lclsTimingRst          : in sl;
      tsThresholdTriggerData : in TriggerDataType;
      emuTriggerData         : in TriggerDataType;
      triggerTimestamp       : in FcTimestampType;

      --------
      -- Outut
      --------
      gtRor           : FcTimestampType;
      gtDaqAxisMaster : AxiStreamMasterType;
      gtDaqAxisSlave  : AxiStreamSlaveType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity S30xlGlobalTriggerLogic;

architecture rtl of S30xlGlobalTriggerLogic is

   type RegType is record
      gtRor : FcTimestampType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      gtRor => FC_TIMESTAMP_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal tsS30xlThresholdTriggerDaq : TsS30xlThresholdTriggerDaqType;

begin

   tsS30xlThresholdTriggerDaq <= toThresholdTriggerDaq(tsThresholdTriggerData, triggerTimestamp);

   comb : process (r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      v := r;

      rin <= v;

      gtRor <= r.gtRor;
   end process;


   -- Have to use async reset since recovered lcls clock can drop out
   seq : process (lclsTimingClk, lclsTimingRst) is
   begin
      if (lclsTimingRst = '1') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(lclsTimingClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
