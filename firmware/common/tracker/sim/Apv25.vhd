-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- File       : Apv25.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2013-03-12
-- Last update: 2019-11-20
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.I2cPkg.all;

entity Apv25 is
   generic (
      TPD_G  : time            := 1 ns;
      ADDR_G : slv(4 downto 0) := "00000");
   port (
      clk       : in    sl;
      trig      : in    sl;
      rstL      : in    sl;
      analogOut : out   real;
      sda       : inout sl;
      scl       : inout sl);

end entity Apv25;

architecture behavioral of Apv25 is

   constant ADDR_C : slv(4 downto 0) := not ADDR_G;

   function mapApvChannels return RealArray is
      variable ret : RealArray(0 to 127);
   begin
      for i in 0 to 127 loop
         ret(i) := (real(32 * (i mod 4) + 8 * (i / 4) - 31 * (i /16)) * (0.8/127.0)) - 0.4;
      end loop;
      return ret;
   end function mapApvChannels;

   constant APV_CHANNEL_MAP_C : RealArray(0 to 127) := mapApvChannels;

   constant TRIGGER_MODE_INDEX_C : integer := 1;
   constant THREE_SAMPLE_C       : sl      := '0';
   constant ONE_SAMPLE_C         : sl      := '1';
   constant HEADER_LOW_C         : real    := -0.4 + real(0.0001*real(conv_integer(ADDR_G(2 downto 0))));
   constant HEADER_HIGH_C        : real    := 0.4 - real(0.0001*real(conv_integer(ADDR_G(2 downto 0))));

   signal rst : sl;

   type TriggerStateType is (WATCH_TRIGGER_S, RESET_PERIOD_S, POINTER_INIT_S, INJECT_S);
   type ReadoutStateType is (IDLE_S, HEADER_S, ADDRESS_S, ERROR_BIT_S, DATA_S, SYNC_PULSE_S);

   type I2cRegType is record
      ipre    : slv(7 downto 0);
      ipcasc  : slv(7 downto 0);
      ipsf    : slv(7 downto 0);
      isha    : slv(7 downto 0);
      issf    : slv(7 downto 0);
      ipsp    : slv(7 downto 0);
      imuxin  : slv(7 downto 0);
      ispare  : slv(7 downto 0);
      ical    : slv(7 downto 0);
      vfp     : slv(7 downto 0);
      vfs     : slv(7 downto 0);
      vpsp    : slv(7 downto 0);
      cdrv    : slv(7 downto 0);
      csel    : slv(7 downto 0);
      mode    : slv(7 downto 0);
      latency : slv(7 downto 0);
      muxgain : slv(7 downto 0);
   end record I2cRegType;

   constant I2C_REG_INIT_C : I2cRegType := (
      ipre    => X"62",
      ipcasc  => X"34",
      ipsf    => X"22",
      isha    => X"22",
      issf    => X"22",
      ipsp    => X"37",
      imuxin  => X"22",
      ispare  => X"00",
      ical    => X"1d",
      vfp     => X"1e",
      vfs     => X"3C",
      vpsp    => X"1E",
      cdrv    => X"FE",
      csel    => X"FE",
      mode    => X"3d",
      latency => X"84",
      muxgain => X"04");

   type RegType is record
      i2c            : I2cRegType;
      i2cRdData      : slv(7 downto 0);
      triggerState   : TriggerStateType;
      triggerChain   : slv(2 downto 0);
      outFifoWrEn    : slv(2 downto 0);
      outFifoWrChain : Slv9Array(100 downto 0);
      outFifoRdEn    : sl;
      count          : slv(3 downto 0);
      wrPtr          : slv(7 downto 0);
      rdPtr          : slv(7 downto 0);
      fifoError      : sl;
      readoutState   : ReadoutStateType;
      analogOut      : real;
      readoutCounter : slv(7 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      i2c            => I2C_REG_INIT_C,
      i2cRdData      => (others => '0'),
      triggerState   => WATCH_TRIGGER_S,
      triggerChain   => (others => '0'),
      outFifoWrEn    => (others => '0'),
      outFifoWrChain => (others => (others => '0')),
      outFifoRdEn    => '0',
      count          => (others => '0'),
      wrPtr          => (others => '0'),
      rdPtr          => (others => '0'),
      fifoError      => '0',
      readoutState   => IDLE_S,
      analogOut      => 0.0,
      readoutCounter => (others => '0'));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;


   -- I2C RegSlave IO
   signal i2ci      : i2c_in_type;
   signal i2co      : i2c_out_type;
   signal i2cAddr   : slv(7 downto 0);
   signal i2cWrEn   : sl;
   signal i2cWrData : slv(7 downto 0);
   signal i2cRdEn   : sl;
   signal i2cRdData : slv(7 downto 0);

   -- FIFO IO
   signal outFifoValid    : sl;
   signal outFifoDout     : slv(7 downto 0);
   signal outFifoOverflow : sl;

begin

   rst <= not rstL;

   i2ci.scl <= to_x01z(scl);
   i2ci.sda <= to_x01z(sda);
   sda      <= i2co.sda when i2co.sdaoen = '0' else 'Z';
   scl      <= i2co.scl when i2co.scloen = '0' else 'Z';

   -------------------------------------------------------------------------------------------------
   -- I2C Slave Interface
   -------------------------------------------------------------------------------------------------
   I2cRegSlave_1 : entity surf.I2cRegSlave
      generic map (
         TPD_G                => TPD_G,
         TENBIT_G             => 0,
         I2C_ADDR_G           => conv_integer("01" & ADDR_C),
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => 2,
         ADDR_SIZE_G          => 1,
         DATA_SIZE_G          => 1,
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

   -------------------------------------------------------------------------------------------------
   -- Output Fifo
   -- Simulates the 31 slot APV25 output buffer
   -- Stores only buffer addresses since analog data is fixed
   -------------------------------------------------------------------------------------------------
   Fifo_1 : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         RST_POLARITY_G  => '1',
         RST_ASYNC_G     => true,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "distributed",
         FWFT_EN_G       => true,
         DATA_WIDTH_G    => 8,
         ADDR_WIDTH_G    => 5)
      port map (
         rst      => rst,
         wr_clk   => clk,
         wr_en    => r.outFifoWrChain(100)(8),
         din      => r.outFifoWrChain(100)(7 downto 0),
         overflow => outFifoOverflow,
         rd_clk   => clk,
         rd_en    => r.outFifoRdEn,
         dout     => outFifoDout,
         valid    => outFifoValid);

   comb : process (i2cAddr, i2cWrData, i2cWrEn, outFifoDout, outFifoOverflow, outFifoValid, r, trig) is
      variable v                 : RegType;
      variable readoutCounterInt : integer;
   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- I2C Register Decoding
      ----------------------------------------------------------------------------------------------
      v.i2cRdData := (others => '0');
      case i2cAddr(7 downto 1) is
         when "0010000" =>
            v.i2cRdData := r.i2c.ipre;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.ipre := i2cWrData;
            end if;
         when "0010001" =>
            v.i2cRdData := r.i2c.ipcasc;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.ipcasc := i2cWrData;
            end if;
         when "0010010" =>
            v.i2cRdData := r.i2c.ipsf;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.ipsf := i2cWrData;
            end if;
         when "0010011" =>
            v.i2cRdData := r.i2c.isha;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.isha := i2cWrData;
            end if;
         when "0010100" =>
            v.i2cRdData := r.i2c.issf;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.issf := i2cWrData;
            end if;

         when "0010101" =>
            v.i2cRdData := r.i2c.ipsp;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.ipsp := i2cWrData;
            end if;
         when "0010110" =>
            v.i2cRdData := r.i2c.imuxin;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.imuxin := i2cWrData;
            end if;
         when "0010111" =>
            v.i2cRdData := r.i2c.ispare;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.ispare := i2cWrData;
            end if;
         when "0011000" =>
            v.i2cRdData := r.i2c.ical;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.ical := i2cWrData;
            end if;
         when "0011001" =>
            v.i2cRdData := r.i2c.vfp;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.vfp := i2cWrData;
            end if;
         when "0011010" =>
            v.i2cRdData := r.i2c.vfs;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.vfs := i2cWrData;
            end if;
         when "0011011" =>
            v.i2cRdData := r.i2c.vpsp;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.vpsp := i2cWrData;
            end if;
         when "0011100" =>
            v.i2cRdData := r.i2c.cdrv;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.cdrv := i2cWrData;
            end if;
         when "0011101" =>
            v.i2cRdData := r.i2c.csel;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.csel := i2cWrData;
            end if;
         when "0000001" =>
            v.i2cRdData := r.i2c.mode;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.mode := i2cWrData;
            end if;
         when "0000010" =>
            v.i2cRdData := r.i2c.latency;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.latency := i2cWrData;
            end if;
         when "0000011" =>
            v.i2cRdData := r.i2c.muxgain;
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2c.muxgain := i2cWrData;
            end if;
         when "0000000" =>
            if (i2cWrEn = '1' and i2cAddr(0) = '0') then
               v.i2cRdData(0) := '0';   -- no latency errors for now
               v.i2cRdData(1) := r.fifoError;
            end if;
         when others =>
            null;
      end case;

      i2cRdData <= r.i2cRdData;

      -- Latch in any fifo errors
      if (outFifoOverflow = '1') then
         v.fifoError := '1';
      end if;

      ----------------------------------------------------------------------------------------------
      -- Pointer and Fifo Write Logic
      ----------------------------------------------------------------------------------------------
      v.triggerChain := r.triggerChain(1 downto 0) & trig;

      v.outFifoWrEn := r.outFifoWrEn(1 downto 0) & '0';

      -- Write and read pointers roll over at 192
      v.wrPtr := r.wrPtr + 1;
      if (r.wrPtr = 191) then
         v.wrPtr := (others => '0');
      end if;
      v.rdPtr := r.rdPtr + 1;
      if (r.rdPtr = 191) then
         v.rdPtr := (others => '0');
      end if;


      case (r.triggerState) is
         when WATCH_TRIGGER_S =>
            v.count := (others => '0');
            case (r.triggerChain) is
               when "100" =>                  -- Normal Trigger
                  if (r.i2c.mode(TRIGGER_MODE_INDEX_C) = THREE_SAMPLE_C) then
                     v.outFifoWrEn := "111";  -- Queue 3 writes
                  else
                     v.outFifoWrEn := "100";  -- Queue 1 write
                  end if;

               when "101" =>            -- Soft Reset
                  v.triggerState := RESET_PERIOD_S;

               when "110" =>
                  v.triggerState := INJECT_S;
               when others => null;
            end case;

         when RESET_PERIOD_S =>
            -- Reset takes 11 cycles
            v.fifoError := '0';
            v.wrPtr     := (others => '0');
            v.rdPtr     := (others => '0');
            v.count     := r.count + 1;
            if (r.count = 10) then
               v.count        := (others => '0');
               v.triggerState := POINTER_INIT_S;
            end if;

         when POINTER_INIT_S =>
            -- Wait for distance between read and write pointers to reach programmed
            -- latency value
            v.rdPtr := (others => '0');
            if (r.wrPtr = r.i2c.latency-1) then
               v.triggerState := WATCH_TRIGGER_S;
            end if;

         when INJECT_S =>
            -- Wait state to avoid normal trigger
            v.triggerState := WATCH_TRIGGER_S;
      end case;

      ----------------------------------------------------------------------------------------------
      -- Emulate 100 cycle latency between triggers and output
      ----------------------------------------------------------------------------------------------
      v.outFifoWrChain(100 downto 1)  := r.outFifoWrChain(99 downto 0);
      v.outFifoWrChain(0)(8)          := r.outFifoWrEn(2);
      v.outFifoWrChain(0)(7 downto 0) := r.rdPtr;

      ----------------------------------------------------------------------------------------------
      -- Output Logic
      ----------------------------------------------------------------------------------------------
      v.outFifoRdEn     := '0';
      readoutCounterInt := conv_integer(r.readoutCounter);
      case (r.readoutState) is
         when IDLE_S =>
            -- Output Sync Pulse every 35 cycles
            v.analogOut      := HEADER_LOW_C;
            v.readoutCounter := r.readoutCounter + 1;
            if (r.readoutCounter = 33 and outFifoValid = '1') then
               v.readoutCounter := (others => '0');
               v.readoutState   := HEADER_S;
            end if;
            if (r.readoutCounter = 34) then
               v.readoutCounter := (others => '0');
               v.analogOut      := HEADER_HIGH_C;
            end if;

         when HEADER_S =>
            v.readoutCounter := r.readoutCounter + 1;
            v.analogOut      := HEADER_HIGH_C;
            if (r.readoutCounter = 2) then
               v.readoutCounter := (others => '0');
               v.readoutState   := ADDRESS_S;
            end if;

         when ADDRESS_S =>
            v.readoutCounter := r.readoutCounter + 1;
            v.analogOut      := ite(outFifoDout(7-readoutCounterInt) = '1', HEADER_HIGH_C, HEADER_LOW_C);
            if (r.readoutCounter = 7) then
               v.readoutCounter := (others => '0');
               v.readoutState   := ERROR_BIT_S;
            end if;

         when ERROR_BIT_S =>
            v.readoutCounter := (others => '0');
            v.analogOut      := ite(r.fifoError = '1', HEADER_LOW_C, HEADER_HIGH_C);
            v.readoutState   := DATA_S;

         when DATA_S =>
            v.readoutCounter  := r.readoutCounter + 1;
            readoutCounterInt := conv_integer(r.readoutCounter);
            v.analogOut       := APV_CHANNEL_MAP_C(readoutCounterInt);

            if (r.readoutCounter = 120) then
               v.outFifoRdEn := '1';
            end if;
            if (r.readoutCounter = 127) then
               if (outFifoValid = '0') then
                  v.readoutCounter := X"22";
                  v.readoutState   := IDLE_S;
               else
                  v.readoutCounter := (others => '0');
                  v.readoutState   := HEADER_S;
               end if;
            end if;

         when SYNC_PULSE_S =>
            v.readoutCounter := X"22";  --34
            v.analogOut      := HEADER_HIGH_C;
            v.readoutState   := IDLE_S;

      end case;

      rin <= v;

      analogOut <= r.analogOut;

   end process;

   seq : process (clk, rstL) is
   begin
      if (rstL = '0') then
         r <= REG_INIT_C after TPD_G;
      elsif (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;



end architecture behavioral;
