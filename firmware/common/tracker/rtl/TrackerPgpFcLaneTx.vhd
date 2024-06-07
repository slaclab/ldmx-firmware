-------------------------------------------------------------------------------
-- File       : TrackerPgpFcLaneTx.vhd
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
use surf.AxiStreamPkg.all;
use surf.Pgp2fcPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

entity TrackerPgpFcLaneTx is
   generic (
      TPD_G             : time := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      NUM_VC_EN_G       : integer range 0 to 4 := 4);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk       : in  sl;
      dmaRst       : in  sl;
      dmaObMaster  : in  AxiStreamMasterType;
      dmaObSlave   : out AxiStreamSlaveType;
      -- PGP Interface (pgpTxClk domain)
      pgpTxClk     : in  sl;
      pgpTxRst     : in  sl;
      pgpRxOut     : in  Pgp2fcRxOutType;
      pgpTxOut     : in  Pgp2fcTxOutType;
      pgpTxMasters : out AxiStreamMasterArray(3 downto 0);
      pgpTxSlaves  : in  AxiStreamSlaveArray(3 downto 0));
end TrackerPgpFcLaneTx;

architecture mapping of TrackerPgpFcLaneTx is

   signal dmaMaster : AxiStreamMasterType;
   signal dmaCtrl   : AxiStreamCtrlType;

   signal txMaster : AxiStreamMasterType;
   signal txSlave  : AxiStreamSlaveType;

   signal txMasterSof : AxiStreamMasterType;
   signal txSlaveSof  : AxiStreamSlaveType;

   signal linkReady : sl;
   signal flushEn   : sl;

begin

   linkReady <= pgpTxOut.linkReady and pgpRxOut.linkReady;

   U_FlushSync : entity surf.Synchronizer
      generic map (
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '0')
      port map (
         clk     => dmaClk,
         rst     => dmaRst,
         dataIn  => linkReady,
         dataOut => flushEn);

   U_Flush : entity surf.AxiStreamFlush
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
         SSI_EN_G      => true)
      port map (
         axisClk     => dmaClk,
         axisRst     => dmaRst,
         flushEn     => flushEn,
         sAxisMaster => dmaObMaster,
         sAxisSlave  => dmaObSlave,
         mAxisMaster => dmaMaster,
         mAxisCtrl   => dmaCtrl);

   U_RESIZE : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 5,
         FIFO_PAUSE_THRESH_G => 20,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => PGP2FC_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => dmaClk,
         sAxisRst    => dmaRst,
         sAxisMaster => dmaMaster,
         sAxisCtrl   => dmaCtrl,
         -- Master Port
         mAxisClk    => pgpTxClk,
         mAxisRst    => pgpTxRst,
         mAxisMaster => txMaster,
         mAxisSlave  => txSlave);

   U_SOF : entity surf.SsiInsertSof
      generic map (
         TPD_G               => TPD_G,
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => PGP2FC_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP2FC_AXIS_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => pgpTxClk,
         sAxisRst    => pgpTxRst,
         sAxisMaster => txMaster,
         sAxisSlave  => txSlave,
         -- Master Port
         mAxisClk    => pgpTxClk,
         mAxisRst    => pgpTxRst,
         mAxisMaster => txMasterSof,
         mAxisSlave  => txSlaveSof);

   U_DeMux : entity surf.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => 4,
         MODE_G        => "INDEXED",
         PIPE_STAGES_G => 1,
         TDEST_HIGH_G  => 3, -- TO-DO: is this correct?
         TDEST_LOW_G   => 0)
      port map (
         -- Clock and reset
         axisClk      => pgpTxClk,
         axisRst      => pgpTxRst,
         -- Slave
         sAxisMaster  => txMasterSof,
         sAxisSlave   => txSlaveSof,
         -- Masters
         mAxisMasters => pgpTxMasters,
         mAxisSlaves  => pgpTxSlaves);

end mapping;
