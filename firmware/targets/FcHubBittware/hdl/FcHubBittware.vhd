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

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library ldmx_tdaq;
use ldmx_tdaq.FcPkg.all;

library unisim;
use unisim.vcomponents.all;

entity FcHubBittware is
   generic (
      TPD_G                    : time                        := 1 ns;
      SIM_SPEEDUP_G            : boolean                     := false;
      ROGUE_SIM_EN_G           : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G     : natural range 1024 to 49151 := 11000;
      DMA_BURST_BYTES_G        : integer range 256 to 4096   := 4096;
      DMA_BYTE_WIDTH_G         : integer range 8 to 64       := 8;
      FC_HUB_REFCLKS_G         : integer range 1 to 4        := 1;
      FC_HUB_QUADS_G           : integer range 1 to 4        := 1;
      FC_HUB_QUAD_REFCLK_MAP_G : IntegerArray                := (0 => 0);  --, 1 => 0, 2 => 1, 3 => 1));  -- Map a refclk for each quad
      BUILD_INFO_G             : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP-DD Ports
      qsfpRefClkP    : in  slv(7 downto 0);
      qsfpRefClkN    : in  slv(7 downto 0);
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
      ledL           : out slv(3 downto 0);
      -- PCIe Ports
      pciRstL        : in  sl;
      pciRefClkP     : in  sl;
      pciRefClkN     : in  sl;
      pciRxP         : in  slv(15 downto 0);
      pciRxN         : in  slv(15 downto 0);
      pciTxP         : out slv(15 downto 0);
      pciTxN         : out slv(15 downto 0));
end FcHubBittware;

architecture rtl of FcHubBittware is

   ---------------------------
   -- LCLS-II Timing Interface
   ---------------------------
   signal lclsTimingRefClkP : sl;
   signal lclsTimingRefClkN : sl;
   signal lclsTimingTxP     : sl;
   signal lclsTimingTxN     : sl;
   signal lclsTimingRxP     : sl;
   signal lclsTimingRxN     : sl;
   signal lclsTimingClk     : sl;
   signal lclsTimingRst     : sl;

   --------------------
   --  FC Hub Interface
   --------------------
   signal fcHubRefClkP : slv(FC_HUB_REFCLKS_G-1 downto 0);
   signal fcHubRefClkN : slv(FC_HUB_REFCLKS_G-1 downto 0);
   signal fcHubTxP     : slv(FC_HUB_QUADS_G*4-1 downto 0);
   signal fcHubTxN     : slv(FC_HUB_QUADS_G*4-1 downto 0);
   signal fcHubRxP     : slv(FC_HUB_QUADS_G*4-1 downto 0);
   signal fcHubRxN     : slv(FC_HUB_QUADS_G*4-1 downto 0);

   -------
   -- Misc
   -------
   signal dummyGlobalTriggerRor : FcTimestampType := FC_TIMESTAMP_INIT_C;
   signal dummyRxOutClk         : slv(31 downto 1);
   signal fcTxMsgValid          : sl;

   --------------
   -- User Clocks
   --------------
   signal userClk100 : sl;

   -----------
   -- AXI Lite
   -----------
   -- Always check if this agrees with the MMCM configuration
   constant AXIL_CLK_FREQ_C : real := 125.0e6;

   constant NUM_AXIL_MASTERS_C : natural := 1;
   constant AXIL_FC_HUB_C      : natural := 0;

   constant AXIL_BASE_ADDR_C : slv(31 downto 0) := X"0080_0000";

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      AXIL_FC_HUB_C   => (
         baseAddr     => AXIL_BASE_ADDR_C + X"00_0000",
         addrBits     => 22,
         connectivity => X"FFFF"));

   signal axilClk          : sl;
   signal axilRst          : sl;
   signal stableClk        : sl;
   signal stableRst        : sl;
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
   signal dmaObMasters    : AxiStreamMasterArray(0 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(0 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(0 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(0 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Convert 100 MHz userClk to 125 MHz for AXI-Lite clock and 78.125 MHz for Timing GT stableClk
   -------------------------------------------------------------------------------------------------
   U_AxiClkStableClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G             => TPD_G,
         TYPE_G            => "MMCM",
         INPUT_BUFG_G      => false,
         FB_BUFG_G         => true,
         RST_IN_POLARITY_G => '1',
         NUM_CLOCKS_G      => 2,
         -- MMCM attributes
         BANDWIDTH_G       => "OPTIMIZED",
         CLKIN_PERIOD_G    => 10.0,     -- 100 MHz
         CLKFBOUT_MULT_F_G => 12.5,     -- 100x12.5 = 1250   MHz
         CLKOUT0_DIVIDE_G  => 10,       -- 1250/10  = 125    MHz
         CLKOUT1_DIVIDE_G  => 16)       -- 1250/16  = 78.125 MHz
      port map(
         -- Clock Input
         clkIn     => userClk100,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         clkOut(1) => stableClk,
         -- Reset Outputs
         rstOut(0) => axilRst,
         rstOut(1) => stableRst);

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
         DMA_SIZE_G           => 1)
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
   -- Timing Hub
   -------------------------------------------------------------------------------------------------
   U_FcHub_1 : entity ldmx_tdaq.FcHub
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
         REFCLKS_G         => FC_HUB_REFCLKS_G,
         QUADS_G           => FC_HUB_QUADS_G,
         QUAD_REFCLK_MAP_G => FC_HUB_QUAD_REFCLK_MAP_G,
         AXIL_CLK_FREQ_G   => AXIL_CLK_FREQ_C,
         AXIL_BASE_ADDR_G  => AXIL_XBAR_CFG_C(AXIL_FC_HUB_C).baseAddr)
      port map (
         stableClk             => stableClk,                           -- [in]
         stableRst             => stableRst,                           -- [in]
         lclsTimingRefClkP     => lclsTimingRefClkP,                   -- [in]
         lclsTimingRefClkN     => lclsTimingRefClkN,                   -- [in]
         lclsTimingRxP         => lclsTimingRxP,                       -- [in]
         lclsTimingRxN         => lclsTimingRxN,                       -- [in]
         lclsTimingTxP         => lclsTimingTxP,                       -- [out]
         lclsTimingTxN         => lclsTimingTxN,                       -- [out]
         lclsTimingClkOut      => lclsTimingClk,                       -- [out]
         lclsTimingRstOut      => lclsTimingRst,                       -- [out]
         globalTriggerRor      => dummyGlobalTriggerRor,               -- [in]
         fcTxMsgValid          => fcTxMsgValid,                        -- [out]
         fcHubRefClkP          => fcHubRefClkP,                        -- [in]
         fcHubRefClkN          => fcHubRefClkN,                        -- [in]
         fcHubTxP              => fcHubTxP,                            -- [out]
         fcHubTxN              => fcHubTxN,                            -- [out]
         fcHubRxP              => fcHubRxP,                            -- [in]
         fcHubRxN              => fcHubRxN,                            -- [in]
         axilClk               => axilClk,                             -- [in]
         axilRst               => axilRst,                             -- [in]
         axilReadMaster        => axilReadMasters(AXIL_FC_HUB_C),      -- [in]
         axilReadSlave         => axilReadSlaves(AXIL_FC_HUB_C),       -- [out]
         axilWriteMaster       => axilWriteMasters(AXIL_FC_HUB_C),     -- [in]
         axilWriteSlave        => axilWriteSlaves(AXIL_FC_HUB_C));     -- [out]

   -------------------------------------------------------------------------------------------------
   -- Map DD-QSFP ports
   -------------------------------------------------------------------------------------------------
   -- LCLS-II Timing RX is quad 0
   lclsTimingRefClkP <= qsfpRefClkP(0);
   lclsTimingRefClkN <= qsfpRefClkN(0);
   qsfpTxP(0)        <= lclsTimingTxP;
   qsfpTxN(0)        <= lclsTimingTxN;
   lclsTimingRxP     <= qsfpRxP(0);
   lclsTimingRxN     <= qsfpRxN(0);

   -- Debugging Outputs
   GEN_DBG: for i in 3 downto 0 generate
      ledL(i) <= fcTxMsgValid;
   end generate GEN_DBG;

   -- FC Hub PGP is QUADS 4 and 5 (banks 124 and 125) since they share the recRefClk with 0
   GEN_FEB_REFCLK : for i in FC_HUB_QUADS_G-1 downto 0 generate
      fcHubRefClkP(i) <= qsfpRefClkP(i+4);
      fcHubRefClkN(i) <= qsfpRefClkN(i+4);
   end generate GEN_FEB_REFCLK;

   qsfpTxP(FC_HUB_QUADS_G*4+15 downto 16) <= fcHubTxP;
   qsfpTxN(FC_HUB_QUADS_G*4+15 downto 16) <= fcHubTxN;
   fcHubRxP                               <= qsfpRxP(FC_HUB_QUADS_G*4+15 downto 16);
   fcHubRxN                               <= qsfpRxN(FC_HUB_QUADS_G*4+15 downto 16);

   GEN_CLK_BUF : for i in 1 downto 0 generate
      U_ClkOutBufDiff_1 : entity surf.ClkOutBufDiff
         generic map (
            TPD_G        => TPD_G,
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            clkIn   => lclsTimingClk,   -- [in]
            clkOutP => fabClkOutP(i),   -- [out]
            clkOutN => fabClkOutN(i));  -- [out]
   end generate GEN_CLK_BUF;

   -------------------------------------------------------------------------------------------------
   -- Dummy GTs
   -- Need dummy on every unused GTY in port IO
   -------------------------------------------------------------------------------------------------
   U_Gtye4ChannelDummy_1 : entity surf.Gtye4ChannelDummy
      generic map (
         TPD_G        => TPD_G,
         SIMULATION_G => true,
         WIDTH_G      => 3)
      port map (
         refClk   => axilClk,                    -- [in]
         rxoutClk => dummyRxOutClk(3 downto 1),  -- [out]
         gtRxP    => qsfpRxP(3 downto 1),        -- [in]
         gtRxN    => qsfpRxN(3 downto 1),        -- [in]
         gtTxP    => qsfpTxP(3 downto 1),        -- [out]
         gtTxN    => qsfpTxN(3 downto 1));       -- [out]

   U_Gtye4ChannelDummy_2 : entity surf.Gtye4ChannelDummy
      generic map (
         TPD_G        => TPD_G,
         SIMULATION_G => true,
         WIDTH_G      => 12)
      port map (
         refClk   => axilClk,                     -- [in]
         rxoutClk => dummyRxOutClk(15 downto 4),  -- [out]
         gtRxP    => qsfpRxP(15 downto 4),        -- [in]
         gtRxN    => qsfpRxN(15 downto 4),        -- [in]
         gtTxP    => qsfpTxP(15 downto 4),        -- [out]
         gtTxN    => qsfpTxN(15 downto 4));       -- [out]

   U_Gtye4ChannelDummy_3 : entity surf.Gtye4ChannelDummy
      generic map (
         TPD_G        => TPD_G,
         SIMULATION_G => true,
         WIDTH_G      => 32-(FC_HUB_QUADS_G*4+16))
      port map (
         refClk   => axilClk,                      -- [in]
         rxoutClk => dummyRxOutClk(31 downto FC_HUB_QUADS_G*4+16),  -- [out]
         gtRxP    => qsfpRxP(31 downto FC_HUB_QUADS_G*4+16),        -- [in]
         gtRxN    => qsfpRxN(31 downto FC_HUB_QUADS_G*4+16),        -- [in]
         gtTxP    => qsfpTxP(31 downto FC_HUB_QUADS_G*4+16),        -- [out]
         gtTxN    => qsfpTxN(31 downto FC_HUB_QUADS_G*4+16));       -- [out]

end rtl;
