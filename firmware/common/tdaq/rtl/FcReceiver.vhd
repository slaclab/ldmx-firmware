-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : FebFcRx.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
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
use surf.Pgp2FcPkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;


entity FcReceiver is

   generic (
      TPD_G            : time                 := 1 ns;
      SIM_SPEEDUP_G    : boolean              := false;
      GT_TYPE_G        : string               := "GTY";  -- Or GTH
      NUM_VC_EN_G      : integer range 0 to 4 := 0;
      GEN_FC_EMU_G     : boolean              := true;
      AXIL_CLK_FREQ_G  : real                 := 156.25e6;
      AXIL_BASE_ADDR_G : slv(31 downto 0)     := (others => '0'));
   port (
      -- Reference clock
      fcRefClk185P : in  sl;
      fcRefClk185N : in  sl;
      fcRefClk185G : out sl;
      fcRefRst185  : out sl;
      -- Output Recovered Clock
      fcRecClkP    : out sl;
      fcRecClkN    : out sl;
      -- PGP serial IO
      fcTxP        : out sl;
      fcTxN        : out sl;
      fcRxP        : in  sl;
      fcRxN        : in  sl;
      -- Stable 156.25/2 MHz clock
      stableClk    : in  sl;
      stableRst    : in  sl;
      -- RX FC and PGP interface
      fcClk185     : out sl;
      fcRst185     : out sl;
      fcBus        : out FcBusType;
      fcBunchClk37 : out sl;
      fcBunchRst37 : out sl;
      pgpRxIn      : in  Pgp2fcRxInType                               := PGP2FC_RX_IN_INIT_C;
      pgpRxOut     : out Pgp2fcRxOutType;
      pgpRxMasters : out AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      pgpRxCtrl    : in  AxiStreamCtrlArray(3 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);
      -- Debugging interface
      fcRxMsgValid : out sl;

      -- TX FC and PGP interface
      txClk185     : out sl;
      txRst185     : out sl;
--      fcFb         : in  FcFeedbackType;
      pgpTxIn      : in  Pgp2fcTxInType                               := PGP2FC_TX_IN_INIT_C;
      pgpTxOut     : out Pgp2fcTxOutType;
      pgpTxMasters : in  AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
      pgpTxSlaves  : out AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_INIT_C);

      -- Axil inteface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FcReceiver;

architecture rtl of FcReceiver is

   -- AXI Lite
   constant NUM_AXIL_MASTERS_C : natural := 3;
   constant PGP_FC_LANE_AXIL_C : natural := 0;
   constant FC_RX_LOGIC_AXIL_C : natural := 1;
   constant FC_EMU_AXIL_C      : natural := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      PGP_FC_LANE_AXIL_C => (
         baseAddr        => AXIL_BASE_ADDR_G + X"0_0000",
         addrBits        => 16,
         connectivity    => X"FFFF"),
      FC_RX_LOGIC_AXIL_C => (
         baseAddr        => AXIL_BASE_ADDR_G + X"1_0000",
         addrBits        => 8,
         connectivity    => X"FFFF"),
      FC_EMU_AXIL_C      => (
         baseAddr        => AXIL_BASE_ADDR_G + X"2_0000",
         addrBits        => 8,
         connectivity    => X"FFFF"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   -- Clocks and resets
   signal pgpRefClk          : sl;      -- Refclk after buffering
   signal pgpUserRefClkOdiv2 : sl;      -- Refclk ODIV2
   signal pgpUserRefClk      : sl;      -- ODIV2+BUFG_GT - Used to clock TX
   signal pgpUserRefRst      : sl;
   signal fcClk185Loc        : sl;      -- Recovered RX clock for local use
   signal fcRst185Loc        : sl;
   signal pgpRxRecClk        : sl;

   -- PGP IO
   signal pgpRxInLoc  : Pgp2fcRxInType := PGP2FC_RX_IN_INIT_C;
   signal pgpRxOutLoc : Pgp2fcRxOutType := PGP2FC_RX_OUT_INIT_C;
   signal pgpTxInLoc  : Pgp2fcTxInType  := PGP2FC_TX_IN_INIT_C;
   signal pgpTxOutLoc : Pgp2fcTxOutType := PGP2FC_TX_OUT_INIT_C;

   -- Rx FC Word
   signal fcValid : sl;
   signal fcWord  : slv(FC_LEN_C-1 downto 0);

   -- Emulator
   signal fcEmuMsg     : FcMessageType;
   signal fcEmuEnabled : sl;

begin

   fcClk185 <= fcClk185Loc;
   fcRst185 <= fcRst185Loc;

   txClk185 <= pgpUserRefClk;
   txRst185 <= pgpUserRefRst;

   -- Eventually mix FC feedback in here
--   pgpTxInLoc <= pgpTxIn;
   pgpRxOut <= pgpRxOutLoc;

   fcRefClk185G <= pgpUserRefClk;
   fcRefRst185  <= pgpUserRefRst;

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Clock Input and Output Buffers
   -------------------------------------------------------------------------------------------------
   U_mgtRefClk : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => fcRefClk185P,
         IB    => fcRefClk185N,
         CEB   => '0',
         ODIV2 => pgpUserRefClkOdiv2,
         O     => pgpRefClk);

   U_mgtUserRefClk : BUFG_GT
      port map (
         I       => pgpUserRefClkOdiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",
         O       => pgpUserRefClk);

   -- Output recovered clock on gt clock pins
   -- Might need generic around this
   U_mgtRecClk : OBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH => '1',
         REFCLK_ICNTL_TX   => "00000")
      port map (
         O   => fcRecClkP,
         OB  => fcRecClkN,
         CEB => '0',
         I   => pgpRxRecClk); -- using rxRecClk from Channel=0

   -------------------------------------------------------------------------------------------------
   -- Create a reset for pgpUserRefClk
   -------------------------------------------------------------------------------------------------
--       PwrUpRst_1 : entity surf.PwrUpRst
--          generic map (
--             TPD_G          => TPD_G,
--             SIM_SPEEDUP_G  => true,
--             IN_POLARITY_G  => '1',
--             OUT_POLARITY_G => '1')
--          port map (
--             clk    => pgpUserRefClk,
--             rstOut => pgpUserRefRst);

   RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => pgpUserRefClk,
         asyncRst => '0',
         syncRst  => pgpUserRefRst);


   -------------------------------------------------------------------------------------------------
   -- LDMX FC PGP LANE
   -------------------------------------------------------------------------------------------------
   U_LdmxPgpFcLane_1 : entity ldmx_tdaq.LdmxPgpFcLane
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         GT_TYPE_G        => GT_TYPE_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(PGP_FC_LANE_AXIL_C).baseAddr,
         TX_ENABLE_G      => true,
         RX_ENABLE_G      => true,
         NUM_VC_EN_G      => NUM_VC_EN_G,
         RX_CLK_MMCM_G    => true)
      port map (
         pgpTxP           => fcTxP,                                    -- [out]
         pgpTxN           => fcTxN,                                    -- [out]
         pgpRxP           => fcRxP,                                    -- [in]
         pgpRxN           => fcRxN,                                    -- [in]
         pgpRefClk        => pgpRefClk,                                -- [in]
         pgpUserRefClk    => pgpUserRefClk,                            -- [in]
         pgpRxRecClk      => pgpRxRecClk,                              -- [out]
         pgpUserStableClk => stableClk,                                -- [in]
         pgpUserStableRst => stableRst,                                -- [in]
         pgpRxRstOut      => fcRst185Loc,                              -- [out]
         pgpRxOutClk      => fcClk185Loc,                              -- [out]
         pgpRxIn          => pgpRxInLoc,                               -- [in]
         pgpRxOut         => pgpRxOutLoc,                              -- [out]
         pgpRxMasters     => pgpRxMasters,                             -- [out]
         pgpRxCtrl        => pgpRxCtrl,                                -- [in]
         pgpTxRst         => pgpUserRefRst,                            -- [in]
         pgpTxOutClk      => open,                                     -- [out]
         pgpTxUsrClk      => pgpUserRefClk,                            -- [in]
         pgpTxIn          => pgpTxInLoc,                               -- [in]
         pgpTxOut         => pgpTxOutLoc,                              -- [out]
         pgpTxMasters     => pgpTxMasters,                             -- [in]
         pgpTxSlaves      => pgpTxSlaves,                              -- [out]
         axilClk          => axilClk,                                  -- [in]
         axilRst          => axilRst,                                  -- [in]
         axilReadMaster   => locAxilReadMasters(PGP_FC_LANE_AXIL_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(PGP_FC_LANE_AXIL_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(PGP_FC_LANE_AXIL_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(PGP_FC_LANE_AXIL_C));  -- [out]


   -------------------------------------------------------------------------------------------------
   -- Timing and Fast Control Receiver Logic
   -- Decode Fast Control words and track run state
   -------------------------------------------------------------------------------------------------
   fcValid <= pgpRxOutLoc.fcValid;
   fcWord  <= pgpRxOutLoc.fcWord(FC_LEN_C-1 downto 0);
   U_FcRxLogic_1 : entity ldmx_tdaq.FcRxLogic
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


   -------------------------------------------------------------------------------------------------
   -- FC Emulator Drives TX
   -- Activated when PGP GT placed in loopback mode
   -------------------------------------------------------------------------------------------------
   GEN_FC_EMU : if (GEN_FC_EMU_G) generate
      U_FcEmu_1 : entity ldmx_tdaq.FcEmu
         generic map (
            TPD_G                => TPD_G,
            AXIL_CLK_IS_FC_CLK_G => false,
            TIMING_MSG_PERIOD_G  => 200,
            BUNCH_COUNT_PERIOD_G => 5)
         port map (
            fcClk           => pgpUserRefClk,                       -- [in]
            fcRst           => pgpUserRefRst,                       -- [in]
            enabled         => fcEmuEnabled,                        -- [out]
            fcMsg           => fcEmuMsg,                            -- [out]
            bunchClk        => open,                                -- [out]
            bunchStrobe     => open,                                -- [out]
            axilClk         => axilClk,                             -- [in]
            axilRst         => axilRst,                             -- [in]
            axilReadMaster  => locAxilReadMasters(FC_EMU_AXIL_C),   -- [in]
            axilReadSlave   => locAxilReadSlaves(FC_EMU_AXIL_C),    -- [out]
            axilWriteMaster => locAxilWriteMasters(FC_EMU_AXIL_C),  -- [in]
            axilWriteSlave  => locAxilWriteSlaves(FC_EMU_AXIL_C));  -- [out]

      FC_EMU_GLUE : process (fcEmuEnabled, fcEmuMsg, pgpRxIn, pgpTxIn) is
         variable pgpTxInVar : Pgp2fcTxInType;
         variable pgpRxInVar : Pgp2fcRxInType;
      begin
         pgpRxInVar := pgpRxIn;
         pgpTxInVar := pgpTxIn;

         if (fcEmuEnabled = '1') then

            -- Drive near-end PMA loopback
            pgpRxInVar.loopback := "010";

            -- Send FcEmu messages on TX
            pgpTxInVar.fcValid                     := fcEmuMsg.valid;
            pgpTxInVar.fcWord(FC_LEN_C-1 downto 0) := fcEmuMsg.message;

         else
            pgpRxInVar.loopback := "000";
            pgpTxInVar.fcValid  := '0';
            pgpTxInVar.fcWord   := (others => '0');

         end if;
         pgpTxInLoc <= pgpTxInVar;
         pgpRxInLoc <= pgpRxInVar;
      end process FC_EMU_GLUE;
   end generate GEN_FC_EMU;

   pgpTxOut <= pgpTxOutLoc;

--   pgpTxIn.locData(0) <= fcFb.busy;

   -------------------------------------------------------------------------------------------------
   -- Debugging
   -------------------------------------------------------------------------------------------------
   U_StretchDbgRorTx : entity surf.SynchronizerOneShot
      generic map (
         TPD_G         => TPD_G,
         PULSE_WIDTH_G => 10)
      port map (
         clk     => fcClk185Loc,
         dataIn  => fcValid,
         dataOut => fcRxMsgValid);

end architecture rtl;
