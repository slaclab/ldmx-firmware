-------------------------------------------------------------------------------
-- File       : TrackerPgpFcLaneRx.vhd
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

entity TrackerPgpFcLaneRx is
   generic (
      TPD_G             : time    := 1 ns;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      LANE_G            : natural := 0);
   port (
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaIbMaster     : out AxiStreamMasterType;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- PGP RX Interface (pgpRxClk domain)
      pgpRxClk        : in  sl;
      pgpRxRst        : in  sl;
      pgpRxOut        : in  Pgp2fcRxOutType;
      pgpRxMasters    : in  AxiStreamMasterArray(3 downto 0);
      pgpRxSlaves     : out AxiStreamSlaveArray(3 downto 0);
      pgpRxCtrl       : out AxiStreamCtrlArray(3 downto 0));
end TrackerPgpFcLaneRx;

architecture mapping of TrackerPgpFcLaneRx is

   signal pgpMasters   : AxiStreamMasterArray(3 downto 0);
   signal rxMasters    : AxiStreamMasterArray(3 downto 0);
   signal rxSlaves     : AxiStreamSlaveArray(3 downto 0);
   signal locBuffPause : slv(3 downto 0);
   signal disableSel   : slv(3 downto 0);

   signal rxMaster : AxiStreamMasterType;
   signal rxSlave  : AxiStreamSlaveType;

begin

   BLOWOFF_FILTER : process (pgpRxMasters, pgpRxOut) is
      variable tmp : AxiStreamMasterArray(3 downto 0);
      variable i   : natural;
   begin
      tmp := pgpRxMasters;
      for i in 3 downto 0 loop
         if (pgpRxOut.linkReady = '0') then
            tmp(i).tValid := '0';
         end if;
      end loop;
      pgpMasters <= tmp;
   end process;

   GEN_VEC :
   for i in 3 downto 0 generate

      PGP_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            -- General Configurations
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 1,
            PIPE_STAGES_G       => 1,
            SLAVE_READY_EN_G    => false,
            VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
            VALID_BURST_MODE_G  => true,
            -- FIFO configurations
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => 10,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 128,
            -- AXI Stream Port Configurations
            SLAVE_AXI_CONFIG_G  => PGP2FC_AXIS_CONFIG_C,
            MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
         port map (
            -- Slave Port
            sAxisClk    => pgpRxClk,
            sAxisRst    => pgpRxRst,
            sAxisMaster => pgpMasters(i),
            sAxisCtrl   => pgpRxCtrl(i),
            -- Master Port
            mAxisClk    => pgpRxClk,
            mAxisRst    => pgpRxRst,
            mAxisMaster => rxMasters(i),
            mAxisSlave  => rxSlaves(i));

   end generate GEN_VEC;

   U_Mux : entity surf.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => 4,
         MODE_G               => "INDEXED",
         TID_MODE_G           => "INDEXED",
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => true,
         ILEAVE_REARB_G       => 128,
         PIPE_STAGES_G        => 1)
      port map (
         -- Clock and reset
         axisClk      => pgpRxClk,
         axisRst      => pgpRxRst,
         -- Slaves
         sAxisMasters => rxMasters,
         sAxisSlaves  => rxSlaves,
         disableSel   => disableSel,
         -- Master
         mAxisMaster  => rxMaster,
         mAxisSlave   => rxSlave);

   locBuffPause <= dmaBuffGrpPause(3 downto 0) when (LANE_G mod 2 = 0) else dmaBuffGrpPause(7 downto 4);
   U_disableSel : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 4)
      port map (
         clk     => pgpRxClk,
         dataIn  => locBuffPause,
         dataOut => disableSel);

   ASYNC_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 2,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => DMA_AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Slave Port
         sAxisClk    => pgpRxClk,
         sAxisRst    => pgpRxRst,
         sAxisMaster => rxMaster,
         sAxisSlave  => rxSlave,
         -- Master Port
         mAxisClk    => dmaClk,
         mAxisRst    => dmaRst,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);

end mapping;
