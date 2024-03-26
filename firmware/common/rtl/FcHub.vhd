-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
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

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library ldmx;
use ldmx.FcPkg.all;

entity FcHub is

   generic (
      TPD_G             : time                 := 1 ns;
      SIM_SPEEDUP_G     : boolean              := false;
      REFCLKS_G         : integer range 1 to 4 := 2;
      QUADS_G           : integer range 1 to 4 := 4;
      QUAD_REFCLK_MAP_G : IntegerArray         := (0      => 0, 1 => 0, 2 => 1, 3 => 1);  -- Map a refclk for each quad
      AXIL_CLK_FREQ_G   : real                 := 125.0e6;
      AXIL_BASE_ADDR_G  : slv(31 downto 0)     := (others => '0'));
   port (
      ----------------------------------------------------------------------------------------------
      -- LCLS Timing Interface
      ----------------------------------------------------------------------------------------------
      -- 185 MHz Ref Clk for LCLS timing recovery
      lclsTimingRefClk185P : in  sl;
      lclsTimingRefClk185N : in  sl;
      -- LCLS-II timing interface
      lclsTimingRxP        : in  sl;
      lclsTimingRxN        : in  sl;
      lclsTimingTxP        : out sl;
      lclsTimingTxN        : out sl;

      ----------------------------------------------------------------------------------------------
      -- Global Trigger Interface
      ----------------------------------------------------------------------------------------------
      -- LCLS Recovered Clock Output to pins
      lclsTimingClkOut : out sl;
      lclsTimingRstOut : out sl;
      globalTriggerRor : in  FcTimestampType;

      ----------------------------------------------------------------------------------------------
      -- FC HUB
      ----------------------------------------------------------------------------------------------
      -- Recovered and retimed LCLS Reference clock
      fcHubRefClkP : in  slv(REFCLKS_G-1 downto 0);
      fcHubRefClkN : in  slv(REFCLKS_G-1 downto 0);
      -- PGP FC serial IO
      fcHubTxP     : out slv(QUADS_G*4-1 downto 0);
      fcHubTxN     : out slv(QUADS_G*4-1 downto 0);
      fcHubRxP     : in  slv(QUADS_G*4-1 downto 0);
      fcHubRxN     : in  slv(QUADS_G*4-1 downto 0);

      ----------------------------------------------------------------------------------------------
      -- AXI Lite
      ----------------------------------------------------------------------------------------------
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType);

end entity FcHub;

architecture rtl of FcHub is

   -- AXI Lite
   constant AXIL_NUM_C         : integer := 3;
   constant AXIL_LCLS_TIMING_C : integer := 0;
   constant AXIL_TX_LOGIC_C    : integer := 1;
   constant AXIL_FC_ARRAY_C    : integer := 2;

   constant AXIL_XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(AXIL_NUM_C-1 downto 0) := (
      AXIL_LCLS_TIMING_C => (
         baseAddr        => X"00000000",
         addrBits        => 24,
         connectivity    => X"FFFF"),
      AXIL_TX_LOGIC_C    => (
         baseAddr        => X"01000000",
         addrBits        => 8,
         connectivity    => X"FFFF"),
      AXIL_FC_ARRAY_C    => (
         baseAddr        => X"02000000",
         addrBits        => 24,
         connectivity    => X"FFFF"));

   signal locAxilReadMasters  : AxiLiteReadMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_NUM_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal locAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_NUM_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_NUM_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   -- Recovered LCLS Timing Clock and Bus
   signal lclsTimingClk : sl;
   signal lclsTimingRst : sl;
   signal lclsTimingBus : TimingBusType;

   -- LDMX Fast Control Message to FC Senders
   signal fcTxMsg : FastControlMessageType;

begin
   
   -------------------------------------------------------------------------------------------------
   -- AXI-Lite crossbar
   -------------------------------------------------------------------------------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_NUM_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CONFIG_C)
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
   -- LCLS TIMING RX
   -------------------------------------------------------------------------------------------------
   lclsTimingClkOut <= lclsTimingClk;

   U_Lcls2TimingRx_1 : entity ldmx.Lcls2TimingRx
      generic map (
         TPD_G             => TPD_G,
         TIME_GEN_EXTREF_G => true,
         RX_CLK_MMCM_G     => true,
         USE_TPGMINI_G     => true,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(AXIL_LCLS_TIMING_C).baseAddr)
      port map (
         stableClk        => axilClk,   -- [in] -- axilClk from TenGigEth core is not mmcm
         stableRst        => axilRst,   -- [in]
         axilClk          => axilClk,   -- [in]
         axilRst          => axilRst,   -- [in]
         axilReadMaster   => locAxilReadMasters(AXIL_LCLS_TIMING_C),   -- [in]
         axilReadSlave    => locAxilReadSlaves(AXIL_LCLS_TIMING_C),    -- [out]
         axilWriteMaster  => locAxilWriteMasters(AXIL_LCLS_TIMING_C),  -- [in]
         axilWriteSlave   => locAxilWriteSlaves(AXIL_LCLS_TIMING_C),   -- [out]
         recTimingClk     => lclsTimingClk,                            -- [out]
         recTimingRst     => lclsTimingRst,                            -- [out]
         appTimingBus     => lclsTimingBus,                            -- [out]
         timingRxP        => lclsTimingRxP,                            -- [in]
         timingRxN        => lclsTimingRxN,                            -- [in]
         timingTxP        => lclsTimingTxP,                            -- [out]
         timingTxN        => lclsTimingTxN,                            -- [out]
         timingRefClkInP  => lclsTimingRefClk185P,                     -- [in]
         timingRefClkInN  => lclsTimingRefClk185N,                     -- [in]
         timingRecClkOutP => open,      -- [out]
         timingRecClkOutN => open);     -- [out]

   -------------------------------------------------------------------------------------------------
   -- Fast Control Output Word Logic
   -------------------------------------------------------------------------------------------------
   U_FcTxLogic_1 : entity ldmx.FcTxLogic
      generic map (
         TPD_G => TPD_G)
      port map (
         lclsTimingClk    => lclsTimingClk,     -- [in]
         lclsTimingRst    => lclsTimingRst,     -- [in]
         lclsTimingBus    => lclsTimingBus,     -- [in]
         globalTriggerRor => globalTriggerRor,  -- [in]
         fcMsg            => fcTxMsg,           -- [out]
         axilClk          => axilClk,           -- [in]
         axilRst          => axilRst,           -- [in]
         axilReadMaster   => axilReadMaster,    -- [in]
         axilReadSlave    => axilReadSlave,     -- [out]
         axilWriteMaster  => axilWriteMaster,   -- [in]
         axilWriteSlave   => axilWriteSlave);   -- [out]

   -------------------------------------------------------------------------------------------------
   -- Fast Control Fanout to Subsystems
   -------------------------------------------------------------------------------------------------
   U_FcSenderArray_1 : entity ldmx.FcSenderArray
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
         REFCLKS_G         => REFCLKS_G,
         QUADS_G           => QUADS_G,
         QUAD_REFCLK_MAP_G => QUAD_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_G,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CONFIG_C(AXIL_FC_ARRAY_C).baseAddr)
      port map (
         fcHubRefClkP    => fcHubRefClkP,                          -- [in]
         fcHubRefClkN    => fcHubRefClkN,                          -- [in]
         fcHubTxP        => fcHubTxP,                              -- [out]
         fcHubTxN        => fcHubTxN,                              -- [out]
         fcHubRxP        => fcHubRxP,                              -- [in]
         fcHubRxN        => fcHubRxN,                              -- [in]
         lclsTimingClk   => lclsTimingClk,                         -- [in]
         lclsTimingRst   => lclsTimingRst,                         -- [in]
         fcTxMsg         => fcTxMsg,                               -- [in]
         axilClk         => axilClk,                               -- [in]
         axilRst         => axilRst,                               -- [in]
         axilReadMaster  => locAxilReadMasters(AXIL_FC_ARRAY_C),   -- [in]
         axilReadSlave   => locAxilReadSlaves(AXIL_FC_ARRAY_C),    -- [out]
         axilWriteMaster => locAxilWriteMasters(AXIL_FC_ARRAY_C),  -- [in]
         axilWriteSlave  => locAxilWriteSlaves(AXIL_FC_ARRAY_C));  -- [out]


end rtl;
