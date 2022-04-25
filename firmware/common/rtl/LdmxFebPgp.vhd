-------------------------------------------------------------------------------
-- Title      : Coulter PGP 
-------------------------------------------------------------------------------
-- File       : FetPgp.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-06-03
-- Last update: 2022-01-04
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of Coulter. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of Coulter, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;


library surf;
use surf.StdRtlPkg.all;
use surf.Pgp4Pkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;


library hps_daq;
use hps_daq.HpsPkg.all;

entity LdmxFebPgp is
   generic (
      TPD_G                : time                        := 1 ns;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_SIDEBAND_G : boolean                     := true;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 9000;
      AXIL_BASE_ADDR_G     : slv(31 downto 0)            := (others => '0');
      AXIL_CLK_FREQ_G      : real                        := 156.25e6);
   port (
      -- GT ports
      gtClkP           : in  sl;
      gtClkN           : in  sl;
      gtRxP            : in  sl;
      gtRxN            : in  sl;
      gtTxP            : out sl;
      gtTxN            : out sl;
      -- Reference clock output
      refClkOut        : out sl;
      refRstOut        : out sl;
      -- Output status
      rxLinkReady      : out sl;
      txLinkReady      : out sl;
      -- Timing clock and PGP triggers
      distClk          : in  sl;
      distRst          : in  sl;
      distOpCodeEn     : out sl;
      distOpCode       : out slv(7 downto 0);
      -- AXIL Interface (From SRP)
      axilClk          : in  sl;
      axilRst          : in  sl;
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;
      -- Slave AXIL interface for PGP and GTP
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Streaming data 
      dataClk          : in  sl;
      dataRst          : in  sl;
      dataAxisMaster   : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dataAxisSlave    : out AxiStreamSlaveType;
      dataAxisCtrl     : out AxiStreamCtrlType);

end LdmxFebPgp;

architecture rtl of LdmxFebPgp is

--   signal stableClk : sl;
--   signal stableRst : sl;
--   signal powerUpRst : sl;

   signal pgpClk       : sl;
   signal pgpRst       : sl;
   signal pgpTxMasters : AxiStreamMasterArray(1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlaves  : AxiStreamSlaveArray(1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpRxMasters : AxiStreamMasterArray(1 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxSlaves  : AxiStreamSlaveArray(1 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal pgpRxCtrl    : AxiStreamCtrlArray(1 downto 0)   := (others => AXI_STREAM_CTRL_INIT_C);
   signal pgpRxIn      : Pgp4RxInType                     := PGP4_RX_IN_INIT_C;
   signal pgpRxOut     : Pgp4RxOutType                    := PGP4_RX_OUT_INIT_C;
   signal pgpTxIn      : Pgp4TxInType                     := PGP4_TX_IN_INIT_C;
   signal pgpTxOut     : Pgp4TxOutType                    := PGP4_TX_OUT_INIT_C;

   signal refClk : sl;
   signal refRst : sl;
   signal ssiCmd : SsiCmdMasterType;

begin

   -- Map to signals out
   rxLinkReady <= pgpRxOut.linkReady;
   txLinkReady <= pgpTxOut.linkReady;

   distOpCodeEn <= ssiCmd.valid;
   distOpCode   <= ssiCmd.opCode;

   refClkOut <= refClk;
   U_RefRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G)
      port map (
         clk    => refClk,
         rstIn  => '0',
         rstOut => refRst);

   refRstOut <= refRst;

   -------------------------------
   --       PGP Core            --
   -------------------------------
   U_Pgp4GtyUsWrapper_1 : entity surf.Pgp4GtyUsWrapper
      generic map (
         TPD_G                       => TPD_G,
         ROGUE_SIM_EN_G              => ROGUE_SIM_EN_G,
         ROGUE_SIM_SIDEBAND_G        => ROGUE_SIM_SIDEBAND_G,
         ROGUE_SIM_PORT_NUM_G        => ROGUE_SIM_PORT_NUM_G,
         SYNTH_MODE_G                => "inferred",
         MEMORY_TYPE_G               => "block",
         NUM_LANES_G                 => 1,
         NUM_VC_G                    => 2,
         REFCLK_G                    => true,
         RATE_G                      => "10.3125Gbps",
         PGP_RX_ENABLE_G             => true,
         RX_ALIGN_SLIP_WAIT_G        => 32,      --default
         PGP_TX_ENABLE_G             => true,
--         TX_CELL_WORDS_MAX_G         => TX_CELL_WORDS_MAX_G,
         TX_MUX_ILEAVE_EN_G          => true,
         TX_MUX_ILEAVE_ON_NOTVALID_G => true,
         EN_PGP_MON_G                => true,
         EN_GTH_DRP_G                => true,
         EN_QPLL_DRP_G               => true,
         WRITE_EN_G                  => false,   -- On remote end of link
         AXIL_BASE_ADDR_G            => AXIL_BASE_ADDR_G,
         AXIL_CLK_FREQ_G             => AXIL_CLK_FREQ_G)
      port map (
         stableClk         => refClk,            -- [in]
         stableRst         => refRst,            -- [in]
         pgpGtTxP(0)       => gtTxP,             -- [out]
         pgpGtTxN(0)       => gtTxN,             -- [out]
         pgpGtRxP(0)       => gtRxP,             -- [in]
         pgpGtRxN(0)       => gtRxN,             -- [in]
         pgpRefClkP        => gtClkP,            -- [in]
         pgpRefClkN        => gtClkN,            -- [in]
--         pgpRefClkOut      => pgpRefClkOut,       -- [out]
         pgpRefClkDiv2Bufg => refClk,            -- [out]
         pgpClk(0)         => pgpClk,            -- [out]
         pgpClkRst(0)      => pgpRst,            -- [out]
         pgpRxIn(0)        => pgpRxIn,           -- [in]
         pgpRxOut(0)       => pgpRxOut,          -- [out]
         pgpTxIn(0)        => pgpTxIn,           -- [in]
         pgpTxOut(0)       => pgpTxOut,          -- [out]
         pgpTxMasters      => pgpTxMasters,      -- [in]
         pgpTxSlaves       => pgpTxSlaves,       -- [out]
         pgpRxMasters      => pgpRxMasters,      -- [out]
         pgpRxCtrl         => pgpRxCtrl,         -- [in]
         pgpRxSlaves       => pgpRxSlaves,       -- [in]
         axilClk           => axilClk,           -- [in]
         axilRst           => axilRst,           -- [in]
         axilReadMaster    => sAxilReadMaster,   -- [in]
         axilReadSlave     => sAxilReadSlave,    -- [out]
         axilWriteMaster   => sAxilWriteMaster,  -- [in]
         axilWriteSlave    => sAxilWriteSlave);  -- [out]


   pgpRxIn.resetRx  <= '0';
   pgpRxIn.loopback <= "000";


-- Lane 0, VC0 RX/TX, Register access control        
   U_Vc0AxiMasterRegisters : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => ROGUE_SIM_EN_G,
--          RESP_THOLD_G        => 1,
--          SLAVE_READY_EN_G    => false,
--          EN_32BIT_ADDR_G     => false,
--          USE_BUILT_IN_G      => false,
--          GEN_SYNC_FIFO_G     => false,
--          FIFO_ADDR_WIDTH_G   => 9,
--          FIFO_PAUSE_THRESH_G => 2**8,
         AXI_STREAM_CONFIG_G => PGP4_AXIS_CONFIG_C
         )
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain) 
         sAxisClk         => pgpClk,
         sAxisRst         => pgpRst,
         sAxisMaster      => pgpRxMasters(0),
         sAxisSlave       => pgpRxSlaves(0),
         sAxisCtrl        => pgpRxCtrl(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => pgpClk,
         mAxisRst         => pgpRst,
         mAxisMaster      => pgpTxMasters(0),
         mAxisSlave       => pgpTxSlaves(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axilClk          => pgpClk,
         axilRst          => pgpRst,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave);

   -- Lane 0, VC1 TX, streaming data out
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
         mAxisClk    => pgpClk,                     -- [in]
         mAxisRst    => pgpRst,                     -- [in]
         mAxisMaster => pgpTxMasters(1),            -- [out]
         mAxisSlave  => pgpTxSlaves(1));            -- [in]


   -- Lane 0, VC1 RX, Command processor
   U_Vc1SsiCmdMaster : entity surf.SsiCmdMaster
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         MEMORY_TYPE_G       => "distributed",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 4,
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 8,
         AXI_STREAM_CONFIG_G => PGP4_AXIS_CONFIG_C)
      port map (
         -- Streaming Data Interface
         axisClk     => pgpClk,
         axisRst     => pgpRst,
         sAxisMaster => pgpRxMasters(1),
         sAxisSlave  => pgpRxSlaves(1),
         sAxisCtrl   => pgpRxCtrl(1),
         -- Command signals
         cmdClk      => distClk,
         cmdRst      => distRst,
         cmdMaster   => ssiCmd);


end rtl;

