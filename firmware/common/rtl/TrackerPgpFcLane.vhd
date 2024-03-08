-------------------------------------------------------------------------------
-- File       : TrackerPgpFcLane.vhd
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
use surf.AxiStreamPkg.all;
use surf.Pgp2fcPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library ldmx;
use ldmx.AppPkg.all;

entity TrackerPgpFcLane is
   generic (
      TPD_G             : time                 := 1 ns;
      SIM_SPEEDUP_G     : boolean              := false;
      LANE_G            : natural              := 0;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_CLK_FREQ_G    : real                 := 125.0e6;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := (others => '0');
      TX_ENABLE_G       : boolean              := true;
      RX_ENABLE_G       : boolean              := true;
      NUM_VC_EN_G       : integer range 0 to 4 := 4);
   port (
      -- PGP Serial Ports
      pgpTxP          : out sl;
      pgpTxN          : out sl;
      pgpRxP          : in  sl;
      pgpRxN          : in  sl;
      pgpRefClk       : in  sl;
      pgpFabricRefClk : in  sl;
      pgpUserRefClk   : in  sl;
      rxRecClk        : out sl;
      pgpTxOutClk     : out sl;
      pgpRxOutClk     : out sl;
      pgpTxClk        : in  sl;
      pgpRxClk        : in  sl;
      -- DMA Interface (dmaClk domain)
      dmaClk          : in  sl;
      dmaRst          : in  sl;
      dmaBuffGrpPause : in  slv(7 downto 0);
      dmaObMaster     : in  AxiStreamMasterType;
      dmaObSlave      : out AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
      dmaIbMaster     : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dmaIbSlave      : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);
end TrackerPgpFcLane;

architecture mapping of TrackerPgpFcLane is

   constant NUM_AXI_MASTERS_C : natural := 4;

   constant GT_INDEX_C     : natural := 0;
   constant PGP2FC_INDEX_C : natural := 1;
   constant TX_MON_INDEX_C : natural := 2;
   constant RX_MON_INDEX_C : natural := 3;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 16, 14);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_OK_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_OK_C);

   signal pgpTxIn          : Pgp2fcTxInType;
   signal pgpTxOut         : Pgp2fcTxOutType;

   signal pgpRxIn          : Pgp2fcRxInType;
   signal pgpRxOut         : Pgp2fcRxOutType;

   signal pgpTxMasters     : AxiStreamMasterArray(NUM_VC_EN_G-1 downto 0);
   signal pgpTxSlaves      : AxiStreamSlaveArray(NUM_VC_EN_G-1 downto 0);

   signal pgpRxMasters     : AxiStreamMasterArray(NUM_VC_EN_G-1 downto 0);
   signal pgpRxCtrl        : AxiStreamCtrlArray(NUM_VC_EN_G-1 downto 0);

   signal pgpTxMastersGt   : AxiStreamMasterArray(3 downto 0) :=
                                                 (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlavesGt    : AxiStreamSlaveArray(3 downto 0):=
                                                 (others => AXI_STREAM_SLAVE_INIT_C);
   signal pgpRxMastersGt   : AxiStreamMasterArray(3 downto 0):=
                                                 (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxCtrlGt      : AxiStreamCtrlArray(3 downto 0):=
                                                 (others => AXI_STREAM_CTRL_INIT_C);

   signal pgpTxRst         : sl;
   signal pgpTxResetDone   : sl;

   signal pgpRxRst         : sl;
   signal pgpRxResetDone   : sl;

   signal config           : ConfigType;
   signal txUserRst        : sl;
   signal rxUserRst        : sl;

   signal wdtRst           : sl;
   signal pwrUpRstOut      : sl;

begin

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -----------
   -- PGP Core
   -----------
   U_Pgp : entity surf.Pgp2fcGtyUltra
      generic map (
         TPD_G           => TPD_G,
         SIMULATION_G    => SIM_SPEEDUP_G,
         AXI_CLK_FREQ_G  => AXI_CLK_FREQ_G,
         AXI_BASE_ADDR_G => AXI_BASE_ADDR_G,
         TX_ENABLE_G     => TX_ENABLE_G,
         RX_ENABLE_G     => RX_ENABLE_G,
         FC_WORDS_G      => 5,
         VC_INTERLEAVE_G => 1)          -- AxiStreamDmaV2 supports interleaving
      port map (
         -- GT Clocking
         stableClk       => axilClk,
         stableRst       => axilRst,
         gtRefClk        => pgpRefClk,
         gtFabricRefClk  => pgpFabricRefClk,
         gtUserRefClk    => pgpUserRefClk,
         rxRecClk        => rxRecClk,
         -- Gt Serial IO
         pgpGtTxP        => pgpTxP,
         pgpGtTxN        => pgpTxN,
         pgpGtRxP        => pgpRxP,
         pgpGtRxN        => pgpRxN,
         -- Tx Clocking
         pgpTxReset      => pgpTxRst,
         pgpTxResetDone  => pgpTxResetDone,
         pgpTxOutClk     => pgpTxOutClk,
         pgpTxClk        => pgpTxClk,
         pgpTxMmcmLocked => '1',
         -- Rx clocking
         pgpRxReset      => pgpRxRst,
         pgpRxResetDone  => pgpRxResetDone,
         pgpRxOutClk     => pgpRxOutClk,
         pgpRxClk        => pgpRxClk,
         pgpRxMmcmLocked => '1',
         -- Non VC Rx Signals
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- Non VC Tx Signals
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         -- Frame Transmit Interface
         pgpTxMasters    => pgpTxMastersGt,
         pgpTxSlaves     => pgpTxSlavesGt,
         -- Frame Receive Interface
         pgpRxMasters    => pgpRxMastersGt,
         pgpRxCtrl       => pgpRxCtrlGt,
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(GT_INDEX_C),
         axilReadSlave   => axilReadSlaves(GT_INDEX_C),
         axilWriteMaster => axilWriteMasters(GT_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(GT_INDEX_C));

   --------------
   -- PGP Monitor
   --------------
   U_PgpMon : entity surf.Pgp2fcAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => AXI_CLK_FREQ_G,
         STATUS_CNT_WIDTH_G => 12,
         ERROR_CNT_WIDTH_G  => 18)
      port map (
         -- TX PGP Interface (pgpTxClk)
         pgpTxClk        => pgpTxClk,
         pgpTxClkRst     => pgpTxRst,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         -- RX PGP Interface (pgpRxClk)
         pgpRxClk        => pgpRxClk,
         pgpRxClkRst     => pgpRxRst,
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(PGP2FC_INDEX_C),
         axilReadSlave   => axilReadSlaves(PGP2FC_INDEX_C),
         axilWriteMaster => axilWriteMasters(PGP2FC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PGP2FC_INDEX_C));

   GEN_VC : if NUM_VC_EN_G > 0 generate

      --------------
      -- PGP TX Path
      --------------
      U_Tx : entity ldmx.TrackerPgpFcLaneTx
         generic map (
            TPD_G             => TPD_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            NUM_VC_EN_G       => NUM_VC_EN_G)
         port map (
            -- DMA Interface (dmaClk domain)
            dmaClk       => dmaClk,
            dmaRst       => dmaRst,
            dmaObMaster  => dmaObMaster,
            dmaObSlave   => dmaObSlave,
            -- PGP Interface
            pgpTxClk     => pgpTxClk,
            pgpTxRst     => pgpTxRst,
            pgpRxOut     => pgpRxOut,
            pgpTxOut     => pgpTxOut,
            pgpTxMasters => pgpTxMasters,
            pgpTxSlaves  => pgpTxSlaves);

      --------------
      -- PGP RX Path
      --------------
      U_Rx : entity ldmx.TrackerPgpFcLaneRx
         generic map (
            TPD_G             => TPD_G,
            DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G,
            NUM_VC_EN_G       => NUM_VC_EN_G,
            LANE_G            => LANE_G)
         port map (
            -- DMA Interface (dmaClk domain)
            dmaClk          => dmaClk,
            dmaRst          => dmaRst,
            dmaBuffGrpPause => dmaBuffGrpPause,
            dmaIbMaster     => dmaIbMaster,
            dmaIbSlave      => dmaIbSlave,
            -- PGP RX Interface (pgpRxClk domain)
            pgpRxClk        => pgpRxClk,
            pgpRxRst        => pgpRxRst,
            pgpRxOut        => pgpRxOut,
            pgpRxMasters    => pgpRxMasters,
            pgpRxCtrl       => pgpRxCtrl);

      -----------------------------
      -- Monitor the PGP TX streams
      -----------------------------
      U_AXIS_TX_MON : entity surf.AxiStreamMonAxiL
         generic map(
            TPD_G            => TPD_G,
            COMMON_CLK_G     => false,
            AXIS_CLK_FREQ_G  => AXI_CLK_FREQ_G,
            AXIS_NUM_SLOTS_G => NUM_VC_EN_G,
            AXIS_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
         port map(
            -- AXIS Stream Interface
            axisClk          => pgpTxClk,
            axisRst          => pgpTxRst,
            axisMasters      => pgpTxMasters,
            axisSlaves       => pgpTxSlaves,
            -- AXI lite slave port for register access
            axilClk          => axilClk,
            axilRst          => axilRst,
            sAxilWriteMaster => axilWriteMasters(TX_MON_INDEX_C),
            sAxilWriteSlave  => axilWriteSlaves(TX_MON_INDEX_C),
            sAxilReadMaster  => axilReadMasters(TX_MON_INDEX_C),
            sAxilReadSlave   => axilReadSlaves(TX_MON_INDEX_C));

      -----------------------------
      -- Monitor the PGP RX streams
      -----------------------------
      U_AXIS_RX_MON : entity surf.AxiStreamMonAxiL
         generic map(
            TPD_G            => TPD_G,
            COMMON_CLK_G     => false,
            AXIS_CLK_FREQ_G  => AXI_CLK_FREQ_G,
            AXIS_NUM_SLOTS_G => NUM_VC_EN_G,
            AXIS_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
         port map(
            -- AXIS Stream Interface
            axisClk          => pgpRxClk,
            axisRst          => pgpRxRst,
            axisMasters      => pgpRxMasters,
            axisSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- SLAVE_READY_EN_G=false
            -- AXI lite slave port for register access
            axilClk          => axilClk,
            axilRst          => axilRst,
            sAxilWriteMaster => axilWriteMasters(RX_MON_INDEX_C),
            sAxilWriteSlave  => axilWriteSlaves(RX_MON_INDEX_C),
            sAxilReadMaster  => axilReadMasters(RX_MON_INDEX_C),
            sAxilReadSlave   => axilReadSlaves(RX_MON_INDEX_C));

      GEN_VC_CONNX : for vc in NUM_VC_EN_G-1 downto 0 generate
         pgpTxMastersGt(vc) <= pgpTxMasters(vc);
         pgpRxCtrlGt(vc)    <= pgpRxCtrl(vc);
         pgpTxSlaves(vc)    <= pgpTxSlavesGt(vc);
         pgpRxMasters(vc)   <= pgpRxMastersGt(vc);
      end generate GEN_VC_CONNX;

   end generate GEN_VC;

   GEN_VC_CHECK : if NUM_VC_EN_G < 4 generate

      GEN_GND : for gnd in 3 downto NUM_VC_EN_G generate
         pgpTxMastersGt(gnd) <= AXI_STREAM_MASTER_INIT_C;
         pgpRxCtrlGt(gnd)    <= AXI_STREAM_CTRL_INIT_C;
      end generate GEN_GND;

   end generate GEN_VC_CHECK;

   U_Wtd : entity surf.WatchDogRst
      generic map(
         TPD_G      => TPD_G,
         DURATION_G => getTimeRatio(AXI_CLK_FREQ_G, 0.2))  -- 5 s timeout
      port map (
         clk    => axilClk,
         monIn  => pgpRxOut.remLinkReady,
         rstOut => wdtRst);

   U_PwrUpRst : entity surf.PwrUpRst
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => false,
         DURATION_G    => getTimeRatio(AXI_CLK_FREQ_G, 10.0))  -- 100 ms reset pulse
      port map (
         clk    => axilClk,
         arst   => wdtRst,
         rstOut => pwrUpRstOut);

   U_RstSync_Tx : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => pgpTxClk,          -- [in]
         asyncRst => '0',               -- [in]
         syncRst  => pgpTxRst);         -- [out]

   U_RstSync_Rx : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => pgpRxClk,          -- [in]
         asyncRst => '0',               -- [in]
         syncRst  => pgpRxRst);         -- [out]

end mapping;
