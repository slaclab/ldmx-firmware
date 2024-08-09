-------------------------------------------------------------------------------
-- Title      : Trigger Package
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

package TriggerPkg is

   constant TRIGGER_WORD_SIZE_C : integer := 128;

   type TriggerDataType is record
      valid : sl;
      bc0   : sl;
      data  : slv(TRIGGER_WORD_SIZE_C-1 downto 0);
   end record TriggerDataType;

   constant TRIGGER_DATA_INIT_C : TriggerDataType := (
      valid => '0',
      bc0   => '0',
      data  => (others => '0'));

   type TriggerDataArray is array (natural range <>) of TriggerDataType;

end package;


