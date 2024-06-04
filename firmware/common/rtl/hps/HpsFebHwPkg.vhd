-------------------------------------------------------------------------------
-- Title      : HPS FEB Hardware Support Package
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

library ldmx;

package HpsFebHwPkg is

   type HybridPowerGoodType is record
      v125 : sl;
      dvdd : sl;
      avdd : sl;
   end record HybridPowerGoodType;

   type HybridPowerGoodArray is array (natural range <>) of HybridPowerGoodType;

   type PowerGoodType is record
      hybrid : HybridPowerGoodArray(3 downto 0);
      a22    : sl;
      a18    : sl;
      a16    : sl;
      a29A   : sl;
      a29D   : sl;
   end record PowerGoodType;

end package HpsFebHwPkg;
