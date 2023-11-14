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

library ldmx;

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
   constant SIMULATION_G      : boolean := true;
   constant ADCS_G            : integer := 4;
   constant HYBRIDS_G         : integer := 8;
   constant APVS_PER_HYBRID_G : integer := 6;

   -- component ports
   signal sasGtTxP  : slv(3 downto 0) := (others => '0');  -- [out]
   signal sasGtTxN  : slv(3 downto 0) := (others => '0');  -- [out]
   signal sasGtRxP  : slv(3 downto 0) := (others => '0');  -- [in]
   signal sasGtRxN  : slv(3 downto 0) := (others => '0');  -- [in]
   signal qsfpGtTxP : slv(3 downto 0) := (others => '0');  -- [out]
   signal qsfpGtTxN : slv(3 downto 0) := (others => '0');  -- [out]
   signal qsfpGtRxP : slv(3 downto 0) := (others => '0');  -- [in]
   signal qsfpGtRxN : slv(3 downto 0) := (others => '0');  -- [in]
   signal sfpGtTxP  : sl := '0';               -- [out]
   signal sfpGtTxN  : sl := '0';               -- [out]
   signal sfpGtRxP  : sl := '0';               -- [in]
   signal sfpGtRxN  : sl := '0';               -- [in]

   -------------------------------------------------------------------------------------------------
   -- Bittware generics and signals
   -------------------------------------------------------------------------------------------------
   constant SIM_SPEEDUP_G        : boolean                     := true;
   constant ROGUE_SIM_EN_G       : boolean                     := true;
   constant ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 11000;
   constant PGP_QUADS_G          : integer                     := 1;

   signal qsfpRxP : slv(PGP_QUADS_G*4-1 downto 0) := (others => '0');
   signal qsfpRxN : slv(PGP_QUADS_G*4-1 downto 0) := (others => '0');
   signal qsfpTxP : slv(PGP_QUADS_G*4-1 downto 0) := (others => '0');
   signal qsfpTxN : slv(PGP_QUADS_G*4-1 downto 0) := (others => '0');

begin

   -- component instantiation
   U_LdmxFebSim : entity ldmx.LdmxFebSim
      generic map (
         TPD_G             => TPD_G,
         BUILD_INFO_G      => BUILD_INFO_G,
         SIMULATION_G      => SIMULATION_G,
         ADCS_G            => ADCS_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         sasGtTxP  => sasGtTxP,         -- [out]
         sasGtTxN  => sasGtTxN,         -- [out]
         sasGtRxP  => sasGtRxP,         -- [in]
         sasGtRxN  => sasGtRxN,         -- [in]
         qsfpGtTxP => qsfpGtTxP,        -- [out]
         qsfpGtTxN => qsfpGtTxN,        -- [out]
         qsfpGtRxP => qsfpGtRxP,        -- [in]
         qsfpGtRxN => qsfpGtRxN,        -- [in]
         sfpGtTxP  => sfpGtTxP,         -- [out]
         sfpGtTxN  => sfpGtTxN,         -- [out]
         sfpGtRxP  => sfpGtRxP,         -- [in]
         sfpGtRxN  => sfpGtRxN);        -- [in]

   U_BittWareXupVv8Pgp2fcSim_1 : entity ldmx.BittWareXupVv8Pgp2fcSim
      generic map (
         TPD_G                => TPD_G,
         BUILD_INFO_G         => BUILD_INFO_G,
         SIM_SPEEDUP_G        => SIM_SPEEDUP_G,
         ROGUE_SIM_EN_G       => ROGUE_SIM_EN_G,
         ROGUE_SIM_PORT_NUM_G => ROGUE_SIM_PORT_NUM_G,
         PGP_QUADS_G          => PGP_QUADS_G)
      port map (
         qsfpRxP => qsfpRxP,
         qsfpRxN => qsfpRxN,
         qsfpTxP => qsfpTxP,
         qsfpTxN => qsfpTxN);

   
   qsfpRxP(0) <= sfpGtTxP;
   qsfpRxN(0) <= sfpGtTxN;
   sfpGtRxP   <= qsfpTxP(0);
   sfpGtRxN   <= qsfpTxN(0);


end architecture sim;

----------------------------------------------------------------------------------------------------
