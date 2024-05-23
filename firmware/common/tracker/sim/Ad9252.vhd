-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Ad9252.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
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
use surf.TextUtilPkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

library ldmx; 


entity Ad9252 is
   
   generic (
      TPD_G        : time := 1 ns;
      CLK_PERIOD_G : time := 24 ns);

   port (
      clkP : in sl;
      clkN : in sl;

      vin : in RealArray(7 downto 0);

      dP   : out slv(7 downto 0);
      dN   : out slv(7 downto 0);
      dcoP : out sl;
      dcoN : out sl;
      fcoP : out sl;
      fcoN : out sl;

      sclk : in    sl;
      sdio : inout sl;
      csb  : in    sl);

end entity Ad9252;

architecture behavioral of Ad9252 is

   -------------------------------------------------------------------------------------------------
   -- Config and Sampling constant and signals
   -------------------------------------------------------------------------------------------------
   constant PN_SHORT_TAPS_C : NaturalArray     := (0 => 4, 1 => 8);    -- X9+X5+1
   constant PN_SHORT_INIT_C : slv(8 downto 0)  := "011011111";
   constant PN_LONG_TAPS_C  : NaturalArray     := (0 => 16, 1 => 22);  -- X23+X18+1
   constant PN_LONG_INIT_C  : slv(22 downto 0) := "01001101110000000101000";

   -- ConfigSlave signals
   signal wrEn      : sl;
   signal addr      : slv(12 downto 0);
   signal wrData    : slv(31 downto 0);
   signal byteValid : slv(3 downto 0);

   type GlobalConfigType is record
      mode          : slv(2 downto 0);
      stabilizer    : sl;
      outputLvds    : sl;
      outputInvert  : sl;
      binFormat     : slv(1 downto 0);
      termination   : slv(1 downto 0);
      driveStrength : sl;
      lsbFirst      : sl;
      lowRate       : sl;
      bits          : slv(2 downto 0);
   end record GlobalConfigType;

   constant GLOBAL_CONFIG_INIT_C : GlobalConfigType := (
      mode          => "000",
      stabilizer    => '1',
      outputLvds    => '0',
      outputInvert  => '0',
      binFormat     => "00",
      termination   => "00",
      driveStrength => '0',
      lsbFirst      => '0',
      lowRate       => '0',
      bits          => "000");

   type ChannelConfigType is record
      pn23            : slv(22 downto 0);
      resetPnLongGen  : sl;
      pn9             : slv(8 downto 0);
      resetPnShortGen : sl;
      userTestMode    : slv(1 downto 0);
      outputTestMode  : slv(3 downto 0);
      outputPhase     : slv(3 downto 0);
      userPattern1    : slv(15 downto 0);
      userPattern2    : slv(15 downto 0);
      outputReset     : sl;
      powerDown       : sl;
   end record ChannelConfigType;

   constant CHANNEL_CONFIG_INIT_C : ChannelConfigType := (
      pn23            => PN_LONG_INIT_C,
      resetPnLongGen  => '0',
      pn9             => PN_SHORT_INIT_C,
      resetPnShortGen => '0',
      userTestMode    => "00",
      outputTestMode  => "0000",
      outputPhase     => "0011",
      userPattern1    => X"0000",
      userPattern2    => X"0000",
      outputReset     => '0',
      powerDown       => '0');

   type ChannelConfigArray is array (natural range <>) of ChannelConfigType;

   type ConfigRegType is record
      sample          : Slv14Array(7 downto 0);  -- slv(13 downto 0);
      rdData          : slv(31 downto 0);
      lsbFirst        : sl;
      softReset       : sl;
      channelConfigEn : slv(9 downto 0);
      tmpGlobal       : GlobalConfigType;
      tmpChannel      : ChannelConfigType;
      global          : GlobalConfigType;
      channel         : ChannelConfigArray(9 downto 0);
      word            : sl;
   end record ConfigRegType;

   constant CONFIG_REG_INIT_C : ConfigRegType := (
      sample          => (others => "00000000000000"),
      rdData          => X"00000000",
      lsbFirst        => '0',
      softReset       => '0',
      channelConfigEn => (others => '1'),
      tmpGlobal       => GLOBAL_CONFIG_INIT_C,
      tmpChannel      => CHANNEL_CONFIG_INIT_C,
      global          => GLOBAL_CONFIG_INIT_C,
      channel         => (others => CHANNEL_CONFIG_INIT_C),
      word            => '0');

   signal r   : ConfigRegType := CONFIG_REG_INIT_C;
   signal rin : ConfigRegType;

   -------------------------------------------------------------------------------------------------
   -- Output constants and signals
   -------------------------------------------------------------------------------------------------
--   constant DCLK_PERIOD_C : time := CLK_PERIOD_G / 7.0;

   signal pllRst   : sl;
   signal clk      : sl;
   signal locked   : sl;
   signal rst      : sl;
   signal clkFbOut : sl;
   signal clkFbIn  : sl;
   signal dClkInt  : sl;
   signal dClk     : sl;
   signal fClkInt  : sl;
   signal fClk     : sl;
   signal dcoInt   : sl;
   signal dco      : sl;
   signal fcoInt : sl;
   signal fco : sl;
   signal serData  : slv(7 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Create local clocks
   -------------------------------------------------------------------------------------------------
--   ClkRst_1 : entity surf.ClkRst
--      generic map (
--         RST_HOLD_TIME_G => 50 us)
--      port map (
--         rst => pllRst);

   process is
   begin
      pllRst <= '1';
      wait for  15 us;
      pllRst <= '0';
      wait until locked = '0';
   end process;


   CLK_BUFG : IBUFGDS
      port map (
         I  => clkP,
         IB => clkN,
         O  => clk);

   plle2_adv_inst : PLLE2_ADV
      generic map (
         BANDWIDTH          => "HIGH",
         COMPENSATION       => "ZHOLD",
         DIVCLK_DIVIDE      => 1,
         CLKFBOUT_MULT      => 49,
         CLKFBOUT_PHASE     => 0.000,
         CLKOUT0_DIVIDE     => 49,
         CLKOUT0_PHASE      => 0.000,
         CLKOUT0_DUTY_CYCLE => 0.500,
         CLKOUT1_DIVIDE     => 7,
         CLKOUT1_PHASE      => 0.000,
         CLKOUT1_DUTY_CYCLE => 0.500,
         CLKOUT2_DIVIDE     => 7,
         CLKOUT2_PHASE      => 90.000,
         CLKOUT2_DUTY_CYCLE => 0.500,
         CLKOUT3_DIVIDE     => 49,
         CLKOUT3_PHASE      => 257.143,
         CLKOUT3_DUTY_CYCLE => 0.500,
         CLKIN1_PERIOD      => 24.0,
         REF_JITTER1        => 0.010)
      port map (
         -- Output clocks
         CLKFBOUT => clkFbOut,
         CLKOUT0  => fClkInt,
         CLKOUT1  => dClkInt,
         CLKOUT2  => dcoInt,            -- Shifted serial clock for output
         CLKOUT3  => fcoInt,
         CLKOUT4  => open,
         CLKOUT5  => open,
         -- Input clock control
         CLKFBIN  => clkFbIn,
         CLKIN1   => clk,
         CLKIN2   => '0',
         -- Tied to always select the primary input clock
         CLKINSEL => '1',
         -- Ports for dynamic reconfiguration
         DADDR    => (others => '0'),
         DCLK     => '0',
         DEN      => '0',
         DI       => (others => '0'),
         DO       => open,
         DRDY     => open,
         DWE      => '0',
         -- Other control and status signals
         LOCKED   => locked,
         PWRDWN   => '0',
         RST      => pllRst);

   FB_BUFG : BUFG
      port map (
         I => clkFbOut,
         O => clkFbIn);

   FCLK_BUFG : BUFG
      port map (
         I => fClkInt,
         O => fClk);

   DCLK_BUFG : BUFG
      port map (
         I => dClkInt,
         O => dClk);

   DCO_BUFG : BUFG
      port map (
         I => dcoInt,
         O => dco);

   FCO_BUFG : BUFG
      port map (
         I => fcoInt,
         O => fco);

   RstSync_1 : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '0',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 10)
      port map (
         clk      => fClk,
         asyncRst => locked,
         syncRst  => rst);

   -------------------------------------------------------------------------------------------------
   -- Instantiate configuration interface
   -------------------------------------------------------------------------------------------------
   AdiConfigSlave_1 : entity surf.AdiConfigSlave
      generic map (
         TPD_G => TPD_G)
      port map (
         clk       => fClk,
         sclk      => sclk,
         sdio      => sdio,
         csb       => csb,
         wrEn      => wrEn,
         rdEn      => open,
         addr      => addr,
         wrData    => wrData,
         byteValid => byteValid,
         rdData    => r.rdData);

   -------------------------------------------------------------------------------------------------
   -- Configuration register logic
   -------------------------------------------------------------------------------------------------
   comb : process (addr, r, vin, wrData, wrEn) is
      variable v             : ConfigRegType;
      variable activeChannel : ChannelConfigType;
      variable zero          : slv(13 downto 0) := (others => '0');
   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- Configuration Registers
      ----------------------------------------------------------------------------------------------
      activeChannel := r.channel(0);
      for i in 9 downto 0 loop
         if (r.channelConfigEn(i) = '1') then
            activeChannel := r.channel(i);
         end if;
      end loop;


      v.rdData := (others => '0');
      case (addr(7 downto 0)) is
         
         when X"00" =>                  -- chip_port_config
            v.rdData(6) := r.lsbFirst;
            v.rdData(5) := r.softReset;
            v.rdData(4) := '1';
            v.rdData(3) := '1';
            v.rdData(2) := r.softReset;
            v.rdData(1) := r.lsbFirst;
            if (wrEn = '1') then
               v.lsbFirst  := wrData(6) or wrData(1);
               v.softReset := wrData(5) or wrData(2);
            end if;

         when X"01" =>                  -- chip_id
            v.rdData(7 downto 0) := X"09";

         when X"02" =>                  -- chip_grade
            v.rdData(6 downto 4) := "011";

         -------------------------------------------------------------------------------------------
         when X"04" =>                  -- device_index_2
            v.rdData(3 downto 0) := r.channelConfigEn(7 downto 4);
            if (wrEn = '1') then
               v.channelConfigEn(7 downto 4) := wrData(3 downto 0);
            end if;
            
         when X"05" =>                  -- device_index_1
            v.rdData(3 downto 0) := r.channelConfigEn(3 downto 0);
            v.rdData(4)          := r.channelConfigEn(8);
            v.rdData(5)          := r.channelConfigEn(9);
            if (wrEn = '1') then
               v.channelConfigEn(3 downto 0) := wrData(3 downto 0);
               v.channelConfigEn(8)          := wrData(4);
               v.channelConfigEn(9)          := wrData(5);
            end if;

         when X"FF" =>                  -- device update
            if (wrEn = '1') then
               v.global := r.tmpGlobal;
               for i in 9 downto 0 loop
                  if (r.channelConfigEn(i) = '1') then
                     v.channel(i) := r.tmpChannel;
                     if (r.tmpChannel.resetPnLongGen = '1') then
                        v.channel(i).pn23 := PN_LONG_INIT_C;
                     end if;
                     if (r.tmpChannel.resetPnShortGen = '1') then
                        v.channel(i).pn9 := PN_SHORT_INIT_C;
                     end if;
                  end if;
               end loop;
            end if;

         -------------------------------------------------------------------------------------------
         when X"08" =>                  -- modes
            v.rdData(2 downto 0) := r.global.mode;
            if (wrEn = '1') then
               v.tmpGlobal.mode := wrData(2 downto 0);
            end if;

         when X"09" =>                  -- clock
            v.rdData(0) := r.global.stabilizer;
            if (wrEn = '1') then
               v.tmpGlobal.stabilizer := wrData(0);
            end if;

         when X"0D" =>                  -- test_io
            v.rdData(7 downto 6) := activeChannel.userTestMode;
            v.rdData(5)          := activeChannel.resetPnLongGen;
            v.rdData(4)          := activeChannel.resetPnShortGen;
            v.rdData(3 downto 0) := activeChannel.outputTestMode;
            if (wrEn = '1') then
               v.tmpChannel.userTestMode    := wrData(7 downto 6);
               v.tmpChannel.resetPnLongGen  := wrData(5);
               v.tmpChannel.resetPnShortGen := wrData(4);
               v.tmpChannel.outputTestMode  := wrData(3 downto 0);
            end if;

         when X"14" =>                  -- output_mode
            v.rdData(6)          := r.global.outputLvds;
            v.rdData(2)          := r.global.outputInvert;
            v.rdData(1 downto 0) := r.global.binFormat;
            if (wrEn = '1') then
               v.tmpGlobal.outputLvds   := wrData(6);
               v.tmpGlobal.outputInvert := wrData(2);
               v.tmpGlobal.binFormat    := wrData(1 downto 0);
            end if;

         when X"15" =>                  -- output_adjust
            -- Not sure if this is global
            v.rdData(5 downto 4) := r.global.termination;
            v.rdData(0)          := r.global.driveStrength;
            if (wrEn = '1') then
               v.tmpGlobal.termination   := wrData(5 downto 4);
               v.tmpGlobal.driveStrength := wrData(0);
            end if;

         when X"16" =>                  -- output_phase
            v.rdData(3 downto 0) := activeChannel.outputPhase;
            if (wrEn = '1') then
               v.tmpChannel.outputPhase := wrData(3 downto 0);
            end if;

         when X"19" =>                  -- user_patt1_lsb
            v.rdData(7 downto 0) := activeChannel.userPattern1(7 downto 0);
            if (wrEn = '1') then
               v.tmpChannel.userPattern1(7 downto 0) := wrData(7 downto 0);
            end if;

         when X"1A" =>                  -- user_patt1_msb
            v.rdData(7 downto 0) := activeChannel.userPattern1(15 downto 8);
            if (wrEn = '1') then
               v.tmpChannel.userPattern1(15 downto 8) := wrData(7 downto 0);
            end if;
            
         when X"1B" =>                  -- user_patt2_lsb
            v.rdData(7 downto 0) := activeChannel.userPattern2(7 downto 0);
            if (wrEn = '1') then
               v.tmpChannel.userPattern2(7 downto 0) := wrData(7 downto 0);
            end if;

         when X"1C" =>                  -- user_patt2_msb
            v.rdData(7 downto 0) := activeChannel.userPattern2(15 downto 8);
            if (wrEn = '1') then
               v.tmpChannel.userPattern2(15 downto 8) := wrData(7 downto 0);
            end if;

         when X"21" =>                  -- serial_control
            v.rdData(7)          := r.global.lsbFirst;
            v.rdData(3)          := r.global.lowRate;
            v.rdData(2 downto 0) := r.global.bits;
            if (wrEn = '1') then
               v.tmpGlobal.lsbFirst := wrData(7);
               v.tmpGlobal.lowRate  := wrData(3);
               v.tmpGlobal.bits     := wrData(2 downto 0);
            end if;

         when X"22" =>                  -- serial_ch_stat
            v.rdData(1) := activeChannel.outputReset;
            v.rdData(0) := activeChannel.powerDown;
            if (wrEn = '1') then
               v.tmpChannel.outputReset := wrData(1);
               v.tmpChannel.powerDown   := wrData(0);
            end if;
            
         when others =>
            v.rdData := (others => '1');

      end case;

      ----------------------------------------------------------------------------------------------
      -- ADC Sampling
      ----------------------------------------------------------------------------------------------
      v.word := not r.word;
      for i in 7 downto 0 loop
         if (r.channel(i).powerDown = '0') then
            case (r.channel(i).outputTestMode) is
               when "0000" =>           -- normal
                  v.sample(i) := adcConversion(vin(i), 0.0, 2.0, 14, false);
               when "0001" =>           -- midscale short
                  v.sample(i) := "10000000000000";
               when "0010" =>           -- +FS short
                  v.sample(i) := "11111111111111";
               when "0011" =>           -- -FS short
                  v.sample(i) := "00000000000000";
               when "0100" =>           -- checkerboard
                  v.sample(i) := ite(r.word = '0', "10101010101010", "01010101010101");
               when "0101" =>           -- pn23 (not implemented)
                  v.sample(i) := (others => '0');  --(scrambler(zero, r.pn23, PN_LONG_TAPS_C, v.pn23, v.sample(i));
               when "0110" =>           -- pn9 (not implemented)
                  v.sample(i) := (others => '0');  --scrambler(zero, r.pn9, PN_SHORT_TAPS_C, v.pn9, v.sample(i));
               when "0111" =>           -- one/zero toggle
                  v.sample(i) := ite(r.word = '0', "11111111111111", "00000000000000");
               when "1000" =>           -- user input
                  v.sample(i) := ite(r.word = '0', r.channel(i).userPattern1(13 downto 0), r.channel(i).userPattern2(13 downto 0));
               when "1001" =>           -- 1/0 bit toggle
                  v.sample(i) := "10101010101010";
               when "1010" =>           -- 1x sync
                  v.sample(i) := "00000001111111";
               when "1011" =>           -- one bit high
                  v.sample(i) := "10000000000000";
               when "1100" =>           -- mixed bit frequency
                  v.sample(i) := "10100001100111";
               when others =>
                  v.sample(i) := (others => '0');
            end case;

         else
            v.sample(i) := (others => '0');
         end if;
      end loop;

      rin <= v;
      
   end process comb;

   seq : process (fClk) is
   begin
      if (rising_edge(fClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -------------------------------------------------------------------------------------------------
   -- Output
   -------------------------------------------------------------------------------------------------
   DATA_SERIALIZER_GEN : for i in 7 downto 0 generate
      Ad9252Serializer_1 : entity ldmx.Ad9252Serializer
         port map (
            clk    => dClk,
            clkDiv => fClk,
            rst    => rst,
            iData  => r.sample(i),
            oData  => serData(i));

      DATA_OUT_BUFF : OBUFDS
         port map (
            I  => serData(i),
            O  => dP(i),
            OB => dN(i));
   end generate DATA_SERIALIZER_GEN;


   FCLK_OUT_BUFF : entity surf.ClkOutBufDiff
      port map (
         clkIn   => fco,
         clkOutP => fcoP,
         clkOutN => fcoN);

   DCLK_OUT_BUFF : entity surf.ClkOutBufDiff
      port map (
         clkIn   => dco,
         clkOutP => dcoP,
         clkOutN => dcoN);


end architecture behavioral;
