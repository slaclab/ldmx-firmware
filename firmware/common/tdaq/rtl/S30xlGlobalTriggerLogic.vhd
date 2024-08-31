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
use surf.AxiStreamPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;
use ldmx_tdaq.TriggerPkg.all;

library ldmx_ts;
use ldmx_ts.TsPkg.all;


entity S30xlGlobalTriggerLogic is

   generic (
      TPD_G : time := 1 ns);
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
      gtRor           : out FcTimestampType;
      gtDaqAxisMaster : out AxiStreamMasterType;
      gtDaqAxisSlave  : in  AxiStreamSlaveType;

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

end entity S30xlGlobalTriggerLogic;

architecture rtl of S30xlGlobalTriggerLogic is

   constant MIN_ROR_PERIOD_C : slv(3 downto 0) := toSlv(6, 4);

   type RegType is record
      counter : slv(3 downto 0);
      gtRor   : FcTimestampType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      counter => (others => '0'),
      gtRor   => FC_TIMESTAMP_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal tsS30xlThresholdTriggerDaq : TsS30xlThresholdTriggerDaqType;
   signal emuTriggerMessage          : FcMessageType;

begin

   tsS30xlThresholdTriggerDaq <= toThresholdTriggerDaq(tsThresholdTriggerData, triggerTimestamp);
   emuTriggerMessage          <= toFcMessage(emuTriggerData.data(FC_LEN_C-1 downto 0), emuTriggerData.valid);

   comb : process (emuTriggerData, r, triggerTimestamp, tsS30xlThresholdTriggerDaq) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      v := r;

      v.gtRor.strobe := '0';
      v.gtRor.valid  := '0';

      -- Count down to achieve minimum ror spacing
      if (r.counter /= 0) then
         v.counter := v.counter - 1;
      end if;

      if (r.counter = 0) then

         -- TS Triggering
         if (tsS30xlThresholdTriggerDaq.valid = '1') then
            -- If BC0 seen send a ROR         
            if (tsS30xlThresholdTriggerDaq.bc0 = '1') then
               v.counter      := MIN_ROR_PERIOD_C;
               v.gtRor        := triggerTimestamp;
               v.gtRor.valid  := '1';
               v.gtRor.strobe := '1';
            end if;

            if (tsS30xlThresholdTriggerDaq.hits /= 0) then
               v.counter      := MIN_ROR_PERIOD_C;
               v.gtRor        := triggerTimestamp;
               v.gtRor.valid  := '1';
               v.gtRor.strobe := '1';
            end if;
         end if;

         -- Synthetic triggering
         if (emuTriggerData.valid = '1' and emuTriggerData.data(0) = '1') then
            v.counter      := MIN_ROR_PERIOD_C;
            v.gtRor        := triggerTimestamp;
            v.gtRor.valid  := '1';
            v.gtRor.strobe := '1';
         end if;
         
      end if;



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
