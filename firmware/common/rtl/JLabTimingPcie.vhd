-------------------------------------------------------------------------------
-- Title      : JLab PCIe Timing receiver
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Bridge between JLAB PCIe card signals and DtmTimingSourceV2
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
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;


library hps_daq;
use hps_daq.HpsTiPkg.all;

entity JlabTimingPcie is

   generic (
      TPD_G : time := 1 ns);

   port (
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      controlResetL   : out sl;
      dataResetL      : out sl;

      locClk125 : in sl;
      locRst125 : in sl;

      -- Pcie interface
      timingClk125a : in  sl;
      timingClk125b : in  sl;
      timingTrigger : in  sl;
      timingSync    : in  sl;
      timingBusy    : out sl;

      distClk    : out sl;
      distClkRst : out sl;
      txData     : out Slv10Array(1 downto 0);
      txDataEn   : out slv(1 downto 0);
      txReady    : in  slv(1 downto 0));

end entity JlabTimingPcie;

architecture rtl of JlabTimingPcie is

   attribute IODELAY_GROUP                    : string;
   attribute IODELAY_GROUP of U_DELAY_TRIGGER : label is "DtmTimingGrp";
   attribute IODELAY_GROUP of U_DELAY_SYNC    : label is "DtmTimingGrp";

   constant DEFAULT_DELAY_C : integer := 5;

   signal clk200 : sl;
   signal rst200 : sl;

   signal iTimingBusy : sl;

   signal pllLocked : sl;
   signal pllReset  : sl;

   -------------------------------------------------------------------------------------------------
   -- DIST clock domain signals
   -------------------------------------------------------------------------------------------------
   signal iDistClk      : sl;
   signal iDistClkRst   : sl;
   signal timingRst125b : sl;
   signal timingRst125a : sl;

   constant CODA_END_C      : slv(2 downto 0) := "000";
   constant CODA_DOWNLOAD_C : slv(2 downto 0) := "001";
   constant CODA_PRESTART_C : slv(2 downto 0) := "011";
   constant CODA_GO_C       : slv(2 downto 0) := "010";
   constant CODA_INIT_C     : slv(2 downto 0) := "100";

   type TiRegType is record
      alignPhaseCount    : slv(1 downto 0);
      reset101PhaseCount : slv(6 downto 0);
      downloadSync       : sl;
      triggerPhase       : slv(1 downto 0);
      syncPhase          : slv(1 downto 0);
   end record TiRegType;

   constant TI_REG_INIT_C : TiRegType := (
      alignPhaseCount    => (others => '0'),
      reset101PhaseCount => (others => '0'),
      downloadSync       => '0',
      triggerPhase       => "00",
      syncPhase          => "00");

   signal tiR   : TiRegType := TI_REG_INIT_C;
   signal tiRin : TiRegType;

   type DistRegType is record
      alignCmdAck    : sl;
      reset101CmdAck : sl;
      prestartSync   : sl;
      txData         : Slv10Array(1 downto 0);
      txDataEn       : slv(1 downto 0);
   end record DistRegType;

   constant DIST_REG_INIT_C : DistRegType := (
      alignCmdAck    => '0',
      reset101CmdAck => '0',
      prestartSync   => '0',
      txData         => (others => (others => '0')),
      txDataEn       => "00");

   signal distR   : DistRegType := DIST_REG_INIT_C;
   signal distRin : DistRegType;

   constant JLAB_TIMING_C  : sl := '1';
   constant LOCAL_TIMING_C : sl := '0';
   signal distClkRstTmp    : sl;
   signal distClkSel       : sl;

   -- Delay and IDDR for sync and trigger
   signal timingSyncDelayed : sl;
   signal timingSyncDdr     : slv(1 downto 0);
   signal timingSyncLast    : slv(1 downto 0);

   signal syncEdge     : sl;
   signal syncEdgeComb : sl;

   signal timingTriggerDelayed : sl;
   signal timingTriggerDdr     : slv(1 downto 0);
   signal timingTriggerLast    : slv(1 downto 0);

   signal triggerEdge     : sl;
   signal triggerEdgeComb : sl;

   signal triggersOutstanding : slv(3 downto 0);

   -- Synchronization between domains
   signal codaStateSync   : slv(2 downto 0);
   signal alignCmdReqSync : sl;
   signal alignCmdAckSync : sl;
   signal alignDelaySync  : slv(1 downto 0);

   signal reset101CmdReqSync : sl;
   signal reset101CmdAckSync : sl;


   -------------------------------------------------------------------------------------------------
   -- AXIL clock signals
   -------------------------------------------------------------------------------------------------
   type AxilRegType is record
      controlResetL  : sl;
      dataResetL     : sl;
      clkSel         : sl;
      alignDelay     : slv(1 downto 0);
      alignCmdReq    : sl;
      reset101CmdReq : sl;
      codaState      : slv(2 downto 0);
      cntRst         : sl;
      triggerSet     : sl;
      triggerDelay   : slv(4 downto 0);
      syncSet        : sl;
      syncDelay      : slv(4 downto 0);
      axilWriteSlave : AxiLiteWriteSlaveType;
      axilReadSlave  : AxiLiteReadSlaveType;
   end record AxilRegType;

   constant AXIL_REG_INIT_C : AxiLRegType := (
      controlResetL  => '1',
      dataResetL     => '1',
      clkSel         => JLAB_TIMING_C,
      alignDelay     => (others => '0'),
      alignCmdReq    => '0',
      reset101CmdReq => '0',
      codaState      => CODA_END_C,
      cntRst         => '0',
      triggerSet     => '0',
      triggerDelay   => toSlv(DEFAULT_DELAY_C, 5),
      syncSet        => '0',
      syncDelay      => toSlv(DEFAULT_DELAY_C, 5),
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C);

   signal axilR   : AxilRegType := AXIL_REG_INIT_C;
   signal axilRin : AxilRegType;

   signal axilBusyRate                : slv(31 downto 0);
   signal axilBusyRateMax             : slv(31 downto 0);
   signal axilBusyRateMin             : slv(31 downto 0);
   signal axilBusyTime                : slv(31 downto 0);
   signal axilBusyTimeMax             : slv(31 downto 0);
   signal axilBusyTimeMin             : slv(31 downto 0);
   signal clk125aFreq                 : slv(31 downto 0);
   signal clk125bFreq                 : slv(31 downto 0);
   signal axilTimingSyncCount         : slv(31 downto 0);
   signal axilTimingDownloadSyncCount : slv(31 downto 0);
   signal axilTimingPrestartSyncCount : slv(31 downto 0);
   signal axilTimingTriggerCount      : slv(31 downto 0);
   signal axilPllLocked               : sl;
   signal triggersOutstandingAxil     : slv(3 downto 0);
   signal triggerPhaseAxil            : slv(1 downto 0);
   signal syncPhaseAxil               : slv(1 downto 0);


begin

   distClk    <= iDistClk;
   distClkRst <= iDistClkRst;
   timingBusy <= iTimingBusy;

   -------------------------------------------------------------------------------------------------
   -- Create powerup reset from main clock
   -------------------------------------------------------------------------------------------------
   PwrUpRst_1 : entity surf.PwrUpRst
      generic map (
         TPD_G          => TPD_G,
         SIM_SPEEDUP_G  => true,
         IN_POLARITY_G  => '1',
         OUT_POLARITY_G => '1',
         DURATION_G     => 25000)
      port map (
         clk    => timingClk125a,
         rstOut => timingRst125a);

   -------------------------------------------------------------------------------------------------
   -- Run input clock through 3 stage pll fileter
   -------------------------------------------------------------------------------------------------
--    U_PLL_0 : entity surf.ClockManager7
--       generic map (
--          TPD_G              => TPD_G,
--          TYPE_G             => "MMCM",
--          INPUT_BUFG_G       => false,
--          FB_BUFG_G          => true,
--          NUM_CLOCKS_G       => 1,
--          BANDWIDTH_G        => "LOW",
--          CLKIN_PERIOD_G     => 8.0,
--          DIVCLK_DIVIDE_G    => 1,
--          CLKFBOUT_MULT_F_G  => 8.0,
--          CLKOUT0_DIVIDE_F_G => 8.0)
--       port map (
--          clkIn     => timingClk125b,
--          rstIn     => pllReset,
--          clkOut(0) => timingClk125Tmp0,
--          rstOut(0) => timingRst125Tmp0);

--    U_PLL_1 : entity surf.ClockManager7
--       generic map (
--          TPD_G              => TPD_G,
--          TYPE_G             => "MMCM",
--          INPUT_BUFG_G       => false,
--          FB_BUFG_G          => true,
--          NUM_CLOCKS_G       => 1,
--          BANDWIDTH_G        => "OPTIMIZED",
--          CLKIN_PERIOD_G     => 8.0,
--          DIVCLK_DIVIDE_G    => 1,
--          CLKFBOUT_MULT_F_G  => 8.0,
--          CLKOUT0_DIVIDE_F_G => 8.0)
--       port map (
--          clkIn     => timingClk125Tmp0,
--          rstIn     => timingRst125Tmp0,
--          clkOut(0) => timingClk125Tmp1,
--          rstOut(0) => timingRst125Tmp1);

--    U_PLL_2 : entity surf.ClockManager7
--       generic map (
--          TPD_G            => TPD_G,
--          TYPE_G           => "PLL",
--          INPUT_BUFG_G     => false,
--          FB_BUFG_G        => true,
--          NUM_CLOCKS_G     => 1,
--          BANDWIDTH_G      => "OPTIMIZED",
--          CLKIN_PERIOD_G   => 8.0,
--          DIVCLK_DIVIDE_G  => 1,
--          CLKFBOUT_MULT_G  => 14,
--          CLKOUT0_DIVIDE_G => 14)
--       port map (
--          clkIn     => timingClk125Tmp1,
--          rstIn     => timingRst125Tmp1,
--          clkOut(0) => timingClk125Clean,
--          rstOut(0) => timingRst125Clean,
--          locked    => pllLocked);

--    U_Synchronizer_PLL_LOCKED : entity surf.Synchronizer
--       generic map (
--          TPD_G => TPD_G)
--       port map (
--          clk     => axilClk,            -- [in]
--          rst     => '0',                -- [in]
--          dataIn  => pllLocked,          -- [in]
--          dataOut => axilPllLocked);     -- [out]

--    U_SynchronizerOneShot_1 : entity surf.SynchronizerOneShot
--       generic map (
--          TPD_G           => TPD_G,
--          RST_POLARITY_G  => '0',
-- --         BYPASS_SYNC_G   => BYPASS_SYNC_G,
--          RELEASE_DELAY_G => 10,
--          IN_POLARITY_G   => '0',
--          OUT_POLARITY_G  => '1',
--          PULSE_WIDTH_G   => 1000)
--       port map (
--          clk     => axilClk,            -- [in]
-- --         rst     => rst,                -- [in]
--          dataIn  => pllLocked,          -- [in]
--          dataOut => pllReset);          -- [out]

   -------------------------------------------------------------------------------------------------
   -- timingSync and timingTrigger need IDELAY and IDDR since they may arrive on either edge
   -------------------------------------------------------------------------------------------------
   -- First create 200 MHz clock for IDELAYCTRL
--    U_CLK200_PLL : entity surf.ClockManager7
--       generic map (
--          TPD_G            => TPD_G,
--          TYPE_G           => "PLL",
--          INPUT_BUFG_G     => false,
--          FB_BUFG_G        => true,
--          NUM_CLOCKS_G     => 1,
--          BANDWIDTH_G      => "OPTIMIZED",
--          CLKIN_PERIOD_G   => 8.0,
--          DIVCLK_DIVIDE_G  => 1,
--          CLKFBOUT_MULT_G  => 8,
--          CLKOUT0_DIVIDE_G => 5)
--       port map (
--          clkIn     => locClk125,
--          rstIn     => locRst125,
--          clkOut(0) => clk200,
--          rstOut(0) => rst200);

   -- Send both trigger and sync through a delay block
   U_DELAY_TRIGGER : IDELAYE2
      generic map (
         DELAY_SRC             => "IDATAIN",
         HIGH_PERFORMANCE_MODE => "TRUE",
         IDELAY_TYPE           => "VAR_LOAD",
         IDELAY_VALUE          => DEFAULT_DELAY_C,
         REFCLK_FREQUENCY      => 200.0,
         SIGNAL_PATTERN        => "DATA"
         )
      port map (
         C           => axilClk,
         REGRST      => '0',
         LD          => axilR.triggerSet,
         CE          => '0',
         INC         => '1',
         CINVCTRL    => '0',
         CNTVALUEIN  => axilR.triggerDelay,
         IDATAIN     => timingTrigger,
         DATAIN      => '0',
         LDPIPEEN    => '0',
         DATAOUT     => timingTriggerDelayed,
         CNTVALUEOUT => open);

   U_DELAY_SYNC : IDELAYE2
      generic map (
         DELAY_SRC             => "IDATAIN",
         HIGH_PERFORMANCE_MODE => "TRUE",
         IDELAY_TYPE           => "VAR_LOAD",
         IDELAY_VALUE          => DEFAULT_DELAY_C,
         REFCLK_FREQUENCY      => 200.0,
         SIGNAL_PATTERN        => "DATA"
         )
      port map (
         C           => axilClk,
         REGRST      => '0',
         LD          => axilR.syncSet,
         CE          => '0',
         INC         => '1',
         CINVCTRL    => '0',
         CNTVALUEIN  => axilR.SyncDelay,
         IDATAIN     => timingSync,
         DATAIN      => '0',
         LDPIPEEN    => '0',
         DATAOUT     => timingSyncDelayed,
         CNTVALUEOUT => open);

   --Now put both trigger and sync through an IDDR
   U_IDDR_TRIGGER : IDDR
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE")
      port map (
         C  => timingClk125a,
         CE => '1',
         D  => timingTriggerDelayed,
         Q1 => timingTriggerDdr(0),
         Q2 => timingTriggerDdr(1));

   U_IDDR_SYNC : IDDR
      generic map (
         DDR_CLK_EDGE => "SAME_EDGE")
      port map (
         C  => timingClk125a,
         CE => '1',
         D  => timingSyncDelayed,
         Q1 => timingSyncDdr(0),
         Q2 => timingSyncDdr(1));

--    Need OR on trigger since watching for rising edge
--    timingTriggerOr <= timingTriggerDdr1 or timingTriggerDdr2;

--    Need AND on sync since watching for falling edge
--    timingSyncAnd <= timingSyncDdr1 and timingSyncDdr2;

   U_RegisterVector_Sync : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk   => timingClk125a,        -- [in]
         sig_i => timingSyncDdr,        -- [in]
         reg_o => timingSyncLast);      -- [out]

   -- Detect trigger rising edge
   syncEdgeComb <= '1' when timingSyncLast = "11" and timingSyncDdr /= "11" else '0';

   U_RegisterVector_SyncEdge : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         clk      => timingClk125a,     -- [in]
         sig_i(0) => syncEdgeComb,      -- [in]
         reg_o(0) => syncEdge);         -- [out]


   U_RegisterVector_Trigger : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk   => timingClk125a,        -- [in]
         sig_i => timingTriggerDdr,     -- [in]
         reg_o => timingTriggerLast);   -- [out]

   -- Detect trigger rising edge
   triggerEdgeComb <= '1' when timingTriggerLast = "00" and timingTriggerDdr /= "00" else '0';

   U_RegisterVector_TriggerEdge : entity surf.RegisterVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 1)
      port map (
         clk      => timingClk125a,     -- [in]
         sig_i(0) => triggerEdgeComb,   -- [in]
         reg_o(0) => triggerEdge);      -- [out]


   -- Trigger filter to create BUSY
   TriggerFilter_1 : entity hps_daq.TriggerFilter
      generic map (
         TPD_G             => TPD_G,
         CLK_PERIOD_G      => 8.0E-9,
         TRIGGER_TIME_G    => 27.0E-6,
         MAX_OUTSTANDING_G => 4)
      port map (
         clk                 => timingClk125a,
         rst                 => timingRst125a,
         trigger             => triggerEdge,
         triggersOutstanding => triggersOutstanding,
         busy                => iTimingBusy);

   -------------------------------------------------------------------------------------------------
   -- Status and reporting, clock and busy rates, trigger counts
   -------------------------------------------------------------------------------------------------
   SyncTrigRate_PERCENT : entity surf.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => false,
         IN_POLARITY_G  => '1',
         COUNT_EDGES_G  => false,
         REF_CLK_FREQ_G => 125.0E6,
         REFRESH_RATE_G => 1.0E0,
         CNT_WIDTH_G    => 32)
      port map (
         trigIn          => iTimingBusy,
         trigRateUpdated => open,
         trigRateOut     => axilBusyTime,
         trigRateOutMax  => axilBusyTimeMax,
         trigRateOutMin  => axilBusyTimeMin,
         locClkEn        => '1',
         locClk          => timingClk125a,
         locRst          => timingRst125a,
         refClk          => axilClk,
         refRst          => axilR.cntRst);

   SyncTrigRate_RATE : entity surf.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => false,
         IN_POLARITY_G  => '1',
         COUNT_EDGES_G  => true,
         REF_CLK_FREQ_G => 125.0E6,
         REFRESH_RATE_G => 1.0E0,
         CNT_WIDTH_G    => 32)
      port map (
         trigIn          => iTimingBusy,
         trigRateUpdated => open,
         trigRateOut     => axilBusyRate,
         trigRateOutMax  => axilBusyRateMax,
         trigRateOutMin  => axilBusyRateMin,
         locClkEn        => '1',
         locClk          => timingClk125a,
         locRst          => timingRst125a,
         refClk          => axilClk,
         refRst          => axilR.cntRst);

   U_SyncClockFreq_1 : entity surf.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => 125.0E6,
         REFRESH_RATE_G => 1.0,
         COMMON_CLK_G   => true,
         CNT_WIDTH_G    => 32)
      port map (
         freqOut     => clk125aFreq,    -- [out]
         freqUpdated => open,           -- [out]
         locked      => open,           -- [out]
         tooFast     => open,           -- [out]
         tooSlow     => open,           -- [out]
         clkIn       => timingClk125a,  -- [in]
         locClk      => axilClk,        -- [in]
         refClk      => axilClk);       -- [in]

   U_SyncClockFreq_2 : entity surf.SyncClockFreq
      generic map (
         TPD_G          => TPD_G,
         REF_CLK_FREQ_G => 125.0E6,
         REFRESH_RATE_G => 1.0,
         COMMON_CLK_G   => true,
         CNT_WIDTH_G    => 32)
      port map (
         freqOut     => clk125bFreq,    -- [out]
         freqUpdated => open,           -- [out]
         locked      => open,           -- [out]
         tooFast     => open,           -- [out]
         tooSlow     => open,           -- [out]
         clkIn       => timingClk125b,  -- [in]
         locClk      => axilClk,        -- [in]
         refClk      => axilClk);       -- [in]

   U_SynchronizerOneShotCnt_SYNC : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '1',              -- Falling edges
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32)
      port map (
         dataIn     => syncEdge,             -- [in]
         rollOverEn => '0',                  -- [in]
         cntRst     => axilR.cntRst,         -- [in]
         cntOut     => axilTimingSyncCount,  -- [out]
         wrClk      => timingClk125a,        -- [in]
         wrRst      => '0',                  -- [in]
         rdClk      => axilClk,              -- [in]
         rdRst      => axilRst);             -- [in]

   U_SynchronizerOneShotCnt_DOWNLOAD_SYNC : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '1',                      -- Falling edges
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32)
      port map (
         dataIn     => tiR.downloadSync,             -- [in]
         rollOverEn => '0',                          -- [in]
         cntRst     => axilR.cntRst,                 -- [in]
         cntOut     => axilTimingDownloadSyncCount,  -- [out]
         wrClk      => timingClk125a,                -- [in]
         wrRst      => '0',                          -- [in]
         rdClk      => axilClk,                      -- [in]
         rdRst      => axilRst);                     -- [in]

   U_SynchronizerOneShotCnt_PRESTART_SYNC : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '1',                      -- Falling edges
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32)
      port map (
         dataIn     => distR.prestartSync,           -- [in]
         rollOverEn => '0',                          -- [in]
         cntRst     => axilR.cntRst,                 -- [in]
         cntOut     => axilTimingPrestartSyncCount,  -- [out]
         wrClk      => timingClk125a,                -- [in]
         wrRst      => '0',                          -- [in]
         rdClk      => axilClk,                      -- [in]
         rdRst      => axilRst);                     -- [in]


   U_SynchronizerOneShotCnt_TRIGGER : entity surf.SynchronizerOneShotCnt
      generic map (
         TPD_G          => TPD_G,
--         COMMON_CLK_G    => COMMON_CLK_G,
         CNT_RST_EDGE_G => true,
         CNT_WIDTH_G    => 32)
      port map (
         dataIn     => triggerEdge,             -- [in]
         rollOverEn => '0',                     -- [in]
         cntRst     => axilR.cntRst,            -- [in]
         cntOut     => axilTimingTriggerCount,  -- [out]
         wrClk      => timingClk125a,           -- [in]
         wrRst      => '0',                     -- [in]
         rdClk      => axilClk,                 -- [in]
         rdRst      => axilRst);                -- [in]

   -------------------------------------------------------------------------------------------------
   -- DIST Clock selection and reset
   -------------------------------------------------------------------------------------------------
   CLKMUX : BUFGMUX_CTRL
      port map (
         I1 => timingClk125a,
         I0 => locClk125,
         S  => axilR.clkSel,
         O  => iDistClk);

   -- Just use locRst125 pwruprst
   -- and resync to muxed clk
   distClkRstTmp <= locRst125 when axilR.clkSel = '0' else timingRst125a;
   RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => iDistClk,
         asyncRst => distClkRstTmp,
         syncRst  => iDistClkRst);

   -------------------------------------------------------------------------------------------------
   -- Synchronization between AXIL and other clock domains
   -------------------------------------------------------------------------------------------------
   U_Synchronizer_AlignCmd : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => timingClk125a,      -- [in]
         rst     => '0',                -- [in]
         dataIn  => axilR.alignCmdReq,  -- [in]
         dataOut => alignCmdReqSync);   -- [out]

   U_Synchronizer_AlignAck : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,            -- [in]
         rst     => '0',                -- [in]
         dataIn  => distR.alignCmdAck,  -- [in]
         dataOut => alignCmdAckSync);   -- [out]

   U_Synchronizer_Reset101Cmd : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => timingClk125a,         -- [in]
         rst     => '0',                   -- [in]
         dataIn  => axilR.reset101CmdReq,  -- [in]
         dataOut => reset101CmdReqSync);   -- [out]

   U_Synchronizer_Reset101Ack : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => axilClk,               -- [in]
         rst     => '0',                   -- [in]
         dataIn  => distR.reset101CmdAck,  -- [in]
         dataOut => reset101CmdAckSync);   -- [out]


   U_SynchronizerVector_1 : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 2)
      port map (
         clk     => timingClk125a,      -- [in]
         rst     => '0',                -- [in]
         dataIn  => axilR.alignDelay,   -- [in]
         dataOut => alignDelaySync);    -- [out]

   U_Synchronizer_1 : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => timingClk125a,      -- [in]
         rst     => '0',                -- [in]
         dataIn  => axilR.clkSel,       -- [in]
         dataOut => distClkSel);        -- [out]

   U_SynchronizerVector_2 : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3)
      port map (
         clk     => timingClk125a,      -- [in]
         rst     => '0',                -- [in]
         dataIn  => axilR.codaState,    -- [in]
         dataOut => codaStateSync);     -- [out]

   U_SynchronizerFifo_1 : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 4)
      port map (
         rst    => timingRst125a,             -- [in]
         wr_clk => timingClk125a,             -- [in]
         din    => triggersOutstanding,       -- [in]
         rd_clk => axilClk,                   -- [in]
         dout   => triggersOutstandingAxil);  -- [out]


   -------------------------------------------------------------------------------------------------
   -- Count clocks on ti clock to deterine APV phase
   -- Reset on sync pulse
   -------------------------------------------------------------------------------------------------
   ticlk_comb : process (tiR, timingRst125a, timingSyncDdr, timingSyncLast, timingTriggerDdr,
                         timingTriggerLast) is
      variable v : TiRegType;
   begin
      v := tiR;

      v.downloadSync := '0';

      v.alignPhaseCount := tiR.alignPhaseCount + 1;
      if (tiR.alignPhaseCount = "10") then
         v.alignPhaseCount := "00";
      end if;

      v.reset101PhaseCount := tiR.reset101PhaseCount + 1;
      if (tiR.reset101PhaseCount = 104) then
         v.reset101PhaseCount := (others => '0');
      end if;

      -- Falling edge of sync
      if (timingSyncDdr /= "11" and timingSyncLast = "11") then
         v.alignPhaseCount    := "00";
         v.reset101PhaseCount := (others => '0');
         v.downloadSync       := '1';
         v.syncPhase          := timingSyncDdr;
      end if;

      if (timingTriggerDdr /= "00" and timingTriggerLast = "00") then
         v.triggerPhase := timingTriggerDdr;
      end if;

      if (timingRst125a = '1') then
         v := TI_REG_INIT_C;
      end if;

      tiRin <= v;

   end process;

   ticlk_seq : process (timingClk125a) is
   begin
      if (rising_edge(timingClk125a)) then
         tiR <= tiRin after TPD_G;
      end if;
   end process ticlk_seq;

   -------------------------------------------------------------------------------------------------
   -- Send commands to DPMs
   -------------------------------------------------------------------------------------------------
   dist_comb : process (alignCmdReqSync, alignDelaySync, codaStateSync, distClkSel, distR,
                        iDistClkRst, reset101CmdReqSync, syncEdge, tiR, triggerEdge) is
      variable v : DistRegType;
   begin
      v := distR;

      v.txDataEn := "00";
      v.txData   := (others => (others => '0'));

      -- Immediately register inputs to reduce any timing issues
      if (distClkSel = JLAB_TIMING_C) then

         -- Watch for falling edge of sync signal 
         if (syncEdge = '1') then
            if (codaStateSync = CODA_PRESTART_C) then
               -- Use sync at end of prestart to reset firmware run counters
               v.txData(0)    := TI_START_CODE_C;
               v.txDataEn(0)  := '1';
               v.prestartSync := '1';
            end if;
         end if;

         -- Watch for trigger signal and issue a trigger command
         if (triggerEdge = '1' and codaStateSync = CODA_GO_C) then
            v.txData(0)   := TI_TRIG_CODE_C;
            v.txDataEn(0) := '1';
         end if;

         -- Check for reset101 req
         if (reset101CmdReqSync = '1' and distR.reset101CmdAck = '0' and tiR.reset101PhaseCount = 0) then
            v.txData(0)      := TI_APV_RESET_101_C;
            v.txDataEn(0)    := '1';
            v.reset101CmdAck := '1';
         end if;

         -- Deassert ack when cmd deasserted
         if (distR.reset101CmdAck = '1' and reset101CmdReqSync = '0') then
            v.reset101CmdAck := '0';
         end if;


         -- Align code has priority, but really these never happen at the same time
         if (alignCmdReqSync = '1' and distR.alignCmdAck = '0' and tiR.alignPhaseCount = alignDelaySync) then
            v.txData(0)   := TI_ALIGN_CODE_C;
            v.txDataEn(0) := '1';
            v.alignCmdAck := '1';
         end if;

         -- Deassert ack when cmd deasserted
         if (distR.alignCmdAck = '1' and alignCmdReqSync = '0') then
            v.alignCmdAck := '0';
         end if;



      end if;

      if (iDistClkRst = '1') then
         v := DIST_REG_INIT_C;
      end if;

      distRin  <= v;
      txData   <= distR.txData;
      txDataEn <= distR.txDataEn;

   end process;

   dist_seq : process (iDistClk) is
   begin
      if (rising_edge(iDistClk)) then
         distR <= distRin after TPD_G;
      end if;
   end process dist_seq;

   -------------------------------------------------------------------------------------------------
   -- Sync between dist and axil
   -------------------------------------------------------------------------------------------------
   U_SynchronizerFifo_TriggerPhase : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 2)
      port map (
         rst    => timingRst125a,       -- [in]
         wr_clk => timingClk125a,       -- [in]
         din    => tiR.triggerPhase,    -- [in]
         rd_clk => axilClk,             -- [in]
         dout   => triggerPhaseAxil);   -- [out]

   U_SynchronizerFifo_SyncPhase : entity surf.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 2)
      port map (
         rst    => timingRst125a,       -- [in]
         wr_clk => timingClk125a,       -- [in]
         din    => tiR.syncPhase,       -- [in]
         rd_clk => axilClk,             -- [in]
         dout   => syncPhaseAxil);      -- [out]

   axil_comb : process (alignCmdAckSync, axilBusyRate, axilBusyRateMax, axilBusyRateMin,
                        axilBusyTime, axilBusyTimeMax, axilBusyTimeMin, axilR, axilReadMaster,
                        axilRst, axilTimingDownloadSyncCount, axilTimingPrestartSyncCount,
                        axilTimingSyncCount, axilTimingTriggerCount, axilWriteMaster, clk125aFreq,
                        clk125bFreq, reset101CmdAckSync, syncPhaseAxil, triggerPhaseAxil,
                        triggersOutstandingAxil) is
      variable v      : AxilRegType;
      variable axilEp : AxiLiteEndpointType;
   begin
      -- Latch the current value
      v := axilR;

      if (alignCmdAckSync = '1') then
         v.alignCmdReq := '0';
      end if;

      if (reset101CmdAckSync = '1') then
         v.reset101CmdReq := '0';
      end if;

      v.syncSet    := '0';
      v.triggerSet := '0';

      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegisterR(axilEp, X"00", 0, axilBusyRate);
      axiSlaveRegisterR(axilEp, X"04", 0, axilBusyRateMax);
      axiSlaveRegisterR(axilEp, X"08", 0, axilBusyRateMin);
      axiSlaveRegisterR(axilEp, X"0C", 0, clk125aFreq);
      axiSlaveRegisterR(axilEp, X"10", 0, clk125bFreq);
      axiSlaveRegisterR(axilEp, X"14", 0, axilTimingSyncCount);
      axiSlaveRegisterR(axilEp, X"18", 0, axilTimingTriggerCount);
      axiSlaveRegister(axilEp, X"1C", 0, v.clkSel);
      axiSlaveRegister(axilEp, X"20", 0, v.alignDelay);
      axiSlaveRegister(axilEp, X"24", 0, v.cntRst);
      axiSlaveRegister(axilEp, X"28", 0, v.codaState);
      axiSlaveRegisterR(axilEp, X"2C", 0, axilTimingDownloadSyncCount);
      axiSlaveRegisterR(axilEp, X"30", 0, axilTimingPrestartSyncCount);
      axiSlaveRegisterR(axilEp, X"34", 0, axilBusyTime);
      axiSlaveRegisterR(axilEp, X"38", 0, axilBusyTimeMax);
      axiSlaveRegisterR(axilEp, X"3C", 0, axilBusyTimeMin);

      axiSlaveRegister(axilEp, X"40", 0, v.alignCmdReq, '1');

      axiSlaveRegisterR(axilEp, X"44", 0, triggersOutstandingAxil);

      axiWrDetect(axilEp, X"50", v.triggerSet);
      axiSlaveRegister(axilEp, X"50", 0, v.triggerDelay);

      axiWrDetect(axilEp, X"54", v.syncSet);
      axiSlaveRegister(axilEp, X"54", 0, v.syncDelay);

      axiSlaveRegisterR(axilEp, X"60", 0, syncPhaseAxil);
      axiSlaveRegisterR(axilEp, X"60", 2, triggerPhaseAxil);

      axiSlaveRegister(axilEp, X"64", 0, v.reset101CmdReq);

      axiSlaveRegister(axilEp, X"70", 0, v.controlResetL);
      axiSlaveRegister(axilEp, X"70", 1, v.dataResetL);

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      if (axilRst = '1') then
         v := AXIL_REG_INIT_C;
      end if;

      axilRin        <= v;
      axilWriteSlave <= axilR.axilWriteSlave;
      axilReadSlave  <= axilR.axilReadSlave;
   end process;

   axil_seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         axilR <= axilRin after TPD_G;
      end if;
   end process;

end architecture rtl;
