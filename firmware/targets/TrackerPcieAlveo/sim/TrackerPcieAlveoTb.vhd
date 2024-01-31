-------------------------------------------------------------------------------
-- Title      : Testbench for design "TrackerPcieAlveo"
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
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

library surf;
use surf.StdRtlPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

library ldmx;

----------------------------------------------------------------------------------------------------

entity TrackerPcieAlveoTb is

end entity TrackerPcieAlveoTb;

----------------------------------------------------------------------------------------------------

architecture sim of TrackerPcieAlveoTb is

   -- component generics
   constant TPD_G                : time                        := 1 ns;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
   constant DMA_BYTE_WIDTH_G     : integer range 8 to 64       := 16;
   constant BUILD_INFO_G         : BuildInfoType               := BUILD_INFO_C;

   -- component ports
   signal ddrClkP       : sl                    := '0';                          -- [in]
   signal ddrClkN       : sl                    := '0';                          -- [in]
   signal qsfp0RefClkP  : slv(1 downto 0)       := (others => '0');              -- [in]
   signal qsfp0RefClkN  : slv(1 downto 0)       := (others => '0');              -- [in]
   signal qsfp0RxP      : slv(3 downto 0)       := (others => '0');              -- [in]
   signal qsfp0RxN      : slv(3 downto 0)       := (others => '0');              -- [in]
   signal qsfp0TxP      : slv(3 downto 0)       := (others => '0');              -- [out]
   signal qsfp0TxN      : slv(3 downto 0)       := (others => '0');              -- [out]
   signal qsfp1RefClkP  : slv(1 downto 0)       := (others => '0');              -- [in]
   signal qsfp1RefClkN  : slv(1 downto 0)       := (others => '0');              -- [in]
   signal qsfp1RxP      : slv(3 downto 0)       := (others => '0');              -- [in]
   signal qsfp1RxN      : slv(3 downto 0)       := (others => '0');              -- [in]
   signal qsfp1TxP      : slv(3 downto 0)       := (others => '0');              -- [out]
   signal qsfp1TxN      : slv(3 downto 0)       := (others => '0');              -- [out]
   signal userClkP      : sl                    := '0';                          -- [in]
   signal userClkN      : sl                    := '0';                          -- [in]
   signal i2cRstL       : sl                    := '1';                          -- [out]
   signal i2cScl        : sl                    := 'H';                          -- [inout]
   signal i2cSda        : sl                    := 'H';                          -- [inout]
   signal qsfpFs        : Slv2Array(1 downto 0) := (others => (others => '0'));  -- [out]
   signal qsfpRefClkRst : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpRstL      : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpLpMode    : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpModSelL   : slv(1 downto 0)       := (others => '0');              -- [out]
   signal qsfpModPrsL   : slv(1 downto 0)       := (others => '0');              -- [in]
   signal pciRstL       : sl                    := '1';                          -- [in]
   signal pciRefClkP    : sl                    := '0';                          -- [in]
   signal pciRefClkN    : sl                    := '0';                          -- [in]
   signal pciRxP        : slv(15 downto 0)      := (others => '0');              -- [in]
   signal pciRxN        : slv(15 downto 0)      := (others => '0');              -- [in]
   signal pciTxP        : slv(15 downto 0)      := (others => '0');              -- [out]
   signal pciTxN        : slv(15 downto 0)      := (others => '0');              -- [out]

begin

   -- component instantiation
   U_TrackerPcieAlveo : entity ldmx.TrackerPcieAlveo
      generic map (
         TPD_G                => TPD_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         DMA_BYTE_WIDTH_G     => DMA_BYTE_WIDTH_G,
         BUILD_INFO_G         => BUILD_INFO_G)
      port map (
         ddrClkP       => ddrClkP,        -- [in]
         ddrClkN       => ddrClkN,        -- [in]
         qsfp0RefClkP  => qsfp0RefClkP,   -- [in]
         qsfp0RefClkN  => qsfp0RefClkN,   -- [in]
         qsfp0RxP      => qsfp0RxP,       -- [in]
         qsfp0RxN      => qsfp0RxN,       -- [in]
         qsfp0TxP      => qsfp0TxP,       -- [out]
         qsfp0TxN      => qsfp0TxN,       -- [out]
         qsfp1RefClkP  => qsfp1RefClkP,   -- [in]
         qsfp1RefClkN  => qsfp1RefClkN,   -- [in]
         qsfp1RxP      => qsfp1RxP,       -- [in]
         qsfp1RxN      => qsfp1RxN,       -- [in]
         qsfp1TxP      => qsfp1TxP,       -- [out]
         qsfp1TxN      => qsfp1TxN,       -- [out]
         userClkP      => userClkP,       -- [in]
         userClkN      => userClkN,       -- [in]
         i2cRstL       => i2cRstL,        -- [out]
         i2cScl        => i2cScl,         -- [inout]
         i2cSda        => i2cSda,         -- [inout]
         qsfpFs        => qsfpFs,         -- [out]
         qsfpRefClkRst => qsfpRefClkRst,  -- [out]
         qsfpRstL      => qsfpRstL,       -- [out]
         qsfpLpMode    => qsfpLpMode,     -- [out]
         qsfpModSelL   => qsfpModSelL,    -- [out]
         qsfpModPrsL   => qsfpModPrsL,    -- [in]
         pciRstL       => pciRstL,        -- [in]
         pciRefClkP    => pciRefClkP,     -- [in]
         pciRefClkN    => pciRefClkN,     -- [in]
         pciRxP        => pciRxP,         -- [in]
         pciRxN        => pciRxN,         -- [in]
         pciTxP        => pciTxP,         -- [out]
         pciTxN        => pciTxN);        -- [out]


   -------------------------------------------------------------------------------------------------
   -- Clocks
   -------------------------------------------------------------------------------------------------
   U_ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 3.332 ns,
         CLK_DELAY_G  => 1 ns)
      port map (
         clkP => ddrClkP,
         clkN => ddrClkN);

   U_ClkRst_2 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 6.4 ns,
         CLK_DELAY_G  => 1 ns)
      port map (
         clkP => qsfp0RefClkP(0),
         clkN => qsfp0RefClkN(0));

   U_ClkRst_3 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 5.385 ns,
         CLK_DELAY_G  => 1 ns)
      port map (
         clkP => qsfp0RefClkP(1),
         clkN => qsfp0RefClkN(1));

   qsfp1RefClkP <= qsfp0RefClkP;
   qsfp1RefClkN <= qsfp0RefClkN;
   userClkP     <= qsfp0RefClkP(1);
   userClkN     <= qsfp0RefClkN(1);

   U_ClkRst_4 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 10.0 ns,
         CLK_DELAY_G  => 1 ns)
      port map (
         clkP => pciRefClkP,
         clkN => pciRefClkN);

   -------------------------------------------------------------------------------------------------
   -- Loopback
   -------------------------------------------------------------------------------------------------
   qsfp0RxP <= qsfp0TxP;
   qsfp0RxN <= qsfp0TxN;
   qsfp1RxP <= qsfp1TxP;
   qsfp1RxN <= qsfp1TxN;


end architecture sim;

----------------------------------------------------------------------------------------------------
