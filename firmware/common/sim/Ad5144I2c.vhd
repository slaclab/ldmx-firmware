-------------------------------------------------------------------------------
-- Title      : AD5144 Simulation Module
-------------------------------------------------------------------------------
-- File       : Ad5144I2c.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-01-27
-- Last update: 2023-09-15
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

entity Ad5144I2c is

   generic (
      TPD_G  : time            := 1 ns;
      ADDR_G : slv(1 downto 0) := "00");

   port (
      scl  : inout sl;
      sda  : inout sl;
      rout : out   RealArray(0 to 3));

end entity Ad5144I2c;

architecture rtl of Ad5144I2c is

   constant ADDR_C : slv(6 downto 0) := ite(
      ADDR_G = "11", "0100000", ite(
         ADDR_G = "Z1", "0100010", ite(
            ADDR_G = "01", "0100011", ite(
               ADDR_G = "1Z", "0101000", ite(
                  ADDR_G = "ZZ", "0101010", ite(
                     ADDR_G = "01", "0101011", ite(
                        ADDR_G = "10", "0101100", ite(
                           ADDR_G = "Z0", "0101110", ite(
                              ADDR_G = "00", "0101111", "XXXXXXX")))))))));

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
      rdData  : slv(7 downto 0);
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

   signal clk       : sl;
   signal rst       : sl;
   signal i2ci      : i2c_in_type;
   signal i2co      : i2c_out_type;
   signal i2cAddr   : slv(7 downto 0);
   signal i2cWrEn   : sl;
   signal i2cWrData : slv(7 downto 0);
   signal i2cRdEn   : sl;
   signal i2cRdData : slv(7 downto 0);


begin

   -- Create internal clock to drive SpiSlave
   ClkRst_1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 5 ns)
      port map (
         clkP => clk,
         rst  => rst);

   I2cRegSlave_1 : entity surf.I2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => conv_integer(ADDR_C),
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => 2,
         ADDR_SIZE_G          => 1,
         DATA_SIZE_G          => 1,
         ADDR_AUTO_INC_G      => false,
         ENDIANNESS_G         => 0)
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


   comb : process (i2cAddr, i2cRdEn, i2cWrData, i2cWrEn, r, rst) is
      variable v            : RegType;
      variable ctrlCode     : slv(3 downto 0);
      variable address      : slv(3 downto 0);
      variable data         : slv(7 downto 0);
      variable addressIndex : integer;
   begin

      ctrlCode     := i2cAddr(7 downto 4);
      address      := i2cAddr(3 downto 0);
      addressIndex := conv_integer(address(1 downto 0));
      data         := i2cWrData(7 downto 0);

      v.rdStb := '0';

--       if (i2cWrEn = '1' and r.i2cRdEn = '0') then
--          -- Echo data back by default
--          v.rdData := wrData;
--          v.rdStb  := '1';

      case (ctrlCode) is                -- decode control code
         when CMD_WR_RDAC_C =>
            if (i2cWrEn = '1') then
               if (address(3) = '1') then
                  for i in 0 to 3 loop
                     v.rdac(i) := data;
                  end loop;
               else
                  v.rdac(addressIndex) := data;
               end if;
            end if;

         when CMD_WR_INP_C =>
            if (i2cWrEn = '1') then
               if (address(3) = '1') then
                  for i in 0 to 3 loop
                     v.inp(i) := data;
                  end loop;
               else
                  v.inp(addressIndex) := data;
               end if;
            end if;

         when CMD_RDBACK_C =>
            case data(1 downto 0) is
               when "00" =>             -- Read Input Reg
                  v.rdData(7 downto 0) := r.inp(addressIndex);
               when "01" =>             -- Read EERPOM
                  v.rdData(7 downto 0) := r.eeprom(addressIndex);
               when "10" =>             -- READ control reg
                  v.rdData(7 downto 0) := "0000" & r.control;
               when "11" =>             -- Read RDAC
                  v.rdData(7 downto 0) := r.rdac(addressIndex);
               when others =>
                  v.rdData(7 downto 0) := (others => '0');
            end case;

         when CMD_LRDAC_C =>
            if (i2cWrEn = '1') then
               if (address(3) = '1') then
                  v.rdac := r.inp;
               else
                  v.rdac(addressIndex) := r.inp(addressIndex);
               end if;
            end if;

         when CMD_CPY_C =>
            if (i2cWrEn = '1') then
               if (data(0) = '1') then
                  -- Copy rdac to eeprom
                  v.eeprom(addressIndex) := r.rdac(addressIndex);
               else
                  v.rdac(addressIndex) := r.eeprom(addressIndex);
               end if;
            end if;

         when CMD_WR_EEPROM_C =>
            if (i2cWrEn = '1') then
               v.eeprom(addressIndex) := data(7 downto 0);
            end if;

         when CMD_SOFT_RESET_C =>
            if (i2cWrEn = '1') then
               v.rdac := r.eeprom;
               v.inp  := (others => (others => '0'));
            end if;

         when CMD_WR_CTRLREG_C =>
            if (i2cWrEn = '1') then
               v.control := data(3 downto 0);
            end if;

         when others => null;
      end case;

      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      i2cRdData <= r.rdData;

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
