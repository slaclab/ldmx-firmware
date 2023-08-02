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

----------------------------------------------------------------------------------------------------

entity BittWareXupVv8Pgp2fcTb is

end entity BittWareXupVv8Pgp2fcTb;

----------------------------------------------------------------------------------------------------

architecture sim of BittWareXupVv8Pgp2fcTb is

   -- component generics
   constant TPD_G                : time                        := 0.2 ns;
   constant SIM_SPEEDUP_G        : boolean                     := true;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
   constant DMA_BURST_BYTES_G    : integer range 256 to 4096   := 4096;
   constant DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 8;
   constant PGP_QUADS_G          : integer                     := 1;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;

   -- component ports
   signal qsfpRefClkP    : slv(PGP_QUADS_G-1 downto 0);    -- [in]
   signal qsfpRefClkN    : slv(PGP_QUADS_G-1 downto 0);    -- [in]
   signal qsfpRxP        : slv(PGP_QUADS_G*4-1 downto 0);  -- [in]
   signal qsfpRxN        : slv(PGP_QUADS_G*4-1 downto 0);  -- [in]
   signal qsfpTxP        : slv(PGP_QUADS_G*4-1 downto 0);  -- [out]
   signal qsfpTxN        : slv(PGP_QUADS_G*4-1 downto 0);  -- [out]
   signal fpgaI2cMasterL : sl;                             -- [out]
   signal userClkP       : sl;                             -- [in]
   signal userClkN       : sl;                             -- [in]
   signal pciRstL        : sl := '1';                      -- [in]
   signal pciRefClkP     : sl;                             -- [in]
   signal pciRefClkN     : sl;                             -- [in]
   signal pciRxP         : slv(15 downto 0);               -- [in]
   signal pciRxN         : slv(15 downto 0);               -- [in]
   signal pciTxP         : slv(15 downto 0);               -- [out]
   signal pciTxN         : slv(15 downto 0);               -- [out]

begin

   -- component instantiation
   U_BittWareXupVv8Pgp2fc : entity work.BittWareXupVv8Pgp2fc
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
         qsfpRxP        => qsfpRxP,         -- [in]
         qsfpRxN        => qsfpRxN,         -- [in]
         qsfpTxP        => qsfpTxP,         -- [out]
         qsfpTxN        => qsfpTxN,         -- [out]
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


   GEN_REFCLKS : for i in PGP_QUADS_G-1 downto 0 generate
      U_ClkRst_REFCLK : entity surf.ClkRst
         generic map (
            CLK_PERIOD_G      => 5.3846 ns, -- 185.714285 MHz = 5.3846 ns
            CLK_DELAY_G       => 1 ns,
            RST_START_DELAY_G => 0 ns,
            RST_HOLD_TIME_G   => 5 us,
            SYNC_RESET_G      => true)
         port map (
            clkP => qsfpRefClkP(i),
            clkN => qsfpRefClkN(i));
   end generate;

   U_ClkRst_USERCLK : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 10.0 ns, -- 100.0 MHz = 10.0 ns
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => userClkP,
         clkN => userClkN);

   pciRefClkP <= userClkP;
   pciRefClkN <= userClkN;

   qsfpRxP <= qsfpTxP;
   qsfpRxN <= qsfpTxN;


end architecture sim;

----------------------------------------------------------------------------------------------------
