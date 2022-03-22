-------------------------------------------------------------------------------
-- Title      : Testbench for design "ExampleDtm"
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

entity ExampleDtmTb is

end entity ExampleDtmTb;

----------------------------------------------------------------------------------------------------

architecture sim of ExampleDtmTb is

   -- component generics
   constant TPD_G        : time          := 1 ns;
   constant BUILD_INFO_G : BuildInfoType := BUILD_INFO_DEFAULT_SLV_C;
   constant SIMULATION_G : boolean       := true;

   -- component ports
   signal locRefClkP  : sl;
   signal locRefClkM  : sl;
   signal dtmToRtmHsP : sl := '0';        -- [out]
   signal dtmToRtmHsM : sl := '0';        -- [out]
   signal rtmToDtmHsP : sl := '0';        -- [in]
   signal rtmToDtmHsM : sl := '0';        -- [in]
   signal dpmClkP     : slv(2 downto 0);  -- [out]
   signal dpmClkM     : slv(2 downto 0);  -- [out]
   signal dpmFbP      : slv(7 downto 0);  -- [in]
   signal dpmFbM      : slv(7 downto 0);  -- [in]

begin

   rtmToDtmHsP <= dtmToRtmHsP;
   rtmToDtmHsM <= dtmToRtmHsM;

   -- component instantiation
   U_ExampleDtm : entity ldmx.ExampleDtm
      generic map (
         TPD_G        => TPD_G,
         BUILD_INFO_G => BUILD_INFO_G,
         SIMULATION_G => SIMULATION_G)
      port map (
         locRefClkP  => locRefClkP,     -- [in]
         locRefClkM  => locRefClkM,     -- [in]
         dtmToRtmHsP => dtmToRtmHsP,    -- [out]
         dtmToRtmHsM => dtmToRtmHsM,    -- [out]
         rtmToDtmHsP => rtmToDtmHsP,    -- [in]
         rtmToDtmHsM => rtmToDtmHsM,    -- [in]
         dpmClkP     => dpmClkP,        -- [out]
         dpmClkM     => dpmClkM,        -- [out]
         dpmFbP      => dpmFbP,         -- [in]
         dpmFbM      => dpmFbM);        -- [in]

   U_ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => 8 ns,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => locRefClkP,
         clkN => locRefClkM);

   U_ExampleDpm_1 : entity ldmx.ExampleDpm
      generic map (
         TPD_G           => TPD_G,
         BUILD_INFO_G    => BUILD_INFO_G,
         HS_LINK_COUNT_G => 4)
      port map (
         dpmToRtmHsP => dpmToRtmHsP,          -- [out]
         dpmToRtmHsM => dpmToRtmHsM,          -- [out]
         rtmToDpmHsP => rtmToDpmHsP,          -- [in]
         rtmToDpmHsM => rtmToDpmHsM,          -- [in]
         locRefClkP  => locRefClkP,           -- [in]
         locRefClkM  => locRefClkM,           -- [in]
         dtmRefClkP  => dtmClkP(0),           -- [in]
         dtmRefClkM  => dtmClkM(0),           -- [in]
         dtmClkP     => dtmClkP(2 downto 1),  -- [in]
         dtmClkM     => dtmClkM(2 downto 1),  -- [in]
         dtmFbP      => dtmFbP(0),            -- [out]
         dtmFbM      => dtmFbM(0));           -- [out]


end architecture sim;

----------------------------------------------------------------------------------------------------
