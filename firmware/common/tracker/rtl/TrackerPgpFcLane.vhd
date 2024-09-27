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

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library ldmx_tracker;

entity TrackerPgpFcLane is
   generic (
      TPD_G             : time                 := 1 ns;
      SIM_SPEEDUP_G     : boolean              := false;
      LANE_G            : natural              := 0;
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXIL_CLK_FREQ_G   : real                 := 125.0e6;
      AXIL_BASE_ADDR_G  : slv(31 downto 0)     := (others => '0');
      NUM_VC_EN_G       : integer range 0 to 4 := 4);
   port (
      -- PGP Serial Ports
      pgpTxP            : out sl;
      pgpTxN            : out sl;
      pgpRxP            : in  sl;
      pgpRxN            : in  sl;
      pgpRefClk         : in  sl;
      pgpUserRefClk     : in  sl;
      pgpUserDiv2RefClk : in  sl;
      -- Fast Control Interface
      -- Drives TX
      fcClk185          : in  sl;
      fcRst185          : in  sl;
      fcBus             : in  FcBusType;
      -- DMA Interface (dmaClk domain)
      dmaClk            : in  sl;
      dmaRst            : in  sl;
      dmaBuffGrpPause   : in  slv(7 downto 0);
      dmaObMaster       : in  AxiStreamMasterType;
      dmaObSlave        : out AxiStreamSlaveType  := AXI_STREAM_SLAVE_INIT_C;
      dmaIbMaster       : out AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dmaIbSlave        : in  AxiStreamSlaveType;
      -- AXI-Lite Interface (axilClk domain)
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType);
end entity TrackerPgpFcLane;

architecture mapping of TrackerPgpFcLane is

   signal pgpRxOutClk : sl;
   signal pgpRxRstOut : sl;


   -- Rx
   signal pgpRxIn  : Pgp2fcRxInType  := PGP2FC_RX_IN_INIT_C;
   signal pgpRxOut : Pgp2fcRxOutType := PGP2FC_RX_OUT_INIT_C;
   signal pgpTxIn  : Pgp2fcTxInType  := PGP2FC_TX_IN_INIT_C;
   signal pgpTxOut : Pgp2fcTxOutType := PGP2FC_TX_OUT_INIT_C;



   signal pgpTxMasters : AxiStreamMasterArray(NUM_VC_EN_G-1 downto 0);
   signal pgpTxSlaves  : AxiStreamSlaveArray(NUM_VC_EN_G-1 downto 0);
   signal pgpRxMasters : AxiStreamMasterArray(NUM_VC_EN_G-1 downto 0);
   signal pgpRxCtrl    : AxiStreamCtrlArray(NUM_VC_EN_G-1 downto 0);

begin

   -- Glue logic
   pgpTxIn.fcWord(FC_LEN_C-1 downto 0) <= fcBus.fcMsg.message;
   pgpTxIn.fcValid                     <= fcBus.fcMsg.valid;

   -----------
   -- PGP Core
   -----------
   U_LdmxPgpFcLane_1 : entity ldmx_tdaq.LdmxPgpFcLane
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXIL_BASE_ADDR_G,
         NUM_VC_EN_G      => NUM_VC_EN_G)
      port map (
         pgpTxP           => pgpTxP,            -- [out]
         pgpTxN           => pgpTxN,            -- [out]
         pgpRxP           => pgpRxP,            -- [in]
         pgpRxN           => pgpRxN,            -- [in]
         pgpRefClk        => pgpRefClk,         -- [in]
         pgpUserRefClk    => pgpUserRefClk,     -- [in]
         pgpUserStableClk => pgpUserDiv2RefClk, -- [in]
         pgpRxRstOut      => pgpRxRstOut,       -- [out]
         pgpRxOutClk      => pgpRxOutClk,       -- [out]
         pgpRxIn          => pgpRxIn,           -- [in]
         pgpRxOut         => pgpRxOut,          -- [out]
         pgpRxMasters     => pgpRxMasters,      -- [out]
         pgpRxCtrl        => pgpRxCtrl,         -- [in]
         pgpTxRst         => fcRst185,          -- [in]
         pgpTxOutClk      => open,              -- [out]
         pgpTxUsrClk      => fcClk185,          -- [in]
         pgpTxIn          => pgpTxIn,           -- [in]
         pgpTxOut         => pgpTxOut,          -- [out]
         pgpTxMasters     => pgpTxMasters,      -- [in]
         pgpTxSlaves      => pgpTxSlaves,       -- [out]
         axilClk          => axilClk,           -- [in]
         axilRst          => axilRst,           -- [in]
         axilReadMaster   => axilReadMaster,    -- [in]
         axilReadSlave    => axilReadSlave,     -- [out]
         axilWriteMaster  => axilWriteMaster,   -- [in]
         axilWriteSlave   => axilWriteSlave);   -- [out]


   GEN_BUFF : if NUM_VC_EN_G > 0 generate

      --------------
      -- PGP TX Path
      --------------
      U_Tx : entity ldmx_tracker.TrackerPgpFcLaneTx
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
            pgpTxClk     => fcClk185,
            pgpTxRst     => fcRst185,
            pgpRxOut     => pgpRxOut,
            pgpTxOut     => pgpTxOut,
            pgpTxMasters => pgpTxMasters,
            pgpTxSlaves  => pgpTxSlaves);

      --------------
      -- PGP RX Path
      --------------
      U_Rx : entity ldmx_tracker.TrackerPgpFcLaneRx
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
            pgpRxClk        => pgpRxOutClk,
            pgpRxRst        => pgpRxRstOut,
            pgpRxOut        => pgpRxOut,
            pgpRxMasters    => pgpRxMasters,
            pgpRxCtrl       => pgpRxCtrl);

   end generate GEN_BUFF;


end mapping;
