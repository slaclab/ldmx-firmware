-------------------------------------------------------------------------------
-- Title      : AdcReadout Support Package
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Provides data types and constant for AdcReadout module
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

package AdcReadoutPkg is

  -- Interface to AD9592 chip
  type AdcChipOutType is record
    fClkP : sl;                         -- Frame clock
    fClkN : sl;
    dClkP : sl;                         -- Data clock
    dClkN : sl;
    chP   : slv(7 downto 0);            -- Serial Data channels
    chN   : slv(7 downto 0);
  end record AdcChipOutType;

  type AdcChipOutArray is array (natural range <>) of AdcChipOutType;


end package AdcReadoutPkg;
