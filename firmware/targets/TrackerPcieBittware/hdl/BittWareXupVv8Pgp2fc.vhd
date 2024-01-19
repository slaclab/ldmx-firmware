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

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ldmx;

library axi_pcie_core;
use axi_pcie_core.AxiPciePkg.all;

library unisim;
use unisim.vcomponents.all;

entity BittWareXupVv8Pgp2fc is
   generic (
      TPD_G                : time                        := 1 ns;
      SIM_SPEEDUP_G        : boolean                     := true;
      ROGUE_SIM_EN_G       : boolean                     := false;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 8000;
      DMA_BURST_BYTES_G    : integer range 256 to 4096   := 4096;
      DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 8;
      PGP_QUADS_G          : integer                     := 1;
      BUILD_INFO_G         : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP-DD Ports
      qsfpRefClkP : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRefClkN : in  slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkP : out slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkN : out slv(PGP_QUADS_G-1 downto 0);
      qsfpRxP     : in  slv(PGP_QUADS_G*4-1 downto 0);
      qsfpRxN     : in  slv(PGP_QUADS_G*4-1 downto 0);
      qsfpTxP     : out slv(PGP_QUADS_G*4-1 downto 0);
      qsfpTxN     : out slv(PGP_QUADS_G*4-1 downto 0);
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
end BittWareXupVv8Pgp2fc;

architecture top_level of BittWareXupVv8Pgp2fc is

   constant DMA_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(dataBytes => DMA_BYTE_WIDTH_G, tDestBits => 8, tIdBits => 3);

   -- Always check if this agrees with the MMCM configuration
   constant AXI_CLK_FREQ_C : real := 125.0e6;

   signal userClk100      : sl;
   signal userRst100      : sl;
   signal axilClk         : sl;
   signal axilRst         : sl;
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal dmaClk          : sl;
   signal dmaRst          : sl;
   signal dmaBuffGrpPause : slv(7 downto 0);
   signal dmaObMasters    : AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);
   signal dmaIbMasters    : AxiStreamMasterArray(PGP_QUADS_G-1 downto 0);
   signal dmaIbSlaves     : AxiStreamSlaveArray(PGP_QUADS_G-1 downto 0);

begin

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
         CLKIN_PERIOD_G    => 10.0, -- 100 MHz
         CLKFBOUT_MULT_G   => 10,   -- 100x10 = 1000 MHz
         CLKOUT0_DIVIDE_G  => 8)    -- 1000/8 = 125  MHz
      port map(
         -- Clock Input
         clkIn     => userClk100,
         rstIn     => dmaRst,
         -- Clock Outputs
         clkOut(0) => axilClk,
         -- Reset Outputs
         rstOut(0) => axilRst);

   U_PwrUpRst : entity surf.PwrUpRst
      generic map (
         TPD_G      => TPD_G,
         DURATION_G => 500)
      port map (
         arst   => '0',                 -- [in]
         clk    => userClk100,          -- [in]
         rstOut => userRst100);         -- [out]

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

   U_PgpLaneWrapper : entity ldmx.PgpLaneWrapper
      generic map (
         TPD_G             => TPD_G,
         SIM_SPEEDUP_G     => SIM_SPEEDUP_G,
         DMA_AXIS_CONFIG_G => DMA_AXIS_CONFIG_C,
         PGP_QUADS_G       => PGP_QUADS_G,
         AXI_CLK_FREQ_G    => AXI_CLK_FREQ_C,
         AXI_BASE_ADDR_G   => X"0080_0000")
      port map (
         qsfpRefClkP     => qsfpRefClkP,      -- [in]
         qsfpRefClkN     => qsfpRefClkN,      -- [in]
         qsfpRecClkP     => qsfpRecClkP,      -- [out]
         qsfpRecClkN     => qsfpRecClkN,      -- [out]
         qsfpRxP         => qsfpRxP,          -- [in]
         qsfpRxN         => qsfpRxN,          -- [in]
         qsfpTxP         => qsfpTxP,          -- [out]
         qsfpTxN         => qsfpTxN,          -- [out]
         dmaClk          => dmaClk,           -- [in]
         dmaRst          => dmaRst,           -- [in]
         dmaBuffGrpPause => dmaBuffGrpPause,  -- [in]
         dmaObMasters    => dmaObMasters,     -- [in]
         dmaObSlaves     => dmaObSlaves,      -- [out]
         dmaIbMasters    => dmaIbMasters,     -- [out]
         dmaIbSlaves     => dmaIbSlaves,      -- [in]
         axilClk         => axilClk,          -- [in]
         axilRst         => axilRst,          -- [in]
         axilReadMaster  => axilReadMaster,   -- [in]
         axilReadSlave   => axilReadSlave,    -- [out]
         axilWriteMaster => axilWriteMaster,  -- [in]
         axilWriteSlave  => axilWriteSlave);  -- [out]


--    U_DmaXvc : entity work.DmaXvcWrapper
--       generic map(
--          TPD_G          => TPD_G,
--          COMMON_CLOCK_G => false,
--          AXIS_CONFIG_G  => DMA_AXIS_CONFIG_C)
--       port map(
--          -- Clock and Reset (xvcClk domain)
--          xvcClk       => clk156,
--          xvcRst       => rst156,
--          -- Clock and Reset (pgpClk domain)
--          axisClk      => dmaClk,
--          axisRst      => dmaRst,
--          -- OB Stream
--          obFifoMaster => dmaObMasters(1),
--          obFifoSlave  => dmaObSlaves(1),
--          -- IB Stream
--          ibFifoSlave  => dmaIbSlaves(1),
--          ibFifoMaster => dmaIbMasters(1));

end top_level;
