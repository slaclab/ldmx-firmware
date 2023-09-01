-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Description: Declare project wide constants and data types
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

package LdmxPkg is

   constant UNKNOWN_HYBRID_C  : slv(2 downto 0) := "000";
   constant LDMX_C00_HYBRID_C : slv(2 downto 0) := "001";
   constant HPS_OLD_HYBRID_C  : slv(2 downto 0) := "101";
   constant HPS_NEW_HYBRID_C  : slv(2 downto 0) := "110";
   constant HPS_L0_HYBRID_C   : slv(2 downto 0) := "111";

   constant APV_DATA_SSI_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(2, TKEEP_COMP_C);

   -- AXI-Stream configuration for DAQ events
   -- 128 bits wide
   constant EVENT_SSI_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 10,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

--    type HybridInfoType is record
--       febAddress : slv(3 downto 0);
--       hybridNum  : slv(2 downto 0);
--       hybridType : slv(2 downto 0);
--       syncStatus : slv(5 downto 0);
--    end record;

--    type HybridInfoArray is array (natural range <>) of HybridInfoType;

--    constant HYBRID_INFO_INIT_C : HybridInfoType := (
--       febAddress => (others => '1'),
--       hybridNum  => (others => '1'),
--       hybridType => (others => '0'),
--       syncStatus => (others => '0'));

--    function toSlv (hybridInfo    : HybridInfoType) return slv;
--    function toHybridInfo (vector : slv(15 downto 0)) return HybridInfoType;

   constant ADC_STREAM_CFG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 2,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   type AdcStreamArray is array (7 downto 0) of AxiStreamMasterArray(5 downto 0);

   constant ADC_STREAM_ARRAY_INIT_C : AdcStreamArray := (others => (others => axiStreamMasterInit(ADC_STREAM_CFG_C)));


end package LdmxPkg;

package body LdmxPkg is

--    function toSlv (hybridInfo : HybridInfoType) return slv is
--       variable ret : slv(15 downto 0);
--    begin
--       ret               := (others => '0');
--       ret(15 downto 12) := hybridInfo.febAddress;
--       ret(11 downto 9)  := hybridInfo.hybridNum;
--       ret(8 downto 6)   := hybridInfo.hybridType;
--       ret(5 downto 0)   := hybridInfo.syncStatus;
--       return ret;
--    end function toSlv;

--    function toHybridInfo (
--       vector : slv(15 downto 0))
--       return HybridInfoType is
--       variable ret : HybridInfoType;
--    begin
--       ret.febAddress := vector(15 downto 12);
--       ret.hybridNum  := vector(11 downto 9);
--       ret.hybridType := vector(8 downto 6);
--       ret.syncStatus := vector(5 downto 0);
--       return ret;
--    end function toHybridInfo;

end package body LdmxPkg;
