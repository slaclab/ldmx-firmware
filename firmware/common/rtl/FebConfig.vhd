-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.FebConfigPkg.all;

entity FebConfig is
   generic (
      TPD_G : time := 1 ns);
   port (
      axiClk : in sl;
      axiRst : in sl;

      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      febConfig : out FebConfigType);

end FebConfig;

architecture rtl of FebConfig is

   type RegType is record
      axiReadSlave    : AxiLiteReadSlaveType;
      axiWriteSlave   : AxiLiteWriteSlaveType;
      febConfig       : FebConfigType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      axiReadSlave    => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave   => AXI_LITE_WRITE_SLAVE_INIT_C,
      febConfig       => FEB_CONFIG_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


begin


   comb : process (axiReadMaster, axiRst, axiWriteMaster, r) is
      variable v       : RegType;
      variable axilEp  : AxiLiteEndpointType;
      variable addrInt : integer;
   begin
      v := r;

      -- Turn on hybrid hard reset when no power to hybrid
      -- Only allow it high for one cycle when there is power
      v.febConfig.hyHardRst := not r.febConfig.hyPwrEn;

      axiSlaveWaitTxn(axilEp, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);

      axiSlaveRegister(axilEp, X"00", 0, v.febConfig.hyPwrEn);
      axiSlaveRegister(axilEp, X"04", 0, v.febConfig.hyHardRst);
      axiSlaveRegister(axilEp, X"0C", 0, v.febConfig.hyTrigEn);
      axiSlaveRegister(axilEp, X"18", 0, v.febConfig.febAddress);
      axiSlaveRegister(axilEp, X"1C", 0, v.febConfig.hybridType(0));
      axiSlaveRegister(axilEp, X"1C", 2, v.febConfig.hybridType(1));
      axiSlaveRegister(axilEp, X"1C", 4, v.febConfig.hybridType(2));
      axiSlaveRegister(axilEp, X"1C", 6, v.febConfig.hybridType(3));
      axiSlaveRegister(axilEp, X"1C", 8, v.febConfig.hybridType(4));
      axiSlaveRegister(axilEp, X"1C", 10, v.febConfig.hybridType(5));
      axiSlaveRegister(axilEp, X"1C", 12, v.febConfig.hybridType(6));
      axiSlaveRegister(axilEp, X"1C", 14, v.febConfig.hybridType(7));
      
      axiSlaveRegister(axilEp, X"28", 0, v.febConfig.calDelay);
      axiSlaveRegister(axilEp, X"28", 8, v.febConfig.calEn);
      axiSlaveRegister(axilEp, X"2C", 0, v.febConfig.hyApvDataStreamEn);
      axiSlaveRegister(axilEp, X"40", 0, v.febConfig.headerHighThreshold);
      axiSlaveRegister(axilEp, X"48", 0, v.febConfig.allowResync);

      axiSlaveRegister(axilEp, X"58", 0, v.febConfig.threshold1CutEn);
      axiSlaveRegister(axilEp, X"58", 1, v.febConfig.slopeCutEn);
      axiSlaveRegister(axilEp, X"58", 3, v.febConfig.calGroup);
      axiSlaveRegister(axilEp, X"58", 6, v.febConfig.threshold1CutNum);
      axiSlaveRegister(axilEp, X"58", 9, v.febConfig.threshold1MarkOnly);
      axiSlaveRegister(axilEp, X"58", 10, v.febConfig.errorFilterEn);
      axiSlaveRegister(axilEp, X"58", 11, v.febConfig.threshold2CutEn);
      axiSlaveRegister(axilEp, X"58", 12, v.febConfig.threshold2CutNum);
      axiSlaveRegister(axilEp, X"58", 15, v.febConfig.threshold2MarkOnly);                  
      axiSlaveRegister(axilEp, X"5C", 0, v.febConfig.dataPipelineRst);
      

      axiSlaveDefault(axilEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Reset
      ----------------------------------------------------------------------------------------------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;
      febConfig     <= r.febConfig;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
