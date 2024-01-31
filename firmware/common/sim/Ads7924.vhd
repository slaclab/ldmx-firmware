-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Ads7924.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-13
-- Last update: 2015-02-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.I2cPkg.all;

entity Ads7924 is
   
   generic (
      TPD_G  : time := 1 ns;
      AVDD_G : real := 2.5;
      ADDR_G : sl   := '0');

   port (
      ain : in    RealArray(0 to 3);
      scl : inout sl;
      sda : inout sl);

end entity Ads7924;

architecture behavioral of Ads7924 is

   constant I2C_ADDR_C : slv(6 downto 0) := "100100" & ADDR_G;



   signal clk : sl;
   signal rst : sl;

   -- I2C RegSlave IO
   signal i2ci      : i2c_in_type;
   signal i2co      : i2c_out_type;
   signal i2cAddr   : slv(7 downto 0);
   signal i2cWrEn   : sl;
   signal i2cWrData : slv(15 downto 0);
   signal i2cRdEn   : sl;
   signal i2cRdData : slv(15 downto 0);

   type RegType is record
      i2cRdData : slv(15 downto 0);

      mode      : slv(5 downto 0);
      sel       : slv(1 downto 0);
      alrmSt    : slv(3 downto 0);
      aen       : slv(3 downto 0);
      data      : slv12array(3 downto 0);
      ulr       : slv8array(3 downto 0);
      llr       : slv8array(3 downto 0);
      almCnt    : slv(2 downto 0);
      intCnfg   : slv(2 downto 0);
      busy      : sl;
      intPol    : sl;
      intTrig   : sl;
      convCtrl  : sl;
      slpDiv4   : sl;
      slpMult8  : sl;
      slpTime   : slv(2 downto 0);
      acqTime   : slv(4 downto 0);
      calcntl   : sl;
      pwrConPol : sl;
      pwrConEn  : sl;
      pwrUpTime : slv(4 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      i2cRdData => (others => '0'),
      mode      => (others => '0'),
      sel       => (others => '0'),
      alrmSt    => (others => '0'),
      aen       => (others => '0'),
      data      => (others => (others => '0')),
      ulr       => (others => (others => '0')),
      llr       => (others => (others => '0')),
      almCnt    => (others => '0'),
      intCnfg   => (others => '0'),
      busy      => '0',
      intPol    => '0',
      intTrig   => '0',
      convCtrl  => '0',
      slpDiv4   => '0',
      slpMult8  => '0',
      slpTime   => (others => '0'),
      acqTime   => (others => '0'),
      calcntl   => '0',
      pwrConPol => '0',
      pwrConEn  => '0',
      pwrUpTime => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 5 ns,
         SYNC_RESET_G => true)
      port map (
         clkP => clk,
         rst  => rst);

   I2cRegSlave_1 : entity surf.I2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => conv_integer(I2C_ADDR_C),
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => 4,
         ADDR_SIZE_G          => 1,
         DATA_SIZE_G          => 2,
         ENDIANNESS_G         => 1)
      port map (
         aRst   => rst,
         clk    => clk,
         addr   => i2cAddr,
         wrEn   => i2cWrEn,
         wrData => i2cWrData,
         rdEn   => i2cRdEn,
         rdData => i2cRdData,
         i2ci   => i2ci,
         i2co   => i2co);

   i2ci.scl <= to_x01z(scl);
   i2ci.sda <= to_x01z(sda);
   sda      <= i2co.sda when i2co.sdaoen = '0' else 'Z';
   scl      <= i2co.scl when i2co.scloen = '0' else 'Z';

   comb : process (ain, i2cAddr, i2cWrData, i2cWrEn, r) is
      variable v : RegType;
   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- I2C Register Decoding
      ----------------------------------------------------------------------------------------------
      v.i2cRdData := (others => '0');

      case i2cAddr(6 downto 0) is
         when "0000000" =>
            v.i2cRdData(15 downto 10) := r.mode;
            v.i2cRdData(9 downto 8)   := r.sel;
            v.i2cRdData(7 downto 4)   := r.alrmSt;
            v.i2cRdData(3 downto 0)   := r.aen;
            if (i2cWrEn = '1') then
               v.mode   := i2cWrData(15 downto 10);
               v.sel    := i2cWrData(9 downto 8);
               v.alrmSt := i2cWrData(7 downto 4);
               v.aen    := i2cWrData(3 downto 0);
            end if;
         when "0000010" =>
            v.i2cRdData(15 downto 8) := r.data(0)(11 downto 4);
            v.i2cRdData(7 downto 4)  := r.data(0)(3 downto 0);
            v.i2cRdData(3 downto 0)  := (others => '0');
         when "0000100" =>
            v.i2cRdData(15 downto 8) := r.data(1)(11 downto 4);
            v.i2cRdData(7 downto 4)  := r.data(1)(3 downto 0);
            v.i2cRdData(3 downto 0)  := (others => '0');
         when "0000110" =>
            v.i2cRdData(15 downto 8) := r.data(2)(11 downto 4);
            v.i2cRdData(7 downto 4)  := r.data(2)(3 downto 0);
            v.i2cRdData(3 downto 0)  := (others => '0');
         when "0001000" =>
            v.i2cRdData(15 downto 8) := r.data(3)(11 downto 4);
            v.i2cRdData(7 downto 4)  := r.data(3)(3 downto 0);
            v.i2cRdData(3 downto 0)  := (others => '0');
         when "0001010" =>
            v.i2cRdData(15 downto 8) := r.ulr(0);
            v.i2cRdData(7 downto 0)  := r.llr(0);
         when "0001100" =>
            v.i2cRdData(15 downto 8) := r.ulr(1);
            v.i2cRdData(7 downto 0)  := r.llr(1);
         when "0001110" =>
            v.i2cRdData(15 downto 8) := r.ulr(2);
            v.i2cRdData(7 downto 0)  := r.llr(2);
         when "0010000" =>
            v.i2cRdData(15 downto 8) := r.ulr(3);
            v.i2cRdData(7 downto 0)  := r.llr(3);
         when "0010010" =>
            v.i2cRdData(15 downto 13) := r.almCnt;
            v.i2cRdData(12 downto 10) := r.intCnfg;
            v.i2cRdData(9)            := r.intPol;
            v.i2cRdData(8)            := r.intTrig;
            v.i2cRdData(6)            := r.convCtrl;
            v.i2cRdData(5)            := r.slpDiv4;
            v.i2cRdData(4)            := r.slpMult8;
            v.i2cRdData(2 downto 0)   := r.slpTime;
            if (i2cWrEn = '1') then
               v.intCnfg  := i2cWrData(12 downto 10);
               v.intPol   := i2cWrData(9);
               v.intTrig  := i2cWrData(8);
               v.convCtrl := i2cWrData(6);
               v.slpDiv4  := i2cWrData(5);
               v.slpMult8 := i2cWrData(4);
               v.slpTime  := i2cWrData(2 downto 0);
            end if;
         when "0010100" =>
            v.i2cRdData(12 downto 8) := r.acqTime;
            v.i2cRdData(7)           := r.calcntl;
            v.i2cRdData(6)           := r.pwrConPol;
            v.i2cRdData(5)           := r.pwrConEn;
            v.i2cRdData(4 downto 0)  := r.pwrUpTime;
            if (i2cWrEn = '1') then
               v.acqTime   := i2cWrData(12 downto 8);
               v.calcntl   := i2cWrData(7);
               v.pwrConPol := i2cWrData(6);
               v.pwrConEn  := i2cWrData(5);
               v.pwrUpTime := i2cWrData(4 downto 0);
            end if;
         when "0010110" =>
            v.i2cRdData(15 downto 9) := "0001100";
            v.i2cRdData(8)           := ADDR_G;
            v.i2cRdData(7 downto 0)  := (others => '0');
            if (i2cWrEn = '1' and i2cWrData = "10101010") then
               v := REG_INIT_C;
            end if;
         when others => null;
      end case;


      v.data(0) := adcConversion(ain(0), 0.0, AVDD_G, 12, false);
      v.data(1) := adcConversion(ain(1), 0.0, AVDD_G, 12, false);
      v.data(2) := adcConversion(ain(2), 0.0, AVDD_G, 12, false);
      v.data(3) := adcConversion(ain(3), 0.0, AVDD_G, 12, false);

      rin       <= v;
      i2cRdData <= r.i2cRdData;
   end process comb;

   seq : process (clk, rst) is
   begin
      if (rst = '1') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture behavioral;
