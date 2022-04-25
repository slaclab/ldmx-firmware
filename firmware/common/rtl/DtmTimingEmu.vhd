-------------------------------------------------------------------------------
-- File       : 
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-08-04
-- Last update: 2018-03-08
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity DtmTimingEmu is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Clock and Reset
      axilClk         : in  sl                     := '0';
      axilRst         : in  sl                     := '0';
      axilReadMaster  : in  AxiLiteReadMasterType  := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      locRefClkP : in sl;
      locRefClkN : in sl;

      distClk    : out sl;
      distClkRst : out sl;
      txDataEn   : out sl;
      txData     : out slv(9 downto 0));

end DtmTimingEmu;

architecture rtl of DtmTimingEmu is

   type RegType is record
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
      txData         : slv(9 downto 0);
      txDataEn       : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      txData         => (others => '0'),
      txDataEn       => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal valid : sl;

   signal locRefClkGt : sl;
   signal locRefClk   : sl;

begin




   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin

      v := r;

      -- Auto reset for trigger so it is always one cycle
      v.txDataEn := '0';

      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(axilEp, x"00", 0, v.txData);
      axiWrDetect(axilEp, X"00", v.txDataEn);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      if (r.trigger = '1') then
         v.txData := TI_TRIG_CODE_C;
      end if;

      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

   end process;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_SynchronizerFifo_1 : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 10,
         ADDR_WIDTH_G => 4)
      port map (
         rst    => axilRst,             -- [in]
         wr_clk => axilClk,             -- [in]
         wr_en  => r.txDataEn,          -- [in]
         din    => r.txData,            -- [in]
         rd_clk => locRefClk,           -- [in]
         rd_en  => valid,               -- [in]
         dout   => txData,              -- [out]
         valid  => valid);              -- [out]

   txDataEn <= valid;

end rtl;
