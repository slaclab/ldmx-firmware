-------------------------------------------------------------------------------
-- Title      : HPS Data RCE Configuration
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Configuration registers for RceCore on DataDpm.
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


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.RceConfigPkg.all;

entity RceConfig is
   generic (
      TPD_G : time := 1 ns);
   port (
      axiClk    : in sl;
      axiClkRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      rceConfig  : out RceConfigType);
end RceConfig;

architecture rtl of RceConfig is

   type RegType is record
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
      rceConfig     : RceConfigType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      rceConfig     => RCE_CONFIG_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (axiClkRst, axiReadMaster, axiWriteMaster, r) is
      variable v         : RegType;
      variable axiEp : AxiLiteEndpointType;
   begin
      v := r;

      axiSlaveWaitTxn(axiEp, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);

      axiSlaveRegister(axiEp, X"00", 0, v.rceConfig.address);
      axiSlaveRegister(axiEp, X"08", 0, v.rceConfig.threshold1CutEn);
      axiSlaveRegister(axiEp, X"08", 1, v.rceConfig.slopeCutEn);
      axiSlaveRegister(axiEp, X"08", 2, v.rceConfig.calEn);
      axiSlaveRegister(axiEp, X"08", 3, v.rceConfig.calGroup);
      axiSlaveRegister(axiEp, X"08", 6, v.rceConfig.threshold1CutNum);
      axiSlaveRegister(axiEp, X"08", 9, v.rceConfig.threshold1MarkOnly);
      axiSlaveRegister(axiEp, X"08", 10, v.rceConfig.errorFilterEn);
      axiSlaveRegister(axiEp, X"08", 11, v.rceconfig.threshold2CutEn);
      axiSlaveRegister(axiEp, X"08", 12, v.rceconfig.threshold2CutNum);
      axiSlaveRegister(axiEp, X"08", 15, v.rceconfig.threshold2MarkOnly);                  
      axiSlaveRegister(axiEp, X"0C", 0, v.rceConfig.dataPipelineRst);

      axiSlaveDefault(axiEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);


      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      if (axiClkRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;
      rceConfig     <= r.rceConfig;
      
   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
