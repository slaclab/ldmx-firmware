-------------------------------------------------------------------------------
-- File       : TrackerPgpFcLane.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Adds FIFO buffers to each VC and transitions streams for DMA
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
use ldmx.FcPkg.all;

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
      -- Fast Control Interface
      fcBusTx         : in  FastControlBusType;
      fcBusRx         : out FastControlBusType;
      -- GT Clocking and Resets
      pgpRefClk       : in  sl;
      pgpUserRefClk   : in  sl;
      pgpRxRecClk     : out sl;
      pgpTxOutClk     : out sl;
      pgpRxOutClk     : out sl;
      pgpTxUsrClk     : in  sl;
      pgpRxUsrClk     : in  sl;
      pgpTxRstOut     : out sl;
      pgpRxRstOut     : out sl;
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

   -- Rx
   signal pgpRxIn         : Pgp2fcRxInType  := PGP2FC_RX_IN_INIT_C;
   signal pgpRxOut        : Pgp2fcRxOutType := PGP2FC_RX_OUT_INIT_C;
   signal pgpTxIn         : Pgp2fcTxInType  := PGP2FC_TX_IN_INIT_C;
   signal pgpTxOut        : Pgp2fcTxOutType := PGP2FC_TX_OUT_INIT_C;
   signal pgpRxRst        : sl := '0';
   signal pgpRxRstOutLane : sl := '0';
   signal pgpRxResetDone  : sl := '0';


   -- Tx
   signal pgpTxRst        : sl := '0';
   signal pgpTxRstOutLane : sl := '0';
   signal pgpTxResetDone  : sl := '0';


   -- DMA Stream
   signal pgpTxMasters : AxiStreamMasterArray(NUM_VC_EN_G-1 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(NUM_VC_EN_G-1 downto 0);
   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_EN_G-1 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(NUM_VC_EN_G-1 downto 0);

begin

   -- Glue logic
   -- TX (from local host to GT)
   pgpTxIn.fcWord(FC_LEN_C-1 downto 0) <= fcBusTx.fcMsg.message;
   pgpTxIn.fcValid                     <= fcBusTx.fcMsg.valid;
   -- RX (from GT to local host)
   fcBusRx.fcMsg.message               <= pgpRxOut.fcWord(FC_LEN_C-1 downto 0);
   fcBusRx.fcMsg.valid                 <= pgpRxOut.fcValid;
   fcBusRx.rxLinkStatus                <= pgpRxOut.remLinkReady;

   -- Reset Management
   -- If one routes 'pgpRxResetDone' to the RX reset, the align checker does not lock
   U_RstSync_Rx : entity surf.RstSync
      generic map (
         TPD_G         => TPD_G,
         IN_POLARITY_G => '0')
      port map (
         clk      => pgpRxUsrClk,       -- [in]
         asyncRst => pgpTxResetDone,    -- [in]
         syncRst  => pgpRxRst);         -- [out]

   U_RstSync_Tx : entity surf.RstSync
      generic map (
         TPD_G         => TPD_G,
         IN_POLARITY_G => '0')
      port map (
         clk      => pgpTxUsrClk,       -- [in]
         asyncRst => pgpTxResetDone,    -- [in]
         syncRst  => pgpTxRst);         -- [out]

   pgpRxRstOut <= pgpRxRstOutLane;
   pgpTxRstOut <= pgpTxRstOutLane;

   -----------
   -- PGP Core
   -----------
   U_LdmxPgpFcLane_1 : entity ldmx.LdmxPgpFcLane
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         AXIL_CLK_FREQ_G  => AXI_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXI_BASE_ADDR_G,
         NUM_VC_EN_G      => NUM_VC_EN_G)
      port map (
         pgpTxP          => pgpTxP,           -- [out]
         pgpTxN          => pgpTxN,           -- [out]
         pgpRxP          => pgpRxP,           -- [in]
         pgpRxN          => pgpRxN,           -- [in]
         pgpRefClk       => pgpRefClk,        -- [in]
         pgpUserRefClk   => pgpUserRefClk,    -- [in]
         pgpRxRst        => pgpRxRst,         -- [in]
         pgpRxRecClk     => pgpRxRecClk,      -- [out]
         pgpRxRstOut     => pgpRxRstOutLane,  -- [out]
         pgpRxResetDone  => pgpRxResetDone,   -- [out]
         pgpRxOutClk     => pgpRxOutClk,      -- [out]
         pgpRxUsrClk     => pgpRxUsrClk,      -- [in] -- Wrap clock back upstream
         pgpRxIn         => pgpRxIn,          -- [in]
         pgpRxOut        => pgpRxOut,         -- [out]
         pgpRxMasters    => pgpRxMasters,     -- [out]
         pgpRxCtrl       => pgpRxCtrl,        -- [in]
         pgpTxRstOut     => pgpTxRstOutLane,  -- [out]
         pgpTxRst        => pgpTxRst,         -- [in]
         pgpTxResetDone  => pgpTxResetDone,   -- [out]
         pgpTxOutClk     => pgpTxOutClk,      -- [out]
         pgpTxUsrClk     => pgpTxUsrClk,      -- [in]
         pgpTxIn         => pgpTxIn,          -- [in]
         pgpTxOut        => pgpTxOut,         -- [out]
         pgpTxMasters    => pgpTxMasters,     -- [in]
         pgpTxSlaves     => pgpTxSlaves,      -- [out]
         axilClk         => axilClk,          -- [in]
         axilRst         => axilRst,          -- [in]
         axilReadMaster  => axilReadMaster,   -- [in]
         axilReadSlave   => axilReadSlave,    -- [out]
         axilWriteMaster => axilWriteMaster,  -- [in]
         axilWriteSlave  => axilWriteSlave);  -- [out]


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
            pgpTxClk     => pgpTxUsrClk,
            pgpTxRst     => pgpTxRstOutLane,
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
            pgpRxClk        => pgpRxUsrClk,
            pgpRxRst        => pgpRxRstOutLane,
            pgpRxOut        => pgpRxOut,
            pgpRxMasters    => pgpRxMasters,
            pgpRxCtrl       => pgpRxCtrl);

   end generate GEN_VC;

   end mapping;
