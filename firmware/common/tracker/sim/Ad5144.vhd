-------------------------------------------------------------------------------
-- Title      : AD5144 Simulation Module
-------------------------------------------------------------------------------
-- File       : Ad5144.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-27
-- Last update: 2014-05-15
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

entity Ad5144 is
   
   generic (
      TPD_G : time := 1 ns);

   port (
      sclk  : in  sl;
      syncL : in  sl;
      sdi   : in  sl;
      sdo   : out sl;
      rout : out RealArray(0 to 3));

end entity Ad5144;

architecture rtl of Ad5144 is

   constant CMD_NOP_C        : slv(3 downto 0) := "0000";
   constant CMD_WR_RDAC_C    : slv(3 downto 0) := "0001";
   constant CMD_WR_INP_C     : slv(3 downto 0) := "0010";
   constant CMD_RDBACK_C     : slv(3 downto 0) := "0011";
   constant CMD_LRDAC_C      : slv(3 downto 0) := "0110";
   constant CMD_CPY_C        : slv(3 downto 0) := "0111";
   constant CMD_WR_EEPROM_C  : slv(3 downto 0) := "1000";
   constant CMD_SOFT_RESET_C : slv(3 downto 0) := "1011";
   constant CMD_WR_CTRLREG_C : slv(3 downto 0) := "1101";

   type RegType is record
      rdac    : Slv8Array(0 to 3);
      inp     : Slv8Array(0 to 3);
      eeprom  : Slv8Array(0 to 3);
      control : slv(3 downto 0);
      rdData  : slv(15 downto 0);
      rdStb   : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      rdac    => (others => X"80"),
      inp     => (others => X"80"),
      eeprom  => (others => X"80"),
      control => "0011",
      rdData  => (others => '0'),
      rdStb   => '0');

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal clk    : sl;
   signal rst : sl;
   signal wrData : slv(15 downto 0);
   signal wrStb  : sl;

begin

   -- Create internal clock to drive SpiSlave
   ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 5 ns)
      port map (
         clkP => clk,
         rst => rst);

   SpiSlave_1 : entity surf.SpiSlave
      generic map (
         TPD_G       => TPD_G,
         CPOL_G      => '1',
         CPHA_G      => '0',
         WORD_SIZE_G => 16)
      port map (
         clk    => clk,
         rst    => rst,
         sclk   => sclk,
         mosi   => sdi,
         miso   => sdo,
         selL   => syncL,
         rdData => r.rdData,
         rdStb  => r.rdStb,
         wrData => wrData,
         wrStb  => wrStb);

   comb : process (r, rst, wrData, wrStb) is
      variable v            : RegType;
      variable ctrlCode     : slv(3 downto 0);
      variable address      : slv(3 downto 0);
      variable data         : slv(7 downto 0);
      variable addressIndex : integer;
   begin

      ctrlCode     := wrData(15 downto 12);
      address      := wrData(11 downto 8);
      addressIndex := conv_integer(address(1 downto 0));
      data         := wrData(7 downto 0);

      v.rdStb := '0';

      if (wrStb = '1' and r.rdStb = '0') then
         -- Echo data back by default
         v.rdData := wrData;
         v.rdStb  := '1';

         case (ctrlCode) is             -- decode control code
            when CMD_WR_RDAC_C =>
               if (address(3) = '1') then
                  for i in 0 to 3 loop
                     v.rdac(i) := data;
                  end loop;
               else
                  v.rdac(addressIndex) := data;
               end if;
               
            when CMD_WR_INP_C =>
               if (address(3) = '1') then
                  for i in 0 to 3 loop
                     v.inp(i) := data;
                  end loop;
               else
                  v.inp(addressIndex) := data;
               end if;
               
            when CMD_RDBACK_C =>
               case data(1 downto 0) is
                  when "00" =>          -- Read Input Reg
                     v.rdData(7 downto 0) := r.inp(addressIndex);
                  when "01" =>          -- Read EERPOM
                     v.rdData(7 downto 0) := r.eeprom(addressIndex);
                  when "10" =>          -- READ control reg
                     v.rdData(7 downto 0) := "0000" & r.control;
                  when "11" =>          -- Read RDAC
                     v.rdData(7 downto 0) := r.rdac(addressIndex);
                  when others =>
                     v.rdData(7 downto 0) := (others => '0');
               end case;

            when CMD_LRDAC_C =>
               if (address(3) = '1') then
                  v.rdac := r.inp;
               else
                  v.rdac(addressIndex) := r.inp(addressIndex);
               end if;
               
            when CMD_CPY_C =>
               if (data(0) = '1') then
                  -- Copy rdac to eeprom
                  v.eeprom(addressIndex) := r.rdac(addressIndex);
               else
                  v.rdac(addressIndex) := r.eeprom(addressIndex);
               end if;

            when CMD_WR_EEPROM_C =>
               v.eeprom(addressIndex) := data(7 downto 0);

            when CMD_SOFT_RESET_C =>
               v.rdac := r.eeprom;
               v.inp  := (others => (others => '0'));

            when CMD_WR_CTRLREG_C =>
               v.control := data(3 downto 0);
               
            when others => null;
         end case;
         
      end if;

      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      for i in 0 to 3 loop
         rout(i) <= (10.0e3 * real(conv_integer(r.rdac(i)))) / 256.0;
      end loop;

   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
