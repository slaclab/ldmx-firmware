-------------------------------------------------------------------------------
-- Title      : Testbench for design "FrontEndBoard"
-------------------------------------------------------------------------------
-- File       : LdmxFebBoardModel.vhd
-- Company    : SLAC National Accelerator Laboratory
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
use surf.i2cPkg.all;

library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;
----------------------------------------------------------------------------------------------------

entity LdmxFebBoardModel is

   generic (
      TPD_G             : time    := 1 ns;
      ADCS_G            : integer := 4;
      HYBRIDS_G         : integer := 8;
      APVS_PER_HYBRID_G : integer := 6);

   port (
      gtRefClk185P   : out   sl;
      gtRefClk185N   : out   sl;
      gtRefClk250P   : out   sl;
      gtRefClk250N   : out   sl;
      adcFClkP       : out   slv(HYBRIDS_G-1 downto 0);
      adcFClkN       : out   slv(HYBRIDS_G-1 downto 0);
      adcDClkP       : out   slv(HYBRIDS_G-1 downto 0);
      adcDClkN       : out   slv(HYBRIDS_G-1 downto 0);
      adcDataP       : out   slv6Array(HYBRIDS_G-1 downto 0);
      adcDataN       : out   slv6Array(HYBRIDS_G-1 downto 0);
      adcClkP        : in    slv(ADCS_G-1 downto 0);
      adcClkN        : in    slv(ADCS_G-1 downto 0);
      adcCsb         : inout slv(ADCS_G*2-1 downto 0);
      adcSclk        : inout slv(ADCS_G-1 downto 0);
      adcSdio        : inout slv(ADCS_G-1 downto 0);
      adcPdwn        : in    slv(ADCS_G-1 downto 0);
      locI2cScl      : inout sl;
      locI2cSda      : inout sl;
      sfpI2cScl      : inout sl;
      sfpI2cSda      : inout sl;
      qsfpI2cScl     : inout sl;
      qsfpI2cSda     : inout sl;
      qsfpI2cResetL  : inout sl := '1';
      digPmBusScl    : inout sl;
      digPmBusSda    : inout sl;
      digPmBusAlertL : out   sl;
      anaPmBusScl    : inout sl;
      anaPmBusSda    : inout sl;
      anaPmBusAlertL : out   sl;
      hyPwrI2cScl    : inout slv(HYBRIDS_G-1 downto 0);
      hyPwrI2cSda    : inout slv(HYBRIDS_G-1 downto 0);
      hyPwrEnOut     : in    slv(HYBRIDS_G-1 downto 0);
      hyClkP         : in    slv(HYBRIDS_G-1 downto 0);
      hyClkN         : in    slv(HYBRIDS_G-1 downto 0);
      hyTrgP         : in    slv(HYBRIDS_G-1 downto 0);
      hyTrgN         : in    slv(HYBRIDS_G-1 downto 0);
      hyRstL         : in    slv(HYBRIDS_G-1 downto 0);
      hyI2cScl       : in    slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaOut    : in    slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaIn     : out   slv(HYBRIDS_G-1 downto 0);
      vauxp          : out   slv(3 downto 0);
      vauxn          : out   slv(3 downto 0);
      leds           : in    slv(7 downto 0));

end entity LdmxFebBoardModel;


architecture sim of LdmxFebBoardModel is

   constant CLK_185_PERIOD_G  : real := 5.3848e-9;
   constant ADC_CLK_PERIOD_C : time := CLK_185_PERIOD_G * 5 sec;

   constant HY_AVDD_PWR_C : RealArray(0 to 7) := (0.5, 0.4, 0.3, 0.2, 0.5, 0.4, 0.3, 0.2);
   constant HY_DVDD_PWR_C : RealArray(0 to 7) := (0.6, 0.5, 0.4, 0.3, 0.6, 0.5, 0.4, 0.3);
   constant HY_125_PWR_C  : RealArray(0 to 7) := (0.4, 0.3, 0.2, 0.1, 0.4, 0.3, 0.2, 0.1);

   type HybridPowerType is record
      dvdd : real;
      avdd : real;
      v125 : real;
   end record HybridPowerType;
   type HybridPowerArray is array (natural range <>) of HybridPowerType;

   constant HY_CURRENT_C : HybridPowerArray(0 to 7) := (
      0 => (1.0, 1.1, 1.2),
      1 => (0.5, 0.6, 0.7),
      2 => (0.1, 0.2, 0.3),
      3 => (0.4, 0.3, 0.2),
      4 => (1.0, 1.1, 1.2),
      5 => (0.5, 0.6, 0.7),
      6 => (0.1, 0.2, 0.3),
      7 => (0.4, 0.3, 0.2));

   signal hyPwrTrim        : HybridPowerArray(0 to HYBRIDS_G-1);
   signal hyPwrInt         : HybridPowerArray(0 to HYBRIDS_G-1);
   signal hyPwrLocSense    : HybridPowerArray(0 to HYBRIDS_G-1);
   signal hyPwrRemSense    : HybridPowerArray(0 to HYBRIDS_G-1);
   signal hyPwrRemGndSense : HybridPowerArray(0 to HYBRIDS_G-1);

   type HybridAoutArray is array (HYBRIDS_G-1 downto 0) of RealArray(0 to APVS_PER_HYBRID_G-1);
   signal hyAout : HybridAoutArray := (others => (others => 0.0));

   type AdcAinArray is array (HYBRIDS_G-1 downto 0) of RealArray(APVS_PER_HYBRID_G-1 downto 0);
   signal adcAin : AdcAinArray := (others => (others => 0.0));

   signal hyI2cSdaBus : slv(HYBRIDS_G-1 downto 0);
   signal hyI2cSclBus : slv(HYBRIDS_G-1 downto 0);

   signal ampPdB : Slv6Array(HYBRIDS_G-1 downto 0);

   signal aP5Sense       : real;
   signal aN5Sense       : real;
   signal anaNegVinSense : real;
   signal a18vSenseP     : real;
   signal a18vSenseN     : real;
   signal a18vdSenseP    : real;
   signal a18vdSenseN    : real;


begin

   -------------------------------------------------------------------------------------------------
   -- Clock Oscillators
   -------------------------------------------------------------------------------------------------
   ClkRst_CLK0 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G      => CLK_185_PERIOD_G * 1 sec,
         CLK_DELAY_G       => 1 ns,
         RST_START_DELAY_G => 0 ns,
         RST_HOLD_TIME_G   => 5 us,
         SYNC_RESET_G      => true)
      port map (
         clkP => gtRefClk185P,
         clkN => gtRefClk185N,
         rst  => open,
         rstL => open);

   ClkRst_CLK1 : entity surf.ClkRst
      generic map (
         CLK_PERIOD_G => 4.0 ns,
         CLK_DELAY_G  => 3.14159 ns)
      port map (
         clkP => gtRefClk250P,
         clkN => gtRefClk250N,
         rst  => open,
         rstL => open);

   -------------------------------------------------------------------------------------------------
   -- ADCs
   -------------------------------------------------------------------------------------------------
   ADC_GEN : for i in ADCS_G-1 downto 0 generate
      -- ADC config interface pullups
      adcSclk(i) <= 'H';
      adcSdio(i) <= 'H';
      adcCsb(i)  <= 'H';

      U_Ad9249_1 : entity surf.Ad9249
         generic map (
            TPD_G            => TPD_G,
            CLK_PERIOD_G     => ADC_CLK_PERIOD_C,
            DIVCLK_DIVIDE_G  => 1,
            CLKFBOUT_MULT_G  => 49,
            CLK_DCO_DIVIDE_G => 7,
            CLK_FCO_DIVIDE_G => 49)
         port map (
            clkP              => adcClkP(i),                 -- [in]
            clkN              => adcClkN(i),                 -- [in]
            vin(1 downto 0)   => (others => 0.0),            -- [in]
            vin(7 downto 2)   => adcAin(i*2)(5 downto 0),    -- [in]
            vin(13 downto 8)  => adcAin(i*2+1)(5 downto 0),  -- [in]
            vin(15 downto 14) => (others => 0.0),            -- [in]
            dP(1 downto 0)    => open,                       -- [out]
            dp(2)             => adcDataP(i*2)(5),           -- [out]
            dp(3)             => adcDataP(i*2)(4),           -- [out]
            dp(4)             => adcDataP(i*2)(3),           -- [out]
            dp(5)             => adcDataP(i*2)(2),           -- [out]
            dp(6)             => adcDataP(i*2)(1),           -- [out]
            dp(7)             => adcDataP(i*2)(0),           -- [out]
            dp(8)             => adcDataP(i*2+1)(5),         -- [out]
            dp(9)             => adcDataP(i*2+1)(4),         -- [out]
            dp(10)            => adcDataP(i*2+1)(3),         -- [out]
            dp(11)            => adcDataP(i*2+1)(2),         -- [out]
            dp(12)            => adcDataP(i*2+1)(1),         -- [out]
            dp(13)            => adcDataP(i*2+1)(0),         -- [out]
            dp(15 downto 14)  => open,                       -- [out]
            dN(1 downto 0)    => open,                       -- [out]
            dN(2)             => adcDataN(i*2)(5),           -- [out]
            dN(3)             => adcDataN(i*2)(4),           -- [out]
            dN(4)             => adcDataN(i*2)(3),           -- [out]
            dN(5)             => adcDataN(i*2)(2),           -- [out]
            dN(6)             => adcDataN(i*2)(1),           -- [out]
            dN(7)             => adcDataN(i*2)(0),           -- [out]
            dN(8)             => adcDataN(i*2+1)(5),         -- [out]
            dN(9)             => adcDataN(i*2+1)(4),         -- [out]
            dN(10)            => adcDataN(i*2+1)(3),         -- [out]
            dN(11)            => adcDataN(i*2+1)(2),         -- [out]
            dN(12)            => adcDataN(i*2+1)(1),         -- [out]
            dN(13)            => adcDataN(i*2+1)(0),         -- [out]
            dN(15 downto 14)  => open,                       -- [out]
            dcoP(0)           => adcDClkP(i*2),              -- [out]
            dcoP(1)           => adcDClkP(i*2+1),            -- [out]
            dcoN(0)           => adcDClkN(i*2),              -- [out]
            dcoN(1)           => adcDClkN(i*2+1),            -- [out]
            fcoP(0)           => adcFClkP(i*2),              -- [out]
            fcoP(1)           => adcFClkP(i*2+1),            -- [out]
            fcoN(0)           => adcFClkN(i*2),              -- [out]
            fcoN(1)           => adcFClkN(i*2+1),            -- [out]            
            sclk              => adcSclk(i),                 -- [in]
            sdio              => adcSdio(i),                 -- [inout]
            csb               => adcCsb(2*i+1 downto 2*i));  -- [in]

   end generate ADC_GEN;

   -------------------------------------------------------------------------------------------------
   -- Pre-Amps
   -------------------------------------------------------------------------------------------------
   HY_PREAMP_GEN : for hybrid in HYBRIDS_G-1 downto 0 generate
      APV_PREAMP_GEN : for apv in APVS_PER_HYBRID_G-1 downto 0 generate
         adcAin(hybrid)(apv) <= hyAout(hybrid)(apv) * 1.5 + 1.25;
      end generate APV_PREAMP_GEN;
   end generate HY_PREAMP_GEN;


   -------------------------------------------------------------------------------------------------
   -- Preamp Power down
   -------------------------------------------------------------------------------------------------
   -- Pullups for Board I2C Bus
   locI2cSda <= 'H';
   locI2cScl <= 'H';

   -- ampPdB ports are pulled up on the board      
   ampPdB <= (others => (others => 'H'));
   U_Pcal6524_1 : entity ldmx_tracker.Pcal6524
      generic map (
         TPD_G  => TPD_G,
         ADDR_G => '0')
      port map (
         sda     => locI2cSda,          -- [inout]
         scl     => locI2cScl,          -- [inout]
         p(0)(0) => ampPdB(1)(1),
         p(0)(1) => ampPdB(1)(0),
         p(0)(2) => ampPdB(0)(5),
         p(0)(3) => ampPdB(0)(4),
         p(0)(4) => ampPdB(0)(3),
         p(0)(5) => ampPdB(0)(2),
         p(0)(6) => ampPdB(0)(1),
         p(0)(7) => ampPdB(0)(0),
         p(1)(0) => ampPdB(1)(5),
         p(1)(1) => ampPdB(1)(4),
         p(1)(2) => ampPdB(1)(3),
         p(1)(3) => ampPdB(1)(2),
         p(1)(4) => ampPdB(2)(3),
         p(1)(6) => ampPdB(2)(2),
         p(1)(5) => ampPdB(2)(1),
         p(1)(7) => ampPdB(2)(0),
         p(2)(0) => ampPdB(3)(5),
         p(2)(1) => ampPdB(3)(4),
         p(2)(2) => ampPdB(3)(3),
         p(2)(3) => ampPdB(3)(2),
         p(2)(4) => ampPdB(3)(1),
         p(2)(5) => ampPdB(3)(0),
         p(2)(6) => ampPdB(2)(5),
         p(2)(7) => ampPdB(2)(4));

   U_Pcal6524_2 : entity ldmx_tracker.Pcal6524
      generic map (
         TPD_G  => TPD_G,
         ADDR_G => '1')
      port map (
         sda     => locI2cSda,          -- [inout]
         scl     => locI2cScl,          -- [inout]
         p(0)(0) => ampPdB(5)(1),
         p(0)(1) => ampPdB(5)(0),
         p(0)(2) => ampPdB(4)(5),
         p(0)(3) => ampPdB(4)(4),
         p(0)(4) => ampPdB(4)(3),
         p(0)(5) => ampPdB(4)(2),
         p(0)(6) => ampPdB(4)(1),
         p(0)(7) => ampPdB(4)(0),
         p(1)(0) => ampPdB(5)(5),
         p(1)(1) => ampPdB(5)(4),
         p(1)(2) => ampPdB(5)(3),
         p(1)(3) => ampPdB(5)(2),
         p(1)(4) => ampPdB(6)(3),
         p(1)(6) => ampPdB(6)(2),
         p(1)(5) => ampPdB(6)(1),
         p(1)(7) => ampPdB(6)(0),
         p(2)(0) => ampPdB(7)(5),
         p(2)(1) => ampPdB(7)(4),
         p(2)(2) => ampPdB(7)(3),
         p(2)(3) => ampPdB(7)(2),
         p(2)(4) => ampPdB(7)(1),
         p(2)(5) => ampPdB(7)(0),
         p(2)(6) => ampPdB(6)(5),
         p(2)(7) => ampPdB(6)(4));


   -------------------------------------------------------------------------------------------------
   -- Instantiate Hybrids
   -------------------------------------------------------------------------------------------------
   HYBRIDS_GEN : for i in HYBRIDS_G-1 downto 0 generate
--      -- Hybrid I2C Drivers
      hyI2cSclBus(i) <= '0' when hyI2cScl(i) = '1'    else 'H';
      hyI2cSdaBus(i) <= '0' when hyI2cSdaOut(i) = '1' else 'H';
      hyI2cSdaIn(i)  <= to_x01z(hyI2cSdaBus(i));

      -- Instantiate hybrids
      Hybrid_1 : entity ldmx_tracker.LdmxHybrid
         generic map (
            TPD_G => TPD_G)
         port map (
            dvdd      => hyPwrLocSense(i).dvdd,
            avdd      => hyPwrLocSense(i).avdd,
            v125      => hyPwrLocSense(i).v125,
            clk       => hyClkP(i),
            trig      => hyTrgP(i),
            rstL      => hyRstL(i),
            scl       => hyI2cSclBus(i),
            sda       => hyI2cSdaBus(i),
            analogOut => hyAout(i));
   end generate HYBRIDS_GEN;

   -------------------------------------------------------------------------------------------------
   -- Hybrid Power and monitoring
   -------------------------------------------------------------------------------------------------
   HYBRID_POWER_GEN : for i in HYBRIDS_G-1 downto 0 generate

      hyPwrI2cScl(i) <= 'H';
      hyPwrI2cSda(i) <= 'H';
      -- Digipots to control hybrid trimming
      HY_PWR_AD5144 : entity ldmx_tracker.Ad5144I2c
         generic map (
            TPD_G  => TPD_G,
            ADDR_G => "11")
         port map (
            scl     => hyPwrI2cScl(i),
            sda     => hyPwrI2cSda(i),
            rout(0) => hyPwrTrim(i).dvdd,
            rout(1) => hyPwrTrim(i).avdd,
            rout(2) => hyPwrTrim(i).v125,
            rout(3) => open);

      -- Simulate power drivers and sense resistors
      hyPwrInt(i).avdd      <= ite(hyPwrEnOut(i) = '1', (0.8 * (37.4e3 + 14.0e3 + hyPwrTrim(i).avdd)) / (14.0e3 + hyPwrTrim(i).avdd), 0.0);
      hyPwrLocSense(i).avdd <= hyPwrInt(i).avdd - (0.02 * ite(hyPwrEnOut(i) = '1', HY_CURRENT_C(i).avdd, 0.0));

      hyPwrInt(i).dvdd      <= ite(hyPwrEnOut(i) = '1', (0.8 * (37.4e3 + 14.0e3 + hyPwrTrim(i).dvdd)) / (14.0e3 + hyPwrTrim(i).dvdd), 0.0);
      hyPwrLocSense(i).dvdd <= hyPwrInt(i).dvdd - (0.02 * ite(hyPwrEnOut(i) = '1', HY_CURRENT_C(i).dvdd, 0.0));

      hyPwrInt(i).v125      <= ite(hyPwrEnOut(i) = '1', (0.8 * (3.01e3 + 4.12e3 + hyPwrTrim(i).v125)) / (4.12e3 + hyPwrTrim(i).v125), 0.0);
      hyPwrLocSense(i).v125 <= hyPwrInt(i).v125 - (0.02 * ite(hyPwrEnOut(i) = '1', HY_CURRENT_C(i).v125, 0.0));


      -- LTC2991 for voltage and current
      -- Hybrd Power Monitoring
      Ltc2991_U22 : entity ldmx_tracker.Ltc2991
         generic map (
            TPD_G             => TPD_G,
            ADDR_G            => "000",
            VCC_G             => 3.3,
            CONVERSION_TIME_G => 100 us)
         port map (
            sda             => hyPwrI2cSda(i),
            scl             => hyPwrI2cScl(i),
            vin(1)          => hyPwrInt(i).dvdd,
            vin(2)          => hyPwrLocSense(i).dvdd,
            vin(3)          => hyPwrInt(i).avdd,
            vin(4)          => hyPwrLocSense(i).avdd,
            vin(5)          => hyPwrInt(i).v125,
            vin(6)          => hyPwrLocSense(i).v125,
            vin(8 downto 7) => (others => 0.0));

      -- Simulate drop over 100 cm of 28AWG
      hyPwrRemSense(i).avdd    <= (hyPwrLocSense(i).avdd - (HY_CURRENT_C(i).avdd * 64.9e-3 * 3)) * 0.1;
      hyPwrRemGndSense(i).avdd <= (HY_CURRENT_C(i).avdd * 64.9e-3 * 3);

      hyPwrRemSense(i).dvdd    <= (hyPwrLocSense(i).dvdd - (HY_CURRENT_C(i).dvdd * 64.9e-3 * 3)) * 0.1;
      hyPwrRemGndSense(i).dvdd <= (HY_CURRENT_C(i).dvdd * 64.9e-3 * 3);

      hyPwrRemSense(i).v125    <= (hyPwrLocSense(i).v125 - (HY_CURRENT_C(i).v125 * 64.9e-3 * 3)) * 0.1;
      hyPwrRemGndSense(i).v125 <= (HY_CURRENT_C(i).v125 * 64.9e-3 * 3);


      -- Sense monitoring
      Ltc2991_U20 : entity ldmx_tracker.Ltc2991
         generic map (
            TPD_G             => TPD_G,
            ADDR_G            => "001",
            VCC_G             => 3.3,
            CONVERSION_TIME_G => 100 us)
         port map (
            sda             => hyPwrI2cSda(i),
            scl             => hyPwrI2cScl(i),
            vin(1)          => hyPwrRemSense(i).dvdd,
            vin(2)          => hyPwrRemGndSense(i).dvdd,
            vin(3)          => hyPwrRemSense(i).avdd,
            vin(4)          => hyPwrRemGndSense(i).avdd,
            vin(5)          => hyPwrRemSense(i).v125,
            vin(6)          => hyPwrRemGndSense(i).v125,
            vin(8 downto 7) => (others => 0.0));



   end generate HYBRID_POWER_GEN;


   -------------------------------------------------------------------------------------------------
   -- Digital Regulator PM Bus
   -------------------------------------------------------------------------------------------------
   digPmBusSda    <= 'H';
   digPmBusScl    <= 'H';
   digPmBusAlertL <= 'H';

   -- For now just use i2c rams


   -------------------------------------------------------------------------------------------------
   -- Analog Regulator PM Bus
   -------------------------------------------------------------------------------------------------
   anaPmBusSda    <= 'H';
   anaPmBusScl    <= 'H';
   anaPmBusAlertL <= 'H';

   -------------------------------------------------------------------------------------------------
   -- Misc Sense
   -------------------------------------------------------------------------------------------------
   aP5Sense       <= 5.0 * 1.2e3 / (1.0e3 + 1.2e3);
   aN5Sense       <= -5.0 * 1.2e3 / (1.0e3 + 1.2e3);
   anaNegVinSense <= -5.5 * 1.2e3 / (1.0e3 + 1.2e3);
   a18vSenseP     <= 1.795;
   a18vSenseN     <= 1.795 - (0.02 * 2.0);
   a18vdSenseP    <= 1.795;
   a18vdSenseN    <= 1.795 - (0.02 * 2.0);

   -- Sense monitoring
   Ltc2991_U25 : entity ldmx_tracker.Ltc2991
      generic map (
         TPD_G             => TPD_G,
         ADDR_G            => "000",
         VCC_G             => 3.3,
         CONVERSION_TIME_G => 100 us)
      port map (
         sda    => digPmBusSda,
         scl    => digPmBusScl,
         vin(1) => aP5Sense,
         vin(2) => aN5Sense,
         vin(3) => anaNegVinSense,
         vin(4) => 0.0,
         vin(5) => a18vSenseP,
         vin(6) => a18vSenseN,
         vin(7) => a18vdSenseP,
         vin(8) => a18vdSenseN);

   -------------------------------------------------------------------------------------------------
   -- QSFP / SFP I2C
   -------------------------------------------------------------------------------------------------
   sfpI2cSda  <= 'H';
   sfpI2cScl  <= 'H';
   qsfpI2cSda <= 'H';
   qsfpI2cScl <= 'H';

end architecture sim;



