-------------------------------------------------------------------------------
-- Title      : TCA6424A Simulation Module
-------------------------------------------------------------------------------
-- File       : Pcal6524.vhd
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

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.I2cPkg.all;

entity Pcal6524 is

   generic (
      TPD_G  : time := 1 ns;
      ADDR_G : sl   := '0');
   port (
      sda : inout sl;
      scl : inout sl;
      p   : inout slv8Array(2 downto 0));

end entity Pcal6524;

architecture rtl of Pcal6524 is

   constant I2C_ADDR_C : slv(6 downto 0) := "010001" & ADDR_G;

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
      i2cRdData         : slv(7 downto 0);
      outputPort        : slv8Array(2 downto 0);
      polarityPort      : slv8Array(2 downto 0);
      configurationPort : slv8Array(2 downto 0);

   end record RegType;

   constant REG_INIT_C : RegType := (
      i2cRdData         => (others => '0'),
      outputPort        => (others => (others => '1')),
      polarityPort      => (others => (others => '0')),
      configurationPort => (others => (others => '1')));

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

   comb : process (i2cAddr, i2cWrEn, p, r) is
      variable v : RegType;
   begin
      v := r;

      case (i2cAddr) is
         -------------------------------------------------------------------------------------------
         -- Input Port
         -------------------------------------------------------------------------------------------
         when X"00" =>
            v.i2cRdData := p(0) xor r.polarityPort(0);

         when X"01" =>
            v.i2cRdData := p(1) xor r.polarityPort(0);

         when X"02" =>
            v.i2cRdData := p(2) xor r.polarityPort(0);

         -------------------------------------------------------------------------------------------
         -- Output Port
         -------------------------------------------------------------------------------------------
         when X"04" =>
            v.i2cRdData := r.outputPort(0);
            if (i2cWrEn = '1') then
               v.outputPort(0) := i2cWrData;
            end if;

         when X"05" =>
            v.i2cRdData := r.outputPort(1);
            if (i2cWrEn = '1') then
               v.outputPort(1) := i2cWrData;
            end if;

         when X"06" =>
            v.i2cRdData := r.outputPort(2);
            if (i2cWrEn = '1') then
               v.outputPort(2) := i2cWrData;
            end if;

         -------------------------------------------------------------------------------------------
         -- Polarity Port
         -------------------------------------------------------------------------------------------
         when X"08" =>
            v.i2cRdData := r.polarityPort(0);
            if (i2cWrEn = '1') then
               v.polarityPort(0) := i2cWrData;
            end if;

         when X"09" =>
            v.i2cRdData := r.polarityPort(1);
            if (i2cWrEn = '1') then
               v.polarityPort(1) := i2cWrData;
            end if;

         when X"0A" =>
            v.i2cRdData := r.polarityPort(2);
            if (i2cWrEn = '1') then
               v.polarityPort(2) := i2cWrData;
            end if;

         -------------------------------------------------------------------------------------------
         -- Configuration Port
         -------------------------------------------------------------------------------------------
         when X"0C" =>
            v.i2cRdData := r.configurationPort(0);
            if (i2cWrEn = '1') then
               v.configurationPort(0) := i2cWrData;
            end if;

         when X"0D" =>
            v.i2cRdData := r.configurationPort(1);
            if (i2cWrEn = '1') then
               v.configurationPort(1) := i2cWrData;
            end if;

         when X"0E" =>
            v.i2cRdData := r.configurationPort(2);
            if (i2cWrEn = '1') then
               v.configurationPort(2) := i2cWrData;
            end if;

         when others =>
            null;

      end case;
      rin <= v;

   end process;

   

   PORT_GEN : for i in 2 downto 0 generate
      PIN_GEN : for j in 7 downto 0 generate
         U_IOBUFT : IOBUF
            port map (
               I  => r.outputPort(i)(j),
               O  => open,
               IO => p(i)(j),
               T  => r.configurationPort(i)(j));

      end generate PIN_GEN;
   end generate PORT_GEN;


   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end architecture rtl;
