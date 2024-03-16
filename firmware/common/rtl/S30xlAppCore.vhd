-------------------------------------------------------------------------------
-- Title      : S30XL Application Core
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

entity S30xlAppCore is
   generic (
      TPD_G            : time             := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000");
   port (
      -- FC Receiver
      -- (Looped back from fcHub IO)
      appFcRefClkP : in  sl;
      appFcRefClkN : in  sl;
      appFcRxP     : in  sl;
      appFcRxN     : in  sl;
      appFcTxP     : out sl;
      appFcTxN     : out sl;

      -- TS Interface
      tsRefClk250P : in sl;
      tsRefClk250N : in sl;
      tsDataRxP     : in sl;
      tsDataRxN     : in sl;

      -- AXI Lite interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- DAQ Stream
      axisClk       : in  sl;
      axisRst       : in  sl;
      daqDataMaster : out AxiStreamMasterType;
      daqDataSlave  : in  AxiStreamSlaveType);
end entity S30xlAppCore;

architecture rtl of S30xlAppCore is

begin

   -------------------------------------------------------------------------------------------------
   -- Fast Control Receiver
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- TS Data Receiver
   -- (Data Receiver to APX)
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- DAQ Block Shell
   -- (Probably includes Data to DAQ sender and Common block for LDMX event header/trailer)
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- Trigger algorithm block
   -------------------------------------------------------------------------------------------------

   -------------------------------------------------------------------------------------------------
   -- Data to GT Sender
   -- (Encodes trigger data for transmission to GT)
   -------------------------------------------------------------------------------------------------


end architecture rtl;



