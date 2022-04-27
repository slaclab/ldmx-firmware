-------------------------------------------------------------------------------
-- Title      : Feb Pgp
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Pgp block for feb
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;
use surf.Pgp2bPkg.all;
use surf.Gtp7CfgPkg.all;


library ldmx;
--use ldmx.HpsPkg.all;

entity HpsFebPgp is

   generic (
      TPD_G             : time                        := 1 ns;
      ROGUE_SIM_G       : boolean                     := false;
      ROGUE_CTRL_PORT_G : natural range 1024 to 49151 := 9000;
      ROGUE_DATA_PORT_G : natural range 1024 to 49151 := 9100;
      AXI_BASE_ADDR_G   : slv(31 downto 0)            := (others => '0'));
   port (
      -- Reference clocks for PGP MGTs
      gtRefClk186P : in sl;
      gtRefClk186N : in sl;
      gtRefClk250P : in sl;
      gtRefClk250N : in sl;

--      gtRefClk186G : out sl;
      gtRefClk125 : out sl;
      gtRefRst125 : out sl;

      -- MGT IO
      ctrlGtTxP : out sl;
      ctrlGtTxN : out sl;
      ctrlGtRxP : in  sl;
      ctrlGtRxN : in  sl;

      dataGtTxP : out sl;
      dataGtTxN : out sl;
      dataGtRxP : in  sl;
      dataGtRxN : in  sl;

      -- Status output for LEDs
      ctrlTxLink : out sl;
      ctrlRxLink : out sl;
      dataTxLink : out sl;

      -- Control link Opcode and AXI-Stream interface
      distClk       : out sl;           -- Recovered fixed-latency clock
      distRst       : out sl;
      distRxFcWord  : out slv(15 downto 0);
      distRxFcValid : out sl;

      -- All AXI-Lite and AXI-Stream interfaces are synchronous with this clock
      axilClk    : in sl;               -- Also Drives PGP stableClk input
      axilClkRst : in sl;

      -- AXI-Lite Master (Register interface)
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;

      -- AXI-Lite slave interface for PGP statuses
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Streaming data
      dataClk        : in  sl;
      dataRst        : in  sl;
      dataAxisMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dataAxisSlave  : out AxiStreamSlaveType;
      dataAxisCtrl   : out AxiStreamCtrlType);

end entity FebPgp;

architecture rtl of FebPgp is

   -- Clocks
   signal refClk125 : sl;
   signal refRst125 : sl;   

   -- Ctrl PGP
   signal pgpCtrlTxClk     : sl;
   signal pgpCtrlTxRst     : sl;
   signal pgpCtrlRxClk     : sl;
   signal pgpCtrlRxRst     : sl;
   signal pgpCtrlRxIn      : Pgp2fcRxCtrlInType               := PGP2FC_RX_CTRL_IN_INIT_C;
   signal pgpCtrlRxOut     : Pgp2fcRxStatusOutType;
   signal pgpCtrlTxIn      : Pgp2fcTxCtrlInType               := PGP2FC_TX_CTRL_IN_INIT_C;
   signal pgpCtrlTxOut     : Pgp2fcTxStatusOutType;
   signal pgpCtrlRxFcWord  : slv(15 downto 0);
   signal pgpCtrlRxFcValid : sl;
   signal pgpCtrlTxFcWord  : slv(15 downto 0)                 := (others => '0');
   signal pgpCtrlTxFcValid : sl                               := '0';
   signal pgpCtrlRxMasters : AxiStreamMasterArray(3 downto 0);
   signal pgpCtrlRxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpCtrlRxCtrl    : AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);
   signal pgpCtrlTxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpCtrlTxSlaves  : AxiStreamSlaveArray(3 downto 0);

   -- Data PGP
   signal pgpDataClk       : sl;
   signal pgpDataRst       : sl;
   signal pgpDataTxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpDataTxSlaves  : AxiStreamSlaveArray(3 downto 0);





   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(AXIL_MASTERS_C-1 downto 0) := (
      AXIL_CTRL_GTP_C => (
         baseAddr     => AXIL_BASE_ADDR_G,
         addrBits     => 8,
         connectivity => X"0001"),
      AXIL_CTRL_PGP_C => (
         baseAddr     => AXIL_BASE_ADDR_G + X"10000",
         addrBits     => 16,
         connectivity => X"0001"),
      AXIL_DATA_PGP_C => (
         baseAddr     => AXIL_BASE_ADDR_G + X"20000",
         addrBits     => 12,
         connectivity => X"0001"));


   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_MASTERS_C-1 downto 0);


begin

   gtRefClk125 <= refClk125;
   gtRefRst125 <= refRst125;

   -- Ouput recovered clock and FC bus
   distClk       <= pgpCtrlRxClk;
   distRst       <= pgpCtrlRxRst;
   distRxFcValid <= pgpCtrlRxFcValid;
   distRxFcWord  <= pgpCtrlRxFcWord;

   PwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => SIMULATION_G,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1')
      port map (
         clk    => refClk125,
         rstOut => refRst125);

   U_Pgp2fcGtp7Wrapper_1 : entity surf.Pgp2fcGtp7Wrapper
      generic map (
         TPD_G                 => TPD_G,
         COMMON_CLK_G          => COMMON_CLK_G,
         SIM_GTRESET_SPEEDUP_G => SIMULATION_G,
         SIM_VERSION_G         => "2.0",
         SIMULATION_G          => SIMULATION_G,
         VC_INTERLEAVE_G       => 1,
         PAYLOAD_CNT_TOP_G     => 7,
         NUM_VC_EN_G           => 2,
         AXIL_BASE_ADDR_G      => AXIL_XBAR_CFG(AXI_CTRL_GTP_C).baseAddr,
         EXT_RST_POLARITY_G    => '1',
--          TX_POLARITY_G           => TX_POLARITY_G,
--          RX_POLARITY_G           => RX_POLARITY_G,
--          TX_ENABLE_G             => TX_ENABLE_G,
--          RX_ENABLE_G             => RX_ENABLE_G,
         TX_CM_EN_G            => false,
--          TX_CM_TYPE_G            => TX_CM_TYPE_G,
--          TX_CM_CLKIN_PERIOD_G    => TX_CM_CLKIN_PERIOD_G,
--          TX_CM_DIVCLK_DIVIDE_G   => TX_CM_DIVCLK_DIVIDE_G,
--          TX_CM_CLKFBOUT_MULT_F_G => TX_CM_CLKFBOUT_MULT_F_G,
--          TX_CM_CLKOUT_DIVIDE_F_G => TX_CM_CLKOUT_DIVIDE_F_G,
         RX_CM_EN_G            => true,
         RX_CM_TYPE_G          => "PLL",
         RX_CM_BANDWIDTH_G     => "HIGH",
         RX_CM_CLKIN_PERIOD_G  => 5.385,
         RX_CM_DIVCLK_DIVIDE_G => 1,
         RX_CM_CLKFBOUT_MULT_G => 10,
         RX_CM_CLKOUT_DIVIDE_G => 10,
         PMA_RSV_G             => PMA_RSV_G,
         RX_OS_CFG_G           => RX_OS_CFG_G,
         RXCDR_CFG_G           => RXCDR_CFG_G,
         RXDFEXYDEN_G          => RXDFEXYDEN_G,
         STABLE_CLK_SRC_G      => "stableClkIn",
         TX_REFCLK_SRC_G       => "gtClk0",
         TX_USER_CLK_SRC_G     => "txOutClk",                       -- might try gtClk0Div2
         RX_REFCLK_SRC_G       => "gtClk0",
         TX_PLL_CFG_G          => getGtp7QPllCfg(185.715e6, 3.7143e9),
         RX_PLL_CFG_G          => getGtp7QPllCfg(185.715e6, 3.7143e9),
         DYNAMIC_QPLL_G        => false,
         TX_PLL_G              => "PLL0",
         RX_PLL_G              => "PL0")
      port map (
         stableClkIn      => refClk125,                             -- [in]
         extRst           => refRst125,                             -- [in]
         txPllLock        => open,                                  -- [out]
         rxPllLock        => open,                                  -- [out]
         pgpTxClkOut      => pgpCtrlTxClk,                          -- [out]
         pgpTxRstOut      => pgpCtrlTxRst,                          -- [out]
         pgpRxClkOut      => pgpCtrlRxClk,                          -- [out]
         pgpRxRstOut      => pgpCtrlRxRst,                          -- [out]
--         stableClkOut     => gtRefClk186G,                          -- [out]
         pgpRxIn          => pgpCtrlRxIn,                           -- [in]
         pgpRxOut         => pgpCtrlRxOut,                          -- [out]
         pgpTxIn          => pgpCtrlTxIn,                           -- [in]
         pgpTxOut         => pgpCtrlTxOut,                          -- [out]
         pgpTxFcValid     => pgpCtrlTxFcValid                       -- [in]
         pgpTxFcWord      => pgpCtrlTxFcWord,                       -- [in]
         pgpRxFcValid     => pgpCtrlRxFcValid,                      -- [out]
         pgpRxFcWord      => pgpCtrlRxFcWord,                       -- [out]
         pgpTxMasters     => pgpCtrlTxMasters,                      -- [in]
         pgpTxSlaves      => pgpCtrlTxSlaves,                       -- [out]
         pgpRxMasters     => pgpCtrlRxMasters,                      -- [out]
         pgpRxMasterMuxed => open,                                  -- [out]
         pgpRxCtrl        => pgpCtrlRxCtrl,                         -- [in]
--          gtgClk           => gtgClk,            -- [in]
         gtClk0P          => gtRefClk186P,                          -- [in]
         gtClk0N          => gtRefClk186N,                          -- [in]
         gtTxP            => ctrlGtTxP,                             -- [out]
         gtTxN            => ctrlGtTxN,                             -- [out]
         gtRxP            => ctrlGtRxP,                             -- [in]
         gtRxN            => ctrlGtRxN,                             -- [in]
--          txPreCursor      => txPreCursor,       -- [in]
--          txPostCursor     => txPostCursor,      -- [in]
--          txDiffCtrl       => txDiffCtrl,        -- [in]
--         drpOverride      => drpOverride,       -- [in]
--          qPllRxSelect     => qPllRxSelect,      -- [in]
--          qPllTxSelect     => qPllTxSelect,      -- [in]
         axilClk          => axilClk,                               -- [in]
         axilRst          => axilRst,                               -- [in]
         axilReadMaster   => locAxilReadMasters(AXIL_CTRL_GTP_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(AXIL_CTRL_GTP_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(AXIL_CTRL_GTP_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(AXIL_CTRL_GTP_C));  -- [out]

   U_Pgp2bAxi_1 : entity surf.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => false,
         AXI_CLK_FREQ_G     => 125.0e6,                            -- check this
         STATUS_CNT_WIDTH_G => 32,
         ERROR_CNT_WIDTH_G  => 8)
      port map (
         pgpTxClk        => pgpCtrlTxClk,                          -- [in]
         pgpTxClkRst     => pgpCtrlTxRst,                          -- [in]
         pgpTxIn         => pgpCtrlTxIn,                           -- [out]
         pgpTxOut        => pgpCtrlTxOut,                          -- [in]
--         locTxIn         => locTxIn,                               -- [in]
         pgpRxClk        => pgpCtrlRxClk,                          -- [in]
         pgpRxClkRst     => pgpCtrlRxRst,                          -- [in]
         pgpRxIn         => pgpCtrlRxIn,                           -- [out]
         pgpRxOut        => pgpCtrlRxOut,                          -- [in]
--         locRxIn         => locRxIn,                               -- [in]
         axilClk         => axilClk,                               -- [in]
         axilRst         => axilRst,                               -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_CTRL_PGP_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_CTRL_PGP_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_CTRL_PGP_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_CTRL_PGP_C));  -- [out]


   -------------------------------------------------------------------------------------------------
   -- Data PGP
   -------------------------------------------------------------------------------------------------
   U_Pgp4Gtp7Wrapper_1 : entity surf.Pgp4Gtp7Wrapper
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_SIDEBAND_G => ROGUE_SIM_SIDEBAND_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_DATA_PORT_NUM_G,
         NUM_LANES_G          => 1,
         NUM_VC_G             => 1,
         SPEED_GRADE_G        => 1,
         RATE_G               => "3.125Gbps",
         REFCLK_FREQ_G        => 250.0e+6,
         REFCLK_G             => false,
         PGP_RX_ENABLE_G      => false,
         PGP_TX_ENABLE_G      => true,
--         TX_CELL_WORDS_MAX_G         => TX_CELL_WORDS_MAX_G,
--          TX_MUX_MODE_G               => TX_MUX_MODE_G,
--          TX_MUX_TDEST_ROUTES_G       => TX_MUX_TDEST_ROUTES_G,
--          TX_MUX_TDEST_LOW_G          => TX_MUX_TDEST_LOW_G,
--          TX_MUX_ILEAVE_EN_G          => TX_MUX_ILEAVE_EN_G,
--          TX_MUX_ILEAVE_ON_NOTVALID_G => TX_MUX_ILEAVE_ON_NOTVALID_G,
         EN_PGP_MON_G         => true,
         EN_GT_DRP_G          => true,
         EN_QPLL_DRP_G        => true,
         WRITE_EN_G           => false,
--          TX_POLARITY_G               => TX_POLARITY_G,
--          RX_POLARITY_G               => RX_POLARITY_G,
         STATUS_CNT_WIDTH_G   => 16,
         ERROR_CNT_WIDTH_G    => 8,
         AXIL_BASE_ADDR_G     => AXIL_XBAR_CFG(AXIL_DATA_PGP_C).baseAddr,
         AXIL_CLK_FREQ_G      => 125.0e6)
      port map (
         stableClk         => refClk125,                             -- [in]
         stableRst         => refRst125,                             -- [in]
         pgpGtTxP          => dataGtTxP,                             -- [out]
         pgpGtTxN          => dataGtTxN,                             -- [out]
         pgpGtRxP          => dataGtRxP,                             -- [in]
         pgpGtRxN          => dataGtRxN,                             -- [in]
         pgpRefClkP        => gtRefClk250P,                          -- [in]
         pgpRefClkN        => gtRefClk250N,                          -- [in]
--         pgpRefClkIn       => pgpRefClkIn,        -- [in]
--         pgpRefClkOut      => pgpRefClkOut,       -- [out]
         pgpRefClkDiv2Bufg => refClk125,                             -- [out]
         pgpClk            => pgpDataClk,                            -- [out]
         pgpClkRst         => pgpDataRst,                            -- [out]
--          pgpRxIn           => pgpRxIn,            -- [in]
--          pgpRxOut          => pgpRxOut,           -- [out]
--          pgpTxIn           => pgpTxIn,            -- [in]
--          pgpTxOut          => pgpTxOut,           -- [out]
         pgpTxMasters      => pgpDataTxMasters,                      -- [in]
         pgpTxSlaves       => pgpDataTxSlaves,                       -- [out]
         pgpRxMasters      => open,                                  -- [out]
         pgpRxCtrl         => (others => AXI_STREAM_CTRL_UNUSED_C),  -- [in]
         pgpRxSlaves       => (others => AXI_STREAM_SLAVE_FORCE_C),  -- [in]
         debugClk          => open,                                  -- [out]
         debugRst          => open,                                  -- [out]
         axilClk           => axilClk,                               -- [in]
         axilRst           => axilRst,                               -- [in]
         axilReadMaster    => locAxilReadMasters(AXIL_DATA_PGP_C),   -- [in]
         axilReadSlave     => locAxilReadSlaves(AXIL_DATA_PGP_C),    -- [out]
         axilWriteMaster   => locAxilWriteMasters(AXIL_DATA_PGP_C),  -- [in]
         axilWriteSlave    => locAxilWriteSlaves(AXIL_DATA_PGP_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- SRP
   -------------------------------------------------------------------------------------------------
   U_SrpV3AxiLite_1 : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 0,
         PIPE_STAGES_G       => 0,
--          FIFO_PAUSE_THRESH_G   => FIFO_PAUSE_THRESH_G,
--          FIFO_SYNTH_MODE_G     => FIFO_SYNTH_MODE_G,
--          TX_VALID_THOLD_G      => TX_VALID_THOLD_G,
--          TX_VALID_BURST_MODE_G => TX_VALID_BURST_MODE_G,
         SLAVE_READY_EN_G    => ROGUE_SIM_EN_G,
         GEN_SYNC_FIFO_G     => false,
         AXIL_CLK_FREQ_G     => 125.0e6,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk         => pgpCtrlRxClk,         -- [in]
         sAxisRst         => pgpCtrlRxRst,         -- [in]
         sAxisMaster      => pgpCtrlRxMasters(0),  -- [in]
         sAxisSlave       => pgpCtrlRxSlaves(0),   -- [out]
         sAxisCtrl        => pgpCtrlRxCtrl(0),     -- [out]
         mAxisClk         => pgpCtrlTxClk,         -- [in]
         mAxisRst         => pgpCtrlTxRst,         -- [in]
         mAxisMaster      => pgpCtrlTxMasters(0),  -- [out]
         mAxisSlave       => pgpCtrlTxSlaves(0),   -- [in]
         axilClk          => axilClk,              -- [in]
         axilRst          => axilRst,              -- [in]
         mAxilWriteMaster => mAxilWriteMaster,     -- [out]
         mAxilWriteSlave  => mAxilWriteSlave,      -- [in]
         mAxilReadMaster  => mAxilReadMaster,      -- [out]
         mAxilReadSlave   => mAxilReadSlave);      -- [in]

   -------------------------------------------------------------------------------------------------
   -- Data Fifo
   -------------------------------------------------------------------------------------------------
   U_AxiStreamFifoV2_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G                  => TPD_G,
         INT_PIPE_STAGES_G      => 1,
         PIPE_STAGES_G          => 1,
         SLAVE_READY_EN_G       => ROGUE_SIM_EN_G,  -- Check his
         VALID_THOLD_G          => 1,
         VALID_BURST_MODE_G     => false,
         MEMORY_TYPE_G          => "block",
         GEN_SYNC_FIFO_G        => true,
         CASCADE_SIZE_G         => 1,
         CASCADE_PAUSE_SEL_G    => 0,
         FIFO_ADDR_WIDTH_G      => 10,              --13,
         FIFO_FIXED_THRESH_G    => true,
         FIFO_PAUSE_THRESH_G    => 2**10-8,         --2**13-6200,
         INT_WIDTH_SELECT_G     => "WIDE",
--         INT_DATA_WIDTH_G       => INT_DATA_WIDTH_G,
         LAST_FIFO_ADDR_WIDTH_G => 0,
         SLAVE_AXI_CONFIG_G     => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G    => PGP4_AXIS_CONFIG_C)
      port map (
         sAxisClk    => dataClk,                    -- [in]
         sAxisRst    => dataRst,                    -- [in]
         sAxisMaster => dataAxisMaster,             -- [in]
         sAxisSlave  => dataAxisSlave,              -- [out]
         sAxisCtrl   => dataAxisCtrl,               -- [out]
         mAxisClk    => pgpDataTxClk,               -- [in]
         mAxisRst    => pgpDataTxRst,               -- [in]
         mAxisMaster => pgpDataTxMasters(0),        -- [out]
         mAxisSlave  => pgpDataTxSlaves(0));        -- [in]

end architecture rtl;
