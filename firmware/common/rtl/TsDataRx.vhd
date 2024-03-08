-------------------------------------------------------------------------------
-- Title      : Trigger Scintillator Data Rx
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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.FcPkg.all;
use ldmx.TsPkg.all;

entity TsDataRx is
   generic (
      TPD_G            : time             := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -- TS Interface
      tsRefClkP : in sl;
      tsRefClkN : in sl;
      tsRxP     : in sl;
      tsRxN     : in sl;

      -- Fast Control Interface
      fcClk185 : in sl;
      fcRst185 : in sl;
      fcBus : in FastControlBusType;

      -- TS data synchronized to fcClk
      -- and corresponding fcMsg
      tsRxMsg : out TsData8ChMsgType;
      tsFcMsg : out FastControlMessageType;

      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;


end entity TsDataRx;

architecture rtl of TsDataRx is
begin
end architecture rtl;
