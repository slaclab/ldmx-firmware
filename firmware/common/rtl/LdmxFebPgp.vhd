-------------------------------------------------------------------------------
-- Title      : LDMX FEB PGP
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: PGP block for LDMX Tracker FEB
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
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
use surf.Pgp2FcPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.LdmxPkg.all;
use ldmx.FcPkg.all;

entity LdmxFebPgp is
   generic (
      TPD_G                : time                        := 1 ns;
      SIM_SPEEDUP_G        : boolean                     := false;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_SIDEBAND_G : boolean                     := true;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 9000;
      AXIL_BASE_ADDR_G     : slv(31 downto 0)            := (others => '0');
      AXIL_CLK_FREQ_G      : real                        := 125.0e6);
   port (
      -- Reference clocks for PGP MGTs
      gtRefClk185P : in sl;
      gtRefClk185N : in sl;

      userRefClk185 : out sl;
      userRefRst185 : out sl;

      -- MGT IO
      pgpGtTxP : out sl;
      pgpGtTxN : out sl;
      pgpGtRxP : in  sl;
      pgpGtRxN : in  sl;

      -- Status output for LEDs
      pgpTxLink : out sl;
      pgpRxLink : out sl;

      -- Control link Opcode and AXI-Stream interface
      fcClk185     : out sl;            -- Recovered fixed-latency clock
      fcRst185     : out sl;
      fcBus        : out FastControlBusType;
      fcBunchClk37 : out sl;
      fcBunchRst37 : out sl;

      -- All AXI-Lite and AXI-Stream interfaces are synchronous with this clock
      axilClk : in sl;                  -- Also Drives PGP stableClk input
      axilRst : in sl;

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

      -- Waveform capture stream
      waveformAxisMaster : in  AxiStreamMasterType;
      waveformAxisSlave  : out AxiStreamSlaveType;

      -- Streaming data
      dataClk        : in  sl;
      dataRst        : in  sl;
      dataAxisMaster : in  AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
      dataAxisSlave  : out AxiStreamSlaveType;
      dataAxisCtrl   : out AxiStreamCtrlType);

end LdmxFebPgp;

architecture rtl of LdmxFebPgp is

   -------------------------------------------------------------------------------------------------
   -- Clocks
   -------------------------------------------------------------------------------------------------
   signal gtRefClk185Div2 : sl := '0';
   signal gtRefClk185G    : sl := '0';

   -------------------------------------------------------------------------------------------------
   -- PGP
   -------------------------------------------------------------------------------------------------
   constant NUM_AXIL_C  : integer := 3;
   constant FC_INDEX_C  : integer := 0;
   constant SIM_INDEX_C : integer := 1;
   constant FC_RX_LOGIC_AXIL_C : integer := 2;


   -- PGP FC Rx signals
   signal fcClk185Loc  : sl;
   signal fcRst185Loc  : sl;
   signal pgpRxIn      : Pgp2fcRxInType                   := PGP2FC_RX_IN_INIT_C;
   signal pgpRxOut     : Pgp2fcRxOutType                  := PGP2FC_RX_OUT_INIT_C;
   signal pgpRxMasters : AxiStreamMasterArray(2 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxCtrl    : AxiStreamCtrlArray(2 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);
   signal pgpRxSlaves  : AxiStreamSlaveArray(2 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal pgpTxClk     : sl;
   signal pgpTxRst     : sl;
   signal pgpTxIn      : Pgp2fcTxInType                   := PGP2FC_TX_IN_INIT_C;
   signal pgpTxOut     : Pgp2fcTxOutType                  := PGP2FC_TX_OUT_INIT_C;
   signal pgpTxMasters : AxiStreamMasterArray(2 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlaves  : AxiStreamSlaveArray(2 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal buffDataAxisMaster : AxiStreamMasterType;
   signal buffDataAxisSlave  : AxiStreamSlaveType;

   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------
   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_C, AXIL_BASE_ADDR_G, 24, 20);

   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   -------------------------------------------------------------------------------------------------
   -- Emulated Fast control for simulation
   -------------------------------------------------------------------------------------------------
   signal fcEmuMsg : FastControlMessageType;
   signal fcValid  : sl;
   signal fcWord   : slv(FC_LEN_C-1 downto 0);

begin

   fcClk185 <= fcClk185Loc;
   fcRst185 <= fcRst185Loc;


   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_MAIN_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => sAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   pgpTxLink <= pgpTxOut.linkReady;
   pgpRxLink <= pgpRxOut.linkReady;


   NO_SIM : if (not ROGUE_SIM_EN_G) generate

      U_FcReceiver_1 : entity ldmx.FcReceiver
         generic map (
            TPD_G            => TPD_G,
            SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
            NUM_VC_EN_G      => 3,
            GEN_FC_EMU_G     => false,
            AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
            AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(FC_INDEX_C).baseAddr)
         port map (
            fcRefClk185P    => gtRefClk185P,                     -- [in]
            fcRefClk185N    => gtRefClk185N,                     -- [in]
            fcRecClkP       => open,                             -- [out]
            fcRecClkN       => open,                             -- [out]
            fcTxP           => pgpGtTxP,                         -- [out]
            fcTxN           => pgpGtTxN,                         -- [out]
            fcRxP           => pgpGtRxP,                         -- [in]
            fcRxN           => pgpGtRxN,                         -- [in]
            fcClk185        => fcClk185Loc,                      -- [out]
            fcRst185        => fcRst185Loc,                      -- [out]
            fcBus           => fcBus,                            -- [out]
            fcBunchClk37    => fcBunchClk37,                     -- [out]
            fcBunchRst37    => fcBunchRst37,                     -- [out]
            pgpRxIn         => pgpRxIn,                          -- [in]
            pgpRxOut        => pgpRxOut,                         -- [out]
            pgpRxMasters    => pgpRxMasters,                     -- [out]
            pgpRxCtrl       => pgpRxCtrl,                        -- [in]
            txClk185        => pgpTxClk,                         -- [out]
            txRst185        => pgpTxRst,                         -- [out]
--            fcFb            => fcFb,                             -- [in]
            pgpTxIn         => pgpTxIn,                          -- [in]
            pgpTxOut        => pgpTxOut,                         -- [out]
            pgpTxMasters    => pgpTxMasters,                     -- [in]
            pgpTxSlaves     => pgpTxSlaves,                      -- [out]
            axilClk         => axilClk,                          -- [in]
            axilRst         => axilRst,                          -- [in]
            axilReadMaster  => locAxilReadMasters(FC_INDEX_C),   -- [in]
            axilReadSlave   => locAxilReadSlaves(FC_INDEX_C),    -- [out]
            axilWriteMaster => locAxilWriteMasters(FC_INDEX_C),  -- [in]
            axilWriteSlave  => locAxilWriteSlaves(FC_INDEX_C));  -- [out]

   end generate NO_SIM;

   GEN_SIM : if (ROGUE_SIM_EN_G) generate

      U_mgtRefClk : IBUFDS_GTE4
         generic map (
            REFCLK_EN_TX_PATH  => '0',
            REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
            REFCLK_ICNTL_RX    => "00")
         port map (
            I     => gtRefClk185P,
            IB    => gtRefClk185N,
            CEB   => '0',
            ODIV2 => gtRefClk185Div2,
            O     => open);

      U_mgtUserRefClk : BUFG_GT
         port map (
            I       => gtRefClk185Div2,
            CE      => '1',
            CEMASK  => '1',
            CLR     => '0',
            CLRMASK => '1',
            DIV     => "000",
            O       => gtRefClk185G);

      pgpTxClk <= gtRefClk185G;

      PwrUpRst_1 : entity surf.PwrUpRst
         generic map (
            TPD_G          => TPD_G,
            SIM_SPEEDUP_G  => true,
            IN_POLARITY_G  => '1',
            OUT_POLARITY_G => '1')
         port map (
            clk    => pgpTxClk,
            rstOut => pgpTxRst);

      fcClk185Loc <= transport pgpTxClk after 1 ns;
      fcRst185Loc <= transport pgpTxRst after 1 ns;

      U_RoguePgp2fcSim_1 : entity surf.RoguePgp2fcSim
         generic map (
            TPD_G      => TPD_G,
            FC_WORDS_G => 5,
            PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
            NUM_VC_G   => 3)
         port map (
            pgpClk       => pgpTxClk,                  -- [in]
            pgpClkRst    => pgpTxRst,                  -- [in]
            pgpRxIn      => pgpRxIn,                   -- [in]
            pgpRxOut     => pgpRxOut,                  -- [out]
            pgpTxIn      => pgpTxIn,                   -- [in]
            pgpTxOut     => pgpTxOut,                  -- [out]
            pgpTxMasters => pgpTxMasters(2 downto 0),  -- [in]
            pgpTxSlaves  => pgpTxSlaves(2 downto 0),   -- [out]
            pgpRxMasters => pgpRxMasters(2 downto 0),  -- [out]
            pgpRxSlaves  => pgpRxSlaves(2 downto 0));  -- [in]

--       DAQ_CLK_GEN : entity surf.ClkRst
--          generic map (
--             CLK_PERIOD_G      => 5.385 ns,
--             CLK_DELAY_G       => 1 ns,
--             RST_START_DELAY_G => 0 ns,
--             RST_HOLD_TIME_G   => 5 us,
--             SYNC_RESET_G      => true)
--          port map (
--             clkP => fcClk185Tmp,
--             rst  => fcRst185Tmp);

--       fcClk185 <= fcClk185Tmp;
--       fcRst185 <= fcRst185Tmp;

      U_FcEmu_1 : entity ldmx.FcEmu
         generic map (
            TPD_G                => TPD_G,
            AXIL_CLK_IS_FC_CLK_G => false)
         port map (
            fcClk           => fcClk185Loc,                       -- [in]
            fcRst           => fcRst185Loc,                       -- [in]
            fcMsg           => fcEmuMsg,                          -- [out]
            bunchClk        => open,                              -- [out]
            bunchStrobe     => open,                              -- [out]
            axilClk         => axilClk,                           -- [in]
            axilRst         => axilRst,                           -- [in]
            axilReadMaster  => locAxilReadMasters(SIM_INDEX_C),   -- [in]
            axilReadSlave   => locAxilReadSlaves(SIM_INDEX_C),    -- [out]
            axilWriteMaster => locAxilWriteMasters(SIM_INDEX_C),  -- [in]
            axilWriteSlave  => locAxilWriteSlaves(SIM_INDEX_C));  -- [out]

      fcValid <= fcEmuMsg.valid;
      fcWord  <= fcEmuMsg.message;
      U_FcRxLogic_1 : entity ldmx.FcRxLogic
         generic map (
            TPD_G => TPD_G)
         port map (
            fcClk185        => fcClk185Loc,                              -- [in]
            fcRst185        => fcRst185Loc,                              -- [in]
            fcValid         => fcValid,                                  -- [in]
            fcWord          => fcWord,                                   -- [in]
            fcBunchClk37    => fcBunchClk37,                             -- [out]
            fcBunchRst37    => fcBunchRst37,                             -- [out]
            fcBus           => fcBus,                                    -- [out]
            axilClk         => axilClk,                                  -- [in]
            axilRst         => axilRst,                                  -- [in]
            axilReadMaster  => locAxilReadMasters(FC_RX_LOGIC_AXIL_C),   -- [in]
            axilReadSlave   => locAxilReadSlaves(FC_RX_LOGIC_AXIL_C),    -- [out]
            axilWriteMaster => locAxilWriteMasters(FC_RX_LOGIC_AXIL_C),  -- [in]
            axilWriteSlave  => locAxilWriteSlaves(FC_RX_LOGIC_AXIL_C));  -- [out]
--       daqRxFcWord  <= pgpRxOut(0).fcWord(79 downto 0);
--       daqRxFcValid <= pgpRxOut(0).fcValid;


   end generate GEN_SIM;


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
         AXI_STREAM_CONFIG_G => PGP2FC_AXIS_CONFIG_C
         )
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain)
         sAxisClk         => fcClk185Loc,
         sAxisRst         => fcRst185Loc,
         sAxisMaster      => pgpRxMasters(0),
         sAxisSlave       => pgpRxSlaves(0),
         sAxisCtrl        => pgpRxCtrl(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => pgpTxClk,
         mAxisRst         => pgpTxRst,
         mAxisMaster      => pgpTxMasters(0),
         mAxisSlave       => pgpTxSlaves(0),
         -- AXI Lite Bus (axiLiteClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave);

   -- VC1 TX, streaming data out
   -- Large synchronous FIFO to buffer data
   U_AxiStreamFifoV2_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G                  => TPD_G,
         INT_PIPE_STAGES_G      => 1,
         PIPE_STAGES_G          => 1,
         SLAVE_READY_EN_G       => false,    -- Always use ctrl to EventBuilder
         VALID_THOLD_G          => 1,
         VALID_BURST_MODE_G     => false,
--         SYNTH_MODE_G           => "xpm",
         MEMORY_TYPE_G          => "block",
         GEN_SYNC_FIFO_G        => true,
         CASCADE_SIZE_G         => 1,
         CASCADE_PAUSE_SEL_G    => 0,
         FIFO_ADDR_WIDTH_G      => 13,
         FIFO_FIXED_THRESH_G    => true,
         FIFO_PAUSE_THRESH_G    => 2**13-8,
         INT_WIDTH_SELECT_G     => "WIDE",
--         INT_DATA_WIDTH_G       => INT_DATA_WIDTH_G,
         LAST_FIFO_ADDR_WIDTH_G => 0,
         SLAVE_AXI_CONFIG_G     => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G    => EVENT_SSI_CONFIG_C)
      port map (
         sAxisClk    => dataClk,             -- [in]
         sAxisRst    => dataRst,             -- [in]
         sAxisMaster => dataAxisMaster,      -- [in]
         sAxisSlave  => dataAxisSlave,       -- [out]
         sAxisCtrl   => dataAxisCtrl,        -- [out]
         mAxisClk    => dataClk,             -- [in]
         mAxisRst    => dataRst,             -- [in]
         mAxisMaster => buffDataAxisMaster,  -- [out]
         mAxisSlave  => buffDataAxisSlave);  -- [in]

   -- Small async fifo to transition to PGPFC clock
   -- and word size
   U_AxiStreamFifoV2_2 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G                  => TPD_G,
         INT_PIPE_STAGES_G      => 1,
         PIPE_STAGES_G          => 1,
         SLAVE_READY_EN_G       => true,
         VALID_THOLD_G          => 1,
         VALID_BURST_MODE_G     => false,
--         SYNTH_MODE_G           => "xpm",
         MEMORY_TYPE_G          => "distributed",
         GEN_SYNC_FIFO_G        => false,
         CASCADE_SIZE_G         => 1,
         CASCADE_PAUSE_SEL_G    => 0,
         FIFO_ADDR_WIDTH_G      => 5,
         INT_WIDTH_SELECT_G     => "WIDE",
         LAST_FIFO_ADDR_WIDTH_G => 0,
         SLAVE_AXI_CONFIG_G     => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => dataClk,             -- [in]
         sAxisRst    => dataRst,             -- [in]
         sAxisMaster => buffDataAxisMaster,  -- [in]
         sAxisSlave  => buffDataAxisSlave,   -- [out]
         mAxisClk    => pgpTxClk,            -- [in]
         mAxisRst    => pgpTxRst,            -- [in]
         mAxisMaster => pgpTxMasters(1),     -- [out]
         mAxisSlave  => pgpTxSlaves(1));     -- [in]


   -- Small async fifo to transition to PGPFC clock
   U_AxiStreamFifoV2_WAVEFORM : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G                  => TPD_G,
         INT_PIPE_STAGES_G      => 1,
         PIPE_STAGES_G          => 1,
         SLAVE_READY_EN_G       => true,
         VALID_THOLD_G          => 1,
         VALID_BURST_MODE_G     => false,
--         SYNTH_MODE_G           => "xpm",
         MEMORY_TYPE_G          => "distributed",
         GEN_SYNC_FIFO_G        => false,
         CASCADE_SIZE_G         => 1,
         CASCADE_PAUSE_SEL_G    => 0,
         FIFO_ADDR_WIDTH_G      => 4,
         INT_WIDTH_SELECT_G     => "WIDE",
         LAST_FIFO_ADDR_WIDTH_G => 0,
         SLAVE_AXI_CONFIG_G     => PGP2FC_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G    => PGP2FC_AXIS_CONFIG_C)
      port map (
         sAxisClk    => axilClk,             -- [in]
         sAxisRst    => axilRst,             -- [in]
         sAxisMaster => waveformAxisMaster,  -- [in]
         sAxisSlave  => waveformAxisSlave,   -- [out]
         mAxisClk    => pgpTxClk,            -- [in]
         mAxisRst    => pgpTxRst,            -- [in]
         mAxisMaster => pgpTxMasters(2),     -- [out]
         mAxisSlave  => pgpTxSlaves(2));     -- [in]


end rtl;
