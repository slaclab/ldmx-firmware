-------------------------------------------------------------------------------
-- Title      : Testbench for design "BittWareXupVv8Pgp2fc"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of pgp-pcie-apps. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of pgp-pcie-apps, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

library ldmx_tracker;

----------------------------------------------------------------------------------------------------

entity TrackerBittwareSim is
   generic (
      TPD_G                : time                        := 0.2 ns;
      BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;
      SIM_SPEEDUP_G        : boolean                     := true;
      ROGUE_SIM_EN_G       : boolean                     := true;
      ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
      PGP_QUADS_G          : integer                     := 1);
   port (
      fcRxP     : in  sl;
      fcRxN     : in  sl;
      fcTxP     : out sl;
      fcTxN     : out sl;
      qsfpRecClkP : out slv(PGP_QUADS_G-1 downto 0);
      qsfpRecClkN : out slv(PGP_QUADS_G-1 downto 0);
      febPgpFcRxP : in  slv(PGP_QUADS_G*4-1 downto 0);   -- [in]
      febPgpFcRxN : in  slv(PGP_QUADS_G*4-1 downto 0);   -- [in]
      febPgpFcTxP : out slv(PGP_QUADS_G*4-1 downto 0);   -- [out]
      febPgpFcTxN : out slv(PGP_QUADS_G*4-1 downto 0));  -- [out]

end entity TrackerBittwareSim;

----------------------------------------------------------------------------------------------------

architecture sim of TrackerBittwareSim is

   -- component generics
   constant DMA_BURST_BYTES_G : integer range 256 to 4096 := 4096;
   constant DMA_BYTE_WIDTH_G  : integer range 8 to 64     := 8;

   -- component ports
   signal qsfpRefClkP    : slv(7 downto 0)  := (others => '0');  -- [in]
   signal qsfpRefClkN    : slv(7 downto 0)  := (others => '0');  -- [in]
   signal qsfpRxP        : slv(31 downto 0) := (others => '0');  -- [in]
   signal qsfpRxN        : slv(31 downto 0) := (others => '0');  -- [in]
   signal qsfpTxP        : slv(31 downto 0) := (others => '0');  -- [out]
   signal qsfpTxN        : slv(31 downto 0) := (others => '0');  -- [out]
   signal fabClkOutP     : slv(1 downto 0)  := (others => '0');  -- [out]
   signal fabClkOutN     : slv(1 downto 0)  := (others => '0');  -- [out]
   signal fpgaI2cMasterL : sl               := '0';              -- [out]
   signal userClkP       : sl               := '0';              -- [in]
   signal userClkN       : sl               := '0';              -- [in]
   signal pciRstL        : sl               := '0';              -- [in]
   signal pciRefClkP     : sl               := '0';              -- [in]
   signal pciRefClkN     : sl               := '0';              -- [in]
   signal pciRxP         : slv(15 downto 0) := (others => '0');  -- [in]
   signal pciRxN         : slv(15 downto 0) := (others => '0');  -- [in]
   signal pciTxP         : slv(15 downto 0) := (others => '0');  -- [out]
   signal pciTxN         : slv(15 downto 0) := (others => '0');  -- [out]

   -- Internal signals
   signal fcRefClk185P    : sl;
   signal fcRefClk185N    : sl;


begin

   fcTxP <= qsfpTxP(0);
   fcTxN <= qsfpTxN(0);
   qsfpRxP(0) <= fcRxP;
   qsfpRxN(0) <= fcRxN;

   febPgpFcTxP(PGP_QUADS_G*4-1 downto 0) <= qsfpTxP(PGP_QUADS_G*4+15 downto 16);
   febPgpFcTxN(PGP_QUADS_G*4-1 downto 0) <= qsfpTxN(PGP_QUADS_G*4+15 downto 16);
   qsfpRxP(PGP_QUADS_G*4+15 downto 16) <= febPgpFcRxP(PGP_QUADS_G*4-1 downto 0);
   qsfpRxN(PGP_QUADS_G*4+15 downto 16) <= febPgpFcRxN(PGP_QUADS_G*4-1 downto 0);


   -- FPGA
   U_TrackerBittware_1 : entity ldmx_tracker.TrackerBittware
      generic map (
         TPD_G                => TPD_G,
         SIM_SPEEDUP_G        => SIM_SPEEDUP_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         DMA_BURST_BYTES_G    => DMA_BURST_BYTES_G,
         DMA_BYTE_WIDTH_G     => DMA_BYTE_WIDTH_G,
         PGP_QUADS_G          => PGP_QUADS_G,
         BUILD_INFO_G         => BUILD_INFO_G)
      port map (
         qsfpRefClkP    => qsfpRefClkP,     -- [in]
         qsfpRefClkN    => qsfpRefClkN,     -- [in]
         qsfpRecClkP    => qsfpRecClkP,     -- [out]
         qsfpRecClkN    => qsfpRecClkN,     -- [out]
         qsfpRxP        => qsfpRxP,         -- [in]
         qsfpRxN        => qsfpRxN,         -- [in]
         qsfpTxP        => qsfpTxP,         -- [out]
         qsfpTxN        => qsfpTxN,         -- [out]
         fabClkOutP     => fabClkOutP,      -- [out]
         fabClkOutN     => fabClkOutN,      -- [out]
         fpgaI2cMasterL => fpgaI2cMasterL,  -- [out]
         userClkP       => userClkP,        -- [in]
         userClkN       => userClkN,        -- [in]
         pciRstL        => pciRstL,         -- [in]
         pciRefClkP     => pciRefClkP,      -- [in]
         pciRefClkN     => pciRefClkN,      -- [in]
         pciRxP         => pciRxP,          -- [in]
         pciRxN         => pciRxN,          -- [in]
         pciTxP         => pciTxP,          -- [out]
         pciTxN         => pciTxN);         -- [out]

   -- Fast Control Refclk
   U_ClkRst_REFCLK : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 5.3848 ns,  -- 185.714285 MHz = 5.3846 ns
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => fcRefClk185P,
         clkN => fcRefClk185N);

   -- FC is on quad 0
   qsfpRefClkP(0) <= fcRefClk185P;
   qsfpRefClkN(0) <= fcRefClk185N;

   -- FEB PGP is QUADS 4 and 5 (banks 124 and 125) since they share the recRefClk with 0
   GEN_PGP_REFCLK: for i in PGP_QUADS_G-1 downto 0 generate
      qsfpRefClkP(i+4) <= fabClkOutP(0);
      qsfpRefClkN(i+4) <= fabClkOutN(0);
   end generate GEN_PGP_REFCLK;

   U_ClkRst_USERCLK : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 10.0 ns,  -- 100.0 MHz = 10.0 ns
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => userClkP,
         clkN => userClkN);

   pciRefClkP <= userClkP;
   pciRefClkN <= userClkN;


end architecture sim;

----------------------------------------------------------------------------------------------------
