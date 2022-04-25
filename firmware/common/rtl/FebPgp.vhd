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


library hps_daq;
use hps_daq.HpsPkg.all;

entity FebPgp is

   generic (
      TPD_G                 : time                        := 1 ns;
      ROGUE_TCP_SIM_G       : boolean                     := false;
      ROGUE_TCP_CTRL_PORT_G : natural range 1024 to 49151 := 9000;
      ROGUE_TCP_DATA_PORT_G : natural range 1024 to 49151 := 9100;
      AXI_BASE_ADDR_G       : slv(31 downto 0)            := (others => '0');
      TX_CLK_SRC_G          : string                      := "DAQREF";  -- "RXREC", "GTREF125", "DAQREF"
      RX_REC_CLK_MMCM_G     : boolean                     := true;
      DATA_PGP_LINE_RATE_G  : real);
   port (
      stableClk    : in sl;
      -- Reference clocks for PGP MGTs
      gtRefClk125  : in sl;
      gtRefClk125G : in sl;
      gtRefClk250  : in sl;
      daqRefClk    : in sl;
      daqRefClkG   : in sl;

      -- MGT IO
      ctrlGtTxP : out sl;
      ctrlGtTxN : out sl;
      ctrlGtRxP : in  sl;
      ctrlGtRxN : in  sl;

      dataGtTxP : out slv(3 downto 0);
      dataGtTxN : out slv(3 downto 0);
      dataGtRxP : in  slv(3 downto 0);
      dataGtRxN : in  slv(3 downto 0);

      dataTxOutClk : out sl;

      -- Status output for LEDs
      ctrlTxLink : out sl;
      ctrlRxLink : out sl;
      dataTxLink : out slv(3 downto 0);

      -- Control link Opcode and AXI-Stream interface
      ctrlRxRecClk    : out sl;         -- Recovered fixed-latency clock
      ctrlRxRecClkRst : out sl;
      ctrlRxOpcode    : out slv(7 downto 0);
      ctrlRxOpcodeEn  : out sl;

      -- All AXI-Lite and AXI-Stream interfaces are synchronous with this clock
      axilClk    : in sl;               -- Also Drives PGP stableClk input
      axilClkRst : in sl;

      -- AXI-Lite Master (Register interface)
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;

      -- SEM Streaming interface
      semRxAxisMaster : out AxiStreamMasterType;
      semRxAxisSlave  : in  AxiStreamSlaveType;
      semTxAxisMaster : in  AxiStreamMasterType;
      semTxAxisSlave  : out AxiStreamSlaveType;

      -- AXI-Lite slave interface for PGP statuses
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Data Tx interface
      clk250     : in sl;               -- APV/ADC stream clock
      clk250Rst  : in sl;
      dataClk    : in sl;               -- Pgp clk
      dataClkRst : in sl;

      hybridDataAxisMasters : in  AxiStreamQuadMasterArray(3 downto 0);
      hybridDataAxisSlaves  : out AxiStreamQuadSlaveArray(3 downto 0);
      hybridDataAxisCtrl    : out AxiStreamQuadCtrlArray(3 downto 0);

      syncStatuses : in slv5Array(3 downto 0));

end entity FebPgp;

architecture rtl of FebPgp is

   -- Get Ctrl PGP configuration. 125MHz Ref clk. 2.5 Gbps line rate.
   constant CTRL_GTP_CONFIG_C : Gtp7QPllCfgType := getGtp7QPllCfg(125.0E6, 2.5E9);

   constant TX_REFCLK_SEL_C : bit_vector(2 downto 0) := ite(TX_CLK_SRC_G = "RXREC", "111",
                                                            ite(TX_CLK_SRC_G = "GTREF125", "001",
                                                                ite(TX_CLK_SRC_G = "DAQREF", "010",
                                                                    "001")));

   -- Ctrl QPLL Signals
   signal ctrlQPllRefClk     : slv(1 downto 0);
   signal ctrlQPllOutClk     : slv(1 downto 0);
   signal ctrlQPllOutRefClk  : slv(1 downto 0);
   signal ctrlQPllLock       : slv(1 downto 0);
   signal ctrlQPllLockDetClk : slv(1 downto 0);
   signal ctrlQPllRefClkLost : slv(1 downto 0);
   signal ctrlQPllReset      : slv(1 downto 0);

   -- Ctrl PGP Signals
   signal ctrlPgpReset        : sl;
   signal ctrlPgpTxClk        : sl;
   signal ctrlPgpTxRst        : sl;
   signal ctrlPgpRxMmcmReset  : sl;
   signal ctrlPgpRxMmcmLocked : sl;
   signal ctrlRxRecClkGt      : sl;
   signal ctrlRxRecClkRstGt   : sl;
   signal ctrlRxRecClkLoc     : sl;
   signal ctrlRxRecClkRstLoc  : sl;
   signal ctrlRxIn            : Pgp2bRxInType  := PGP2B_RX_IN_INIT_C;
   signal ctrlRxOut           : Pgp2bRxOutType := PGP2B_RX_OUT_INIT_C;
   signal ctrlTxIn            : Pgp2bTxInType  := PGP2B_TX_IN_INIT_C;
   signal axiCtrlTxIn         : Pgp2bTxInType  := PGP2B_TX_IN_INIT_C;
   signal ctrlTxOut           : Pgp2bTxOutType := PGP2B_TX_OUT_INIT_C;
   signal ctrlTxAxisMasters   : AxiStreamMasterArray(3 downto 0);
   signal ctrlTxAxisSlaves    : AxiStreamSlaveArray(3 downto 0);
   signal ctrlRxAxisMasters   : AxiStreamMasterArray(3 downto 0);
   signal ctrlRxAxisSlaves    : AxiStreamSlaveArray(3 downto 0);
   signal ctrlRxAxisCtrl      : AxiStreamCtrlArray(3 downto 0);

   -- Get Data PGP configuration. 
   constant DATA_GTP_CONFIG_C : Gtp7QPllCfgType := getGtp7QPllCfg(250.0E6, DATA_PGP_LINE_RATE_G);

   signal dataQPllRefClk     : slv(1 downto 0);
   signal dataQPllOutClk     : slv(1 downto 0);
   signal dataQPllOutRefClk  : slv(1 downto 0);
   signal dataQPllLock       : slv(1 downto 0);
   signal dataQPllLockDetClk : slv(1 downto 0);
   signal dataQPllRefClkLost : slv(1 downto 0);
   signal dataQPllReset      : Slv2Array(3 downto 0);

   signal dataTxOutClks : slv(3 downto 0);

   signal dataRxIn    : Pgp2bRxInArray(3 downto 0);
   signal dataRxOut   : Pgp2bRxOutArray(3 downto 0);
   signal dataTxIn    : Pgp2bTxInArray(3 downto 0);
   signal axiDataTxIn : Pgp2bTxInArray(3 downto 0);
   signal dataTxOut   : Pgp2bTxOutArray(3 downto 0);

   signal dataTxAxisMasters : AxiStreamQuadMasterArray(3 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal dataTxAxisSlaves  : AxiStreamQuadSlaveArray(3 downto 0);
   signal dataRxAxisMasters : AxiStreamQuadMasterArray(3 downto 0) := (others => (others => AXI_STREAM_MASTER_INIT_C));
   signal dataRxAxisSlaves  : AxiStreamQuadSlaveArray(3 downto 0)  := (others => (others => AXI_STREAM_SLAVE_FORCE_C));

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite PGP signals
   -------------------------------------------------------------------------------------------------
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(5 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(5 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(5 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(5 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   signal cursor : slv32Array(1 downto 0);

   attribute keep_hierarchy        : string;
   attribute keep_hierarchy of rtl : architecture is "yes";

   attribute KEEP : string;
   attribute KEEP of
      ctrlRxRecClkLoc : signal is "TRUE";

--   attribute MARK_DEBUG : string;
--   attribute MARK_DEBUG of
--      ctrlRxIn,
--      ctrlRxOut,
--      ctrlTxIn,
--      ctrlTxOut : signal is "TRUE";

begin

   assert (TX_CLK_SRC_G = "RXREC" or TX_CLK_SRC_G = "DAQREF" or TX_CLK_SRC_G = "GTREF125")
      report "FebPgp: TX_CLK_SRC_G must be RXREC, DAQREF or GTREF125" severity failure;

   -- Output recovered clock and reset
   ctrlRxRecClk    <= ctrlRxRecClkLoc;  -- Output
   ctrlRxRecClkRst <= ctrlRxRecClkRstLoc;

   -------------------------------------------------------------------------------------------------
   -- GTP PLL for Fixed Latency PGP Link
   -- Set for 2.5 Gbps Operation
   -- PLL0 - RX
   -- PLL1 - TX
   -------------------------------------------------------------------------------------------------
   ctrlQPllRefClk(0) <= gtRefClk125;
   ctrlQPllRefClk(1) <= ctrlRxRecClkLoc when TX_CLK_SRC_G = "RXREC" else
                        daqRefClk   when TX_CLK_SRC_G = "DAQREF" else
                        gtRefClk125 when TX_CLK_SRC_G = "GTREF125" else
                        '0';

   ctrlQPllLockDetClk(0) <= clk250;
   ctrlQPllLockDetClk(1) <= clk250;

   ctrlPgpTxClk <= ctrlRxRecClkLoc when TX_CLK_SRC_G = "RXREC" else
                   daqRefClkG when TX_CLK_SRC_G = "DAQREF" else
                   axilClk    when TX_CLK_SRC_G = "GTREF125" else
                   '0';

   ctrlPgpTxRst <= ctrlRxRecClkRstLoc when TX_CLK_SRC_G = "RXREC" else
                   ctrlRxRecClkRstLoc when TX_CLK_SRC_G = "DAQREF" else
                   axilClkRst         when TX_CLK_SRC_G = "GTREF125" else
                   '0';

   -------------------------------------------------------------------------------------------------
   -- Fixed Latency Pgp Link
   -------------------------------------------------------------------------------------------------
   -- Led outputs
   ctrlRxLink <= ctrlRxOut.phyRxReady;
   ctrlTxLink <= ctrlTxOut.phyTxReady;

   -- Output received opCodes
   ctrlRxOpcodeEn <= ctrlRxOut.opCodeEn;
   ctrlRxOpcode   <= ctrlRxOut.opCode;

   -- Wrap Rx opCodes back to tx.
   axiCtrlTxIn.opCodeEn    <= ctrlRxOut.opCodeEn;
   axiCtrlTxIn.opCode      <= ctrlRxOut.opCode;
   axiCtrlTxIn.flush       <= '0';
   axiCtrlTxIn.locData     <= (others => '0');
   axiCtrlTxIn.flowCntlDis <= '0';

   GEN_PGP : if (ROGUE_TCP_SIM_G = false) generate

      Gtp7QuadPll_2500 : entity surf.Gtp7QuadPll
         generic map (
            SIM_RESET_SPEEDUP_G  => "TRUE",
            SIM_VERSION_G        => "2.0",
            PLL0_REFCLK_SEL_G    => "001",                                -- GT_REFCLK_0
            PLL0_FBDIV_IN_G      => CTRL_GTP_CONFIG_C.QPLL_FBDIV_G,       --5,
            PLL0_FBDIV_45_IN_G   => CTRL_GTP_CONFIG_C.QPLL_FBDIV_45_G,    --5,
            PLL0_REFCLK_DIV_IN_G => CTRL_GTP_CONFIG_C.QPLL_REFCLK_DIV_G,  --1
            PLL1_REFCLK_SEL_G    => TX_REFCLK_SEL_C,                      -- GTG_REFCLK -> 125 MHz
            PLL1_FBDIV_IN_G      => CTRL_GTP_CONFIG_C.QPLL_FBDIV_G,       --5,
            PLL1_FBDIV_45_IN_G   => CTRL_GTP_CONFIG_C.QPLL_FBDIV_45_G,    --5,
            PLL1_REFCLK_DIV_IN_G => CTRL_GTP_CONFIG_C.QPLL_REFCLK_DIV_G)  --1)
         port map (
            qPllRefClk     => ctrlQPllRefClk,
            qPllOutClk     => ctrlQPllOutClk,
            qPllOutRefClk  => ctrlQPllOutRefClk,
            qPllLock       => ctrlQPllLock,
            qPllLockDetClk => ctrlQPllLockDetClk,
            qPllRefClkLost => ctrlQPllRefClkLost,
            qPllReset      => ctrlQPllReset);


      Pgp2bGtp7FixedLat_1 : entity surf.Pgp2bGtp7FixedLat
         generic map (
            TPD_G                 => TPD_G,
            SIM_GTRESET_SPEEDUP_G => "TRUE",
            SIM_VERSION_G         => "2.0",
            SIMULATION_G          => ROGUE_TCP_SIM_G,
            STABLE_CLOCK_PERIOD_G => 4.0E-9,
            REF_CLK_FREQ_G        => 125.0E6,
            RXOUT_DIV_G           => CTRL_GTP_CONFIG_C.OUT_DIV_G,    --2,
            TXOUT_DIV_G           => CTRL_GTP_CONFIG_C.OUT_DIV_G,    --2,
            RX_CLK25_DIV_G        => CTRL_GTP_CONFIG_C.CLK25_DIV_G,  --5,
            TX_CLK25_DIV_G        => CTRL_GTP_CONFIG_C.CLK25_DIV_G,  --5,
            TX_PLL_G              => "PLL1",
            RX_PLL_G              => "PLL0",
            RXCDR_CFG_G           => X"0001107FE206021081010",
            VC_INTERLEAVE_G       => 1,
            PAYLOAD_CNT_TOP_G     => 7,
            NUM_VC_EN_G           => 4)
         port map (
            stableClk        => stableClk,
            gtQPllOutRefClk  => ctrlQPllOutRefClk,
            gtQPllOutClk     => ctrlQPllOutClk,
            gtQPllLock       => ctrlQPllLock,
            gtQPllRefClkLost => ctrlQPllRefClkLost,
            gtQPllReset      => ctrlQPllReset,
            gtRxRefClkBufg   => gtRefClk125G,
            gtRxN            => ctrlGtRxN,
            gtRxP            => ctrlGtRxP,
            gtTxN            => ctrlGtTxN,
            gtTxP            => ctrlGtTxP,
            pgpTxReset       => ctrlPgpTxRst,
            pgpTxClk         => ctrlPgpTxClk,
            pgpRxReset       => axilClkRst,  -- Reset rx with axi (main) reset
            pgpRxRecClk      => ctrlRxRecClkGt,
            pgpRxRecClkRst   => ctrlRxRecClkRstGt,
            pgpRxClk         => ctrlRxRecClkLoc,
            pgpRxMmcmReset   => ctrlPgpRxMmcmReset,
            pgpRxMmcmLocked  => ctrlPgpRxMmcmLocked,
            pgpRxIn          => ctrlRxIn,
            pgpRxOut         => ctrlRxOut,
            pgpTxIn          => ctrlTxIn,
            pgpTxOut         => ctrlTxOut,
            pgpTxMasters     => ctrlTxAxisMasters,
            pgpTxSlaves      => ctrlTxAxisSlaves,
            pgpRxMasters     => ctrlRxAxisMasters,
            pgpRxCtrl        => ctrlRxAxisCtrl);



      -------------------------------------------------------------------------------------------------
      -- Clock manager to clean up recovered clock
      -------------------------------------------------------------------------------------------------
      RxClkMmcmGen : if (RX_REC_CLK_MMCM_G) generate
         ClockManager7_1 : entity surf.ClockManager7
            generic map (
               TPD_G              => TPD_G,
               TYPE_G             => "PLL",
               INPUT_BUFG_G       => false,
               FB_BUFG_G          => true,
               NUM_CLOCKS_G       => 1,
               BANDWIDTH_G        => "HIGH",
               CLKIN_PERIOD_G     => 8.0,
               DIVCLK_DIVIDE_G    => 1,
               CLKFBOUT_MULT_G    => 14,
               CLKOUT0_DIVIDE_G   => 14,
               CLKOUT0_RST_HOLD_G => 16)
            port map (
               clkIn     => ctrlRxRecClkGt,
               rstIn     => ctrlPgpRxMmcmReset,
               clkOut(0) => ctrlRxRecClkLoc,
               locked    => ctrlPgpRxMmcmLocked);

         -- I think this is right, sync reset to mmcm clk
         RstSync_1 : entity surf.RstSync
            generic map (
               TPD_G => TPD_G)
            port map (
               clk      => ctrlRxRecClkLoc,
               asyncRst => ctrlRxRecClkRstGt,
               syncRst  => ctrlRxRecClkRstLoc);
      end generate RxClkMmcmGen;

      RxClkNoMmcmGen : if (not RX_REC_CLK_MMCM_G) generate
         ctrlRxRecClkLoc     <= ctrlRxRecClkGt;
         ctrlRxRecClkRstLoc  <= ctrlRxRecClkRstGt;
         ctrlPgpRxMmcmLocked <= '1';
      end generate RxClkNoMmcmGen;



   end generate GEN_PGP;

   GEN_CTRL_SIM : if (ROGUE_TCP_SIM_G = true) generate
      ctrlRxRecClkLoc    <= axilClk;
      ctrlRxRecClkRstLoc <= axilClkRst;
      U_RoguePgp2bSim_1 : entity surf.RoguePgp2bSim
         generic map (
            TPD_G         => TPD_G,
            PORT_NUM_G    => ROGUE_TCP_CTRL_PORT_G,
            NUM_VC_G      => 4,
            EN_SIDEBAND_G => true)
         port map (
            pgpClk       => axilClk,            -- [in]
            pgpClkRst    => axilClkRst,         -- [in]
            pgpRxIn      => ctrlRxIn,           -- [in]
            pgpRxOut     => ctrlRxOut,          -- [out]
            pgpTxIn      => ctrlTxIn,           -- [in]
            pgpTxOut     => ctrlTxOut,          -- [out]
            pgpTxMasters => ctrlTxAxisMasters,  -- [in]
            pgpTxSlaves  => ctrlTxAxisSlaves,   -- [out]
            pgpRxMasters => ctrlRxAxisMasters,  -- [out]
            pgpRxSlaves  => ctrlRxAxisSlaves);  -- [in]
   end generate;

   CntlPgp2bAxi : entity surf.Pgp2bAxi
      generic map (
         TPD_G              => TPD_G,
         COMMON_TX_CLK_G    => false,
         COMMON_RX_CLK_G    => false,
         WRITE_EN_G         => false,
         AXI_CLK_FREQ_G     => 125.0E+6,
         STATUS_CNT_WIDTH_G => 32,
         ERROR_CNT_WIDTH_G  => 8)
      port map (
         pgpTxClk        => ctrlPgpTxClk,  --ctrlRxRecClkLoc,
         pgpTxClkRst     => '0',
         pgpTxIn         => ctrlTxIn,
         pgpTxOut        => ctrlTxOut,
         locTxIn         => axiCtrlTxIn,
         pgpRxClk        => ctrlRxRecClkLoc,
         pgpRxClkRst     => '0',
         pgpRxIn         => ctrlRxIn,
         pgpRxOut        => ctrlRxOut,
         axilClk         => axilClk,
         axilRst         => axilClkRst,
         axilReadMaster  => locAxilReadMasters(0),
         axilReadSlave   => locAxilReadSlaves(0),
         axilWriteMaster => locAxilWriteMasters(0),
         axilWriteSlave  => locAxilWriteSlaves(0));

   -------------------------------------------------------------------------------------------------
   -- SSI AXI-Lite Master on VC0
   -------------------------------------------------------------------------------------------------
   U_SrpV3AxiLite_1 : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 1,
         FIFO_SYNTH_MODE_G => "xpm",
--         FIFO_PAUSE_THRESH_G => 2**8,
--         TX_VALID_THOLD_G    => TX_VALID_THOLD_G,
         SLAVE_READY_EN_G    => ROGUE_TCP_SIM_G,
         GEN_SYNC_FIFO_G     => ROGUE_TCP_SIM_G,    -- Everything on axiclk in sim mode
         AXIL_CLK_FREQ_G     => 125.0e6,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk         => ctrlRxRecClkLoc,       -- [in]
         sAxisRst         => ctrlRxRecClkRstLoc,    -- [in]
         sAxisMaster      => ctrlRxAxisMasters(0),  -- [in]
         sAxisSlave       => ctrlRxAxisSlaves(0),   -- [out],
         sAxisCtrl        => ctrlRxAxisCtrl(0),     -- [out]
         mAxisClk         => ctrlPgpTxClk,          -- [in]
         mAxisRst         => ctrlPgpTxRst,          -- [in]
         mAxisMaster      => ctrlTxAxisMasters(0),  -- [out]
         mAxisSlave       => ctrlTxAxisSlaves(0),   -- [in]
         axilClk          => axilClk,               -- [in]
         axilRst          => axilClkRst,            -- [in]
         mAxilWriteMaster => mAxilWriteMaster,      -- [out]
         mAxilWriteSlave  => mAxilWriteSlave,       -- [in]
         mAxilReadMaster  => mAxilReadMaster,       -- [out]
         mAxilReadSlave   => mAxilReadSlave);       -- [in]


   -------------------------------------------------------------------------------------------------
   -- FIFOs for SEM stream
   -------------------------------------------------------------------------------------------------
   SEM_RX_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => ROGUE_TCP_SIM_G,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 5,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**5-2,
         SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk    => ctrlRxRecClkLoc,
         sAxisRst    => ctrlRxRecClkRstLoc,
         sAxisMaster => ctrlRxAxisMasters(1),
         sAxisSlave  => ctrlRxAxisSlaves(1),
         sAxisCtrl   => ctrlRxAxisCtrl(1),
         mAxisClk    => axilClk,
         mAxisRst    => axilClkRst,
         mAxisMaster => semRxAxisMaster,
         mAxisSlave  => semRxAxisSlave);

   SEM_TX_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => true,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 5,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**5-2,
         SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk    => axilClk,
         sAxisRst    => axilClkRst,
         sAxisMaster => semTxAxisMaster,
         sAxisSlave  => semTxAxisSlave,
         mAxisClk    => ctrlPgpTxClk,
         mAxisRst    => ctrlPgpTxRst,
         mAxisMaster => ctrlTxAxisMasters(1),
         mAxisSlave  => ctrlTxAxisSlaves(1));

--   semTxAxisSlave <= AXI_STREAM_SLAVE_FORCE_C;


   -------------------------------------------------------------------------------------------------
   -- FIFOs for PROM stream 
   -------------------------------------------------------------------------------------------------
   ctrlRxAxisCtrl(2)    <= AXI_STREAM_CTRL_UNUSED_C;
   ctrlRxAxisSlaves(2)  <= AXI_STREAM_SLAVE_FORCE_C;
   ctrlTxAxisMasters(2) <= AXI_STREAM_MASTER_INIT_C;

   -------------------------------------------------------------------------------------------------
   -- VC3 is loopback
   -------------------------------------------------------------------------------------------------
   LOOPBACK_FIFO : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SYNTH_MODE_G        => "xpm",
         MEMORY_TYPE_G       => "block",
         SLAVE_READY_EN_G    => ROGUE_TCP_SIM_G,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 2**9-128,
         SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk    => ctrlRxRecClkLoc,
         sAxisRst    => ctrlRxRecClkRstLoc,
         sAxisMaster => ctrlRxAxisMasters(3),
         sAxisSlave  => ctrlRxAxisSlaves(3),
         sAxisCtrl   => ctrlRxAxisCtrl(3),
         mAxisClk    => ctrlPgpTxClk,
         mAxisRst    => ctrlPgpTxRst,
         mAxisMaster => ctrlTxAxisMasters(3),
         mAxisSlave  => ctrlTxAxisSlaves(3));

   -------------------------------------------------------------------------------------------------
   -- Upstream data channels
   -------------------------------------------------------------------------------------------------
   GEN_DATA_GTPS : if (ROGUE_TCP_SIM_G = false) generate

      dataQPllRefClk(0)     <= gtRefClk250;
      dataQPllRefClk(1)     <= '0';
      dataQPllLockDetClk(0) <= axilClk;
      dataQPllLockDetClk(1) <= '0';
      Gtp7QuadPll_4000 : entity surf.Gtp7QuadPll
         generic map (
            SIM_RESET_SPEEDUP_G  => "TRUE",
            SIM_VERSION_G        => "2.0",
            PLL0_REFCLK_SEL_G    => "001",                                -- Make configurable
            PLL0_FBDIV_IN_G      => DATA_GTP_CONFIG_C.QPLL_FBDIV_G,       --2
            PLL0_FBDIV_45_IN_G   => DATA_GTP_CONFIG_C.QPLL_FBDIV_45_G,    --5
            PLL0_REFCLK_DIV_IN_G => DATA_GTP_CONFIG_C.QPLL_REFCLK_DIV_G,  --1
            PLL1_REFCLK_SEL_G    => "001",                                -- Not used
            PLL1_FBDIV_IN_G      => 2,
            PLL1_FBDIV_45_IN_G   => 5,
            PLL1_REFCLK_DIV_IN_G => 1)
         port map (
            qPllRefClk     => dataQPllRefClk,
            qPllOutClk     => dataQPllOutClk,
            qPllOutRefClk  => dataQPllOutRefClk,
            qPllLock       => dataQPllLock,
            qPllLockDetClk => dataQPllLockDetClk,
            qPllRefClkLost => dataQPllRefClkLost,
            qPllReset(0)   => dataQPllReset(0)(0),
            qPllReset(1)   => '0');

      -------------------------------------------------------------------------------------------------
      -- 4 PGP links at 5 Gbps
      -------------------------------------------------------------------------------------------------

      dataTxOutClk <= dataTxOutClks(0);
      DATA_LANE_GEN : for i in 3 downto 0 generate
         Pgp2bGtp7MultiLane_1 : entity surf.Pgp2bGtp7MultiLane
            generic map (
               TPD_G                 => TPD_G,
               STABLE_CLOCK_PERIOD_G => 4.0E-9,
               RXOUT_DIV_G           => DATA_GTP_CONFIG_C.OUT_DIV_G,    --1,
               TXOUT_DIV_G           => DATA_GTP_CONFIG_C.OUT_DIV_G,    --1,
               RX_CLK25_DIV_G        => DATA_GTP_CONFIG_C.CLK25_DIV_G,  --10,
               TX_CLK25_DIV_G        => DATA_GTP_CONFIG_C.CLK25_DIV_G,  --10,
               TX_PLL_G              => "PLL0",
               RX_PLL_G              => "PLL0",
               RX_ENABLE_G           => false,
               TX_ENABLE_G           => true,
               PAYLOAD_CNT_TOP_G     => 7,
               LANE_CNT_G            => 1,
               VC_INTERLEAVE_G       => 0,
               NUM_VC_EN_G           => 2)
            port map (
               stableClk        => axilClk,
               gtQPllOutRefClk  => dataQPllOutRefClk,
               gtQPllOutClk     => dataQPllOutClk,
               gtQPllLock       => dataQPllLock,
               gtQPllRefClkLost => dataQPllRefClkLost,
               gtQPllReset      => dataQPllReset(i),
               gtTxP(0)         => dataGtTxP(i),
               gtTxN(0)         => dataGtTxN(i),
               gtRxP(0)         => dataGtRxP(i),
               gtRxN(0)         => dataGtRxN(i),
               pgpTxReset       => dataClkRst,
               pgpTxClk         => dataClk,
               pgpTxRecClk      => dataTxOutClks(i),
               pgpTxMmcmReset   => open,
               pgpTxMmcmLocked  => '1',
               txDiffCtrl       => "1111",
               txPreCursor      => cursor(0)(4 downto 0),
               txPostCursor     => cursor(1)(4 downto 0),
               pgpRxReset       => dataClkRst,
               pgpRxRecClk      => open,
               pgpRxClk         => dataClk,
               pgpRxMmcmReset   => open,
               pgpRxMmcmLocked  => '1',
               pgpRxIn          => dataRxIn(i),
               pgpRxOut         => dataRxOut(i),
               pgpTxIn          => dataTxIn(i),
               pgpTxOut         => dataTxOut(i),
               pgpTxMasters     => dataTxAxisMasters(i),
               pgpTxSlaves      => dataTxAxisSlaves(i),
               pgpRxMasters     => open,
               pgpRxMasterMuxed => open,
               pgpRxCtrl        => (others => AXI_STREAM_CTRL_UNUSED_C));

      end generate;
   end generate;

   SIM_DATA_GEN : if (ROGUE_TCP_SIM_G) generate
      SIM_DATA_LOOP : for i in 3 downto 0 generate
         U_RoguePgp2bSim_1 : entity surf.RoguePgp2bSim
            generic map (
               TPD_G         => TPD_G,
               PORT_NUM_G    => ROGUE_TCP_DATA_PORT_G + (i*10),
               NUM_VC_G      => 4,
               EN_SIDEBAND_G => true)
            port map (
               pgpClk       => dataClk,               -- [in]
               pgpClkRst    => dataClkRst,            -- [in]
               pgpRxIn      => dataRxIn(i),           -- [in]
               pgpRxOut     => dataRxOut(i),          -- [out]
               pgpTxIn      => dataTxIn(i),           -- [in]
               pgpTxOut     => dataTxOut(i),          -- [out]
               pgpTxMasters => dataTxAxisMasters(i),  -- [in]
               pgpTxSlaves  => dataTxAxisSlaves(i),   -- [out]
               pgpRxMasters => dataRxAxisMasters(i),  -- [out]
               pgpRxSlaves  => dataRxAxisSlaves(i));  -- [in]
      end generate;
   end generate;

   DataPgp2bAxiGen : for i in 3 downto 0 generate

      dataTxLink(i)              <= dataTxOut(i).linkReady;
      axiDataTxIn(i).flush       <= '0';
      axiDataTxIn(i).opCodeEn    <= '0';
      axiDataTxIn(i).opCode      <= (others => '0');
      axiDataTxIn(i).locData     <= "000" & syncStatuses(i);
      axiDataTxIn(i).flowCntlDis <= '1';

      DataPgp2bAxi : entity surf.Pgp2bAxi
         generic map (
            TPD_G              => TPD_G,
            COMMON_TX_CLK_G    => false,
            COMMON_RX_CLK_G    => false,
            WRITE_EN_G         => true,
            AXI_CLK_FREQ_G     => 125.0E+6,
            STATUS_CNT_WIDTH_G => 32,
            ERROR_CNT_WIDTH_G  => 8)
         port map (
            pgpTxClk        => dataClk,
            pgpTxClkRst     => dataClkRst,
            pgpTxIn         => dataTxIn(i),
            pgpTxOut        => dataTxOut(i),
            locTxIn         => axiDataTxIn(i),
            pgpRxClk        => dataClk,
            pgpRxClkRst     => dataClkRst,
            pgpRxIn         => dataRxIn(i),
            pgpRxOut        => dataRxOut(i),
            axilClk         => axilClk,
            axilRst         => axilClkRst,
            axilReadMaster  => locAxilReadMasters(i+1),
            axilReadSlave   => locAxilReadSlaves(i+1),
            axilWriteMaster => locAxilWriteMasters(i+1),
            axilWriteSlave  => locAxilWriteSlaves(i+1));

   end generate DataPgp2bAxiGen;

   U_AxiLiteRegs_1 : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => 2)
      port map (
         axiClk         => axilClk,                 -- [in]
         axiClkRst      => axilClkRst,              -- [in]
         axiReadMaster  => locAxilReadMasters(5),   -- [in]
         axiReadSlave   => locAxilReadSlaves(5),    -- [out]
         axiWriteMaster => locAxilWriteMasters(5),  -- [in]
         axiWriteSlave  => locAxilWriteSlaves(5),   -- [out]
         writeRegister  => cursor);                 -- [out]


   ----------------------------------------------------------------------------------------------
   -- Buffer for data
   ----------------------------------------------------------------------------------------------
   DATA_FIFO_GEN : for i in 3 downto 0 generate

      AxiStreamFifo_APV : entity surf.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            PIPE_STAGES_G       => 1,
            SYNTH_MODE_G        => "xpm",
            MEMORY_TYPE_G       => "block",
            GEN_SYNC_FIFO_G     => false,
            FIFO_ADDR_WIDTH_G   => 15,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 2**15-3390,
            SLAVE_AXI_CONFIG_G  => SSI_PGP2B_CONFIG_C,
            MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
         port map (
            sAxisClk    => clk250,
            sAxisRst    => clk250Rst,
            sAxisMaster => hybridDataAxisMasters(i)(APV_PGP_VC_C),
            sAxisSlave  => hybridDataAxisSlaves(i)(APV_PGP_VC_C),
            sAxisCtrl   => hybridDataAxisCtrl(i)(APV_PGP_VC_C),
            mAxisClk    => dataClk,
            mAxisRst    => dataClkRst,
            mAxisMaster => dataTxAxisMasters(i)(APV_PGP_VC_C),
            mAxisSlave  => dataTxAxisSlaves(i)(APV_PGP_VC_C));

      AxiStreamFifo_Status : entity surf.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            PIPE_STAGES_G       => 1,
            SYNTH_MODE_G        => "xpm",
            MEMORY_TYPE_G       => "distributed",
            GEN_SYNC_FIFO_G     => true,
            FIFO_ADDR_WIDTH_G   => 4,
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 2**4-1,
            SLAVE_AXI_CONFIG_G  => HYBRID_STATUS_SSI_CONFIG_C,
            MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
         port map (
            sAxisClk    => dataClk,
            sAxisRst    => dataClkRst,
            sAxisMaster => hybridDataAxisMasters(i)(STATUS_PGP_VC_C),
            sAxisSlave  => hybridDataAxisSlaves(i)(STATUS_PGP_VC_C),
            sAxisCtrl   => hybridDataAxisCtrl(i)(STATUS_PGP_VC_C),
            mAxisClk    => dataClk,
            mAxisRst    => dataClkRst,
            mAxisMaster => dataTxAxisMasters(i)(STATUS_PGP_VC_C),
            mAxisSlave  => dataTxAxisSlaves(i)(STATUS_PGP_VC_C));

   end generate DATA_FIFO_GEN;

   -------------------------------------------------------------------------------------------------
   -- Allow monitoring of PGP module statuses via axi-lite
   -------------------------------------------------------------------------------------------------
   Pgp2bAxiAxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 6,
         MASTERS_CONFIG_G   => (
            0               => (        -- Control link Pgp2bAxi
               baseAddr     => AXI_BASE_ADDR_G + X"000",
               addrBits     => 8,
               connectivity => X"0001"),
            1               => (        -- Data0 Pgp2bAxi
               baseAddr     => AXI_BASE_ADDR_G + X"100",
               addrBits     => 8,
               connectivity => X"0001"),
            2               => (        -- Data1 Pgp2bAxi
               baseAddr     => AXI_BASE_ADDR_G + X"200",
               addrBits     => 8,
               connectivity => X"0001"),
            3               => (        -- Data2 Pgp2bAxi
               baseAddr     => AXI_BASE_ADDR_G + X"300",
               addrBits     => 8,
               connectivity => X"0001"),
            4               => (        -- Data3 Pgp2bAxi
               baseAddr     => AXI_BASE_ADDR_G + X"400",
               addrBits     => 8,
               connectivity => X"0001"),
            5               => (
               baseAddr     => AXI_BASE_ADDR_G + X"500",
               addrBits     => 8,
               connectivity => X"0001")))
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilClkRst,
         sAxiWriteMasters(0) => sAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);




end architecture rtl;
