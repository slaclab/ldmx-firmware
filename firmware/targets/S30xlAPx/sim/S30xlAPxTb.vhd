-------------------------------------------------------------------------------
-- Title      : Testbench for design "S30xlAPx"
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

library ldmx_ts;

----------------------------------------------------------------------------------------------------

entity S30xlAPxTb is

end entity S30xlAPxTb;

----------------------------------------------------------------------------------------------------

architecture sim of S30xlAPxTb is

   -- component generics
   constant TPD_G                    : time                 := 1 ns;
   constant BUILD_INFO_G             : BuildInfoType        := BUILD_INFO_DEFAULT_SLV_C;
   constant SIMULATION_G             : boolean              := true;
   constant SIM_SRP_PORT_NUM_G       : integer              := 12000;
   constant SIM_DATA_PORT_NUM_G      : integer              := 13000;
   constant DHCP_G                   : boolean              := false;
   constant IP_ADDR_G                : slv(31 downto 0)     := x"0A01A8C0";
   constant MAC_ADDR_G               : slv(47 downto 0)     := x"00_00_16_56_00_08";
   constant TS_LANES_G               : integer              := 2;
   constant TS_REFCLKS_G             : integer              := 1;
   constant TS_REFCLK_MAP_G          : IntegerArray         := (0 => 0, 1 => 0);
   constant FC_HUB_REFCLKS_G         : integer range 1 to 4 := 1;
   constant FC_HUB_QUADS_G           : integer range 1 to 4 := 1;
   constant FC_HUB_QUAD_REFCLK_MAP_G : IntegerArray         := (0 => 0);

   -- component ports
   signal clk125InP            : sl;                                                   -- [in]
   signal clk125InN            : sl;                                                   -- [in]
   signal clk125OutP           : slv(1 downto 0);                                      -- [out]
   signal clk125OutN           : slv(1 downto 0);                                      -- [out]
   signal lclsTimingRefClkP    : sl;                                                   -- [in]
   signal lclsTimingRefClkN    : sl;                                                   -- [in]
   signal lclsTimingRxP        : sl;                                                   -- [in]
   signal lclsTimingRxN        : sl;                                                   -- [in]
   signal lclsTimingTxP        : sl;                                                   -- [out]
   signal lclsTimingTxN        : sl;                                                   -- [out]
   signal lclsTimingRecClkOutP : slv(1 downto 0);                                      -- [out]
   signal lclsTimingRecClkOutN : slv(1 downto 0);                                      -- [out]
   signal fcHubRefClkP         : slv(FC_HUB_REFCLKS_G-1 downto 0);                     -- [in]
   signal fcHubRefClkN         : slv(FC_HUB_REFCLKS_G-1 downto 0);                     -- [in]
   signal fcHubTxP             : slv(FC_HUB_QUADS_G*4-1 downto 0);                     -- [out]
   signal fcHubTxN             : slv(FC_HUB_QUADS_G*4-1 downto 0);                     -- [out]
   signal fcHubRxP             : slv(FC_HUB_QUADS_G*4-1 downto 0) := (others => '0');  -- [in]
   signal fcHubRxN             : slv(FC_HUB_QUADS_G*4-1 downto 0) := (others => '1');  -- [in]
   signal appFcRefClkP         : sl;                                                   -- [in]
   signal appFcRefClkN         : sl;                                                   -- [in]
   signal appFcRxP             : sl;                                                   -- [in]
   signal appFcRxN             : sl;                                                   -- [in]
   signal appFcTxP             : sl;                                                   -- [out]
   signal appFcTxN             : sl;                                                   -- [out]
   signal tsRefClk250P         : slv(TS_REFCLKS_G-1 downto 0);                         -- [in]
   signal tsRefClk250N         : slv(TS_REFCLKS_G-1 downto 0);                         -- [in]
   signal tsDataRxP            : slv(TS_LANES_G-1 downto 0);                           -- [in]
   signal tsDataRxN            : slv(TS_LANES_G-1 downto 0);                           -- [in]
   signal ethRefClk156P        : sl;                                                   -- [in]
   signal ethRefClk156N        : sl;                                                   -- [in]
   signal ethTxP               : sl                               := '0';              -- [out]
   signal ethTxN               : sl                               := '0';              -- [out]
   signal ethRxP               : sl                               := '0';              -- [in]
   signal ethRxN               : sl                               := '0';              -- [in]

begin

   -- component instantiation
   U_S30xlAPx : entity ldmx_ts.S30xlAPx
      generic map (
         TPD_G                    => TPD_G,
         BUILD_INFO_G             => BUILD_INFO_G,
         SIMULATION_G             => SIMULATION_G,
         SIM_SRP_PORT_NUM_G       => SIM_SRP_PORT_NUM_G,
         SIM_DATA_PORT_NUM_G      => SIM_DATA_PORT_NUM_G,
         DHCP_G                   => DHCP_G,
         IP_ADDR_G                => IP_ADDR_G,
         MAC_ADDR_G               => MAC_ADDR_G,
         TS_LANES_G               => TS_LANES_G,
         TS_REFCLKS_G             => TS_REFCLKS_G,
         TS_REFCLK_MAP_G          => TS_REFCLK_MAP_G,
         FC_HUB_REFCLKS_G         => FC_HUB_REFCLKS_G,
         FC_HUB_QUADS_G           => FC_HUB_QUADS_G,
         FC_HUB_QUAD_REFCLK_MAP_G => FC_HUB_QUAD_REFCLK_MAP_G)
      port map (
         clk125InP            => clk125InP,             -- [in]
         clk125InN            => clk125InN,             -- [in]
         clk125OutP           => clk125OutP,            -- [out]
         clk125OutN           => clk125OutN,            -- [out]
         lclsTimingRefClkP    => lclsTimingRefClkP,     -- [in]
         lclsTimingRefClkN    => lclsTimingRefClkN,     -- [in]
         lclsTimingRxP        => lclsTimingRxP,         -- [in]
         lclsTimingRxN        => lclsTimingRxN,         -- [in]
         lclsTimingTxP        => lclsTimingTxP,         -- [out]
         lclsTimingTxN        => lclsTimingTxN,         -- [out]
         lclsTimingRecClkOutP => lclsTimingRecClkOutP,  -- [out]
         lclsTimingRecClkOutN => lclsTimingRecClkOutN,  -- [out]
         fcHubRefClkP         => fcHubRefClkP,          -- [in]
         fcHubRefClkN         => fcHubRefClkN,          -- [in]
         fcHubTxP             => fcHubTxP,              -- [out]
         fcHubTxN             => fcHubTxN,              -- [out]
         fcHubRxP             => fcHubRxP,              -- [in]
         fcHubRxN             => fcHubRxN,              -- [in]
         appFcRefClkP         => appFcRefClkP,          -- [in]
         appFcRefClkN         => appFcRefClkN,          -- [in]
         appFcRxP             => appFcRxP,              -- [in]
         appFcRxN             => appFcRxN,              -- [in]
         appFcTxP             => appFcTxP,              -- [out]
         appFcTxN             => appFcTxN,              -- [out]
         tsRefClk250P         => tsRefClk250P,          -- [in]
         tsRefClk250N         => tsRefClk250N,          -- [in]
         tsDataRxP            => tsDataRxP,             -- [in]
         tsDataRxN            => tsDataRxN,             -- [in]
         ethRefClk156P        => ethRefClk156P,         -- [in]
         ethRefClk156N        => ethRefClk156N,         -- [in]
         ethTxP               => ethTxP,                -- [out]
         ethTxN               => ethTxN,                -- [out]
         ethRxP               => ethRxP,                -- [in]
         ethRxN               => ethRxN);               -- [in]

   -------------------------------------------------------------------------------------------------
   -- Loopbacks
   -------------------------------------------------------------------------------------------------
   appFcRxP <= fcHubTxP(0);
   appFcRxN <= fcHubTxN(0);
   fcHubRxP(0) <= appFcTxP;
   fcHubRxN(0) <= appFcTxN;

   lclsTimingRxP <= lclsTimingTxP;
   lclsTimingRxN <= lclsTimingTxN;


   -------------------------------------------------------------------------------------------------
   -- Clocks
   -------------------------------------------------------------------------------------------------
   U_ClkRst_CLK_125 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 8 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => clk125InP,
         clkN => clk125InN);

   U_ClkRst_LCLS_TIMING_REF : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 5.384 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => lclsTimingRefClkP,
         clkN => lclsTimingRefClkN);

   U_ClkRst_APP_FC_REFCLK : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 5.384 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => appFcRefClkP,
         clkN => appFcRefClkN);

   GEN_FC_HUB_REF_CLKS : for i in FC_HUB_REFCLKS_G-1 downto 0 generate
      fcHubRefClkP(i) <= lclsTimingRecClkOutP;
      fcHubRefClkN(i) <= lclsTimingRecClkOutN;
   end generate GEN_FC_HUB_REF_CLKS;

   GEN_TS_REF_CLKS : for i in TS_REFCLKS_G-1 downto 0 generate
      U_ClkRst_FC_HUB_REF_CLK : entity surf.ClkRst
         generic map (
            CLK_PERIOD_G      => 4 ns,
            CLK_DELAY_G       => 1 ns,
            RST_START_DELAY_G => 0 ns,
            RST_HOLD_TIME_G   => 5 us,
            SYNC_RESET_G      => true)
         port map (
            clkP => tsRefClk250P(i),
            clkN => tsRefClk250N(i));
   end generate;

   U_ClkRst_CLK_125 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 6.4 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => ethRefClk156P,
         clkN => ethRefClk156N);



end architecture sim;

----------------------------------------------------------------------------------------------------
