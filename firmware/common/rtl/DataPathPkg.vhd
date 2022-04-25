-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

package DataPathPkg is


   -------------------------------------------------------------------------------------------------
   type MultiSampleType is record
      valid      : sl;
      head       : sl;
      tail       : sl;
      data       : slv16Array(0 to 5);  -- 6 samples of data per trigger
      apvChannel : slv(6 downto 0);
      readError  : sl;
      filter     : sl;
      hybridAddr : slv(2 downto 0);
      apvAddr    : slv(2 downto 0);
      febAddr    : slv(7 downto 0);
      rceAddr    : slv(7 downto 0);
   end record MultiSampleType;

   type MultiSampleArray is array (natural range <>) of MultiSampleType;

   constant MULTI_SAMPLE_ZERO_C : MultiSampleType := (
      valid      => '0',
      head       => '0',
      tail       => '0',
      data       => (others => (others => '0')),
      apvChannel => (others => '0'),
      readError  => '0',
      filter     => '0',
      hybridAddr => (others => '0'),
      apvAddr    => (others => '0'),
      febAddr    => (others => '0'),
      rceAddr    => (others => '0'));

   function multiSampleReset (
      hybridAddr : slv(2 downto 0);
      apvAddr    : slv(2 downto 0);
      febAddr    : slv(3 downto 0);
      rceAddr    : slv(7 downto 0))
      return MultiSampleType;

   function toSlv (multiSample : MultiSampleType) return slv;

   function toMultiSample (vector : slv(128 downto 0); valid : sl) return MultiSampleType;

   -------------------------------------------------------------------------------------------------
--   type DataPathOutType is record
--      data    : MultiSampleArray(4 downto 0);
--   end record DataPathOutType;

--   constant DATA_PATH_OUT_INIT_C : DataPathOutType := (
--      data    => (others => MULTI_SAMPLE_ZERO_C),
--      enabled => (others => '0'));

   type DataPathOutArray is array (natural range <>) of MultiSampleArray(5 downto 0);
   type DataPathInArray is array (natural range <>) of slv(5 downto 0);
   
end package DataPathPkg;

package body DataPathPkg is

   function multiSampleReset (
      hybridAddr : slv(2 downto 0);
      apvAddr    : slv(2 downto 0);
      febAddr    : slv(3 downto 0);
      rceAddr    : slv(7 downto 0))
      return MultiSampleType
   is
      variable ret : MultiSampleType;
   begin
      ret            := MULTI_SAMPLE_ZERO_C;
      ret.hybridAddr := hybridAddr;
      ret.apvAddr    := apvAddr;
      ret.febAddr    := "0000" & febAddr;
      ret.rceAddr    := rceAddr;
      return ret;
   end function multiSampleReset;

   -- Convert a MultiSampleType to an slv.
   function toSlv (multiSample : MultiSampleType) return slv is
      variable ret : slv(128 downto 0);
   begin
      ret(128)            := multiSample.filter;
      ret(127)            := multiSample.head;
      ret(126)            := multiSample.tail;
      ret(125)            := multiSample.readError;
      ret(124 downto 122) := multiSample.hybridAddr;
      ret(121 downto 119) := multiSample.apvAddr;
      ret(118 downto 112) := multiSample.apvChannel;
      ret(111 downto 104) := multiSample.febAddr;
      ret(103 downto 96)  := multiSample.rceAddr;
      ret(95 downto 80)   := multiSample.data(5);
      ret(79 downto 64)   := multiSample.data(4);
      ret(63 downto 48)   := multiSample.data(3);
      ret(47 downto 32)   := multiSample.data(2);
      ret(31 downto 16)   := multiSample.data(1);
      ret(15 downto 0)    := multiSample.data(0);
      return ret;
   end function toSlv;

   function toMultiSample (vector : slv(128 downto 0); valid : sl) return MultiSampleType is
      variable ret : MultiSampleType;
   begin
      ret.valid      := valid;
      ret.filter     := vector(128);
      ret.head       := vector(127);
      ret.tail       := vector(126);
      ret.readError  := vector(125);
      ret.hybridAddr := vector(124 downto 122);
      ret.apvAddr    := vector(121 downto 119);
      ret.apvChannel := vector(118 downto 112);
      ret.febAddr    := vector(111 downto 104);
      ret.rceAddr    := vector(103 downto 96);
      ret.data(5)    := vector(95 downto 80);
      ret.data(4)    := vector(79 downto 64);
      ret.data(3)    := vector(63 downto 48);
      ret.data(2)    := vector(47 downto 32);
      ret.data(1)    := vector(31 downto 16);
      ret.data(0)    := vector(15 downto 0);
      return ret;
   end function toMultiSample;

end package body DataPathPkg;



