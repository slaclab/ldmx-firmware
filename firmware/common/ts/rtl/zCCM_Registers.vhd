-------------------------------------------------------------------------------
-- Title      : zCCM Registers
-------------------------------------------------------------------------------
-- File       : zCCM_Registers.vhd
-- Author     : Andrew Whitbeck  <awhitbe1@fnal.gov>
-------------------------------------------------------------------------------
-- Description: Register interface for zCCM
-------------------------------------------------------------------------------
-- Copyright (c) 2013 Fermi National Accelerator Laboratory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity zCCM_Registers is
  generic(
    TPD_G : time := 1 ns);
  port(
    -- Axil inteface
    axilClk         : in  sl;
    axilRst         : in  sl;
    axilReadMaster  : in  AxiLiteReadMasterType;
    axilReadSlave   : out AxiLiteReadSlaveType;
    axilWriteMaster : in  AxiLiteWriteMasterType;
    axilWriteSlave  : out AxiLiteWriteSlaveType);
end entity zCCM_Registers;

architecture rtl of zCCM_Registers is

  type RegType is record
    scratch     : slv(31 downto 0);
    axilReadSlave  : AxiLiteReadSlaveType;
    axilWriteSlave : AxiLiteWriteSlaveType;
  end record RegType;

  constant REG_INIT_C : RegType := (
    scratch => (others => '0'),
    axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
    axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;
  
begin
   comb : process (r, axilReadMaster, axilWriteMaster) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;

   begin

     v := r;

     -- AXI Lite registers
     axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);
     
     axiSlaveRegister(axilEp, X"04", 0, v.scratch);
     
     axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);
     
     
     axilReadSlave  <= r.axilReadSlave;
     axilWriteSlave <= r.axilWriteSlave;
     rin <= v;

   end process comb;
   
   seq : process (axilClk, axilRst) is

   begin

     if (axilRst = '1') then
       r <= REG_INIT_C after TPD_G;
     elsif (rising_edge(axilClk)) then
       r <= rin after TPD_G;
     end if;

   end process seq;  

end architecture rtl;
