-------------------------------------------------------------------------------
-- Title      : Testbench for design "FrontEndBoard"
-------------------------------------------------------------------------------
-- File       : FrontEndBoardModel.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.i2cPkg.all;

library hps_daq;
use hps_daq.FebConfigPkg.all;
use hps_daq.HpsPkg.all;
----------------------------------------------------------------------------------------------------

entity FrontEndBoardModel is

   generic (
      TPD_G          : time                 := 1 ns;
      CLK_0_PERIOD_G : time                 := 8 ns;
      CLK_1_PERIOD_G : time                 := 8 ns;
      HYBRIDS_G      : natural range 1 to 4 := 4;
      HYBRID_TYPE_G  : slv(1 downto 0)      := NEW_HYBRID_C);

   port (
      -- GTP Reference Clocks
      gtRefClk0P : out sl;
      gtRefClk0N : out sl;
      gtRefClk1P : out sl;
      gtRefClk1N : out sl;

      -- ADC Data Interface
      adcClkP  : in  slv(HYBRIDS_G-1 downto 0);  -- 41 MHz clock to ADC
      adcClkN  : in  slv(HYBRIDS_G-1 downto 0);
      adcFClkP : out slv(HYBRIDS_G-1 downto 0);
      adcFClkN : out slv(HYBRIDS_G-1 downto 0);
      adcDClkP : out slv(HYBRIDS_G-1 downto 0);
      adcDClkN : out slv(HYBRIDS_G-1 downto 0);
      adcDataP : out slv5Array(HYBRIDS_G-1 downto 0);
      adcDataN : out slv5Array(HYBRIDS_G-1 downto 0);

      -- ADC Config Interface
      adcCsb  : inout slv(HYBRIDS_G-1 downto 0);
      adcSclk : inout slv(HYBRIDS_G-1 downto 0);
      adcSdio : inout slv(HYBRIDS_G-1 downto 0);

      -- Board I2C Interface
      ampI2cScl : inout sl;
      ampI2cSda : inout sl;

      -- Board I2C Interface
      boardI2cScl : inout sl;
      boardI2cSda : inout sl;

      -- Board SPI Interface
      boardSpiSclk : in  sl;
      boardSpiSdi  : in  sl;
      boardSpiSdo  : out sl;
      boardSpiCsL  : in  slv(4 downto 0);

      -- Hybrid power control
      hyPwrEn   : in  slv(HYBRIDS_G-1 downto 0);
      powerGood : out PowerGoodType;

      -- Interface to Hybrids
      hyClkP      : in  slv(HYBRIDS_G-1 downto 0);
      hyClkN      : in  slv(HYBRIDS_G-1 downto 0);
      hyTrgP      : in  slv(HYBRIDS_G-1 downto 0);
      hyTrgN      : in  slv(HYBRIDS_G-1 downto 0);
      hyRstL      : in  slv(HYBRIDS_G-1 downto 0);
      hyI2cScl    : in  slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaOut : in  slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaIn  : out slv(HYBRIDS_G-1 downto 0));

end entity FrontEndBoardModel;

----------------------------------------------------------------------------------------------------

architecture sim of FrontEndBoardModel is

   constant HY_AVDD_PWR_C : RealArray(0 to 3) := (0.5, 0.4, 0.3, 0.2);
   constant HY_DVDD_PWR_C : RealArray(0 to 3) := (0.6, 0.5, 0.4, 0.3);
   constant HY_125_PWR_C  : RealArray(0 to 3) := (0.4, 0.3, 0.2, 0.1);

   type HybridPowerType is record
      dvdd : real;
      avdd : real;
      v125 : real;
   end record HybridPowerType;
   type HybridPowerArray is array (natural range <>) of HybridPowerType;

   constant HY_CURRENT_C : HybridPowerArray(0 to 3) := (
      0 => (1.0, 1.1, 1.2),
      1 => (0.5, 0.6, 0.7),
      2 => (0.1, 0.2, 0.3),
      3 => (0.4, 0.3, 0.2));

   signal hyPwrTrim  : HybridPowerArray(0 to HYBRIDS_G-1);
   signal hyPwrInt   : HybridPowerArray(0 to HYBRIDS_G-1);
   signal hyPwrSense : HybridPowerArray(0 to HYBRIDS_G-1);

   constant BOARD_I2C_ADDRS_C : Slv3Array := (
      0 => "000",
      1 => "001",
      2 => "010",
      3 => "011",
      4 => "100");

   type HybridAoutArray is array (HYBRIDS_G-1 downto 0) of RealArray(0 to 4);
   signal hyAout : HybridAoutArray;

   type AdcAinArray is array (HYBRIDS_G-1 downto 0) of RealArray(7 downto 0);
   signal adcAin : AdcAinArray;

   signal hyI2cSdaBus : slv(HYBRIDS_G-1 downto 0);
   signal hyI2cSclBus : slv(HYBRIDS_G-1 downto 0);

   signal ampPdB : Slv6Array(3 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Clock Oscillators
   -------------------------------------------------------------------------------------------------
   ClkRst_CLK0 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_0_PERIOD_G,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => gtRefClk0P,
         clkN => gtRefClk0N,
         rst  => open,
         rstL => open);

   ClkRst_CLK1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => CLK_1_PERIOD_G,
         CLK_DELAY_G  => 3.14159 ns)
      port map (
         clkP => gtRefClk1P,
         clkN => gtRefClk1N,
         rst  => open,
         rstL => open);


   powerGood.a22  <= '1';
   powerGood.a18  <= '1';
   powerGood.a16  <= '1';
   powerGood.a29A <= '1';
   powerGood.a29D <= '1';

   -- Pullups for Board I2C Bus
   ampI2cSda <= 'H';
   ampI2cScl <= 'H';

   -- ampPdB ports are pulled up on the board      
   ampPdB <= (others => (others => 'H'));
   U_Tca6424a_1 : entity hps_daq.Tca6424a
      generic map (
         TPD_G  => TPD_G,
         ADDR_G => '0')
      port map (
         sda     => ampI2cSda,          -- [inout]
         scl     => ampI2cScl,          -- [inout]
         p(0)(0) => ampPdB(0)(0),
         p(0)(1) => ampPdB(0)(1),
         p(0)(2) => ampPdB(0)(2),
         p(0)(3) => ampPdB(0)(3),
         p(0)(4) => ampPdB(0)(4),
         p(0)(5) => ampPdB(0)(5),
         p(0)(6) => ampPdB(1)(0),
         p(0)(7) => ampPdB(1)(1),
         p(1)(0) => ampPdB(1)(2),
         p(1)(1) => ampPdB(1)(3),
         p(1)(2) => ampPdB(1)(4),
         p(1)(3) => ampPdB(1)(5),
         p(1)(4) => ampPdB(2)(0),
         p(1)(6) => ampPdB(2)(1),
         p(1)(5) => ampPdB(2)(2),
         p(1)(7) => ampPdB(2)(3),
         p(2)(0) => ampPdB(2)(4),
         p(2)(1) => ampPdB(2)(5),
         p(2)(2) => ampPdB(3)(0),
         p(2)(3) => ampPdB(3)(1),
         p(2)(4) => ampPdB(3)(2),
         p(2)(5) => ampPdB(3)(3),
         p(2)(6) => ampPdB(3)(4),
         p(2)(7) => ampPdB(3)(5));



   HYBRIDS_GEN : for i in HYBRIDS_G-1 downto 0 generate

      -- Digipots to control hybrid trimming
      HY_PWR_AD5144 : entity hps_daq.Ad5144
         generic map (
            TPD_G => TPD_G)
         port map (
            sclk    => boardSpiSclk,
            syncL   => boardSpiCsL(i),
            sdi     => boardSpiSdi,
            sdo     => boardSpiSdo,
            rout(0) => hyPwrTrim(i).v125,
            rout(1) => hyPwrTrim(i).avdd,
            rout(2) => hyPwrTrim(i).dvdd,
            rout(3) => open);

      -- Simulate power drivers and sense resistors
      hyPwrInt(i).avdd         <= ite(hyPwrEn(i) = '1', (0.5 * ((80.6e3 / (15.0e3 + hyPwrTrim(i).avdd) + 1.0))), 0.0);
      hyPwrSense(i).avdd       <= hyPwrInt(i).avdd - (0.15 * ite(hyPwrEn(i) = '1', HY_CURRENT_C(i).avdd, 0.0));
      powerGood.hybrid(i).avdd <= '1' when hyPwrInt(i).avdd > 2.0 else '0';

      hyPwrInt(i).dvdd         <= ite(hyPwrEn(i) = '1', (0.5 * ((80.6e3 / (15.0e3 + hyPwrTrim(i).dvdd) + 1.0))), 0.0);
      hyPwrSense(i).dvdd       <= hyPwrInt(i).dvdd - (0.15 * ite(hyPwrEn(i) = '1', HY_CURRENT_C(i).dvdd, 0.0));
      powerGood.hybrid(i).dvdd <= '1' when hyPwrInt(i).dvdd > 2.0 else '0';

      hyPwrInt(i).v125         <= ite(hyPwrEn(i) = '1', (0.5 * ((30.0e3 / (15.0e3 + hyPwrTrim(i).v125) + 1.0))), 0.0);
      hyPwrSense(i).v125       <= hyPwrInt(i).v125 - (0.15 * ite(hyPwrEn(i) = '1', HY_CURRENT_C(i).v125, 0.0));
      powerGood.hybrid(i).v125 <= '1' when hyPwrInt(i).v125 > 1.0 else '0';

      -- Pullups for Board I2C Bus
      boardI2cSda <= 'H';
      boardI2cScl <= 'H';



      -- LTC2991 for voltage and current
      -- Hybrd Power Monitoring
      Ltc2991_1 : entity hps_daq.Ltc2991
         generic map (
            TPD_G             => TPD_G,
            ADDR_G            => BOARD_I2C_ADDRS_C(i),
            VCC_G             => 3.3,
            CONVERSION_TIME_G => 100 us)
         port map (
            sda             => boardI2cSda,
            scl             => boardI2cScl,
            vin(1)          => hyPwrInt(i).dvdd,
            vin(2)          => hyPwrSense(i).dvdd,
            vin(3)          => hyPwrInt(i).avdd,
            vin(4)          => hyPwrSense(i).avdd,
            vin(5)          => hyPwrInt(i).v125,
            vin(6)          => hyPwrSense(i).v125,
            vin(8 downto 7) => (others => 0.0));

--      -- Hybrid I2C Drivers
      hyI2cSclBus(i) <= '0' when hyI2cScl(i) = '1'    else 'H';
      hyI2cSdaBus(i) <= '0' when hyI2cSdaOut(i) = '1' else 'H';
      hyI2cSdaIn(i)  <= to_x01z(hyI2cSdaBus(i));

      -- Instantiate hybrids
      Hybrid_1 : entity hps_daq.Hybrid
         generic map (
            TPD_G         => TPD_G,
            HYBRID_TYPE_G => HYBRID_TYPE_G)
         port map (
            dvdd      => hyPwrSense(i).dvdd,
            avdd      => hyPwrSense(i).avdd,
            v125      => hyPwrSense(i).v125,
            clk       => hyClkP(i),
            trig      => hyTrgP(i),
            rstL      => hyRstL(i),
            scl       => hyI2cSclBus(i),
            sda       => hyI2cSdaBus(i),
            analogOut => hyAout(i));


      -- Simulate preamplifiers (gain = 1.5, common mode = 1.25)
      -- Map hybrid analog outputs onto adc inputs
      adcAin(i)(0) <= hyAout(i)(0) * 1.5 + 1.25;
      adcAin(i)(1) <= hyAout(i)(1) * 1.5 + 1.25;
      adcAin(i)(2) <= 0.0;
      adcAin(i)(3) <= hyAout(i)(2) * 1.5 + 1.25;
      adcAin(i)(4) <= hyAout(i)(3) * 1.5 + 1.25;
      adcAin(i)(5) <= 0.0;
      adcAin(i)(6) <= hyAout(i)(4) * 1.5 + 1.25;
      adcAin(i)(7) <= 0.0;


      -- ADC config interface pullups
      adcSclk(i) <= 'H';
      adcSdio(i) <= 'H';
      adcCsb(i)  <= 'H';

      Ad9252_1 : entity hps_daq.Ad9252
         generic map (
            TPD_G        => TPD_G,
            CLK_PERIOD_G => 24 ns)
         port map (
            clkP           => adcClkP(i),
            clkN           => adcClkN(i),
            vin            => adcAin(i),
            dP(1 downto 0) => adcDataP(i)(1 downto 0),
            dP(2)          => open,
            dP(4 downto 3) => adcDataP(i)(3 downto 2),
            dP(5)          => open,
            dP(6)          => adcDataP(i)(4),
            dP(7)          => open,
            dN(1 downto 0) => adcDataN(i)(1 downto 0),
            dN(2)          => open,
            dN(4 downto 3) => adcDataN(i)(3 downto 2),
            dN(5)          => open,
            dN(6)          => adcDataN(i)(4),
            dN(7)          => open,
            dcoP           => adcDClkP(i),
            dcoN           => adcDClkN(i),
            fcoP           => adcFClkP(i),
            fcoN           => adcFClkN(i),
            sclk           => adcSclk(i),
            sdio           => adcSdio(i),
            csb            => adcCsb(i));

   end generate HYBRIDS_GEN;

   boardSpiSdo <= 'H';

   -- One more AD5144 for main power trimming
   MAIN_PWR_AD5144 : entity hps_daq.Ad5144
      generic map (
         TPD_G => TPD_G)
      port map (
         sclk  => boardSpiSclk,
         syncL => boardSpiCsL(4),
         sdi   => boardSpiSdi,
         sdo   => boardSpiSdo,
         rout  => open);

   Ltc2991_v125 : entity hps_daq.Ltc2991
      generic map (
         TPD_G             => TPD_G,
         ADDR_G            => BOARD_I2C_ADDRS_C(4),
         VCC_G             => 3.3,
         CONVERSION_TIME_G => 100 us)
      port map (
         sda    => boardI2cSda,
         scl    => boardI2cScl,
         vin(1) => 0.0,
         vin(2) => 0.0,
         vin(3) => 0.0,
         vin(4) => 0.0,
         vin(5) => 0.0,
         vin(6) => 0.0,
         vin(7) => 0.0,
         vin(8) => 0.0);


end architecture sim;



