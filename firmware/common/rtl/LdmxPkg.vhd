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

package HpsPkg is

   constant UNKNOWN_HYBRID_C : slv(1 downto 0) := "00";
   constant OLD_HYBRID_C     : slv(1 downto 0) := "01";
   constant NEW_HYBRID_C     : slv(1 downto 0) := "10";

   constant DAQ_CLK_ALIGN_CODE_C : slv(7 downto 0) := "10100101";  -- 0xA5
   constant DAQ_TRIGGER_CODE_C   : slv(7 downto 0) := "01011010";  -- 0x5A
   constant DAQ_APV_RESET101_C   : slv(7 downto 0) := "00011111";  -- 0x1F

   constant APV_DATA_SSI_CONFIG_C      : AxiStreamConfigType := ssiAxiStreamConfig(2, TKEEP_COMP_C);

   -- AXI-Stream configuration for DAQ events
   -- 128 bits wide
   constant EVENT_SSI_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 16,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

--    function apvIndex (
--       index      : integer;
--       hybridType : slv(1 downto 0))
--       return integer;

   type HybridInfoType is record
      febAddress : slv(3 downto 0);
      hybridNum  : slv(2 downto 0);
      hybridType : slv(1 downto 0);
      syncStatus : slv(5 downto 0);
   end record;

   type HybridInfoArray is array (natural range <>) of HybridInfoType;

   constant HYBRID_INFO_INIT_C : HybridInfoType := (
      febAddress => (others => '1'),
      hybridNum  => (others => '1'),
      hybridType => (others => '0'),
      syncStatus => (others => '0'));

   function toSlv (hybridInfo    : HybridInfoType) return slv;
   function toHybridInfo (vector : slv(15 downto 0)) return HybridInfoType;


   type AdcStreamArray is array (7 downto 0) of AxiStreamMasterArray(5 downto 0);

   constant ADC_STREAM_ARRAY_INIT_C : AdcStreamArray := (others => (others => AXI_STREAM_MASTER_INIT_C));


end package HpsPkg;

package body HpsPkg is

   -- Helper function to remap APVs of new hybrids
--    function apvIndex (
--       index      : integer;
--       hybridType : slv(1 downto 0))
--       return integer is
--    begin
--       if (hybridType = NEW_HYBRID_C) then
--          return (index+2) mod 5;
--       else
--          return index;
--       end if;
--    end function apvIndex;


   function toSlv (hybridInfo : HybridInfoType) return slv is
      variable ret : slv(15 downto 0);
   begin
      ret               := (others => '0');
      ret(14 downto 11) := hybridInfo.febAddress;
      ret(10 downto 8)   := hybridInfo.hybridNum;
      ret(7 downto 6)   := hybridInfo.hybridType;
      ret(5 downto 0)   := hybridInfo.syncStatus;
      return ret;
   end function toSlv;

   function toHybridInfo (
      vector : slv(15 downto 0))
      return HybridInfoType is
      variable ret : HybridInfoType;
   begin
      ret.febAddress := vector(14 downto 11);
      ret.hybridNum  := vector(10 downto 8);
      ret.hybridType := vector(7 downto 6);
      ret.syncStatus := vector(5 downto 0);
      return ret;
   end function toHybridInfo;

end package body HpsPkg;
