-------------------------------------------------------------------------------
-- Title      : Lcls2 Timing Receiver
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Wrapper for LCLS-II timing receiver
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Lcls2TimingRx is
   generic (
      TPD_G             : time    := 1 ns;
      SIMULATION_G      : boolean := false;
      TIME_GEN_EXTREF_G : boolean := false;
      RX_CLK_MMCM_G     : boolean := true;
      USE_TPGMINI_G     : boolean := true;
      AXI_CLK_FREQ_G    : real             := 156.25e6;
      AXIL_BASE_ADDR_G  : slv(31 downto 0) := X"00000000");
   port (
      stableClk        : in  sl;
      stableRst        : in  sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk          : in  sl;
      axilRst          : in  sl;
      axilReadMaster   : in  AxiLiteReadMasterType;
      axilReadSlave    : out AxiLiteReadSlaveType;
      axilWriteMaster  : in  AxiLiteWriteMasterType;
      axilWriteSlave   : out AxiLiteWriteSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Timing Interface
      recTimingClk     : out sl;
      recTimingRst     : out sl;
--       appTimingClk         : in  sl;
--       appTimingRst         : in  sl;
      appTimingBus     : out TimingBusType;
--      appTimingPhyClk     : out sl;     -- txusrclk
--      appTimingPhyRst     : out sl;
--      appTimingRefClk     : out sl;
--      appTimingRefClkDiv2 : out sl;

      ----------------
      -- Core Ports --
      ----------------
      -- LCLS Timing Ports
      timingRxP        : in  sl;
      timingRxN        : in  sl;
      timingTxP        : out sl;
      timingTxN        : out sl;
      timingRefClkInP  : in  sl;
      timingRefClkInN  : in  sl;
      timingRecClkOutP : out sl;
      timingRecClkOutN : out sl);
end Lcls2TimingRx;

architecture rtl of Lcls2TimingRx is

   -- AXI Lite signals and constants
   constant NUM_AXIL_C        : integer := 2;
   constant AXIL_CORE_INDEX_C : integer := 0;
   constant AXIL_GTY_INDEX_C  : integer := 1;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_C-1 downto 0) := (
      AXIL_CORE_INDEX_C => (
         baseAddr       => (AXIL_BASE_ADDR_G+x"00000000"),
         addrBits       => 18,
         connectivity   => x"FFFF"),
      AXIL_GTY_INDEX_C  => (
         baseAddr       => (AXIL_BASE_ADDR_G+x"00040000"),
         addrBits       => 13,
         connectivity   => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (NUM_AXIL_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_INIT_C);
   signal axilReadMasters  : AxiLiteReadMasterArray (NUM_AXIL_C-1 downto 0) := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal axilReadSlaves   : AxiLiteReadSlaveArray (NUM_AXIL_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_INIT_C);

   -- Reference clocks
   signal timingRefClk     : sl;
   signal timingRefDiv2    : sl;
   signal timingRefClkDiv2 : sl;

   -- Recovered clocks
   signal timingRxOutClkGt : sl;
   signal timingRxOutClk   : sl;
   signal timingRxOutRst   : sl;
   signal timingRxRecClk   : sl;

   -- Rx ports
   signal rxReset          : sl;
   signal rxUsrClkActive   : sl;
   signal rxCdrStable      : sl;
   signal rxStatus         : TimingPhyStatusType;
   signal rxControl        : TimingPhyControlType;
   signal rxData           : slv(15 downto 0);
   signal rxDataK          : slv(1 downto 0);
   signal rxDispErr        : slv(1 downto 0);
   signal rxDecErr         : slv(1 downto 0);
   signal txUsrClk         : sl;
   signal txUsrRst         : sl;
   signal txUsrClkActive   : sl;
   signal txStatus         : TimingPhyStatusType := TIMING_PHY_STATUS_INIT_C;
   signal timingPhy        : TimingPhyType;
   signal coreTimingPhy    : TimingPhyType;
   signal loopback         : slv(2 downto 0);
   signal refclksel        : slv(2 downto 0);
   signal appBus           : TimingBusType;
   signal appTimingClk     : sl;
   signal appTimingRst     : sl;
   signal appTimingMode    : sl;
   signal timingStrobe     : sl;
   signal timingValid      : sl;
   signal rxPmaRstDoneOut  : sl;


begin

   --------------------------
   -- AXI-Lite: Crossbar Core
   --------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C(NUM_AXIL_C-1 downto 0))
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters(NUM_AXIL_C-1 downto 0),
         mAxiWriteSlaves     => axilWriteSlaves(NUM_AXIL_C-1 downto 0),
         mAxiReadMasters     => axilReadMasters(NUM_AXIL_C-1 downto 0),
         mAxiReadSlaves      => axilReadSlaves(NUM_AXIL_C-1 downto 0));

   -------------------------------------------------------------------------------------------------
   -- Signal glue
   -------------------------------------------------------------------------------------------------
   recTimingClk <= timingRxOutClk;
   recTimingRst <= not(rxStatus.resetDone);

   appTimingClk <= timingRxOutClk;
   appTimingRst <= not rxStatus.resetDone;

   timingPhy <= coreTimingPhy;

   txUsrRst       <= not(txStatus.resetDone);
--   appTimingPhyClk <= txUsrClk;
--    appTimingPhyRst <= txUsrRst;
   txUsrClkActive <= '1';

   -------------------------------------------------------------------------------------------------
   -- Clock Buffers
   -------------------------------------------------------------------------------------------------
   U_IBUFDS_GT : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',     -- Refer to Transceiver User Guide
         REFCLK_HROW_CK_SEL => "00",    -- ODIV2 = 0
         REFCLK_ICNTL_RX    => "00")    -- Refer to Transceiver User Guide
      port map (
         O     => timingRefClk,         -- 1-bit output: Refer to Transceiver User Guide
         ODIV2 => timingRefDiv2,        -- 1-bit output: Refer to Transceiver User Guide
         CEB   => '0',                  -- 1-bit input: Refer to Transceiver User Guide
         I     => timingRefClkInP,      -- 1-bit input: Refer to Transceiver User Guide
         IB    => timingRefClkInN);     -- 1-bit input: Refer to Transceiver User Guide


   U_BUFG_GT_DIV2 : BUFG_GT
      port map (
         I       => timingRefDiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",
         O       => timingRefClkDiv2);

--   appTimingRefClk     <= timingRefClk;
--   appTimingRefClkDiv2 <= timingRefClkDiv2;

   -------------------------------------------------------------------------------------------------
   -- GT Timing Receiver
   -------------------------------------------------------------------------------------------------
   TimingGtCoreWrapper_1 : entity lcls_timing_core.TimingGtCoreWrapper
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         AXI_CLK_FREQ_G    => AXI_CLK_FREQ_G,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CFG_C(AXIL_GTY_INDEX_C).baseAddr,
         EXTREF_G          => TIME_GEN_EXTREF_G,
         DISABLE_TIME_GT_G => false,
         GTY_DRP_OFFSET_G  => x"00001000")
      port map (
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(AXIL_GTY_INDEX_C),
         axilReadSlave   => axilReadSlaves(AXIL_GTY_INDEX_C),
         axilWriteMaster => axilWriteMasters(AXIL_GTY_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(AXIL_GTY_INDEX_C),
         stableClk       => stableClk,
         stableRst       => stableRst,
         gtRefClk        => timingRefClk,
         gtRefClkDiv2    => timingRefClkDiv2,
         gtRxP           => timingRxP,
         gtRxN           => timingRxN,
         gtTxP           => timingTxP,
         gtTxN           => timingTxN,
         rxControl       => rxControl,
         rxStatus        => rxStatus,
         rxUsrClkActive  => rxUsrClkActive,
         rxCdrStable     => rxCdrStable,
         rxPmaRstDoneOut => rxPmaRstDoneOut,
         rxUsrClk        => timingRxOutClk,
         rxData          => rxData,
         rxDataK         => rxDataK,
         rxDispErr       => rxDispErr,
         rxDecErr        => rxDecErr,
         rxOutClk        => timingRxOutClkGt,
         rxRecClk        => timingRxRecClk,  -- Piped directly to GTCLK Pins
         txControl       => timingPhy.control,
         txStatus        => txStatus,
         txUsrClk        => txUsrClk,
         txUsrClkActive  => txUsrClkActive,
         txData          => timingPhy.data,
         txDataK         => timingPhy.dataK,
         txOutClk        => txUsrClk,
         loopback        => loopback);

   ------------------------------------------------------------------------------------------------
   -- Pass recovered clock through MMCM (maybe unnecessary?)
   ------------------------------------------------------------------------------------------------
   RX_CLK_MMCM_GEN : if (RX_CLK_MMCM_G) generate
      U_ClockManager : entity surf.ClockManagerUltraScale
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => "MMCM",
            INPUT_BUFG_G       => false,
            FB_BUFG_G          => true,
            RST_IN_POLARITY_G  => '0',
            NUM_CLOCKS_G       => 1,
            -- MMCM attributes
            BANDWIDTH_G        => "OPTIMIZED",
            CLKIN_PERIOD_G     => 5.384,
            DIVCLK_DIVIDE_G    => 1,
            CLKFBOUT_MULT_F_G  => 6.500,
            CLKOUT0_DIVIDE_F_G => 6.500)
         port map(
            clkIn     => timingRxOutClkGt,
            rstIn     => rxPmaRstDoneOut, -- reset polarity low -> active-low reset
            clkOut(0) => timingRxOutClk,
--            rstOut(0) => open,
            locked    => rxUsrClkActive);

   end generate RX_CLK_MMCM_GEN;

   NO_RX_CLK_MMCM_GEN : if (not RX_CLK_MMCM_G) generate
      timingRxOutClk <= timingRxOutClkGt;
      rxUsrClkActive <= '1';
   end generate NO_RX_CLK_MMCM_GEN;

   -- Output recovered clock from GT to GTREFCLK pins for jitter cleaning
   U_mgtRecClk : OBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH => '1',
         REFCLK_ICNTL_TX   => "00000")
      port map (
         O   => timingRecClkOutP,
         OB  => timingRecClkOutN,
         CEB => '0',
         I   => timingRxRecClk);


   ------------------------------------------------------------------------------------------------
   -- Timing Core
   -- Decode timing message from GTH and distribute to system
   ------------------------------------------------------------------------------------------------
   TimingCore_1 : entity lcls_timing_core.TimingCore
      generic map (
         TPD_G            => TPD_G,
         TPGEN_G          => false,
         STREAM_L1_G      => false,
--         ETHMSG_AXIS_CFG_G => EMAC_AXIS_CONFIG_C,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(AXIL_CORE_INDEX_C).baseAddr,
         AXIL_RINGB_G     => true,
         ASYNC_G          => false,
         CLKSEL_MODE_G    => "LCLSII",
         USE_TPGMINI_G    => USE_TPGMINI_G)
      port map (
         gtTxUsrClk       => txUsrClk,
         gtTxUsrRst       => txUsrRst,
         gtRxRecClk       => timingRxOutClk,
         gtRxData         => rxData,
         gtRxDataK        => rxDataK,
         gtRxDispErr      => rxDispErr,
         gtRxDecErr       => rxDecErr,
         gtRxControl      => rxControl,
         gtRxStatus       => rxStatus,
         gtLoopback       => loopback,
         appTimingClk     => appTimingClk,
         appTimingRst     => appTimingRst,
         appTimingMode    => open,
         appTimingBus     => appBus,
         tpgMiniTimingPhy => coreTimingPhy,
         timingClkSel     => open,
         axilClk          => axilClk,
         axilRst          => axilRst,
         axilReadMaster   => axilReadMasters(AXIL_CORE_INDEX_C),
         axilReadSlave    => axilReadSlaves(AXIL_CORE_INDEX_C),
         axilWriteMaster  => axilWriteMasters(AXIL_CORE_INDEX_C),
         axilWriteSlave   => axilWriteSlaves(AXIL_CORE_INDEX_C));

   process(appTimingClk)
   begin
      if rising_edge(appTimingClk) then
         timingStrobe <= appBus.strobe after TPD_G;  -- Pipeline for register replication during impl_1
         timingValid  <= appBus.valid  after TPD_G;  -- Pipeline for register replication during impl_1
      end if;
   end process;

   -- No pipelining: message, V1, and V2 only updated during strobe's HIGH cycle
   process(appBus, timingStrobe, timingValid)
      variable v : TimingBusType;
   begin
      v            := appBus;
      v.strobe     := timingStrobe;
      v.valid      := timingValid;
      appTimingBus <= v;
   end process;


end rtl;
