-------------------------------------------------------------------------------
-- Title      : RCE Config Support Package
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Data types and constants for RceConfig module.
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

package RceConfigPkg is

   type RceConfigType is record
      address            : slv(7 downto 0);
      threshold1CutEn    : sl;
      threshold1CutNum   : slv(2 downto 0);
      threshold1MarkOnly : sl;
      threshold2CutEn    : sl;
      threshold2CutNum   : slv(2 downto 0);
      threshold2MarkOnly : sl;
      slopeCutEn         : sl;
      calEn              : sl;
      calGroup           : slv(2 downto 0);
      errorFilterEn      : sl;
      dataPipelineRst    : sl;
   end record RceConfigType;

   constant RCE_CONFIG_INIT_C : RceConfigType := (
      address            => (others => '0'),
      threshold1CutEn    => '0',
      threshold1CutNum   => "011",
      threshold1MarkOnly => '0',
      threshold2CutEn    => '0',
      threshold2CutNum   => "011",
      threshold2MarkOnly => '0',
      slopeCutEn         => '0',
      calEn              => '0',
      calGroup           => (others => '0'),
      errorFilterEn      => '1',
      dataPipelineRst    => '0');


end package RceConfigPkg;

