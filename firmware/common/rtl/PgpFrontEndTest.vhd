-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : PgpFrontEnd.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-08-06
-- Last update: 2022-04-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;
use surf.Pgp2bPkg.all;
use surf.Gtp7CfgPkg.all;


library ldmx;
use ldmx.HpsPkg.all;

entity PgpFrontEndTest is

   generic (
      TPD_G                 : time             := 1 ns;
      SIM_GTRESET_SPEEDUP_G : string           := "FALSE";
      SIM_VERSION_G         : string           := "1.0";
      SIMULATION_G          : boolean          := false;
      EN_DATA_CHANS_G       : boolean          := false;
      AXI_BASE_ADDR_G       : slv(31 downto 0) := (others => '0'));
   port (
      -- Reference clocks for PGP MGTs
      gtRefClk125  : in sl;
      gtRefClk125G : in sl;
      gtRefClk250  : in sl;

      sysGtTxP : out sl;
      sysGtTxN : out sl;
      sysGtRxP : in  sl;
      sysGtRxN : in  sl;

      dataGtTxP : out slv(3 downto 0);
      dataGtTxN : out slv(3 downto 0);
      dataGtRxP : in  slv(3 downto 0) := (others => '0');
      dataGtRxN : in  slv(3 downto 0) := (others => '0');

      daqClk    : in sl;
      daqClkRst : in sl;

      pgpClk    : in sl;
      pgpClkRst : in sl;

      pgpDataClk    : in sl;
      pgpDataClkRst : in sl;

      axiClk : in sl;
      axiRst : in sl;

      rxLink : out sl;
      txLink : out sl;

--      dataTxLink : out slv(3 downto 0);

      -- Command interface for software triggers
      cmdMaster : out SsiCmdMasterType;

      -- Axi Master Interface - Registers
      regAxiReadMaster  : out AxiLiteReadMasterType;
      regAxiReadSlave   : in  AxiLiteReadSlaveType;
      regAxiWriteMaster : out AxiLiteWriteMasterType;
      regAxiWriteSlave  : in  AxiLiteWriteSlaveType;

      -- Event Data Stream
      eventAxisMaster : in  AxiStreamMasterType;
      eventAxisSlave  : out AxiStreamSlaveType;
      eventAxisCtrl   : out AxiStreamCtrlType;

      -- Axi Slave Interface for PGP statuses
      sPgpAxiReadMaster  : in  AxiLiteReadMasterType;
      sPgpAxiReadSlave   : out AxiLiteReadSlaveType;
      sPgpAxiWriteMaster : in  AxiLiteWriteMasterType;
      sPgpAxiWriteSlave  : out AxiLiteWriteSlaveType);

end entity PgpFrontEndTest;

architecture rtl of PgpFrontEndTest is

   constant SYS_GTP_CFG_C : Gtp7QPllCfgType := getGtp7QPllCfg(125.0E6, 3.125E9);

   -- Sys QPLL Signals
   signal sysQPllRefClk     : slv(1 downto 0);
   signal sysQPllOutClk     : slv(1 downto 0);
   signal sysQPllOutRefClk  : slv(1 downto 0);
   signal sysQPllLock       : slv(1 downto 0);
   signal sysQPllLockDetClk : slv(1 downto 0);
   signal sysQPllRefClkLost : slv(1 downto 0);
   signal sysQPllReset      : slv(1 downto 0);

   -- Sys PGP Signals
   signal sysPgpTxReset       : sl;
   signal sysPgpTxClk         : sl;
   signal sysPgpRxReset       : sl;
   signal sysPgpRxClk         : sl;
   signal sysPgpRxRecClkLoc   : sl;
   signal sysPgpRxRecRstLoc   : sl;
   signal sysPgpRxIn          : Pgp2bRxInType;
   signal sysPgpRxOut         : Pgp2bRxOutType;
   signal sysPgpTxIn          : Pgp2bTxInType;
   signal sysPgpTxOut         : Pgp2bTxOutType;
   signal sysPgpTxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal sysPgpTxAxisSlaves  : AxiStreamSlaveArray(3 downto 0);
   signal sysPgpRxAxisMasters : AxiStreamMasterArray(3 downto 0);
   signal sysPgpRxAxisCtrl    : AxiStreamCtrlArray(3 downto 0);

   constant DATA_GTP_CFG_C : Gtp7QPllCfgType := getGtp7QPllCfg(125.0E6, 4.0E9);

   signal dataQPllRefClk     : slv(1 downto 0);
   signal dataQPllOutClk     : slv(1 downto 0);
   signal dataQPllOutRefClk  : slv(1 downto 0);
   signal dataQPllLock       : slv(1 downto 0);
   signal dataQPllLockDetClk : slv(1 downto 0);
   signal dataQPllRefClkLost : slv(1 downto 0);
   signal dataQPllReset      : Slv2Array(3 downto 0);

   signal dataPgpTxReset : slv(3 downto 0);
   signal dataPgpRxIn    : Pgp2bRxInArray(3 downto 0);
   signal dataPgpRxOut   : Pgp2bRxOutArray(3 downto 0);
   signal dataPgpTxIn    : Pgp2bTxInArray(3 downto 0);
   signal dataPgpTxOut   : Pgp2bTxOutArray(3 downto 0);

   type AxiStreamMasterQuadArray is array (natural range <>) of AxiStreamMasterArray(3 downto 0);
   type AxiStreamSlaveQuadArray is array (natural range <>) of AxiStreamSlaveArray(3 downto 0);
   signal prbsTxAxisMasters : AxiStreamMasterQuadArray(3 downto 0);
   signal prbsTxAxisSlaves  : AxiStreamSlaveQuadArray(3 downto 0);

   signal mPgpAxiWriteMasters : AxiLiteWriteMasterArray(4 downto 0);
   signal mPgpAxiWriteSlaves  : AxiLiteWriteSlaveArray(4 downto 0);
   signal mPgpAxiReadMasters  : AxiLiteReadMasterArray(4 downto 0);
   signal mPgpAxiReadSlaves   : AxiLiteReadSlaveArray(4 downto 0);

   attribute keep_hierarchy        : string;
   attribute keep_hierarchy of rtl : architecture is "yes";

begin


   -------------------------------------------------------------------------------------------------
   -- GTP PLL for Fixed Latency PGP Link
   -- Set for 2.5 Gbps Operation
   -- PLL0 - TX
   -- PLL1 - RX
   -------------------------------------------------------------------------------------------------
   sysQPllRefClk(0)     <= gtRefClk125;
   sysQPllRefClk(1)     <= '0';         --gtRefClk125;
   sysQPllLockDetClk(0) <= pgpDataClk;
   sysQPllLockDetClk(1) <= '0';         --pgpClk;
   Gtp7QuadPll_2500 : entity surf.Gtp7QuadPll
      generic map (
         SIM_RESET_SPEEDUP_G  => "TRUE",
         SIM_VERSION_G        => "1.0",
         PLL0_REFCLK_SEL_G    => "001",  -- or use "010" for MGT_USER_REFCLK
         PLL0_FBDIV_IN_G      => SYS_GTP_CFG_C.QPLL_FBDIV_G,
         PLL0_FBDIV_45_IN_G   => SYS_GTP_CFG_C.QPLL_FBDIV_45_G,
         PLL0_REFCLK_DIV_IN_G => SYS_GTP_CFG_C.QPLL_REFCLK_DIV_G,
         PLL1_REFCLK_SEL_G    => "001",  -- GT_REFCLK_0 -> 125 MHz
         PLL1_FBDIV_IN_G      => SYS_GTP_CFG_C.QPLL_FBDIV_G,       --5,
         PLL1_FBDIV_45_IN_G   => SYS_GTP_CFG_C.QPLL_FBDIV_45_G,    --5,
         PLL1_REFCLK_DIV_IN_G => SYS_GTP_CFG_C.QPLL_REFCLK_DIV_G)  --1)
      port map (
         qPllRefClk     => sysQPllRefClk,
         qPllOutClk     => sysQPllOutClk,
         qPllOutRefClk  => sysQPllOutRefClk,
         qPllLock       => sysQPllLock,
         qPllLockDetClk => sysQPllLockDetClk,
         qPllRefClkLost => sysQPllRefClkLost,
         qPllReset      => sysQPllReset);


   -------------------------------------------------------------------------------------------------
   -- Fixed Latency Pgp Link delivers clock and resets
   -- Hooked up to RegSlave
   -------------------------------------------------------------------------------------------------
   sysPgpTxReset <= pgpClkRst;          --axiRst;          -- Figure out what to do with these
   sysPgpRxReset <= pgpClkRst;          --axiRst;

   rxLink <= sysPgpRxOut.linkReady;
   txLink <= sysPgpTxOut.linkReady;
--   sysPgpRxIn.flush   <= '0';
--   sysPgpRxIn.resetRx <= '0';

--   sysPgpTxIn.flush        <= '0';
--   sysPgpTxIn.locLinkReady <= sysPgpRxOut.linkReady;
--   sysPgpTxIn.locData      <= (others => '0');
--   sysPgpTxIn.opCodeEn     <= '0';
--   sysPgpTxIn.opCode       <= (others => '0');

   Pgp2bGtp7MultiLane_1 : entity surf.Pgp2bGtp7MultiLane
      generic map (
         TPD_G                 => TPD_G,
         SIM_GTRESET_SPEEDUP_G => SIM_GTRESET_SPEEDUP_G,
         SIM_VERSION_G         => SIM_VERSION_G,
         STABLE_CLOCK_PERIOD_G => 4.0E-9,
         RXOUT_DIV_G           => SYS_GTP_CFG_C.OUT_DIV_G,
         TXOUT_DIV_G           => SYS_GTP_CFG_C.OUT_DIV_G,
         RX_CLK25_DIV_G        => SYS_GTP_CFG_C.CLK25_DIV_G,  -- 13,
         TX_CLK25_DIV_G        => SYS_GTP_CFG_C.CLK25_DIV_G,  -- 13,
         TX_PLL_G              => "PLL0",
         RX_PLL_G              => "PLL0",
         RX_ENABLE_G           => true,
         TX_ENABLE_G           => true,
         PAYLOAD_CNT_TOP_G     => 7,
         LANE_CNT_G            => 1,
         VC_INTERLEAVE_G       => 0,
         NUM_VC_EN_G           => 2)
      port map (
         stableClk        => axiClk,
         gtQPllOutRefClk  => sysQPllOutRefClk,
         gtQPllOutClk     => sysQPllOutClk,
         gtQPllLock       => sysQPllLock,
         gtQPllRefClkLost => sysQPllRefClkLost,
         gtQPllReset      => sysQPllReset,
         gtTxP(0)         => sysGtTxP,
         gtTxN(0)         => sysGtTxN,
         gtRxP(0)         => sysGtRxP,
         gtRxN(0)         => sysGtRxN,
         pgpTxReset       => sysPgpTxReset,
         pgpTxClk         => pgpClk,                          --axiClk,
         pgpTxMmcmReset   => open,
         pgpTxMmcmLocked  => '1',
         pgpRxReset       => sysPgpRxReset,
         pgpRxRecClk      => open,
         pgpRxClk         => pgpClk,                          --axiClk,
         pgpRxMmcmReset   => open,
         pgpRxMmcmLocked  => '1',
         pgpRxIn          => sysPgpRxIn,
         pgpRxOut         => sysPgpRxOut,
         pgpTxIn          => sysPgpTxIn,
         pgpTxOut         => sysPgpTxOut,
         pgpTxMasters     => sysPgpTxAxisMasters,
         pgpTxSlaves      => sysPgpTxAxisSlaves,
         pgpRxMasters     => sysPgpRxAxisMasters,
         pgpRxMasterMuxed => open,
         pgpRxCtrl        => sysPgpRxAxisCtrl);


   -------------------------------------------------------------------------------------------------
   -- AXI Master For Register access
   -------------------------------------------------------------------------------------------------
   SsiAxiLiteMaster_1 : entity surf.SsiAxiLiteMaster
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 2**8,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk            => pgpClk,     --sysPgpRxRecClkLoc, --axiClk,
         sAxisRst            => pgpClkRst,  --sysPgpRxRecRstLoc, --axiRst,
         sAxisMaster         => sysPgpRxAxisMasters(0),
         sAxisSlave          => open,
         sAxisCtrl           => sysPgpRxAxisCtrl(0),
         mAxisClk            => pgpClk,     --axiClk,
         mAxisRst            => pgpClkRst,  --axiRst,
         mAxisMaster         => sysPgpTxAxisMasters(0),
         mAxisSlave          => sysPgpTxAxisSlaves(0),
         axiLiteClk          => axiClk,
         axiLiteRst          => axiRst,
         mAxiLiteWriteMaster => regAxiWriteMaster,
         mAxiLiteWriteSlave  => regAxiWriteSlave,
         mAxiLiteReadMaster  => regAxiReadMaster,
         mAxiLiteReadSlave   => regAxiReadSlave);

   -------------------------------------------------------------------------------------------------
   -- CMD Slave for software triggers
   -------------------------------------------------------------------------------------------------
   SsiCmdMaster_1 : entity surf.SsiCmdMaster
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         USE_BUILT_IN_G      => false,
         FIFO_ADDR_WIDTH_G   => 5,
         FIFO_PAUSE_THRESH_G => 2**4,
         AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         axisClk     => pgpClk,         --sysPgpRxRecClkLoc, --axiClk,
         axisRst     => pgpClkRst,      --sysPgpRxRecRstLoc, --axiRst,
         sAxisMaster => sysPgpRxAxisMasters(1),
         sAxisSlave  => open,
         sAxisCtrl   => sysPgpRxAxisCtrl(1),
         cmdClk      => daqClk,
         cmdRst      => daqClkRst,
         cmdMaster   => cmdMaster);

   -------------------------------------------------------------------------------------------------
   -- Event Data Upstream buffer
   -------------------------------------------------------------------------------------------------
   AxiStreamFifo_EventBuff : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G    => false,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 12,
         FIFO_PAUSE_THRESH_G => 2**12-8,
         SLAVE_AXI_CONFIG_G  => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G => SSI_PGP2B_CONFIG_C)
      port map (
         sAxisClk    => axiClk,
         sAxisRst    => axiRst,
         sAxisMaster => eventAxisMaster,
         sAxisSlave  => eventAxisSlave,
         sAxisCtrl   => eventAxisCtrl,
         mAxisClk    => pgpClk,
         mAxisRst    => pgpClkRst,
         mAxisMaster => sysPgpTxAxisMasters(1),
         mAxisSlave  => sysPgpTxAxisSlaves(1));


   -- RX channel 2 is unused
   sysPgpTxAxisMasters(2) <= AXI_STREAM_MASTER_INIT_C;
   sysPgpRxAxisCtrl(2)    <= AXI_STREAM_CTRL_UNUSED_C;

   -------------------------------------------------------------------------------------------------
   -- No other channels used
   -------------------------------------------------------------------------------------------------
   sysPgpRxAxisCtrl(3)    <= AXI_STREAM_CTRL_UNUSED_C;
   sysPgpTxAxisMasters(3) <= AXI_STREAM_MASTER_INIT_C;

   -------------------------------------------------------------------------------------------------
   -- Upstream data channels
   -------------------------------------------------------------------------------------------------
   GEN_DATA_CHANNELS : if (EN_DATA_CHANS_G) generate


      -------------------------------------------------------------------------------------------------
      -- QPLL for upstream data PGP links
      -- Sets link speed to 5 Gbps
      -------------------------------------------------------------------------------------------------
      dataQPllRefClk(0)     <= gtRefClk250;
      dataQPllRefClk(1)     <= '0';
      dataQPllLockDetClk(0) <= axiClk;
      dataQPllLockDetClk(1) <= '0';
      Gtp7QuadPll_4000 : entity surf.Gtp7QuadPll
         generic map (
            SIM_RESET_SPEEDUP_G  => "TRUE",
            SIM_VERSION_G        => "1.0",
            PLL0_REFCLK_SEL_G    => "001",                             -- Make configurable
            PLL0_FBDIV_IN_G      => DATA_GTP_CFG_C.QPLL_FBDIV_G,       --2,
            PLL0_FBDIV_45_IN_G   => DATA_GTP_CFG_C.QPLL_FBDIV_45_G,    --5,
            PLL0_REFCLK_DIV_IN_G => DATA_GTP_CFG_C.QPLL_REFCLK_DIV_G,  --1,
            PLL1_REFCLK_SEL_G    => "001",                             -- Not used
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
      -- Each attached to a VC UsBuff
      -------------------------------------------------------------------------------------------------
--   dataPgpRxIn <= (flush => '0', resetRx => '0');

      DATA_CHANNEL_GEN : for i in 0 to 3 generate

--      dataPgpTxIn(i).flush        <= '0';
--      dataPgpTxIn(i).opCodeEn     <= '0';
--      dataPgpTxIn(i).opCode       <= (others => '0');
--      dataPgpTxIn(i).locLinkReady <= '1';
--      dataPgpTxIn(i).locData      <= (others => '0');

--         dataTxLink(i) <= dataPgpTxOut(i).linkReady;

         Pgp2bGtp7MultiLane_1 : entity surf.Pgp2bGtp7MultiLane
            generic map (
               TPD_G                 => TPD_G,
               SIM_GTRESET_SPEEDUP_G => SIM_GTRESET_SPEEDUP_G,
               SIM_VERSION_G         => SIM_VERSION_G,
               STABLE_CLOCK_PERIOD_G => 4.0E-9,
               RXOUT_DIV_G           => DATA_GTP_CFG_C.OUT_DIV_G,    --1,
               TXOUT_DIV_G           => DATA_GTP_CFG_C.OUT_DIV_G,    --1,
               RX_CLK25_DIV_G        => DATA_GTP_CFG_C.CLK25_DIV_G,  --10,
               TX_CLK25_DIV_G        => DATA_GTP_CFG_C.CLK25_DIV_G,  --10,
               TX_PLL_G              => "PLL0",
               RX_PLL_G              => "PLL0",
               RX_ENABLE_G           => false,
               TX_ENABLE_G           => true,
               PAYLOAD_CNT_TOP_G     => 7,
               LANE_CNT_G            => 1,
               VC_INTERLEAVE_G       => 0,
               NUM_VC_EN_G           => 1)
            port map (
               stableClk        => axiClk,
               gtQPllOutRefClk  => dataQPllOutRefClk,
               gtQPllOutClk     => dataQPllOutClk,
               gtQPllLock       => dataQPllLock,
               gtQPllRefClkLost => dataQPllRefClkLost,
               gtQPllReset      => dataQPllReset(i),
               gtTxP(0)         => dataGtTxP(i),
               gtTxN(0)         => dataGtTxN(i),
               gtRxP(0)         => dataGtRxP(i),
               gtRxN(0)         => dataGtRxN(i),
               pgpTxReset       => pgpDataClkRst,
               pgpTxClk         => pgpDataClk,
               pgpTxMmcmReset   => open,
               pgpTxMmcmLocked  => '1',
               pgpRxReset       => pgpDataClkRst,
               pgpRxRecClk      => open,
               pgpRxClk         => pgpDataClk,
               pgpRxMmcmReset   => open,
               pgpRxMmcmLocked  => '1',
               pgpRxIn          => dataPgpRxIn(i),
               pgpRxOut         => dataPgpRxOut(i),
               pgpTxIn          => dataPgpTxIn(i),
               pgpTxOut         => dataPgpTxOut(i),
               pgpTxMasters     => prbsTxAxisMasters(i),
               pgpTxSlaves      => prbsTxAxisSlaves(i),
               pgpRxMasters     => open,
               pgpRxMasterMuxed => open,
               pgpRxCtrl        => (others => AXI_STREAM_CTRL_UNUSED_C));


         SsiPrbsTx_1 : entity surf.SsiPrbsTx
            generic map (
               TPD_G                      => TPD_G,
               MEMORY_TYPE_G              => "distributed",
               GEN_SYNC_FIFO_G            => false,
               FIFO_ADDR_WIDTH_G          => 4,
               FIFO_PAUSE_THRESH_G        => 2**4-1,
               MASTER_AXI_STREAM_CONFIG_G => SSI_PGP2B_CONFIG_C,
               MASTER_AXI_PIPE_STAGES_G   => 1)
            port map (
               mAxisClk     => pgpDataClk,
               mAxisRst     => pgpDataClkRst,
               mAxisSlave   => prbsTxAxisSlaves(i)(0),
               mAxisMaster  => prbsTxAxisMasters(i)(0),
               locClk       => axiClk,  -- pgpDataClk,
               locRst       => axiRst,  -- pgpDataClkRst,
               trig         => '1',
               packetLength => X"0000FFFF",
               busy         => open,
               tDest        => X"00",
               tId          => X"00");

         prbsTxAxisMasters(i)(3 downto 1) <= (others => AXI_STREAM_MASTER_INIT_C);

      end generate;


      -------------------------------------------------------------------------------------------------
      -- Allow monitoring of PGP module statuses via axi-lite
      -------------------------------------------------------------------------------------------------
      Pgp2bAxiAxiCrossbar : entity surf.AxiLiteCrossbar
         generic map (
            TPD_G              => TPD_G,
            NUM_SLAVE_SLOTS_G  => 1,
            NUM_MASTER_SLOTS_G => 5,
            MASTERS_CONFIG_G   => (
               0               => (     -- Control link
                  baseAddr     => AXI_BASE_ADDR_G + X"000",
                  addrBits     => 8,
                  connectivity => X"0001"),
               1               => (
                  baseAddr     => AXI_BASE_ADDR_G + X"100",
                  addrBits     => 8,
                  connectivity => X"0001"),
               2               => (
                  baseAddr     => AXI_BASE_ADDR_G + X"200",
                  addrBits     => 8,
                  connectivity => X"0001"),
               3               => (
                  baseAddr     => AXI_BASE_ADDR_G + X"300",
                  addrBits     => 8,
                  connectivity => X"0001"),
               4               => (
                  baseAddr     => AXI_BASE_ADDR_G + X"400",
                  addrBits     => 8,
                  connectivity => X"0001")))
         port map (
            axiClk              => axiClk,
            axiClkRst           => axiRst,
            sAxiWriteMasters(0) => sPgpAxiWriteMaster,
            sAxiWriteSlaves(0)  => sPgpAxiWriteSlave,
            sAxiReadMasters(0)  => sPgpAxiReadMaster,
            sAxiReadSlaves(0)   => sPgpAxiReadSlave,
            mAxiWriteMasters    => mPgpAxiWriteMasters,
            mAxiWriteSlaves     => mPgpAxiWriteSlaves,
            mAxiReadMasters     => mPgpAxiReadMasters,
            mAxiReadSlaves      => mPgpAxiReadSlaves);

      CntlPgp2bAxi : entity surf.Pgp2bAxi
         generic map (
            TPD_G              => TPD_G,
            COMMON_TX_CLK_G    => false,
            COMMON_RX_CLK_G    => false,
            WRITE_EN_G         => false,
            AXI_CLK_FREQ_G     => 125.0E+6,
            STATUS_CNT_WIDTH_G => 32,
            ERROR_CNT_WIDTH_G  => 4)
         port map (
            pgpTxClk        => pgpClk,
            pgpTxClkRst     => pgpClkRst,
            pgpTxIn         => sysPgpTxIn,
            pgpTxOut        => sysPgpTxOut,
--         locTxIn         => ,
            pgpRxClk        => pgpClk,
            pgpRxClkRst     => pgpClkRst,
            pgpRxIn         => sysPgpRxIn,
            pgpRxOut        => sysPgpRxOut,
--         locRxIn         => ,
            statusWord      => open,
            statusSend      => open,
            axilClk         => axiClk,
            axilRst         => axiRst,
            axilReadMaster  => mPgpAxiReadMasters(0),
            axilReadSlave   => mPgpAxiReadSlaves(0),
            axilWriteMaster => mPgpAxiWriteMasters(0),
            axilWriteSlave  => mPgpAxiWriteSlaves(0));

      DataPgp2bAxiGen : for i in 3 downto 0 generate
         DataPgp2bAxi : entity surf.Pgp2bAxi
            generic map (
               TPD_G              => TPD_G,
               COMMON_TX_CLK_G    => false,
               COMMON_RX_CLK_G    => false,
               WRITE_EN_G         => false,
               AXI_CLK_FREQ_G     => 125.0E+6,
               STATUS_CNT_WIDTH_G => 32,
               ERROR_CNT_WIDTH_G  => 4)
            port map (
               pgpTxClk        => pgpDataClk,
               pgpTxClkRst     => pgpDataClkRst,
               pgpTxIn         => dataPgpTxIn(i),
               pgpTxOut        => dataPgpTxOut(i),
--         locTxIn         => ,
               pgpRxClk        => pgpDataClk,
               pgpRxClkRst     => pgpDataClkRst,
               pgpRxIn         => dataPgpRxIn(i),
               pgpRxOut        => dataPgpRxOut(i),
--         locRxIn         => ,
               statusWord      => open,
               statusSend      => open,
               axilClk         => axiClk,
               axilRst         => axiRst,
               axilReadMaster  => mPgpAxiReadMasters(i+1),
               axilReadSlave   => mPgpAxiReadSlaves(i+1),
               axilWriteMaster => mPgpAxiWriteMasters(i+1),
               axilWriteSlave  => mPgpAxiWriteSlaves(i+1));
      end generate DataPgp2bAxiGen;
   end generate GEN_DATA_CHANNELS;

   -- If no data channels, no need for crossbar. Just hook up directly
   NO_GEN_DATA_CHANNELS : if (EN_DATA_CHANS_G = false) generate
      CntlPgp2bAxi : entity surf.Pgp2bAxi
         generic map (
            TPD_G              => TPD_G,
            COMMON_TX_CLK_G    => false,
            COMMON_RX_CLK_G    => false,
            WRITE_EN_G         => false,
            AXI_CLK_FREQ_G     => 125.0E+6,
            STATUS_CNT_WIDTH_G => 32,
            ERROR_CNT_WIDTH_G  => 4)
         port map (
            pgpTxClk        => pgpClk,
            pgpTxClkRst     => pgpClkRst,
            pgpTxIn         => sysPgpTxIn,
            pgpTxOut        => sysPgpTxOut,
--         locTxIn         => ,
            pgpRxClk        => pgpClk,
            pgpRxClkRst     => pgpClkRst,
            pgpRxIn         => sysPgpRxIn,
            pgpRxOut        => sysPgpRxOut,
--         locRxIn         => ,
            statusWord      => open,
            statusSend      => open,
            axilClk         => axiClk,
            axilRst         => axiRst,
            axilReadMaster  => sPgpAxiReadMaster,
            axilReadSlave   => sPgpAxiReadSlave,
            axilWriteMaster => sPgpAxiWriteMaster,
            axilWriteSlave  => sPgpAxiWriteSlave);
   end generate NO_GEN_DATA_CHANNELS;

end architecture rtl;
