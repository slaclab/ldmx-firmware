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

library hps_daq;
use hps_daq.HpsPkg.all;

package FebConfigPkg is

   type FebConfigType is record
      hybridType          : slv2Array(7 downto 0);
      daqTimingEn         : sl;
      hyTrigEn            : sl;
      calEn               : sl;
      calDelay            : slv(7 downto 0);
      hyPwrEn             : slv(7 downto 0);
      hyHardRst           : slv(7 downto 0);
      hyApvDataStreamEn   : slv(47 downto 0);
      prbsDataStreamEn    : slv(7 downto 0);
      febAddress          : slv(3 downto 0);
      headerHighThreshold : slv(13 downto 0);
      statusInterval      : slv(31 downto 0);
      allowResync         : sl;
      ledEn               : sl;

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
      daqTimingEn         => '1',
      hyTrigEn            => '1',
      calEn               => '0',
      calDelay            => (others => '0'),
      hyPwrEn             => (others => '0'),
      hyHardRst           => (others => '0'),
      hyApvDataStreamEn   => (others => '1'),
      prbsDataStreamEn    => (others => '0'),
      febAddress          => "1110",
      headerHighThreshold => "10" & X"400",
      statusInterval      => toSlv(125000000, 32),  -- 1 second
      allowResync         => '1',
      ledEn               => '1',
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

   constant POWER_GOOD_SLV_LENGTH_C : integer := 17;
   function toSlv (powerGood        : PowerGoodType) return slv;


--   function toSlv (config : FebConfigType) return slv;

--   function toFebConfig (vec : slv(63 downto 0)) return FebConfigType;
   
end package FebConfigPkg;

package body FebConfigPkg is

   function toSlv (powerGood : PowerGoodType) return slv
   is
      variable ret : slv(POWER_GOOD_SLV_LENGTH_C-1 downto 0) := (others => '0');
   begin
      ret(0) := powerGood.a22;
      ret(1) := powerGood.a18;
      ret(2) := powerGood.a16;
      ret(3) := powerGood.a29A;
      ret(4) := powerGood.a29D;

      ret(5) := powerGood.hybrid(0).v125;
      ret(6) := powerGood.hybrid(0).dvdd;
      ret(7) := powerGood.hybrid(0).avdd;

      ret(8)  := powerGood.hybrid(1).v125;
      ret(9)  := powerGood.hybrid(1).dvdd;
      ret(10) := powerGood.hybrid(1).avdd;

      ret(11) := powerGood.hybrid(2).v125;
      ret(12) := powerGood.hybrid(2).dvdd;
      ret(13) := powerGood.hybrid(2).avdd;

      ret(14) := powerGood.hybrid(3).v125;
      ret(15) := powerGood.hybrid(3).dvdd;
      ret(16) := powerGood.hybrid(3).avdd;
      return ret;
   end function toSlv;

end package body FebConfigPkg;
