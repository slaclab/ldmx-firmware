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

entity LdmxTrackerFullTb is

end entity LdmxTrackerFullTb;

----------------------------------------------------------------------------------------------------

architecture sim of LdmxTrackerFullTb is

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
   constant SIM_SPEEDUP_G        : boolean                     := true;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
   constant PGP_QUADS_G          : integer                     := 1;

   signal fcRxP       : sl;                             -- [in]
   signal fcRxN       : sl;                             -- [in]
   signal fcTxP       : sl;                             -- [out]
   signal fcTxN       : sl;                             -- [out]
   signal febPgpFcRxP : slv(PGP_QUADS_G*4-1 downto 0);  -- [in]
   signal febPgpFcRxN : slv(PGP_QUADS_G*4-1 downto 0);  -- [in]
   signal febPgpFcTxP : slv(PGP_QUADS_G*4-1 downto 0);  -- [out]
   signal febPgpFcTxN : slv(PGP_QUADS_G*4-1 downto 0);  -- [out]

begin

   U_TrackerBittwareSim_1 : entity ldmx_tracker.TrackerBittwareSim
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         SIM_SPEEDUP_G        => SIM_SPEEDUP_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
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

--    febPgpFcRxP <= febPgpFcTxP;
--    febPgpFcRxN <= febPgpFcTxN;   

   -- Loop back fast control for now
   fcRxP <= fcTxP;
   fcRxN <= fcTxN;


   -- component instantiation
   GEN_FEBS : for feb in NUM_FEBS_C-1 downto 0 generate
      febQsfpGtRxP(feb)(0) <= febPgpFcTxP(feb);
      febQsfpGtRxN(feb)(0) <= febPgpFcTxN(feb);

      febPgpFcRxP(feb) <= febQsfpGtTxP(feb)(0);
      febPgpFcRxN(feb) <= febQsfpGtTxN(feb)(0);

      U_LdmxFebSim : entity ldmx_tracker.LdmxFebSim
         generic map (
            TPD_G             => TPD_G,
            BUILD_INFO_G      => BUILD_INFO_G,
            SIMULATION_G      => SIMULATION_G,
            ADCS_G            => ADCS_G,
            HYBRIDS_G         => HYBRIDS_G,
            APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
         port map (
            qsfpGtTxP => febQsfpGtTxP(feb),   -- [out]
            qsfpGtTxN => febQsfpGtTxN(feb),   -- [out]
            qsfpGtRxP => febQsfpGtRxP(feb),   -- [in]
            qsfpGtRxN => febQsfpGtRxN(feb));  -- [in]
   end generate GEN_FEBS;

--    febQsfpGtRxP <= febQsfpGtTxP;
--    febQsfpGtRxN <= febQsfpGtTxN;   

end architecture sim;

----------------------------------------------------------------------------------------------------
