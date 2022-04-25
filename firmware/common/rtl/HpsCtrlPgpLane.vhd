-------------------------------------------------------------------------------
-- Title         : PGP Lane For Control DPM
-- File          : HpsPgpCtrlLane.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 05/21/2014
-------------------------------------------------------------------------------
-- Description:
-- PGP Lane
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 05/21/2014: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.Pgp2bPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.SsiPkg.all;
use surf.Gtx7CfgPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

entity HpsCtrlPgpLane is
   generic (
      TPD_G               : time                        := 1 ns;
      SIMULATION_G        : boolean                     := false;
      SIM_PGP_PORT_NUM_G  : natural range 1024 to 49151 := 4000;
      AXIL_BASE_ADDRESS_G : slv(31 downto 0)            := (others => '0');
      TX_PLL_G            : string                      := "QPLL";
      RX_PLL_G            : string                      := "CPLL";
      RX_FIXED_LAT_G      : boolean                     := true;
      QPLL_CFG_G          : Gtx7QPllCfgType             := getGtx7QPllCfg(125.0E6, 2.5E9));
   port (

      -- Transmit
      pgpRxRst    : in sl;              -- async reset for rx side
      pgpTxClk    : in sl;
      pgpTxRst    : in sl;
      pgpTxData   : in slv(9 downto 0);
      pgpTxDataEn : in sl;

      -- AXI Stream Data
      pgpAxisClk   : in  sl;
      pgpAxisRst   : in  sl;
      pgpRxMasters : out AxiStreamMasterType;
      pgpRxSlaves  : in  AxiStreamSlaveType;
      pgpTxMasters : in  AxiStreamMasterType;
      pgpTxSlaves  : out AxiStreamSlaveType;

      -- Axi Bus
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- PHY
      sysClk200 : in sl;

      cPllRefClk     : in  sl;
      qPllOutRefClk  : in  sl;
      qPllOutClk     : in  sl;
      qPllLock       : in  sl;
      qPllRefClkLost : in  sl;
      qPllReset      : out sl;

      rxRefClkG       : in  sl;
      pgpTxMmcmLocked : in  sl;
      dpmToRtmHsP     : out sl;
      dpmToRtmHsM     : out sl;
      rtmToDpmHsP     : in  sl;
      rtmToDpmHsM     : in  sl);

end HpsCtrlPgpLane;

architecture STRUCTURE of HpsCtrlPgpLane is

   constant NUM_VC_EN_C : integer := 4;
   constant CTRL_VC_C   : integer := 0;
   constant SEM_VC_C    : integer := 1;

   -- Should this be HPS_DMA_DATA_CONFIG_C ????
   constant AXIS_CONFIG_C : AxiStreamConfigType := RCEG3_AXIS_DMA_CONFIG_C;

   constant CPLL_REFCLK_FREQ_C : real := ite(TX_PLL_G = "CPLL", 125.0E6,
                                             ite(RX_PLL_G = "CPLL", 250.0E6,
                                                 125.0E6));
   constant CPLL_CONFIG_C : Gtx7CPllCfgType := getGtx7CPllCfg(CPLL_REFCLK_FREQ_C, 2.5E9);
   constant GTX_CONFIG_C  : Gtx7CfgType     := getGtx7Cfg(TX_PLL_G, RX_PLL_G, CPLL_CONFIG_C, QPLL_CFG_G);

--   constant CPLL_REFCLK_FREQ_C : real            := 125.0E6;
--   constant CPLL_CONFIG_C      : Gtx7CPllCfgType := getGtx7CPllCfg(CPLL_REFCLK_FREQ_C, 2.5E9);
--   constant GTX_CONFIG_C       : Gtx7CfgType     := getGtx7Cfg(TX_PLL_G, RX_PLL_G, CPLL_CONFIG_C, QPLL_CFG_G);

   signal pgpRxClk       : sl;
   signal pgpRxRecClk    : sl;
   signal pgpRxRecClkRst : sl;
   signal pgpRxIn        : Pgp2bRxInType;
   signal pgpRxOut       : Pgp2bRxOutType;
   signal pgpTxIn        : Pgp2bTxInType;
   signal locTxIn        : Pgp2bTxInType := PGP2B_TX_IN_INIT_C;
   signal pgpTxOut       : Pgp2bTxOutType;

   -- TX
   signal flushEn             : sl;
   signal pgpTxFlushedMasters : AxiStreamMasterType;
   signal pgpTxFlushedCtrl    : AxiStreamCtrlType;
   signal pgpTxFifoMasters    : AxiStreamMasterType;
   signal pgpTxFifoSlaves     : AxiStreamSlaveType;

   -- RX
   signal blowoffVcRxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpVcTxMasters     : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpVcTxSlaves      : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpVcRxMasters     : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpVcRxSlaves      : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
   signal pgpVcRxCtrl        : AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);
   signal fifoVcRxMasters    : AxiStreamMasterArray(NUM_VC_EN_C-1 downto 0);
   signal fifoVcRxSlaves     : AxiStreamSlaveArray(NUM_VC_EN_C-1 downto 0);
   signal muxRxMaster        : AxiStreamMasterType;
   signal muxRxSlave         : AxiStreamSlaveType;

begin

   -------------------------------------------------------------------------------------------------
   -- TX Buffers and Demux
   -------------------------------------------------------------------------------------------------

   -- Flush any data that arrives when remote link is not active
   U_FlushSync : entity surf.Synchronizer
      generic map(
         TPD_G          => TPD_G,
         OUT_POLARITY_G => '0')
      port map (
         clk     => pgpAxisClk,
         rst     => pgpAxisRst,
         dataIn  => pgpRxOut.remLinkReady,
         dataOut => flushEn);

   U_Flush : entity surf.AxiStreamFlush
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => AXIS_CONFIG_C,
         SSI_EN_G      => true)
      port map (
         axisClk     => pgpAxisClk,
         axisRst     => pgpAxisRst,
         flushEn     => flushEn,
         sAxisMaster => pgpTxMasters,
         sAxisSlave  => pgpTxSlaves,
         mAxisMaster => pgpTxFlushedMasters,
         mAxisCtrl   => pgpTxFlushedCtrl);

   -- AxiStreamFlush requires a FIFO downstream
   -- Do the resize and sync to pgp
   U_RESIZE : entity surf.AxiStreamFifoV2
      generic map (
         -- General Configurations
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         -- FIFO configurations
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 20,
         -- AXI Stream Port Configurations
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         -- Slave Port
         sAxisClk    => pgpAxisClk,
         sAxisRst    => pgpAxisRst,
         sAxisMaster => pgpTxFlushedMasters,
         sAxisCtrl   => pgpTxFlushedCtrl,
         -- Master Port
         mAxisClk    => pgpTxClk,
         mAxisRst    => pgpTxRst,
         mAxisMaster => pgpTxFifoMasters,
         mAxisSlave  => pgpTxFifoSlaves);


   -- Control Stream De-Mux
   U_CntrlDeMux : entity surf.AxiStreamDeMux
      generic map (
         TPD_G         => TPD_G,
         NUM_MASTERS_G => NUM_VC_EN_C,
         MODE_G        => "INDEXED",
         PIPE_STAGES_G => 1,
         TDEST_HIGH_G  => 3,
         TDEST_LOW_G   => 0)
      port map (
         axisClk      => pgpAxisClk,
         axisRst      => pgpAxisRst,
         sAxisMaster  => pgpTxFifoMasters,
         sAxisSlave   => pgpTxFifoSlaves,
         mAxisMasters => pgpVcTxMasters,
         mAxisSlaves  => pgpVcTxSlaves);

   -- No longer FIFO between demux and PGP
--       U_TxFifo : entity surf.AxiStreamFifoV2
--          generic map (
--             TPD_G               => TPD_G,
--             INT_PIPE_STAGES_G   => 1,
--             PIPE_STAGES_G       => 1,
--             SLAVE_READY_EN_G    => true,
--             VALID_THOLD_G       => 128,
--             VALID_BURST_MODE_G  => true,
--             INT_WIDTH_SELECT_G  => "WIDE",
--             MEMORY_TYPE_G           => "block",
--             GEN_SYNC_FIFO_G     => false,
--             CASCADE_SIZE_G      => 1,
--             FIFO_ADDR_WIDTH_G   => 10,
--             SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,
--             MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C
--             )
--          port map (
--             sAxisClk        => pgpAxisClk,
--             sAxisRst        => pgpAxisRst,
--             sAxisMaster     => fifoVcTxMasters(i),
--             sAxisSlave      => fifoVcTxSlaves(i),
--             sAxisCtrl       => open,
--             fifoPauseThresh => (others => '1'),
--             mAxisClk        => pgpTxClk,
--             mAxisRst        => pgpTxRst,
--             mAxisMaster     => pgpVcTxMasters(i),
--             mAxisSlave      => pgpVcTxSlaves(i));

   -------------------------------------------------------------------------------------------------
   -- PGP
   -------------------------------------------------------------------------------------------------

   locTxIn.opCodeEn    <= pgpTxDataEn and toSl(pgpTxData(9 downto 8) = "00");
   locTxIn.opCode      <= pgpTxData(7 downto 0);
   -------------------------------------------------------------------------------------------------
   locTxIn.flush       <= '0';
   locTxIn.locData     <= (others => '0');
   locTxIn.flowCntlDis <= '0';

   GEN_REAL_PGP : if (SIMULATION_G = false) generate


      -- PGP Core
      GEN_FIXED_LAT_PGP : if (RX_FIXED_LAT_G) generate
         pgpRxClk <= pgpRxRecClk;
         Pgp2bGtx7Fixedlat_1 : entity surf.Pgp2bGtx7Fixedlat
            generic map (
               TPD_G                 => TPD_G,
               SIM_GTRESET_SPEEDUP_G => "TRUE",
               SIM_VERSION_G         => "4.0",
               SIMULATION_G          => SIMULATION_G,
               STABLE_CLOCK_PERIOD_G => 4.0E-9,
               CPLL_REFCLK_SEL_G     => "001",
               CPLL_FBDIV_G          => GTX_CONFIG_C.CPLL_FBDIV_G,
               CPLL_FBDIV_45_G       => GTX_CONFIG_C.CPLL_FBDIV_45_G,
               CPLL_REFCLK_DIV_G     => GTX_CONFIG_C.CPLL_REFCLK_DIV_G,
               RXOUT_DIV_G           => GTX_CONFIG_C.RXOUT_DIV_G,
               TXOUT_DIV_G           => GTX_CONFIG_C.TXOUT_DIV_G,
               RX_CLK25_DIV_G        => GTX_CONFIG_C.RX_CLK25_DIV_G,
               TX_CLK25_DIV_G        => GTX_CONFIG_C.TX_CLK25_DIV_G,
               TX_PLL_G              => TX_PLL_G,
               RX_PLL_G              => RX_PLL_G,
               RXCDR_CFG_G           => x"03000023ff20400020",
               PMA_RSV_G             => X"0018480",
               RXDFEXYDEN_G          => '1',
               RX_DFE_KL_CFG2_G      => x"301148AC",
               VC_INTERLEAVE_G       => 1,
               NUM_VC_EN_G           => NUM_VC_EN_C)
            port map (
               stableClk        => axilClk,
               gtCPllRefClk     => cPllRefClk,
               gtCPllLock       => open,
               gtQPllRefClk     => qPllOutRefClk,
               gtQPllClk        => qPllOutClk,
               gtQPllLock       => qPllLock,
               gtQPllRefClkLost => qPllRefClkLost,
               gtQPllReset      => qPllReset,
               gtRxRefClkBufg   => rxRefClkG,
               gtRxN            => rtmToDpmHsM,
               gtRxP            => rtmToDpmHsP,
               gtTxN            => dpmToRtmHsM,
               gtTxP            => dpmToRtmHsP,
               pgpTxReset       => pgpTxRst,
               pgpTxClk         => pgpTxClk,
               pgpRxReset       => pgpRxRst,
               pgpRxRecClk      => pgpRxRecClk,
               pgpRxRecClkRst   => pgpRxRecClkRst,
               pgpRxClk         => pgpRxClk,  --pgpRxRecClk,
               pgpRxMmcmReset   => open,
               pgpRxMmcmLocked  => '1',
               pgpRxIn          => pgpRxIn,
               pgpRxOut         => pgpRxOut,
               pgpTxIn          => pgpTxIn,
               pgpTxOut         => pgpTxOut,
               pgpTxMasters     => pgpVcTxMasters,
               pgpTxSlaves      => pgpVcTxSlaves,
               pgpRxMasters     => pgpVcRxMasters,
               pgpRxMasterMuxed => open,
               pgpRxCtrl        => pgpVcRxCtrl);
      end generate GEN_FIXED_LAT_PGP;

      GEN_VAR_LAT_RX_PGP : if (RX_FIXED_LAT_G = false) generate
         pgpRxClk <= axilClk;
         Pgp2bGtx7MultiLane_1 : entity surf.Pgp2bGtx7MultiLane
            generic map (
               TPD_G                 => TPD_G,
               SIM_GTRESET_SPEEDUP_G => "TRUE",
               SIM_VERSION_G         => "4.0",
               STABLE_CLOCK_PERIOD_G => 4.0E-9,
               CPLL_REFCLK_SEL_G     => "001",
               CPLL_FBDIV_G          => GTX_CONFIG_C.CPLL_FBDIV_G,
               CPLL_FBDIV_45_G       => GTX_CONFIG_C.CPLL_FBDIV_45_G,
               CPLL_REFCLK_DIV_G     => GTX_CONFIG_C.CPLL_REFCLK_DIV_G,
               RXOUT_DIV_G           => GTX_CONFIG_C.RXOUT_DIV_G,
               TXOUT_DIV_G           => GTX_CONFIG_C.TXOUT_DIV_G,
               RX_CLK25_DIV_G        => GTX_CONFIG_C.RX_CLK25_DIV_G,
               TX_CLK25_DIV_G        => GTX_CONFIG_C.TX_CLK25_DIV_G,
--            RX_OS_CFG_G           => RX_OS_CFG_G,
               RXCDR_CFG_G           => x"03000023ff40200020",
--            PMA_RSV_G             => GTX_CONFIG_C.PMA_RSV_G,
--            RXDFEXYDEN_G          => '1',
               RX_DFE_KL_CFG2_G      => x"301148AC",
               TX_PLL_G              => TX_PLL_G,
               RX_PLL_G              => RX_PLL_G,
               -- Configure TX for fixed latnecy
               TX_BUF_EN_G           => false,
               TX_OUTCLK_SRC_G       => "PLLREFCLK",
               TX_DLY_BYPASS_G       => '0',
               TX_PHASE_ALIGN_G      => "MANUAL",
               TX_BUF_ADDR_MODE_G    => "FULL",
               LANE_CNT_G            => 1,
               RX_ENABLE_G           => true,
               TX_ENABLE_G           => true,
               VC_INTERLEAVE_G       => 1,
               NUM_VC_EN_G           => NUM_VC_EN_C)
            port map (
               stableClk        => axilClk,
               gtCPllRefClk     => cPllRefClk,
               gtCPllLock       => open,
               gtQPllRefClk     => qPllOutRefClk,
               gtQPllClk        => qPllOutClk,
               gtQPllLock       => qPllLock,
               gtQPllRefClkLost => qPllRefClkLost,
               gtQPllReset      => qPllReset,
               gtTxP(0)         => dpmToRtmHsP,
               gtTxN(0)         => dpmToRtmHsM,
               gtRxP(0)         => rtmToDpmHsP,
               gtRxN(0)         => rtmToDpmHsM,
               pgpTxReset       => pgpTxRst,
               pgpTxClk         => pgpTxClk,
               pgpTxMmcmReset   => open,
               pgpTxMmcmLocked  => '1',
--               txDiffCtrl       => "1111",
               pgpRxReset       => pgpRxRst,
               pgpRxRecClk      => open,
               pgpRxClk         => pgpRxClk,  -- Could use recovered clock here?
               pgpRxMmcmReset   => open,
               pgpRxMmcmLocked  => '1',
               pgpRxIn          => pgpRxIn,
               pgpRxOut         => pgpRxOut,
               pgpTxIn          => pgpTxIn,
               pgpTxOut         => pgpTxOut,
               pgpTxMasters     => pgpVcTxMasters,
               pgpTxSlaves      => pgpVcTxSlaves,
               pgpRxMasters     => pgpVcRxMasters,
               pgpRxMasterMuxed => open,
               pgpRxCtrl        => pgpVcRxCtrl);
      end generate GEN_VAR_LAT_RX_PGP;


   end generate GEN_REAL_PGP;

   SIM_PGP : if (SIMULATION_G) generate
      pgpRxClk <= pgpTxClk;
      U_RoguePgp2bSim_1 : entity surf.RoguePgp2bSim
         generic map (
            TPD_G         => TPD_G,
            PORT_NUM_G    => SIM_PGP_PORT_NUM_G,
            NUM_VC_G      => 4,
            EN_SIDEBAND_G => true)
         port map (
            pgpClk       => pgpTxClk,        -- [in]
            pgpClkRst    => pgpTxRst,        -- [in]
            pgpRxIn      => pgpRxIn,         -- [in]
            pgpRxOut     => pgpRxOut,        -- [out]
            pgpTxIn      => locTxIn,         -- [in]
            pgpTxOut     => pgpTxOut,        -- [out]
            pgpTxMasters => pgpVcTxMasters,  -- [in]
            pgpTxSlaves  => pgpVcTxSlaves,   -- [out]
            pgpRxMasters => pgpVcRxMasters,  -- [out]
            pgpRxSlaves  => pgpVcRxSlaves);  -- [in]
   end generate SIM_PGP;

   -- Register Control
   U_Pgp2bAxi : entity surf.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => (RX_FIXED_LAT_G = false),
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => 125.0E+6,
         STATUS_CNT_WIDTH_G => 32,
         ERROR_CNT_WIDTH_G  => 16
         )
      port map (
         pgpTxClk        => pgpTxClk,
         pgpTxClkRst     => pgpTxRst,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         locTxIn         => locTxIn,
         pgpRxClk        => pgpRxClk,         --pgpRxRecClk,
         pgpRxClkRst     => '0',              -- pgpTxRst
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,   --locAxilReadMasters(PGP2B_AXIL_INDEX_C),
         axilReadSlave   => axilReadSlave,    --locAxilReadSlaves(PGP2B_AXIL_INDEX_C),
         axilWriteMaster => axilWriteMaster,  --locAxilWriteMasters(PGP2B_AXIL_INDEX_C),
         axilWriteSlave  => axilWriteSlave    --locAxilWriteSlaves(PGP2B_AXIL_INDEX_C)
         );


   -------------------------------------------------------------------------------------------------
   -- RX Buffers and MUX
   -------------------------------------------------------------------------------------------------
   buff : for i in NUM_VC_EN_C-1 downto 0 generate

      blowoff : process (pgpVcRxMasters(i), pgpRxOut.linkReady) is
         variable tmp : AxiStreamMasterType;
      begin
         tmp := pgpVcRxMasters(i);
         if (pgpRxOut.linkReady = '0') then
            tmp.tValid := '0';
         end if;
         blowoffVcRxMasters(i) <= tmp;
      end process blowoff;


      U_RxFifo : entity surf.SsiFifo
         generic map (
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 1,
            PIPE_STAGES_G       => 1,
            SLAVE_READY_EN_G    => SIMULATION_G,
--            EN_FRAME_FILTER_G   => true,
--            OR_DROP_FLAGS_G     => true,
            VALID_THOLD_G       => 1,
            VALID_BURST_MODE_G  => true,
            SYNTH_MODE_G        => "xpm",
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 10,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 512,
            SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
            MASTER_AXI_CONFIG_G => AXIS_CONFIG_C
            )
         port map (
            sAxisClk    => pgpRxClk,    --pgpRxRecClk,     --pgpTxClk,
            sAxisRst    => pgpRxRst,    --pgpRxRecClkRst,  --pgpTxRst
            sAxisMaster => blowoffVcRxMasters(i),
            sAxisSlave  => pgpVcRxSlaves(i),
            sAxisCtrl   => pgpVcRxCtrl(i),
            mAxisClk    => pgpAxisClk,
            mAxisRst    => pgpAxisRst,
            mAxisMaster => fifoVcRxMasters(i),
            mAxisSlave  => fifoVcRxSlaves(i));

   end generate buff;

   -- MUX RX VCs
   U_CntrlMux : entity surf.AxiStreamMux
      generic map (
         TPD_G                => TPD_G,
         NUM_SLAVES_G         => NUM_VC_EN_C,
         PIPE_STAGES_G        => 1,
         TDEST_LOW_G          => 0,
         ILEAVE_EN_G          => true,
         ILEAVE_ON_NOTVALID_G => false,
         ILEAVE_REARB_G       => 128)
      port map (
         axisClk      => pgpAxisClk,
         axisRst      => pgpAxisRst,
         sAxisMasters => fifoVcRxMasters,
         sAxisSlaves  => fifoVcRxSlaves,
         mAxisMaster  => muxRxMaster,   --pgpRxMasters,
         mAxisSlave   => muxRxSlave);   -- pgpRxSlaves);


   -- Buffer the mux output and resynchronize
   RX_ASYNC_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         VALID_THOLD_G       => 1,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_C)
      port map (
         sAxisClk    => pgpAxisClk,
         sAxisRst    => pgpAxisRst,
         sAxisMaster => muxRxMaster,
         sAxisSlave  => muxRxSlave,
         mAxisClk    => pgpAxisClk,
         mAxisRst    => pgpAxisRst,
         mAxisMaster => pgpRxMasters,
         mAxisSlave  => pgpRxSlaves);


end architecture STRUCTURE;

