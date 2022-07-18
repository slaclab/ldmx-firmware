-------------------------------------------------------------------------------
-- File       : PgpMiscCtrl.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library ldmx;
use ldmx.AppPkg.all;

entity PgpMiscCtrl is
   generic (
      TPD_G            : time            := 1 ns);
   port (
      -- Control/Status  (axilClk domain)
      config          : out ConfigType;
      rxUserRst       : out sl;
      txUserRst       : out sl;
      -- AXI-Lite Register Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end PgpMiscCtrl;

architecture rtl of PgpMiscCtrl is

   type RegType is record
      config         : ConfigType;
      rxUserRst      : sl;
      txUserRst      : sl;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record;

   constant REG_INIT_C : RegType := (
      config         => CONFIG_INIT_C,
      rxUserRst      => '0',
      txUserRst      => '0',
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal rxUserReset : sl;
   signal txUserReset : sl;

   attribute use_dsp48      : string;
   attribute use_dsp48 of r : signal is "yes";

begin

   ---------------------
   -- AXI Lite Interface
   ---------------------
   comb : process (axilReadMaster, axilRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
      variable i      : natural;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(regCon, x"68", 0, v.config.gtDrpOverride);
      axiSlaveRegister(regCon, x"6C", 0, v.config.txDiffCtrl);

      axiSlaveRegister(regCon, x"70", 0, v.config.txPreCursor);
      axiSlaveRegister(regCon, x"74", 0, v.config.txPostCursor);
      axiSlaveRegister(regCon, x"78", 0, v.config.qPllRxSelect);
      axiSlaveRegister(regCon, x"7C", 0, v.config.qPllTxSelect);

      axiSlaveRegister(regCon, x"80", 0, v.txUserRst);
      axiSlaveRegister(regCon, x"84", 0, v.rxUserRst);

      -- Closeout the transaction
      axiSlaveDefault(regCon, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilWriteSlave <= r.axilWriteSlave;
      axilReadSlave  <= r.axilReadSlave;
      config         <= r.config;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_rxUserRst : entity surf.PwrUpRst
      generic map (
         TPD_G       => TPD_G,
         DURATION_G  => 125000000)
      port map (
         arst   => r.rxUserRst,
         clk    => axilClk,
         rstOut => rxUserReset);

   U_RstRx : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => rxUserReset,
         rstOut => rxUserRst);

   U_txUserRst : entity surf.PwrUpRst
      generic map (
         TPD_G       => TPD_G,
         DURATION_G  => 125000000)
      port map (
         arst   => r.txUserRst,
         clk    => axilClk,
         rstOut => txUserReset);

   U_RstTx : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => axilClk,
         rstIn  => txUserReset,
         rstOut => txUserRst);

end rtl;
