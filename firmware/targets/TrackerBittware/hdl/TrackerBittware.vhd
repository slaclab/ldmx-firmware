-------------------------------------------------------------------------------
-- File       : BittWareXupVv8Pgp2fc.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ldmx;
use ldmx.FcPkg.all;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity TrackerBittware is
   generic (
      TPD_G                : time                        := 1 ns;
      SIM_SPEEDUP_G        : boolean                     := true;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
      DMA_BURST_BYTES_G    : integer range 256 to 4096   := 4096;
      DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 8;
      PGP_QUADS_G          : integer                     := 2;
      BUILD_INFO_G         : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP-DD Ports
      qsfpRefClkP    : in  slv(7 downto 0);
      qsfpRefClkN    : in  slv(7 downto 0);
      qsfpRecClkP    : out slv(7 downto 0);
      qsfpRecClkN    : out slv(7 downto 0);
      qsfpRxP        : in  slv(31 downto 0);
      qsfpRxN        : in  slv(31 downto 0);
      qsfpTxP        : out slv(31 downto 0);
      qsfpTxN        : out slv(31 downto 0);
      -- Fabric Clock Ports
      fabClkOutP     : out slv(1 downto 0);
      fabClkOutN     : out slv(1 downto 0);
      --------------
      --  Core Ports
      --------------
      -- FPGA I2C Master
      fpgaI2cMasterL : out sl;
      -- System Ports
      userClkP       : in  sl;
      userClkN       : in  sl;
      -- PCIe Ports
      pciRstL        : in  sl;
      pciRefClkP     : in  sl;
      pciRefClkN     : in  sl;
      pciRxP         : in  slv(15 downto 0);
      pciRxN         : in  slv(15 downto 0);
      pciTxP         : out slv(15 downto 0);
      pciTxN         : out slv(15 downto 0));
end TrackerBittware;

architecture rtl of TrackerBittware is

   -----------------------------------------
   -- Fast Control Interface from Timing Hub
   -----------------------------------------
   signal fcRefClk185P    : sl;
   signal fcRefClk185N    : sl;
   signal fcRecClkP       : sl;
   signal fcRecClkN       : sl;
   signal fcTxP           : sl;
   signal fcTxN           : sl;
   signal fcRxP           : sl;
   signal fcRxN           : sl;
   ---------------------
   --  PGP FC Interface to Tracker FEBs
   ---------------------
   signal febPgpFcRefClkP : slv(PGP_QUADS_G-1 downto 0);
   signal febPgpFcRefClkN : slv(PGP_QUADS_G-1 downto 0);
   signal febPgpFcRxP     : slv(PGP_QUADS_G*4-1 downto 0);
   signal febPgpFcRxN     : slv(PGP_QUADS_G*4-1 downto 0);
   signal febPgpFcTxP     : slv(PGP_QUADS_G*4-1 downto 0);
   signal febPgpFcTxN     : slv(PGP_QUADS_G*4-1 downto 0);

   --------------
   -- User Clocks
   --------------
   signal userClk100 : sl;
   signal userRst100 : sl;

   -----------------------------
   -- Fast Control clock and bus
   -----------------------------
   signal fcClk185 : sl;
   signal fcRst185 : sl;
   signal fcBus    : FastControlBusType;

   -----------
   -- AXI Lite
   -----------
   -- Always check if this agrees with the MMCM configuration
   constant AXIL_CLK_FREQ_C : real := 125.0e6;

   constant NUM_AXIL_MASTERS_C : natural := 2;
   constant FC_RX_AXIL_C       : natural := 0;
   constant FEB_PGP_AXIL_C     : natural := 1;

   constant AXIL_BASE_ADDR_C : slv(31 downto 0) := X"0080_0000";

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      FC_RX_AXIL_C    => (
         baseAddr     => AXIL_BASE_ADDR_C + X"00_0000",
         addrBits     => 20,
         connectivity => X"FFFF"),
      FEB_PGP_AXIL_C  => (
         baseAddr     => AXIL_BASE_ADDR_C + X"10_0000",
         addrBits     => 20,
         connectivity => X"FFFF"));

   signal axilClk          : sl;
   signal axilRst          : sl;
   signal axilReadMaster   : AxiLiteReadMasterType;
   signal axilReadSlave    : AxiLiteReadSlaveType;
   signal axilWriteMaster  : AxiLiteWriteMasterType;
   signal axilWriteSlave   : AxiLiteWriteSlaveType;
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   ------------
   -- DMA
   ------------
   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => DMA_BYTE_WIDTH_G, tDestBits => 8, tIdBits => 3);

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Convert 100 MHz user clock to 125 MHz for AXI-Lite clock
   -------------------------------------------------------------------------------------------------
   U_PwrUpRst : entity surf.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => 500)
      port map (
         arst   => '0',                 -- [in]
         clk    => userClk100,          -- [in]
         rstOut => userRst100);         -- [out]

   U_axilClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "PLL",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 1,
         -- MMCM attributes
         BANDWIDTH_G       => "OPTIMIZED",
         CLKIN_PERIOD_G    => 10.0,     -- 100 MHz
         CLKFBOUT_MULT_G   => 10,       -- 100x10 = 1000 MHz
         CLKOUT0_DIVIDE_G  => 8)        -- 1000/8 = 125  MHz
      port map(
         -- Clock Input
         clkIn     => userClk100,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   -----------------------
   -- axi-pcie-core module
   -----------------------
   U_Core : entity axi_pcie_core.BittWareXupVv8Core
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         ROGUE_SIM_CH_COUNT_G => 4,
         DMA_BURST_BYTES_G    => DMA_BURST_BYTES_G,
         DMA_AXIS_CONFIG_G    => DMA_AXIS_CONFIG_C,
         DMA_SIZE_G           => PGP_QUADS_G)
      port map (
         ------------------------
         --  Top Level Interfaces
         ------------------------
         userClk100      => userClk100,
         -- DMA Interfaces
         dmaClk          => dmaClk,
         dmaRst          => dmaRst,
         dmaBuffGrpPause => dmaBuffGrpPause,
         dmaObMasters    => dmaObMasters,
         dmaObSlaves     => dmaObSlaves,
         dmaIbMasters    => dmaIbMasters,
         dmaIbSlaves     => dmaIbSlaves,
         -- Application AXI-Lite Interfaces [0x00100000:0x00FFFFFF]
         appClk          => axilClk,
         appRst          => axilRst,
         appReadMaster   => axilReadMaster,
         appReadSlave    => axilReadSlave,
         appWriteMaster  => axilWriteMaster,
         appWriteSlave   => axilWriteSlave,
         --------------
         --  Core Ports
         --------------
         -- FPGA I2C Master
         fpgaI2cMasterL  => fpgaI2cMasterL,
         -- System Ports
         userClkP        => userClkP,
         userClkN        => userClkN,
         -- PCIe Ports
         pciRstL         => pciRstL,
         pciRefClkP      => pciRefClkP,
         pciRefClkN      => pciRefClkN,
         pciRxP          => pciRxP,
         pciRxN          => pciRxN,
         pciTxP          => pciTxP,
         pciTxN          => pciTxN);

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
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Fast Control Receiver
   -------------------------------------------------------------------------------------------------
   U_FcReceiver_1 : entity ldmx.FcReceiver
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G => AXIL_XBAR_CFG_C(FC_RX_AXIL_C).baseAddr)
      port map (
         fcRefClk185P    => fcRefClk185P,                    -- [in]
         fcRefClk185N    => fcRefClk185N,                    -- [in]
         fcRecClkP       => fcRecClkP,                       -- [out]
         fcRecClkN       => fcRecClkN,                       -- [out]
         fcTxP           => fcTxP,                           -- [out]
         fcTxN           => fcTxN,                           -- [out]
         fcRxP           => fcRxP,                           -- [in]
         fcRxN           => fcRxN,                           -- [in]
         fcClk185        => fcClk185,                        -- [out]
         fcRst185        => fcRst185,                        -- [out]
         fcBus           => fcBus,                           -- [out]
         fcFb            => FC_FB_INIT_C,                    -- [in]
         fcBunchClk37    => open,                            -- [out]
         fcBunchRst37    => open,                            -- [out]
         axilClk         => axilClk,                         -- [in]
         axilRst         => axilRst,                         -- [in]
         axilReadMaster  => axilReadMasters(FC_RX_AXIL_C),   -- [in]
         axilReadSlave   => axilReadSlaves(FC_RX_AXIL_C),    -- [out]
         axilWriteMaster => axilWriteMasters(FC_RX_AXIL_C),  -- [in]
         axilWriteSlave  => axilWriteSlaves(FC_RX_AXIL_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- PGP Interface to FEBs
   -- Stream Lanes Tied to DMA
   -------------------------------------------------------------------------------------------------
   U_FebPgpArray : entity ldmx.TrackerPgpFcArray
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         PGP_QUADS_G       => 2,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CFG_C(FEB_PGP_AXIL_C).baseAddr)
      port map (
         pgpFcRefClkP    => febPgpFcRefClkP,                   -- [in]
         pgpFcRefClkN    => febPgpFcRefClkN,                   -- [in]
         pgpFcRxP        => febPgpFcRxP,                       -- [in]
         pgpFcRxN        => febPgpFcRxN,                       -- [in]
         pgpFcTxP        => febPgpFcTxP,                       -- [out]
         pgpFcTxN        => febPgpFcTxN,                       -- [out]
         fcClk185        => fcClk185,                          -- [in]
         fcRst185        => fcRst185,                          -- [in]
         fcBus           => fcBus,                             -- [in]
         dmaClk          => dmaClk,                            -- [in]
         dmaRst          => dmaRst,                            -- [in]
         dmaBuffGrpPause => dmaBuffGrpPause,                   -- [in]
         dmaObMasters    => dmaObMasters,                      -- [in]
         dmaObSlaves     => dmaObSlaves,                       -- [out]
         dmaIbMasters    => dmaIbMasters,                      -- [out]
         dmaIbSlaves     => dmaIbSlaves,                       -- [in]
         axilClk         => axilClk,                           -- [in]
         axilRst         => axilRst,                           -- [in]
         axilReadMaster  => axilReadMasters(FEB_PGP_AXIL_C),   -- [in]
         axilReadSlave   => axilReadSlaves(FEB_PGP_AXIL_C),    -- [out]
         axilWriteMaster => axilWriteMasters(FEB_PGP_AXIL_C),  -- [in]
         axilWriteSlave  => axilWriteSlaves(FEB_PGP_AXIL_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- Map DD-QSFP ports
   -------------------------------------------------------------------------------------------------
   -- FC RX is quad 0
   fcRefClk185P   <= qsfpRefClkP(0);
   fcRefClk185N   <= qsfpRefClkN(0);
   qsfpRecClkP(0) <= fcRecClkP;
   qsfpRecClkN(0) <= fcRecClkN;
   qsfpTxP(0)     <= fcTxP;
   qsfpTxN(0)     <= fcTxN;
   fcRxP          <= qsfpRxP(0);
   fcRxN          <= qsfpRxN(0);
   -- Might need dummies for qsfp(3 downto 1)

   -- FEB PGP is QUADS 4 and 5 (banks 124 and 125) since they share the recRefClk with 0
   febPgpFcRefClkP       <= qsfpRefClkP(5 downto 4);
   febPgpFcRefClkN       <= qsfpRefClkN(5 downto 4);
   qsfpTxP(23 downto 16) <= febPgpFcTxP;
   qsfpTxN(23 downto 16) <= febPgpFcTxN;
   febPgpFcRxP           <= qsfpRxP(23 downto 16);
   febPgpFcRxN           <= qsfpRxN(23 downto 16);

   GEN_CLK_BUF : for i in 1 downto 0 generate
      U_ClkOutBufDiff_1 : entity surf.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            clkIn   => fcClk185,        -- [in]
            clkOutP => fabClkOutP(i),   -- [out]
            clkOutN => fabClkOutN(i));  -- [out]
   end generate GEN_CLK_BUF;

   -------------------------------------------------------------------------------------------------
   -- Dummy GTs
   -- Need dummy on every unused GTY in port IO
   -------------------------------------------------------------------------------------------------
--    DUMMY_GEN_1: for i in 3 downto 1 generate
--    U_Gtye4ChannelDummy_1: entity surf.Gtye4ChannelDummy
--       generic map (
--          TPD_G        => TPD_G,
--          SIMULATION_G => SIMULATION_G,
--          WIDTH_G      => WIDTH_G)
--       port map (
--          refClk   => refClk,            -- [in]
--          rxoutclk => rxoutclk,          -- [out]
--          gtRxP    => gtRxP,             -- [in]
--          gtRxN    => gtRxN,             -- [in]
--          gtTxP    => gtTxP,             -- [out]
--          gtTxN    => gtTxN);            -- [out]

--    end generate DUMMY_GEN_1;



end rtl;
