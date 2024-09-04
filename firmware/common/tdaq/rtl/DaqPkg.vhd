-------------------------------------------------------------------------------
-- Title      : LDMX DAQ Package
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Constants and helper functions for LDMX DAQ
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
use surf.AxiStreamPkg.all;

package DaqPkg is

   constant TDAQ_SUBSYSTEM_ID_C    : slv(7 downto 0) := X"01";
   constant TS_SUBSYSTEM_ID_C      : slv(7 downto 0) := X"02";
   constant TRACKER_SUBSYSTEM_ID_C : slv(7 downto 0) := X"03";
   constant ECAL_SUBSYSTEM_ID_C    : slv(7 downto 0) := X"04";
   constant HCAL_SUBSYSTEM_ID_C    : slv(7 downto 0) := X"05";

   constant DAQ_EVENT_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => 8,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);



end package DaqPkg;
