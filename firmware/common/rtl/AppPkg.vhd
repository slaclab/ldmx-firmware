-------------------------------------------------------------------------------
-- File       : AppPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'PGP PCIe APP DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'PGP PCIe APP DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;

package AppPkg is

   type ConfigType is record
      gtDrpOverride : sl;
      txDiffCtrl    : slv(3 downto 0);
      txPreCursor   : slv(4 downto 0);
      txPostCursor  : slv(4 downto 0);
      qPllRxSelect  : slv(1 downto 0);
      qPllTxSelect  : slv(1 downto 0);
   end record;
   constant CONFIG_INIT_C : ConfigType := (
      gtDrpOverride => '0',
      txDiffCtrl    => "1000",
      txPreCursor   => "00000",
      txPostCursor  => "00000",
      qPllRxSelect  => "11",
      qPllTxSelect  => "11");

end package AppPkg;
