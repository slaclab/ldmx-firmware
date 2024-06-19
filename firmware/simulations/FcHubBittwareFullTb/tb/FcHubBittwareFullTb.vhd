-------------------------------------------------------------------------------
-- Title      : Testbench for design "LdmxTrackerFull"
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

library ldmx_tracker;

----------------------------------------------------------------------------------------------------

entity FcHubBittwareFullTb is

end entity FcHubBittwareFullTb;

----------------------------------------------------------------------------------------------------

architecture sim of FcHubBittwareFullTb is

   -------------------------------------------------------------------------------------------------
   -- Shared generics
   -------------------------------------------------------------------------------------------------
   constant TPD_G        : time          := 0.2 ns;
   constant BUILD_INFO_G : BuildInfoType := BUILD_INFO_DEFAULT_SLV_C;

   -------------------------------------------------------------------------------------------------
   -- FEB Generics and signals
   -------------------------------------------------------------------------------------------------
   constant NUM_FEBS_C        : integer := 1;
   constant SIMULATION_G      : boolean := true;
   constant ADCS_G            : integer := 4;
   constant HYBRIDS_G         : integer := 8;
   constant APVS_PER_HYBRID_G : integer := 6;

   -- component ports
   signal febQsfpGtTxP : slv4Array(NUM_FEBS_C-1 downto 0) := (others => (others => '0'));  -- [out]
   signal febQsfpGtTxN : slv4Array(NUM_FEBS_C-1 downto 0) := (others => (others => '0'));  -- [out]
   signal febQsfpGtRxP : slv4Array(NUM_FEBS_C-1 downto 0) := (others => (others => '0'));  -- [in]
   signal febQsfpGtRxN : slv4Array(NUM_FEBS_C-1 downto 0) := (others => (others => '0'));  -- [in]

   -------------------------------------------------------------------------------------------------
   -- Bittware generics and signals
   -------------------------------------------------------------------------------------------------
   constant SIM_SPEEDUP_G                : boolean                     := true;
   constant ROGUE_SIM_EN_G               : boolean                     := true;
   constant ROGUE_SIM_PORT_FCHUB_NUM_G   : natural range 1024 to 49151 := 11000;
   constant ROGUE_SIM_PORT_TRACKER_NUM_G : natural range 1024 to 49151 := 12000;
   constant FC_HUB_QUADS_G               : integer                     := 1;
   constant PGP_QUADS_G                  : integer                     := 1;

   signal lclsTimingRxP : sl;                               -- [in]
   signal lclsTimingRxN : sl;                               -- [in]
   signal lclsTimingTxP : sl;                               -- [out]
   signal lclsTimingTxN : sl;                               -- [out]
   signal fcRxP         : sl;                               -- [in]
   signal fcRxN         : sl;                               -- [in]
   signal fcTxP         : sl;                               -- [out]
   signal fcTxN         : sl;                               -- [out]
   signal fcHubRxP      : slv(FC_HUB_QUADS_G*4-1 downto 0); -- [in]
   signal fcHubRxN      : slv(FC_HUB_QUADS_G*4-1 downto 0); -- [in]
   signal fcHubTxP      : slv(FC_HUB_QUADS_G*4-1 downto 0); -- [out]
   signal fcHubTxN      : slv(FC_HUB_QUADS_G*4-1 downto 0); -- [out]
   signal febPgpFcRxP   : slv(PGP_QUADS_G*4-1 downto 0);    -- [in]
   signal febPgpFcRxN   : slv(PGP_QUADS_G*4-1 downto 0);    -- [in]
   signal febPgpFcTxP   : slv(PGP_QUADS_G*4-1 downto 0);    -- [out]
   signal febPgpFcTxN   : slv(PGP_QUADS_G*4-1 downto 0);    -- [out]

begin

   U_FcHubBittwareSim_1 : entity ldmx_tracker.FcHubBittwareSim
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         SIM_SPEEDUP_G        => SIM_SPEEDUP_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_FCHUB_NUM_G,
         FC_HUB_QUADS_G       => FC_HUB_QUADS_G)
      port map (
         lclsTimingRxP => lclsTimingRxP, -- [in]
         lclsTimingRxN => lclsTimingRxN, -- [in]
         lclsTimingTxP => lclsTimingTxP, -- [out]
         lclsTimingTxN => lclsTimingTxN, -- [out]
         fcHubTxP      => fcHubTxP,      -- [in]
         fcHubTxN      => fcHubTxN,      -- [in]
         fcHubRxP      => fcHubRxP,      -- [out]
         fcHubRxN      => fcHubRxN);     -- [out]

   U_TrackerBittwareSim_1 : entity ldmx_tracker.TrackerBittwareSim
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         SIM_SPEEDUP_G        => SIM_SPEEDUP_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_TRACKER_NUM_G,
         PGP_QUADS_G          => PGP_QUADS_G)
      port map (
         fcRxP       => fcRxP,          -- [in]
         fcRxN       => fcRxN,          -- [in]
         fcTxP       => fcTxP,          -- [out]
         fcTxN       => fcTxN,          -- [out]
         febPgpFcRxP => febPgpFcRxP,    -- [in]
         febPgpFcRxN => febPgpFcRxN,    -- [in]
         febPgpFcTxP => febPgpFcTxP,    -- [out]
         febPgpFcTxN => febPgpFcTxN);   -- [out]

   -- loopback tracker feb connections
   febPgpFcRxP <= febPgpFcTxP;
   febPgpFcRxN <= febPgpFcTxN;

   -- loopback the timing link
   lclsTimingRxP <= lclsTimingTxP;
   lclsTimingRxN <= lclsTimingTxN;

   -- connect fc hub to tracker
   fcHubRxP(0) <= fcTxP;
   fcHubRxN(0) <= fcTxN;
   fcRxP       <= fcHubTxP(0);
   fcRxN       <= fcHubTxN(0);

end architecture sim;

----------------------------------------------------------------------------------------------------
