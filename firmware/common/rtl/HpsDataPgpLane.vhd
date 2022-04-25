-------------------------------------------------------------------------------
-- Title         : PGP Lane For Data DPM
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
use surf.Gtx7CfgPkg.all;
use surf.Pgp2bPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.SsiPkg.all;

library hps_daq;
use hps_daq.HpsPkg.all;

entity HpsDataPgpLane is
   generic (
      TPD_G                : time                        := 1 ns;
      SIMULATION_G         : boolean                     := false;
      SIM_PGP_PORT_NUM_G   : natural range 1024 to 49151 := 4000;
      AXIL_BASE_ADDRESS_G  : slv(31 downto 0)            := (others => '0');
      DATA_PGP_LINE_RATE_G : real);
   port (
      -- Pgp rx data interface
      pgpClk           : in  sl;
      pgpClkRst        : in  sl;
      dataClk          : in  sl;
      dataClkRst       : in  sl;
      pgpRxAxisMasters : out AxiStreamMasterArray(1 downto 0);
      pgpRxAxisSlaves  : in  AxiStreamSlaveArray(1 downto 0);
      pgpRxStatus      : out slv(7 downto 0);

      -- AXI Bus
      axilClk         : in  sl;
      axilClkRst      : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- PHY
      pgpRefClk   : in  sl;
      dpmToRtmHsP : out sl;
      dpmToRtmHsM : out sl;
      rtmToDpmHsP : in  sl;
      rtmToDpmHsM : in  sl
      );
end HpsDataPgpLane;

architecture STRUCTURE of HpsDataPgpLane is

   constant AXIL_NUM_MASTERS_C   : integer := 3;
   constant PGP2B_AXIL_INDEX_C   : integer := 0;
   constant PRBS_RX_AXIL_INDEX_C : integer := 1;

   -- Give each one 12 bits (more than what they really need but this is easier)
   constant AXIL_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray :=
      genAxiLiteConfig(AXIL_NUM_MASTERS_C, AXIL_BASE_ADDRESS_G, 16, 12);

   constant CPLL_REFCLK_FREQ_C : real            := 250.0E6;
   constant CPLL_CONFIG_C      : Gtx7CPllCfgType := getGtx7CPllCfg(CPLL_REFCLK_FREQ_C, DATA_PGP_LINE_RATE_G);
   constant QPLL_CONFIG_C      : Gtx7QPllCfgType := getGtx7QPllCfg(250.0E6, DATA_PGP_LINE_RATE_G);
   constant GTX_CONFIG_C       : Gtx7CfgType     := getGtx7Cfg("CPLL", "CPLL", CPLL_CONFIG_C, QPLL_CONFIG_C);

   signal pgpRxIn      : Pgp2bRxInType;
   signal pgpRxOut     : Pgp2bRxOutType                   := PGP2B_RX_OUT_INIT_C;
   signal pgpTxIn      : Pgp2bTxInType;
   signal pgpTxOut     : Pgp2bTxOutType                   := PGP2B_TX_OUT_INIT_C;
   signal intTxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal intTxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
   signal intRxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal intRxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);
   signal intRxCtrl    : AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_INIT_C);

   signal blowoffRxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_NUM_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_NUM_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_NUM_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

begin

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite crossbar
   -------------------------------------------------------------------------------------------------
   U_AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_NUM_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilClkRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   -- PGP Core
   REAL_PGP : if (SIMULATION_G = false) generate


      U_Pgp : entity surf.Pgp2bGtx7MultiLane
         generic map (
            TPD_G                 => TPD_G,
            -----------------------------------------
            -- GT Settings
            -----------------------------------------
            -- Sim Generics
            SIM_GTRESET_SPEEDUP_G => "FALSE",
            SIM_VERSION_G         => "4.0",
            CPLL_REFCLK_SEL_G     => "001",

            -- 5Gbps
            STABLE_CLOCK_PERIOD_G => 4.0E-9,
            CPLL_FBDIV_G          => GTX_CONFIG_C.CPLL_FBDIV_G,       --2,
            CPLL_FBDIV_45_G       => GTX_CONFIG_C.CPLL_FBDIV_45_G,    --5,
            CPLL_REFCLK_DIV_G     => GTX_CONFIG_C.CPLL_REFCLK_DIV_G,  --1,
            RXOUT_DIV_G           => GTX_CONFIG_C.RXOUT_DIV_G,        --1,
            TXOUT_DIV_G           => GTX_CONFIG_C.TXOUT_DIV_G,        --1,
            RX_CLK25_DIV_G        => GTX_CONFIG_C.RX_CLK25_DIV_G,     --10,
            TX_CLK25_DIV_G        => GTX_CONFIG_C.TX_CLK25_DIV_G,     --10,
            RXCDR_CFG_G           => x"03000023ff20400020",           -- Set by wizard
--         PMA_RSV_G             => X"0018480",
--         RXDFEXYDEN_G          => '0',                             -- Set by wizard
            RX_DFE_KL_CFG2_G      => x"301148AC",                     -- Set by wizard
            -- Configure PLL sourc
            TX_PLL_G              => "CPLL",
            RX_PLL_G              => "CPLL",
            -- Configure Number of
            LANE_CNT_G            => 1,
            ----------------------------------------
            -- PGP Settings
            ----------------------------------------
            RX_ENABLE_G           => true,
            TX_ENABLE_G           => false,
            PAYLOAD_CNT_TOP_G     => 7,  -- Top bit for payload counter
            VC_INTERLEAVE_G       => 0,
            NUM_VC_EN_G           => 2
            )
         port map (
            -- GT Clocking
            stableClk        => pgpClk,  -- GT needs a stable clock to "boot up"
            gtCPllRefClk     => pgpRefClk,                            -- Drives CPLL if used
            gtQPllRefClk     => '0',    -- Signals from QPLL if used
            gtQPllClk        => '0',
            gtQPllLock       => '0',
            gtQPllRefClkLost => '0',
            gtQPllReset      => open,
            -- Gt Serial IO
            gtTxP(0)         => dpmToRtmHsP,                          -- GT Serial Transmit Positive
            gtTxN(0)         => dpmToRtmHsM,                          -- GT Serial Transmit Negative
            gtRxP(0)         => rtmToDpmHsP,                          -- GT Serial Receive Positive
            gtRxN(0)         => rtmToDpmHsM,                          -- GT Serial Receive Negative
            -- Tx Clocking
            pgpTxReset       => pgpClkRst,
            pgpTxClk         => pgpClk,
            pgpTxMmcmReset   => open,
            pgpTxMmcmLocked  => '1',
            -- Rx clocking
            pgpRxReset       => pgpClkRst,
            pgpRxRecClk      => open,   -- recovered clock
            pgpRxClk         => pgpClk,
            pgpRxMmcmReset   => open,
            pgpRxMmcmLocked  => '1',
            -- Non VC Rx Signals
            pgpRxIn          => pgpRxIn,
            pgpRxOut         => pgpRxOut,
            -- Non VC Tx Signals
            pgpTxIn          => pgpTxIn,
            pgpTxOut         => pgpTxOut,
            -- Frame Transmit Interface - 1 Lane, Array of 4 VCs
            pgpTxMasters     => intTxMasters,
            pgpTxSlaves      => intTxSlaves,
            -- Frame Receive Interface - 1 Lane, Array of 4 VCs
            pgpRxMasters     => intRxMasters,
            pgpRxMasterMuxed => open,
            pgpRxCtrl        => intRxCtrl
            );

   end generate REAL_PGP;

   SIM_PGP : if (SIMULATION_G) generate
      U_RoguePgp2bSim_1 : entity surf.RoguePgp2bSim
         generic map (
            TPD_G         => TPD_G,
            PORT_NUM_G    => SIM_PGP_PORT_NUM_G,
            NUM_VC_G      => 4,
            EN_SIDEBAND_G => true)
         port map (
            pgpClk       => pgpClk,        -- [in]
            pgpClkRst    => pgpClkRst,     -- [in]
            pgpRxIn      => pgpRxIn,       -- [in]
            pgpRxOut     => pgpRxOut,      -- [out]
            pgpTxIn      => pgpTxIn,       -- [in]
            pgpTxOut     => pgpTxOut,      -- [out]
            pgpTxMasters => intTxMasters,  -- [in]
            pgpTxSlaves  => intTxSlaves,   -- [out]
            pgpRxMasters => intRxMasters,  -- [out]
            pgpRxSlaves  => intRxSlaves);  -- [in]
   end generate SIM_PGP;

   -- Register Control
   U_Pgp2bAxi : entity surf.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => true,
         AXI_CLK_FREQ_G     => 125.0E+6,
         STATUS_CNT_WIDTH_G => 32,
         ERROR_CNT_WIDTH_G  => 16
         )
      port map (
         pgpTxClk        => pgpClk,
         pgpTxClkRst     => pgpClkRst,
         pgpTxIn         => pgpTxIn,
         pgpTxOut        => pgpTxOut,
         pgpRxClk        => pgpClk,
         pgpRxClkRst     => pgpClkRst,
         pgpRxIn         => pgpRxIn,
         pgpRxOut        => pgpRxOut,
         axilClk         => axilClk,
         axilRst         => axilClkRst,
         axilReadMaster  => locAxilReadMasters(PGP2B_AXIL_INDEX_C),
         axilReadSlave   => locAxilReadSlaves(PGP2B_AXIL_INDEX_C),
         axilWriteMaster => locAxilWriteMasters(PGP2B_AXIL_INDEX_C),
         axilWriteSlave  => locAxilWriteSlaves(PGP2B_AXIL_INDEX_C)
         );

   -- VC Buffers
   GEN_PGP_BUFFERS : for i in 1 downto 0 generate

      blowoff : process (intRxMasters(i), pgpRxOut.linkReady) is
         variable tmp : AxiStreamMasterType;
      begin
         tmp := intRxMasters(i);
         if (pgpRxOut.linkReady = '0') then
            tmp.tValid := '0';
         end if;
         blowoffRxMasters(i) <= tmp;
      end process blowoff;

      U_RxFifo : entity surf.SsiFifo
         generic map (
            TPD_G               => TPD_G,
            PIPE_STAGES_G       => 1,
            INT_PIPE_STAGES_G   => 1,
--            EN_FRAME_FILTER_G   => true,
            SLAVE_READY_EN_G    => SIMULATION_G,
            VALID_THOLD_G       => 128,
            VALID_BURST_MODE_G  => true,
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => false,
            CASCADE_SIZE_G      => 1,
            FIFO_ADDR_WIDTH_G   => 10,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 2**10-1,
            SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
            MASTER_AXI_CONFIG_G => APV_DATA_SSI_CONFIG_C)
         port map (
            sAxisClk    => pgpClk,
            sAxisRst    => pgpClkRst,
            sAxisMaster => blowoffRxMasters(i),
            sAxisSlave  => intRxSlaves(i),
            sAxisCtrl   => intRxCtrl(i),
            mAxisClk    => dataClk,
            mAxisRst    => dataClkRst,
            mAxisMaster => pgpRxAxisMasters(i),
            mAxisSlave  => pgpRxAxisSlaves(i));
   end generate;

--   pgpRxAxisMasters(3) <= AXI_STREAM_MASTER_INIT_C;

   pgpRxStatus <= pgpRxOut.remLinkData;

end architecture STRUCTURE;

