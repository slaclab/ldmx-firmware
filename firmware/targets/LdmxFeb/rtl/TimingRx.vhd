-------------------------------------------------------------------------------
-- File       : TimingRx.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- This file is part of LCLS2 PGP Firmware Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LCLS2 PGP Firmware Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library l2si_core;
use l2si_core.L2SiPkg.all;

library lcls2_pgp_fw_lib;

entity TimingRx is
   generic (
      TPD_G             : time    := 1 ns;
      SIMULATION_G      : boolean := false;
      BYP_GT_SIM_G      : boolean := false;
      AXIL_CLK_FREQ_G   : real    := 156.25E+6;  -- units of Hz
      DMA_AXIS_CONFIG_G : AxiStreamConfigType;
      AXI_BASE_ADDR_G   : slv(31 downto 0));
   port (
      timingRxClkOut : out sl;
      timingRxRstOut : out sl;

      -- Trigger Interface
      triggerClk  : in  sl;
      triggerRst  : in  sl;
      triggerData : out TriggerEventDataArray(NUM_DETECTORS_G-1 downto 0);

      -- L1 trigger feedback (optional)
      l1Clk                 : in  sl                                                 := '0';
      l1Rst                 : in  sl                                                 := '0';
      l1Feedbacks           : in  TriggerL1FeedbackArray(NUM_DETECTORS_G-1 downto 0) := (others => TRIGGER_L1_FEEDBACK_INIT_C);
      l1Acks                : out slv(NUM_DETECTORS_G-1 downto 0);
      -- Event streams
      eventClk              : in  sl;
      eventRst              : in  sl;
      eventTrigMsgMasters   : out AxiStreamMasterArray(NUM_DETECTORS_G-1 downto 0);
      eventTrigMsgSlaves    : in  AxiStreamSlaveArray(NUM_DETECTORS_G-1 downto 0);
      eventTrigMsgCtrl      : in  AxiStreamCtrlArray(NUM_DETECTORS_G-1 downto 0);
      eventTimingMsgMasters : out AxiStreamMasterArray(NUM_DETECTORS_G-1 downto 0);
      eventTimingMsgSlaves  : in  AxiStreamSlaveArray(NUM_DETECTORS_G-1 downto 0);
      clearReadout          : out slv(NUM_DETECTORS_G-1 downto 0)                    := (others => '0');
      -- AXI-Lite Interface
      axilClk               : in  sl;
      axilRst               : in  sl;
      axilReadMaster        : in  AxiLiteReadMasterType;
      axilReadSlave         : out AxiLiteReadSlaveType;
      axilWriteMaster       : in  AxiLiteWriteMasterType;
      axilWriteSlave        : out AxiLiteWriteSlaveType;
      -- GT Serial Ports
      refClkP               : in  slv(1 downto 0)                                    := "00";  -- USE_GT_REFCLK_G = TRUE
      refClkN               : in  slv(1 downto 0)                                    := "11";  -- USE_GT_REFCLK_G = TRUE
      timingRxP             : in  slv(1 downto 0);
      timingRxN             : in  slv(1 downto 0);
      timingTxP             : out slv(1 downto 0);
      timingTxN             : out slv(1 downto 0));
end TimingRx;

architecture mapping of TimingRx is

   constant NUM_AXIL_MASTERS_C : positive := 6;

   constant RX_PHY0_INDEX_C  : natural := 0;
   constant RX_PHY1_INDEX_C  : natural := 1;
   constant MON_INDEX_C      : natural := 2;
   constant TIMING_INDEX_C   : natural := 3;
   constant XPM_MINI_INDEX_C : natural := 4;
   constant TEM_INDEX_C      : natural := 5;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      RX_PHY0_INDEX_C  => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0000_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      RX_PHY1_INDEX_C  => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0001_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      MON_INDEX_C      => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0002_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      XPM_MINI_INDEX_C => (
         baseAddr      => (AXI_BASE_ADDR_G+X"0003_0000"),
         addrBits      => 16,
         connectivity  => X"FFFF"),
      TEM_INDEX_C      => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0004_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      TIMING_INDEX_C   => (
         baseAddr      => (AXI_BASE_ADDR_G+x"0008_0000"),
         addrBits      => 18,
         connectivity  => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal initReadMaster  : AxiLiteReadMasterType;
   signal initReadSlave   : AxiLiteReadSlaveType;
   signal initWriteMaster : AxiLiteWriteMasterType;
   signal initWriteSlave  : AxiLiteWriteSlaveType;

   signal mmcmRst      : sl;
   signal gtediv2      : sl;
   signal refClk       : sl;
   signal refClkDiv2   : sl;
   signal refRst       : sl;
   signal refRstDiv2   : sl;
   signal mmcmLocked   : sl;
   signal timingClkSel : sl;
   signal useMiniTpg   : sl;
   signal loopback     : slv(2 downto 0);

   signal rxUserRst       : sl;
   signal gtRxOutClk      : sl;
   signal gtRxClk         : sl;
   signal timingRxClk     : sl;
   signal timingRxRst     : sl;
   signal timingRxRstTmp  : sl;
   signal gtRxData        : Slv16Array(1 downto 0);
   signal rxData          : slv(15 downto 0);
   signal gtRxDataK       : Slv2Array(1 downto 0);
   signal rxDataK         : slv(1 downto 0);
   signal gtRxDispErr     : Slv2Array(1 downto 0);
   signal rxDispErr       : slv(1 downto 0);
   signal gtRxDecErr      : Slv2Array(1 downto 0);
   signal rxDecErr        : slv(1 downto 0);
   signal gtRxStatus      : TimingPhyStatusArray(1 downto 0);
   signal rxStatus        : TimingPhyStatusType;
   signal timingRxControl : TimingPhyControlType;
   signal gtRxControl     : TimingPhyControlType;

   signal txUserRst     : sl;
   signal gtTxOutClk    : slv(1 downto 0);
   signal gtTxClk       : slv(1 downto 0);
   signal timingTxClk   : sl;
   signal timingTxRst   : sl;
--   signal txStatus   : TimingPhyStatusType := TIMING_PHY_STATUS_FORCE_C;
   signal gtTxStatus    : TimingPhyStatusArray(1 downto 0);
   signal gtTxControl   : TimingPhyControlType;
   signal txPhyReset    : sl;
   signal txPhyPllReset : sl;

   signal tpgMiniStreamTimingPhy : TimingPhyType;
   signal xpmMiniTimingPhy       : TimingPhyType;
   signal appTimingBus           : TimingBusType;
   signal appTimingMode          : sl;

   -----------------------------------------------
   -- Event Header Cache signals
   -----------------------------------------------
   signal temTimingTxPhy : TimingPhyType;

   signal eventTimingMessagesValid : slv(NUM_DETECTORS_G-1 downto 0);
   signal eventTimingMessages      : TimingMessageArray(NUM_DETECTORS_G-1 downto 0);
   signal eventTimingMessagesRd    : slv(NUM_DETECTORS_G-1 downto 0);

begin

   timingTxRst    <= txUserRst;
   timingRxRstTmp <= rxUserRst or not rxStatus.resetDone;

   U_RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => timingRxClk,       -- [in]
         asyncRst => timingRxRstTmp,    -- [in]
         syncRst  => timingRxRst);      -- [out]


   U_IBUFDS_GTE3 : IBUFDS_GTE3
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",    -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => refClkP,
         IB    => refClkN,
         CEB   => '0',
         ODIV2 => gtediv2,
         O     => open);

   U_BUFG_GT : BUFG_GT
      port map (
         I       => gtediv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => refClk);

   U_RstSync : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => refClk,
         asyncRst => mmcmRst,
         syncRst  => refRst);

   mmcmLocked <= not(refRst);


   -----------------------------------------------
   -- Power Up Initialization of the Timing RX PHY
   -----------------------------------------------
   U_TimingPhyInit : entity lcls2_pgp_fw_lib.TimingPhyInit
      generic map (
         TPD_G              => TPD_G,
         SIMULATION_G       => SIMULATION_G,
         TIMING_BASE_ADDR_G => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr,
         AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
         mmcmLocked       => mmcmLocked,
         -- AXI-Lite Register Interface (sysClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilReadMaster  => initReadMaster,
         mAxilReadSlave   => initReadSlave,
         mAxilWriteMaster => initWriteMaster,
         mAxilWriteSlave  => initWriteSlave);

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 2,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteMasters(1) => initWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiWriteSlaves(1)  => initWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadMasters(1)  => initReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         sAxiReadSlaves(1)   => initReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   -------------
   -- GTH Module
   -------------
   GEN_VEC : for i in 1 downto 0 generate

      U_refClkDiv2 : BUFGCE_DIV
         generic map (
            BUFGCE_DIVIDE => 2)
         port map (
            I   => refClk(i),
            CE  => '1',
            CLR => '0',
            O   => refClkDiv2(i));

      U_refRstDiv2 : entity surf.RstSync
         generic map (
            TPD_G => TPD_G)
         port map (
            clk      => refClkDiv2(i),
            asyncRst => refRst(i),
            syncRst  => refRstDiv2(i));

      U_RXCLK : BUFGMUX
         generic map (
            CLK_SEL_TYPE => "ASYNC")    -- ASYNC, SYNC
         port map (
            O  => gtRxClk(i),           -- 1-bit output: Clock output
            I0 => gtRxOutClk(i),        -- 1-bit input: Clock input (S=0)
            I1 => refClkDiv2(i),        -- 1-bit input: Clock input (S=1)
            S  => useMiniTpg);          -- 1-bit input: Clock select
      --
      U_TXCLK : BUFGMUX
         generic map (
            CLK_SEL_TYPE => "ASYNC")    -- ASYNC, SYNC
         port map (
            O  => gtTxClk(i),           -- 1-bit output: Clock output
            I0 => gtTxOutClk(i),        -- 1-bit input: Clock input (S=0)
            I1 => refClkDiv2(i),        -- 1-bit input: Clock input (S=1)
            S  => useMiniTpg);          -- 1-bit input: Clock select
      --

      REAL_PCIE : if (not BYP_GT_SIM_G) generate
         U_GTH : entity lcls_timing_core.TimingGtCoreWrapper
            generic map (
               TPD_G            => TPD_G,
               EXTREF_G         => false,
               AXIL_BASE_ADDR_G => AXIL_CONFIG_C(RX_PHY0_INDEX_C+i).baseAddr,
               ADDR_BITS_G      => 12,
               GTH_DRP_OFFSET_G => x"00001000")
            port map (
               -- AXI-Lite Port
               axilClk         => axilClk,
               axilRst         => axilRst,
               axilReadMaster  => axilReadMasters(RX_PHY0_INDEX_C+i),
               axilReadSlave   => axilReadSlaves(RX_PHY0_INDEX_C+i),
               axilWriteMaster => axilWriteMasters(RX_PHY0_INDEX_C+i),
               axilWriteSlave  => axilWriteSlaves(RX_PHY0_INDEX_C+i),
               stableClk       => axilClk,
               stableRst       => axilRst,
               -- GTH FPGA IO
               gtRefClk        => '0',          -- Using GTGREFCLK instead
               gtRefClkDiv2    => refClkDiv2(i),
               gtRxP           => timingRxP(i),
               gtRxN           => timingRxN(i),
               gtTxP           => timingTxP(i),
               gtTxN           => timingTxN(i),
               -- GTGREFCLK Interface Option
               gtgRefClk       => refClk(i),
               cpllRefClkSel   => "111",
               -- Rx ports
               rxControl       => gtRxControl,
               rxStatus        => gtRxStatus(i),
               rxUsrClkActive  => mmcmLocked(i),
               rxUsrClk        => timingRxClk,
               rxData          => gtRxData(i),
               rxDataK         => gtRxDataK(i),
               rxDispErr       => gtRxDispErr(i),
               rxDecErr        => gtRxDecErr(i),
               rxOutClk        => gtRxOutClk(i),
               -- Tx Ports
               txControl       => gtTxControl,  --temTimingTxPhy.control,
               txStatus        => gtTxStatus(i),
               txUsrClk        => gtTxOutClk(i),
               txUsrClkActive  => mmcmLocked(i),
               txData          => temTimingTxPhy.data,
               txDataK         => temTimingTxPhy.dataK,
               txOutClk        => gtTxOutClk(i),
               -- Misc.
               loopback        => loopback);
      end generate;


      SIM_PCIE : if (BYP_GT_SIM_G) generate

         axilReadSlaves(RX_PHY0_INDEX_C+i)  <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
         axilWriteSlaves(RX_PHY0_INDEX_C+i) <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;

         gtRxOutClk(i) <= refClkDiv2(i);
         gtTxOutClk(i) <= refClkDiv2(i);

         gtTxStatus(i)  <= TIMING_PHY_STATUS_FORCE_C;
         gtRxStatus(i)  <= TIMING_PHY_STATUS_FORCE_C;
         gtRxData(i)    <= (others => '0');  --temTimingTxPhy.data;
         gtRxDataK(i)   <= (others => '0');  --temTimingTxPhy.dataK;
         gtRxDispErr(i) <= "00";
         gtRxDecErr(i)  <= "00";

      end generate;
   end generate GEN_VEC;

   process(timingRxClk)
   begin
      -- Register to help meet timing
      if rising_edge(timingRxClk) then
         if (useMiniTpg = '1') then
            if (timingClkSel = '1' and EN_LCLS_II_TIMING_G) then
               rxStatus  <= TIMING_PHY_STATUS_FORCE_C after TPD_G;
               rxData    <= xpmMiniTimingPhy.data     after TPD_G;
               rxDataK   <= xpmMiniTimingPhy.dataK    after TPD_G;
               rxDispErr <= "00"                      after TPD_G;
               rxDecErr  <= "00"                      after TPD_G;
            elsif (timingClkSel = '0' and EN_LCLS_I_TIMING_G) then
               rxStatus  <= TIMING_PHY_STATUS_FORCE_C    after TPD_G;
               rxData    <= tpgMiniStreamTimingPhy.data  after TPD_G;
               rxDataK   <= tpgMiniStreamTimingPhy.dataK after TPD_G;
               rxDispErr <= "00"                         after TPD_G;
               rxDecErr  <= "00"                         after TPD_G;
            end if;
         elsif (timingClkSel = '1') then
--            txStatus  <= gtTxStatus(1)  after TPD_G;
            rxStatus  <= gtRxStatus(1)  after TPD_G;
            rxData    <= gtRxData(1)    after TPD_G;
            rxDataK   <= gtRxDataK(1)   after TPD_G;
            rxDispErr <= gtRxDispErr(1) after TPD_G;
            rxDecErr  <= gtRxDecErr(1)  after TPD_G;
         else
--            txStatus  <= gtTxStatus(0)  after TPD_G;
            rxStatus  <= gtRxStatus(0)  after TPD_G;
            rxData    <= gtRxData(0)    after TPD_G;
            rxDataK   <= gtRxDataK(0)   after TPD_G;
            rxDispErr <= gtRxDispErr(0) after TPD_G;
            rxDecErr  <= gtRxDecErr(0)  after TPD_G;
         end if;
      end if;
   end process;

   U_RXCLK : BUFGMUX
      generic map (
         CLK_SEL_TYPE => "ASYNC")       -- ASYNC, SYNC
      port map (
         O  => timingRxClk,             -- 1-bit output: Clock output
         I0 => gtRxClk(0),              -- 1-bit input: Clock input (S=0)
         I1 => gtRxClk(1),              -- 1-bit input: Clock input (S=1)
         S  => timingClkSel);           -- 1-bit input: Clock select

   -- NEED to do the same thing as RX!!!!
   -- NEED TXOUTCLKs switched in here
   U_TXCLK : BUFGMUX
      generic map (
         CLK_SEL_TYPE => "ASYNC")       -- ASYNC, SYNC
      port map (
         O  => timingTxClk,             -- 1-bit output: Clock output
         I0 => gtTxClk(0),              -- 1-bit input: Clock input (S=0)
         I1 => gtTxClk(1),              -- 1-bit input: Clock input (S=1)
         S  => timingClkSel);           -- 1-bit input: Clock select

   -----------------------
   -- Insert user RX reset
   -----------------------
   gtRxControl.reset       <= timingRxControl.reset or rxUserRst;
   gtRxControl.inhibit     <= timingRxControl.inhibit;
   gtRxControl.polarity    <= timingRxControl.polarity;
   gtRxControl.bufferByRst <= timingRxControl.bufferByRst;
   gtRxControl.pllReset    <= timingRxControl.pllReset or rxUserRst;

   gtTxControl.reset       <= temTimingTxPhy.control.reset or txPhyReset;
   gtTxControl.pllReset    <= temTimingTxPhy.control.pllReset or txPhyPllReset;
   gtTxControl.inhibit     <= temTimingTxPhy.control.inhibit;
   gtTxControl.polarity    <= temTimingTxPhy.control.polarity;
   gtTxControl.bufferByRst <= temTimingTxPhy.control.bufferByRst;

   --------------
   -- Timing Core
   --------------
   U_TimingCore : entity lcls_timing_core.TimingCore
      generic map (
         TPD_G             => TPD_G,
         DEFAULT_CLK_SEL_G => toSl(EN_LCLS_II_TIMING_G),  -- '0': default LCLS-I, '1': default LCLS-II
         TPGEN_G           => false,
         AXIL_RINGB_G      => false,
         ASYNC_G           => true,
         AXIL_BASE_ADDR_G  => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr)
      port map (
         -- GT Interface
         gtTxUsrClk       => timingTxClk,
         gtTxUsrRst       => timingTxRst,
         gtRxRecClk       => timingRxClk,
         gtRxData         => rxData,
         gtRxDataK        => rxDataK,
         gtRxDispErr      => rxDispErr,
         gtRxDecErr       => rxDecErr,
         gtRxControl      => timingRxControl,
         gtRxStatus       => rxStatus,
         tpgMiniTimingPhy => open,
         timingClkSel     => timingClkSel,
         -- Decoded timing message interface
         appTimingClk     => timingRxClk,
         appTimingRst     => timingRxRst,
         appTimingMode    => appTimingMode,
         appTimingBus     => appTimingBus,
         -- AXI Lite interface
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave    => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster  => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave   => axilWriteSlaves(TIMING_INDEX_C));

   ---------------------
   -- XPM Mini Wrapper
   -- Simulates a timing/xpm stream
   ---------------------
   U_XpmMiniWrapper_1 : entity l2si_core.XpmMiniWrapper
      generic map (
         TPD_G           => TPD_G,
         NUM_DS_LINKS_G  => 1,
         AXIL_BASEADDR_G => AXIL_CONFIG_C(XPM_MINI_INDEX_C).baseAddr)
      port map (
         timingClk => timingRxClk,       -- [in]
         timingRst => timingRxRst,       -- [in]
         dsTx(0)   => xpmMiniTimingPhy,  -- [out]

         dsRxClk(0)     => timingTxClk,           -- [in]
         dsRxRst(0)     => timingTxRst,           -- [in]
         dsRx(0).data   => temTimingTxPhy.data,   -- [in]
         dsRx(0).dataK  => temTimingTxPhy.dataK,  -- [in]
         dsRx(0).decErr => (others => '0'),       -- [in]
         dsRx(0).dspErr => (others => '0'),       -- [in]

         tpgMiniStream => tpgMiniStreamTimingPhy,  -- [out]

         axilClk         => axilClk,                             -- [in]
         axilRst         => axilRst,                             -- [in]
         axilReadMaster  => axilReadMasters(XPM_MINI_INDEX_C),   -- [in]
         axilReadSlave   => axilReadSlaves(XPM_MINI_INDEX_C),    -- [out]
         axilWriteMaster => axilWriteMasters(XPM_MINI_INDEX_C),  -- [in]
         axilWriteSlave  => axilWriteSlaves(XPM_MINI_INDEX_C));  -- [out]

   ---------------------
   -- Timing PHY Monitor
   -- This is mostly unused now. Trigger monitoring is done in the TriggerEventManager
   -- Still need the useMiniTpg register
   ---------------------
   U_Monitor : entity lcls2_pgp_fw_lib.TimingPhyMonitor
      generic map (
         TPD_G           => TPD_G,
         SIMULATION_G    => SIMULATION_G,
         AXIL_CLK_FREQ_G => AXIL_CLK_FREQ_G)
      port map (
         rxUserRst       => rxUserRst,
         txUserRst       => txUserRst,
         txPhyReset      => txPhyReset,
         txPhyPllReset   => txPhyPllReset,
         useMiniTpg      => useMiniTpg,
         mmcmRst         => mmcmRst,
         loopback        => loopback,
         remTrig         => (others => '0'),  --remTrig,
         remTrigDrop     => (others => '0'),  --remTrigDrop,
         locTrig         => (others => '0'),  --locTrig,
         locTrigDrop     => (others => '0'),  --locTrigDrop,
         mmcmLocked      => mmcmLocked,
         refClk          => refClk,
         refRst          => refRst,
         txClk           => timingTxClk,
         txRst           => timingTxRst,
         rxClk           => timingRxClk,
         rxRst           => timingRxRst,
         -- AXI Lite interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(MON_INDEX_C),
         axilReadSlave   => axilReadSlaves(MON_INDEX_C),
         axilWriteMaster => axilWriteMasters(MON_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(MON_INDEX_C));


   ---------------------------------------------------------------
   -- Decode events and buffer them for the application
   ---------------------------------------------------------------
   U_TriggerEventManager_1 : entity l2si_core.TriggerEventManager
      generic map (
         TPD_G                          => TPD_G,
         EN_LCLS_I_TIMING_G             => EN_LCLS_I_TIMING_G,
         EN_LCLS_II_TIMING_G            => EN_LCLS_II_TIMING_G,
         NUM_DETECTORS_G                => NUM_DETECTORS_G,
         AXIL_BASE_ADDR_G               => AXIL_CONFIG_C(TEM_INDEX_C).baseAddr,
         EVENT_AXIS_CONFIG_G            => DMA_AXIS_CONFIG_G,
         L1_CLK_IS_TIMING_TX_CLK_G      => false,
         TRIGGER_CLK_IS_TIMING_RX_CLK_G => false,
         EVENT_CLK_IS_TIMING_RX_CLK_G   => false)
      port map (
         timingRxClk              => timingRxClk,                    -- [in]
         timingRxRst              => timingRxRst,                    -- [in]
         timingBus                => appTimingBus,                   -- [in]
         timingMode               => appTimingMode,                  -- [in]
         timingTxClk              => timingTxClk,                    -- [in]
         timingTxRst              => timingTxRst,                    -- [in]
         timingTxPhy              => temTimingTxPhy,                 -- [out]
         triggerClk               => triggerClk,                     -- [in]
         triggerRst               => triggerRst,                     -- [in]
         triggerData              => triggerData,                    -- [out]
         clearReadout             => clearReadout,                   -- [out]
         l1Clk                    => l1Clk,                          -- [in]
         l1Rst                    => l1Rst,                          -- [in]
         l1Feedbacks              => l1Feedbacks,                    -- [in]
         l1Acks                   => l1Acks,                         -- [out]
         eventClk                 => eventClk,                       -- [in]
         eventRst                 => eventRst,                       -- [in]
         eventTimingMessagesValid => eventTimingMessagesValid,       -- [out]
         eventTimingMessages      => eventTimingMessages,            -- [out]
         eventTimingMessagesRd    => eventTimingMessagesRd,          -- [in]
         eventAxisMasters         => eventTrigMsgMasters,            -- [out]
         eventAxisSlaves          => eventTrigMsgSlaves,             -- [in]
         eventAxisCtrl            => eventTrigMsgCtrl,               -- [in]
         axilClk                  => axilClk,                        -- [in]
         axilRst                  => axilRst,                        -- [in]
         axilReadMaster           => axilReadMasters(TEM_INDEX_C),   -- [in]
         axilReadSlave            => axilReadSlaves(TEM_INDEX_C),    -- [out]
         axilWriteMaster          => axilWriteMasters(TEM_INDEX_C),  -- [in]
         axilWriteSlave           => axilWriteSlaves(TEM_INDEX_C));  -- [out]

   U_EventTimingMessage : entity l2si_core.EventTimingMessage
      generic map (
         TPD_G               => TPD_G,
         NUM_DETECTORS_G     => NUM_DETECTORS_G,
         EVENT_AXIS_CONFIG_G => DMA_AXIS_CONFIG_G)
      port map (
         -- Clock and Reset
         eventClk                 => eventClk,                  -- [in]
         eventRst                 => eventRst,                  -- [in]
         -- Input Streams
         eventTimingMessagesValid => eventTimingMessagesValid,  -- [in]
         eventTimingMessages      => eventTimingMessages,       -- [in]
         eventTimingMessagesRd    => eventTimingMessagesRd,     -- [out]
         -- Output Streams
         eventTimingMsgMasters    => eventTimingMsgMasters,     -- [out]
         eventTimingMsgSlaves     => eventTimingMsgSlaves);     -- [in]

end mapping;
