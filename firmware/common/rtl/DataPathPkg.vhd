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

   constant MULTI_SAMPLE_LENGTH_C : integer := 72;

   -------------------------------------------------------------------------------------------------
   type MultiSampleType is record
      valid      : sl;
      head       : sl;
      tail       : sl;
      data       : slv16Array(0 to 3);  -- 6 samples of data per trigger
      apvChannel : slv(6 downto 0);
      readError  : sl;
      filter     : sl;
      hybridAddr : slv(2 downto 0);
      apvAddr    : slv(2 downto 0);
      febAddr    : slv(3 downto 0);
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
      febAddr    => (others => '0'));

   function multiSampleReset (
      hybridNum : integer;
      apvNum    : integer;
      febAddr   : slv(3 downto 0))
      return MultiSampleType;

   function toSlv (multiSample : MultiSampleType) return slv;

   function toMultiSample (vector : slv(MULTI_SAMPLE_LENGTH_C-1 downto 0); valid : sl) return MultiSampleType;

   type DataPathOutArray is array (natural range <>) of MultiSampleArray(5 downto 0);
   type DataPathInArray is array (natural range <>) of slv(5 downto 0);

end package DataPathPkg;

package body DataPathPkg is

   function multiSampleReset (
      hybridNum : integer;
      apvNum    : integer;
      febAddr   : slv(3 downto 0))
      return MultiSampleType
   is
      variable ret : MultiSampleType;
   begin
      ret            := MULTI_SAMPLE_ZERO_C;
      ret.hybridAddr := toSlv(hybridNum, ret.hybridAddr'length);
      ret.apvAddr    := toSlv(apvNum, ret.apvAddr'length);
      ret.febAddr    := febAddr;
      return ret;
   end function multiSampleReset;

   -- Convert a MultiSampleType to an slv.
   function toSlv (multiSample : MultiSampleType) return slv is
      variable ret : slv(MULTI_SAMPLE_LENGTH_C-1 downto 0);
   begin
      ret     := (others => '0');
      ret(71) := multiSample.filter;
      ret(70) := multiSample.head;
      ret(69) := multiSample.tail;
      ret(68) := multiSample.readError;

      ret(67 downto 64) := multiSample.febAddr;
      ret(62 downto 60) := multiSample.hybridAddr;
      ret(58 downto 56) := multiSample.apvAddr;
      ret(54 downto 48) := multiSample.apvChannel;

      ret(47 downto 32) := multiSample.data(2);
      ret(31 downto 16) := multiSample.data(1);
      ret(15 downto 0)  := multiSample.data(0);
      return ret;
   end function toSlv;

   function toMultiSample (vector : slv(MULTI_SAMPLE_LENGTH_C-1 downto 0); valid : sl) return MultiSampleType is
      variable ret : MultiSampleType;
   begin
      ret.valid      := valid;
      ret.filter     := vector(71);
      ret.head       := vector(70);
      ret.tail       := vector(69);
      ret.readError  := vector(68);

      ret.febAddr    := vector(67 downto 64);      
      ret.hybridAddr := vector(62 downto 60);
      ret.apvAddr    := vector(58 downto 56);
      ret.apvChannel := vector(54 downto 48);

      ret.data(2)    := vector(47 downto 32);
      ret.data(1)    := vector(31 downto 16);
      ret.data(0)    := vector(15 downto 0);
      return ret;
   end function toMultiSample;

end package body DataPathPkg;



