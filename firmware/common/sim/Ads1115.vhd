-------------------------------------------------------------------------------
-- Title      : ADS1115 Simulation Model
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
use surf.I2cPkg.all;

entity Ads1115 is
   
   generic (
      TPD_G  : time := 1 ns;
      ADDR_G : sl   := '0');

   port (
      ain : in    RealArray(0 to 3);
      scl : inout sl;
      sda : inout sl);

end entity Ads1115;

architecture behavioral of Ads1115 is

   constant I2C_ADDR_C : slv(6 downto 0) := "100100" & ADDR_G;

   constant DATA_RATE_DIVIDERS_C : IntegerArray(0 to 7) := (
      0 => 1633990,                     -- 8 SPS
      1 => 817000,                      -- 16 SPS
      2 => 408500,                      -- 32 SPS
      3 => 204250,                      -- 64 SPS
      4 => 102125,                      -- 128 SPS
      5 => 52288,                       -- 256 SPS
      6 => 27520,                       -- 512 SPS
      7 => 15200);

   constant PGA_AMPLIFICATION_C : RealArray(0 to 7) := (
      0 => 0.6667,
      1 => 1.0,
      2 => 2.0,
      3 => 4.0,
      4 => 8.0,
      5 => 16.0,
      6 => 16.0,
      7 => 16.0);

   constant FULL_SCALE_RANGE_C : RealArray(0 to 7) := (
      0 => 6.144,
      1 => 4.096,
      2 => 2.048,
      3 => 1.024,
      4 => 0.512,
      5 => 0.256,
      6 => 0.256,
      7 => 0.256);

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
      count           : integer;
      i2cRdData       : slv(15 downto 0);
      newConfig       : sl;
      startConversion : sl;
      conversion      : slv(15 downto 0);
      os              : sl;
      mux             : slv(2 downto 0);
      pga             : slv(2 downto 0);
      mode            : sl;
      dr              : slv(2 downto 0);
      compMode        : sl;
      compPol         : sl;
      compLat         : sl;
      compQue         : slv(1 downto 0);
      threshLow       : slv(15 downto 0);
      threshHigh      : slv(15 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      count           => 0,
      i2cRdData       => (others => '0'),
      newConfig       => '0',
      startConversion => '0',
      conversion      => (others => '0'),
      os              => '1',
      mux             => "000",
      pga             => "010",
      mode            => '1',
      dr              => "100",
      compMode        => '0',
      compPol         => '0',
      compLat         => '0',
      compQue         => "00",
      threshLow       => X"8000",
      threshHigh      => X"7FFF");

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

   comb : process (ain, i2cAddr, i2cRdEn, i2cWrData, i2cWrEn, r) is
      variable v : RegType;

      impure function doConversion (ain : RealArray) return slv is
         variable pgaIndex : integer;
         variable tmpR     : real;
         variable tmpI     : integer;
         variable tmpSlv   : slv(15 downto 0);
      begin
         pgaIndex := conv_integer(r.pga);

         tmpR := 0.0;

         if (r.mux(2) = '0') then
            case (r.mux(1 downto 0)) is
               when "00" =>
                  tmpR := ain(0) - ain(1);
               when "01" =>
                  tmpR := ain(0) - ain(3);
               when "10" =>
                  tmpR := ain(1) - ain(3);
               when "11" =>
                  tmpR := ain(2) - ain(3);
               when others =>
                  tmpR := 0.0;
            end case;
         else
            tmpR := ain(conv_integer(r.mux(1 downto 0)));
         end if;

         -- Perform programmable gain
         tmpR := tmpR * PGA_AMPLIFICATION_C(pgaIndex);  -- Multiply by PGA

         -- Do conversion
         return adcConversion(tmpR, (-1.0 * FULL_SCALE_RANGE_C(pgaIndex)), FULL_SCALE_RANGE_C(pgaIndex), 16, true);
         
      end function doConversion;
      
   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- I2C Register Decoding
      ----------------------------------------------------------------------------------------------
      v.i2cRdData       := (others => '0');
      v.newConfig       := '0';
      v.startConversion := '0';
      case i2cAddr(1 downto 0) is
         when "00" =>
            v.i2cRdData := r.conversion;
         when "01" =>
            v.i2cRdData(15)           := r.os;
            v.i2cRdData(14 downto 12) := r.mux;
            v.i2cRdData(11 downto 9)  := r.pga;
            v.i2cRdData(8)            := r.mode;
            v.i2cRdData(7 downto 5)   := r.dr;
            v.i2cRdData(4)            := r.compMode;
            v.i2cRdData(3)            := r.compPol;
            v.i2cRdData(2)            := r.compLat;
            v.i2cRdData(1 downto 0)   := r.compQue;
            if (i2cWrEn = '1') then
               if (r.mode = '1') then   -- Single Shot
                  v.os := i2cWrData(15);
                  if (v.os = '1') then
                     v.startConversion := '1';
                  end if;
               end if;
               v.mux       := i2cWrData(14 downto 12);
               v.pga       := i2cWrData(11 downto 9);
               v.mode      := i2cWrData(8);
               v.dr        := i2cWrData(7 downto 5);
               v.compMode  := i2cWrData(4);
               v.compPol   := i2cWrData(3);
               v.compLat   := i2cWrData(2);
               v.compQue   := i2cWrData(1 downto 0);
               v.newConfig := '1';
            end if;
            if (i2cRdEn = '1') then
            -- Reset os upon read of conversion reg (is this right)?
--               v.os := '0';
            end if;
         when "10" =>
            v.i2cRdData := r.threshLow;
            if (i2cWrEn = '1') then
               v.threshLow := i2cWrData;
            end if;
         when "11" =>
            v.i2cRdData := r.threshHigh;
            if (i2cWrEn = '1') then
               v.threshHigh := i2cWrData;
            end if;
         when others => null;
      end case;


      if (r.mode = '0') then            -- Continuous
         v.count := r.count + 1;
         v.os    := '1';                -- Always performing a conversion
         if (r.count = DATA_RATE_DIVIDERS_C(conv_integer(r.dr))) then
            v.count      := 0;
            v.conversion := doConversion(ain);
         elsif (r.newConfig = '1') then
            v.count := 0;
         end if;

      else                              -- Power down mode
         if (r.startConversion = '1') then
            v.os    := '0';
            v.count := 0;
         end if;

         if (v.os = '0') then
            v.count := r.count + 1;
            if (r.count = DATA_RATE_DIVIDERS_C(conv_integer(r.dr))) then
               v.count      := 0;
               v.conversion := doConversion(ain);
               v.os         := '1';
            end if;
         end if;
      end if;

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
