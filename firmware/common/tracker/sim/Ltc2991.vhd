-------------------------------------------------------------------------------
-- Title      : LTC2991 Simulation Module
-------------------------------------------------------------------------------
-- File       : Ltc2991.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-27
-- Last update: 2014-04-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Implements AD5144 Digital Potentiometer SPI registers.
-------------------------------------------------------------------------------
-- Copyright (c) 2014 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.I2cPkg.all;

entity Ltc2991 is
   
   generic (
      TPD_G             : time := 1 ns;
      ADDR_G            : slv(2 downto 0);
      VCC_G             : real := 5.0;
      CONVERSION_TIME_G : time := 1.5 ms);

   port (
      sda : inout sl;
      scl : inout sl;
      vin : in    RealArray(8 downto 1));

end entity Ltc2991;

architecture rtl of Ltc2991 is
   
   constant I2C_ADDR_C         : slv(6 downto 0) := "1001" & ADDR_G;
   constant T_INTERNAL_INDEX_C : integer         := 9;
   constant VCC_INDEX_C        : integer         := 10;
   constant CLK_PERIOD_C       : time            := 10 ns;  -- 100 MHZ
   constant MAX_COUNT_C        : integer         := integer(CONVERSION_TIME_G/CLK_PERIOD_C)-1;
   constant COUNTER_SIZE_C     : integer         := bitSize(MAX_COUNT_C);

   signal clk : sl;
   signal rst : sl;

   -- I2C RegSlave IO
   signal i2ci      : i2c_in_type;
   signal i2co      : i2c_out_type;
   signal i2cAddr   : slv(7 downto 0);
   signal i2cWrEn   : sl;
   signal i2cWrData : slv(7 downto 0);
   signal i2cRdEn   : sl;
--   signal i2cRdData : slv(7 downto 0);


--   shared variable status       : slv(10 downto 1);  -- Vx contains new data
   type RegType is record
      count        : integer;
      channel      : integer;
      freeze       : boolean;
      i2cRdData    : slv(7 downto 0);
      enable       : slv(10 downto 1);         -- Channel enables
      busy         : sl;                       -- A conversion is in process
      filter       : slv(10 downto 1);
      differential : slv(8 downto 1);
      temperature  : slv(8 downto 1);
      kelvin       : slv(10 downto 1);
      repeat       : sl;
      vout         : Slv16Array(10 downto 1);  -- Converted data registers
   end record RegType;

   constant REG_INIT_C : RegType := (
      count        => 0,
      channel      => 1,
      freeze       => false,
      i2cRdData    => (others => '0'),
      enable       => (others => '0'),
      busy         => '0',
      filter       => (others => '0'),
      differential => (others => '0'),
      temperature  => (others => '0'),
      kelvin       => (others => '0'),
      repeat       => '0',
      vout         => (others => X"0000"));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   
begin

   -- Create internal clock to drive I2C Slave
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
         FILTER_G             => 2,
         ADDR_SIZE_G          => 1,
         DATA_SIZE_G          => 1,
         ENDIANNESS_G         => 1)
      port map (
         aRst   => rst,
         clk    => clk,
         addr   => i2cAddr,
         wrEn   => i2cWrEn,
         wrData => i2cWrData,
         rdEn   => i2cRdEn,
         rdData => r.i2cRdData,
         i2ci   => i2ci,
         i2co   => i2co);

   i2ci.scl <= to_x01z(scl);
   i2ci.sda <= to_x01z(sda);
   sda      <= i2co.sda when i2co.sdaoen = '0' else 'Z';
   scl      <= i2co.scl when i2co.scloen = '0' else 'Z';

   comb : process (i2cAddr, i2cWrData, i2cWrEn, r, rst, vin) is
      variable v : RegType;
   begin
      v := r;

      if (conv_integer(i2cAddr) mod 2 = 0 and i2cRdEn = '1') then
         v.freeze := true;
      end if;
      if (conv_integer(i2cAddr) mod 2 = 1 and i2cRdEn = '1') then
         v.freeze := false;
      end if;

      case (i2cAddr) is
         when X"00" =>
            v.i2cRdData(7) := r.vout(8)(15);
            v.i2cRdData(6) := r.vout(7)(15);
            v.i2cRdData(5) := r.vout(6)(15);
            v.i2cRdData(4) := r.vout(5)(15);
            v.i2cRdData(3) := r.vout(4)(15);
            v.i2cRdData(2) := r.vout(3)(15);
            v.i2cRdData(1) := r.vout(2)(15);
            v.i2cRdData(0) := r.vout(1)(15);

         when X"01" =>
            v.i2cRdData(7) := r.enable(8);
            v.i2cRdData(6) := r.enable(6);
            v.i2cRdData(5) := r.enable(4);
            v.i2cRdData(4) := r.enable(2);
            v.i2cRdData(3) := r.enable(T_INTERNAL_INDEX_C);
            v.i2cRdData(2) := r.busy;
            v.i2cRdData(1) := r.vout(T_INTERNAL_INDEX_C)(15);
            v.i2cRdData(0) := r.vout(VCC_INDEX_C)(15);

            if (i2cWrEn = '1') then
               v.enable(8 downto 7)         := i2cWrData(7) & i2cWrData(7);
               v.enable(6 downto 5)         := i2cWrData(6) & i2cWrData(6);
               v.enable(4 downto 3)         := i2cWrData(5) & i2cWrData(5);
               v.enable(2 downto 1)         := i2cWrData(4) & i2cWrData(4);
               v.enable(T_INTERNAL_INDEX_C) := i2cWrData(3);
               v.enable(VCC_INDEX_C)        := i2cWrData(3);

               v.busy := '1';
            end if;

         when X"06" =>
            v.i2cRdData(7) := r.filter(4);
            v.i2cRdData(6) := r.kelvin(4);
            v.i2cRdData(5) := r.temperature(4);
            v.i2cRdData(4) := r.differential(4);
            v.i2cRdData(3) := r.filter(2);
            v.i2cRdData(2) := r.kelvin(2);
            v.i2cRdData(1) := r.temperature(2);
            v.i2cRdData(0) := r.differential(2);

            if (i2cWrEn = '1') then
               v.filter(4 downto 3)       := i2cWrData(7) & i2cWrData(7);
               v.kelvin(4 downto 3)       := i2cWrData(6) & i2cWrData(6);
               v.temperature(4 downto 3)  := i2cWrData(5) & i2cWrData(5);
               v.differential(4 downto 3) := i2cWrData(4) & i2cWrData(4);
               v.filter(2 downto 1)       := i2cWrData(3) & i2cWrData(3);
               v.kelvin(2 downto 1)       := i2cWrData(2) & i2cWrData(2);
               v.temperature(2 downto 1)  := i2cWrData(1) & i2cWrData(1);
               v.differential(2 downto 1) := i2cWrData(0) & i2cWrData(1);
            end if;
            
         when X"07" =>
            v.i2cRdData(7) := r.filter(8);
            v.i2cRdData(6) := r.kelvin(8);
            v.i2cRdData(5) := r.temperature(8);
            v.i2cRdData(4) := r.differential(8);
            v.i2cRdData(3) := r.filter(6);
            v.i2cRdData(2) := r.kelvin(6);
            v.i2cRdData(1) := r.temperature(6);
            v.i2cRdData(0) := r.differential(6);

            if (i2cWrEn = '1') then
               v.filter(8 downto 7)       := i2cWrData(7) & i2cWrData(7);
               v.kelvin(8 downto 7)       := i2cWrData(6) & i2cWrData(6);
               v.temperature(8 downto 7)  := i2cWrData(5) & i2cWrData(5);
               v.differential(8 downto 7) := i2cWrData(4) & i2cWrData(4);
               v.filter(6 downto 5)       := i2cWrData(3) & i2cWrData(3);
               v.kelvin(6 downto 5)       := i2cWrData(2) & i2cWrData(2);
               v.temperature(6 downto 5)  := i2cWrData(1) & i2cWrData(1);
               v.differential(6 downto 5) := i2cWrData(0) & i2cWrData(0);
            end if;

         when X"08" =>
            v.i2cRdData(7) := '0';
            v.i2cRdData(6) := '0';
            v.i2cRdData(5) := '0';
            v.i2cRdData(4) := r.repeat;
            v.i2cRdData(3) := r.filter(T_INTERNAL_INDEX_C);
            v.i2cRdData(2) := r.kelvin(T_INTERNAL_INDEX_C);
            v.i2cRdData(1) := '0';
            v.i2cRdData(0) := '0';

            if (i2cWrEn = '1') then
               v.repeat := i2cWrData(4);
               v.filter(T_INTERNAL_INDEX_C) := i2cWrData(3);
               v.filter(VCC_INDEX_C)        := i2cWrData(3);
               v.kelvin(T_INTERNAL_INDEX_C) := i2cWrData(2);
               v.kelvin(VCC_INDEX_C)        := i2cWrData(2);
            end if;

         when X"0A" =>
            v.i2cRdData   := r.vout(1)(15 downto 8);
            v.vout(1)(15) := '0';
         when X"0B" =>
            v.i2cRdData := r.vout(1)(7 downto 0);
         when X"0C" =>
            v.i2cRdData   := r.vout(2)(15 downto 8);
            v.vout(2)(15) := '0';
         when X"0D" =>
            v.i2cRdData := r.vout(2)(7 downto 0);
         when X"0E" =>
            v.i2cRdData   := r.vout(3)(15 downto 8);
            v.vout(3)(15) := '0';
         when X"0F" =>
            v.i2cRdData := r.vout(3)(7 downto 0);
         when X"10" =>
            v.i2cRdData   := r.vout(4)(15 downto 8);
            v.vout(4)(15) := '0';
         when X"11" =>
            v.i2cRdData := r.vout(4)(7 downto 0);
         when X"12" =>
            v.i2cRdData   := r.vout(5)(15 downto 8);
            v.vout(5)(15) := '0';
         when X"13" =>
            v.i2cRdData := r.vout(5)(7 downto 0);
         when X"14" =>
            v.i2cRdData   := r.vout(6)(15 downto 8);
            v.vout(6)(15) := '0';
         when X"15" =>
            v.i2cRdData := r.vout(6)(7 downto 0);
         when X"16" =>
            v.i2cRdData   := r.vout(7)(15 downto 8);
            v.vout(7)(15) := '0';
         when X"17" =>
            v.i2cRdData := r.vout(7)(7 downto 0);
         when X"18" =>
            v.i2cRdData   := r.vout(8)(15 downto 8);
            v.vout(8)(15) := '0';
         when X"19" =>
            v.i2cRdData := r.vout(8)(7 downto 0);
         when X"1A" =>
            v.i2cRdData                    := r.vout(T_INTERNAL_INDEX_C)(15 downto 8);
            v.vout(T_INTERNAL_INDEX_C)(15) := '0';
         when X"1B" =>
            v.i2cRdData := r.vout(T_INTERNAL_INDEX_C)(7 downto 0);
         when X"1C" =>
            v.i2cRdData             := r.vout(VCC_INDEX_C)(15 downto 8);
            v.vout(VCC_INDEX_C)(15) := '0';
         when X"1D" =>
            v.i2cRdData := r.vout(VCC_INDEX_C)(7 downto 0);
            
         when others =>
            v.i2cRdData := (others => '0');
            
      end case;



      if (r.busy = '1' and r.freeze = false) then
         v.count := r.count + 1;
         if (r.enable(r.channel) = '1') then
            if (r.count = MAX_COUNT_C) then
               -- do conversion
               if (r.channel mod 2 /= 0 and r.channel <= 8) then  --i = 1 or i = 3 or i = 5 or i = 7) then
                  v.vout(r.channel)(14 downto 0) := adcConversion(vin(r.channel), -5.0, 5.0, 15, true);
               elsif (r.channel mod 2 = 0 and r.channel <= 8) then  -- = 2 or i = 4 or i = 6 or i = 8) then
                  if (r.differential(r.channel) = '1') then
                     v.vout(r.channel)(14 downto 0) := adcConversion(vin(r.channel-1)-vin(r.channel), -0.3, 0.3, 15, true);
                  else
                     v.vout(r.channel)(14 downto 0) := adcConversion(vin(r.channel), -5.0, 5.0, 15, true);
                  end if;
               elsif (r.channel = T_INTERNAL_INDEX_C) then
                  if (r.kelvin(T_INTERNAL_INDEX_C) = '1') then
                     v.vout(r.channel)(12 downto 0) := adcConversion(310.928, 0.0, 512.0, 13, false);
                  else
                     v.vout(r.channel)(12 downto 0) := adcConversion(37.7778, -256.0, 256.0, 13, true);
                  end if;
               elsif (r.channel = VCC_INDEX_C) then
                  v.vout(r.channel)(14 downto 0) := adcConversion(VCC_G-2.5, -5.0, 5.0, 15, true);
               end if;
               v.vout(r.channel)(15) := '1';

               v.count   := 0;
               v.channel := r.channel + 1;
               if (r.channel = 10) then
                  v.channel := 1;
                  v.busy    := r.repeat;
               end if;
            end if;
         else
            v.count   := 0;
            v.channel := r.channel + 1;
            if (r.channel = 10) then
               v.channel := 1;
               v.busy    := r.repeat;
            end if;
         end if;
      end if;

      if (rst = '1') then
         v := REG_INIT_C;
         for i in 1 to 8 loop
            v.vout(i)(14 downto 0) := adcConversion(vin(i), -5.0, 5.0, 15, true);
         end loop;
         v.vout(T_INTERNAL_INDEX_C)(12 downto 0) := adcConversion(37.7778, -256.0, 256.0, 13, true);
         v.vout(VCC_INDEX_C)(14 downto 0)        := adcConversion(VCC_G-2.5, -0.3, 5.0, 15, true);
         
      end if;

      rin <= v;

   end process;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end architecture rtl;
