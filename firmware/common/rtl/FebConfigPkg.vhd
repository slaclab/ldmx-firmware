-------------------------------------------------------------------------------
-- Title      : FEB Config Support Package
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Data types and constants for FebConfig module
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

library ldmx;
use ldmx.LdmxPkg.all;

package FebConfigPkg is

   type FebConfigType is record
      hybridType          : slv3Array(7 downto 0);
      hyTrigEn            : sl;
      calEn               : sl;
      calDelay            : slv(7 downto 0);
      hyPwrEn             : slv(7 downto 0);
      hyHardRst           : slv(7 downto 0);
      hyApvDataStreamEn   : slv6Array(7 downto 0);
      febAddress          : slv(3 downto 0);
      headerHighThreshold : slv(13 downto 0);
      allowResync         : sl;
      threshold1CutEn    : sl;
      threshold1CutNum   : slv(2 downto 0);
      threshold1MarkOnly : sl;
      threshold2CutEn    : sl;
      threshold2CutNum   : slv(2 downto 0);
      threshold2MarkOnly : sl;
      slopeCutEn         : sl;
      calGroup           : slv(2 downto 0);
      errorFilterEn      : sl;
      dataPipelineRst    : sl;

   end record FebConfigType;
   
   constant FEB_CONFIG_INIT_C : FebConfigType := (
      hybridType          => (others => UNKNOWN_HYBRID_C),
      hyTrigEn            => '1',
      calEn               => '0',
      calDelay            => (others => '0'),
      hyPwrEn             => (others => '0'),
      hyHardRst           => (others => '0'),
      hyApvDataStreamEn   => (others => (others => '1')),
  --    prbsDataStreamEn    => (others => '0'),
      febAddress          => "1110",
      headerHighThreshold => "10" & X"400",
--      statusInterval      => toSlv(125000000, 32),  -- 1 second
      allowResync         => '1',
      threshold1CutEn    => '0',
      threshold1CutNum   => "011",
      threshold1MarkOnly => '0',
      threshold2CutEn    => '0',
      threshold2CutNum   => "011",
      threshold2MarkOnly => '0',
      slopeCutEn         => '0',
      calGroup           => (others => '0'),
      errorFilterEn      => '1',
      dataPipelineRst    => '0');


end package FebConfigPkg;

