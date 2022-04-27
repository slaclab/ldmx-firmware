-------------------------------------------------------------------------------
-- Title         : APV25 Sync Pulse Detect
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : ApvFrameExtractor.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/08/2011
-------------------------------------------------------------------------------
-- Description:
-- Detects the sync pulse from APV25
-------------------------------------------------------------------------------
-- Copyright (c) 2011 by SLAC. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 12/08/2011: created.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.FebConfigPkg.all;

entity ApvFrameExtractor is
   generic (
      TPD_G        : time                 := 1 ns;
      HYBRID_NUM_G : integer range 0 to 7 := 0;
      APV_NUM_G    : integer range 0 to 6 := 0);
   port (
      -- Master system clock, 125Mhz
      sysClk : in sl;
      sysRst : in sl;

      -- ADC Stream
      adcValid : in sl;
      adcData  : in slv(15 downto 0);

      -- Config
      febConfig : in FebConfigType;

      -- Status outputs
      syncBase      : out slv(15 downto 0);
      syncPeak      : out slv(15 downto 0);
      syncDetected  : out sl;
      frameCount    : out slv(31 downto 0);
      pulseStream   : out slv(63 downto 0);
      minSample     : out slv(15 downto 0);
      maxSample     : out slv(15 downto 0);
      lostSyncCount : out slv(31 downto 0);
      countReset    : in  sl;

      -- Axi-Stream (SSI) extracted frames
      apvFrameAxisMaster : out AxiStreamMasterType);
end ApvFrameExtractor;

architecture ApvFrameExtractor of ApvFrameExtractor is


   type StateType is (FIRST_PULSE_S, N_PULSES_S, SYNCED_IDLE_S, DATA_S);

   type RegType is record
      state         : StateType;
      frameCount    : slv(31 downto 0);
      adcValid      : sl;
      adcData       : slv(15 downto 0);
      pulseStream   : slv(63 downto 0);
      pulseCount    : slv(2 downto 0);
      sampleCount   : slv(7 downto 0);
      lostSyncCount : slv(31 downto 0);
      syncDetected  : sl;
      syncBase      : slv(13 downto 0);
      syncPeak      : slv(13 downto 0);
      maxSample     : slv(13 downto 0);
      minSample     : slv(13 downto 0);
      ssiMaster     : SsiMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state         => FIRST_PULSE_S,
      frameCount    => (others => '0'),
      adcValid      => '0',
      adcData       => (others => '0'),
      pulseStream   => (others => '0'),
      pulseCount    => (others => '0'),
      sampleCount   => (others => '0'),
      lostSyncCount => (others => '0'),
      syncDetected  => '0',
      syncBase      => (others => '0'),
      syncPeak      => (others => '0'),
      maxSample     => (others => '0'),
      minSample     => (others => '1'),
      ssiMaster     => ssiMasterInit(APV_DATA_SSI_CONFIG_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (adcData, adcValid, countReset, febConfig, r, sysRst) is
      variable v : RegType;
   begin
      v := r;

      v.ssiMaster.strb(15 downto 0) := X"0003";
      v.ssiMaster.keep(15 downto 0) := X"0003";
      v.ssiMaster.data              := (others => '0');
      v.ssiMaster.valid             := '0';
      v.ssiMaster.sof               := '0';
      v.ssiMaster.eof               := '0';
      v.ssiMaster.eofe              := '0';

      -- Pipeline stage 1, check for header/sync pulse
      v.adcValid := adcValid;
      v.adcData  := adcData;

      if (countReset = '1') then
         v.maxSample     := (others => '0');
         v.minSample     := (others => '1');
         v.lostSyncCount := (others => '0');
      end if;

      if (adcValid = '1') then
         v.pulseStream := r.pulseStream(62 downto 0) & toSl(adcData(13 downto 0) > febConfig.headerHighThreshold);

         if (adcData(13 downto 0) > r.maxSample) then
            v.maxSample := adcData(13 downto 0);
         end if;

         if (adcData(13 downto 0) < r.minSample) then
            v.minSample := adcData(13 downto 0);
         end if;
      end if;

      if (r.adcValid = '1') then
         v.sampleCount := r.sampleCount + 1;

         -- Log bases and peaks
         if (r.pulseStream(0) = '1') then
            v.syncPeak := r.adcData(13 downto 0);
         else
            v.syncBase := r.adcData(13 downto 0);
         end if;


         case (r.state) is
            when FIRST_PULSE_S =>
               -- Start state. Wait for first pulse to kick everything off
               v.syncDetected   := '0';
               v.pulseCount     := (others => '0');
               v.frameCount     := (others => '0');  -- Reverts to zero when sync lost
               v.sampleCount    := (others => '0');
               v.sampleCount(0) := '1';
               if (r.pulseStream(0) = '1' and febConfig.allowResync = '1') then
                  v.state := N_PULSES_S;
               end if;

            when N_PULSES_S =>
               -- Wait for N properly spaced pulses
               v.syncDetected := '0';
               v.sampleCount  := r.sampleCount + 1;
               if (r.sampleCount = 34) then
                  if (r.pulseStream(34) = '1' and r.pulseStream(33 downto 0) = 0) then
                     -- Good pulse
                     v.pulseCount  := r.pulseCount + 1;
                     v.sampleCount := (others => '0');
                  else
                     v.state := FIRST_PULSE_S;
                  end if;
               end if;

               if (r.pulseCount = 7) then
                  v.state := SYNCED_IDLE_S;
               end if;

            when SYNCED_IDLE_S =>
               -- Keep checking for sync
               v.syncDetected := '1';
               v.sampleCount  := r.sampleCount + 1;
               if (r.sampleCount = 34) then
                  if (r.pulseStream(34) = '1' and r.pulseStream(33 downto 0) = 0) then
                     -- Good pulse
                     v.pulseCount  := r.pulseCount + 1;
                     v.sampleCount := (others => '0');
                  else
                     v.lostSyncCount := r.lostSyncCount + 1;
                     v.state         := FIRST_PULSE_S;
                  end if;
               end if;


               if (r.sampleCount = 11 and r.pulseStream(11 downto 9) = "111") then
                  -- Readout header
                  v.ssiMaster.sof                := '1';
                  -- Need to modify APV number if new hybrid
                  v.ssiMaster.data(15 downto 13) := toSlv(apvIndex(APV_NUM_G, febConfig.hybridType(HYBRID_NUM_G)), 3);
                  v.ssiMaster.data(12 downto 9)  := r.frameCount(3 downto 0);
                  v.ssiMaster.data(8 downto 1)   := r.pulseStream(8 downto 1);  -- Address
                  v.ssiMaster.data(0)            := r.pulseStream(0);           -- Error bit
                  v.ssiMaster.valid              := '1';
                  v.state                        := DATA_S;
                  v.frameCount                   := r.frameCount + 1;
                  v.sampleCount                  := (others => '0');
               end if;

            when DATA_S =>
               v.syncDetected                := '1';
               v.ssiMaster.data(15 downto 0) := r.adcData;
               v.ssiMaster.valid             := '1';
               v.sampleCount                 := r.sampleCount + 1;
               if (r.sampleCount = 127) then
                  v.ssiMaster.eof := '1';
                  v.sampleCount   := (others => '0');
                  v.state         := SYNCED_IDLE_S;
               end if;
            when others => null;
         end case;
      end if;

      -- Don't allow channel to sync if stream is not enabled
      if (febConfig.hyApvDataStreamEn(HYBRID_NUM_G*5+apvIndex(APV_NUM_G, febConfig.hybridType(HYBRID_NUM_G))) = '0') then
         v.state := FIRST_PULSE_S;
      end if;

      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      syncBase      <= "00" & r.syncBase;
      syncPeak      <= "00" & r.syncPeak;
      syncDetected  <= r.syncDetected;
      frameCount    <= r.frameCount;
      pulseStream   <= r.pulseStream;
      maxSample     <= "00" & r.maxSample;
      minSample     <= "00" & r.minSample;
      lostSyncCount <= r.lostSyncCount;

      apvFrameAxisMaster <= ssi2AxisMaster(APV_DATA_SSI_CONFIG_C, r.ssiMaster);

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end ApvFrameExtractor;

