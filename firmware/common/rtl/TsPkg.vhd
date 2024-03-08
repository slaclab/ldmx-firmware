-------------------------------------------------------------------------------
-- Title      : Trigger Scintillator Support Package
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;

package TsPkg is

   type TsData8ChMsgType is record
      strobe : sl;                      -- Indicates new data
      capId  : slv(1 downto 0);
      cd     : sl;
      bc0    : sl;
      adc    : Slv8Array(7 downto 0);
      tdc    : Slv2Array(7 downto 0);
   end record;

   type TsData6ChMsgType is record
      strobe : sl;                      -- Indicates new data
      capId  : slv(1 downto 0);
      cd     : sl;
      bc0    : sl;
      adc    : Slv8Array(5 downto 0);
      tdc    : Slv6Array(5 downto 0);
   end record;


end package TsPkg;
