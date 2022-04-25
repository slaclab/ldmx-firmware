-------------------------------------------------------------------------------
-- Title         : Threshold.vhd
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : Threshold.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 02/01/2012
-------------------------------------------------------------------------------
-- Description:
-- Threshold logic
-------------------------------------------------------------------------------
-- Copyright (c) 2012 by SLAC. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 02/01/2012: created.
-------------------------------------------------------------------------------
--Here are the sample cuts I use in the simulation:
--Require 3 of the 6 samples to be above threshold (I'm using 4*rms noise)
--Require sample 3 > sample 2 || sample 4 > sample 3
--Omar Moreno

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library hps_daq;
use hps_daq.DataPathPkg.all;
use hps_daq.FebConfigPkg.all;

entity Threshold is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Master system clock, 125Mhz
      sysClk         : in sl;
      sysRst         : in sl;
      sysPipelineRst : in sl;

      -- Thresholds programmed through AXI bus
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- Enables for each threshold cut
      febConfig : FebConfigType;

      -- Input
      dataIn : in MultiSampleType;

      -- Output
      dataOut : out MultiSampleType
      );

end Threshold;

-- Define architecture
architecture Threshold of Threshold is

   type PipelineStageType is record
      sample     : MultiSampleType;
      threshold1 : slv(15 downto 0);
      threshold2 : slv(15 downto 0);
   end record;

   constant PIPELINE_STAGE_INIT_C : PipelineStageType := (
      sample     => MULTI_SAMPLE_ZERO_C,
      threshold1 => (others => '0'),
      threshold2 => (others => '0'));

   type RegType is record
      input      : PipelineStageType;
      mem        : PipelineStageType;
      threshold1 : PipelineStageType;
      threshold2 : PipelineStageType;
      slope      : PipelineStageType;
      cal        : PipelineStageType;
      error      : PipelineStageType;
      output     : PipelineStageType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      input      => PIPELINE_STAGE_INIT_C,
      mem        => PIPELINE_STAGE_INIT_C,
      threshold1 => PIPELINE_STAGE_INIT_C,
      threshold2 => PIPELINE_STAGE_INIT_C,
      slope      => PIPELINE_STAGE_INIT_C,
      cal        => PIPELINE_STAGE_INIT_C,
      error      => PIPELINE_STAGE_INIT_C,
      output     => PIPELINE_STAGE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal thresholdMemData : slv(31 downto 0);

begin

   -------------------------------------------------------------------------------------------------
   -- Threshold memory
   -------------------------------------------------------------------------------------------------
   AxiDualPortRam_1 : entity surf.AxiDualPortRam
      generic map (
         TPD_G          => TPD_G,
         MEMORY_TYPE_G  => "distributed",
         READ_LATENCY_G => 0,
         COMMON_CLK_G   => true,
         ADDR_WIDTH_G   => 7,
         DATA_WIDTH_G   => 32)
      port map (
         axiClk         => sysClk,
         axiRst         => sysRst,
         axiReadMaster  => axiReadMaster,
         axiReadSlave   => axiReadSlave,
         axiWriteMaster => axiWriteMaster,
         axiWriteSlave  => axiWriteSlave,
         clk            => sysClk,      -- not used internally
         en             => '1',
         rst            => sysRst,      -- not used internally
         addr           => r.input.sample.apvChannel,
         dout           => thresholdMemData);


   -------------------------------------------------------------------------------------------------
   -- Threshold pipeline
   -------------------------------------------------------------------------------------------------
   comb : process (dataIn, r, febConfig, sysPipelineRst, sysRst, thresholdMemData) is
      variable v                  : RegType;
      variable threshold1Exceeded : slv(5 downto 0);
      variable threshold2Exceeded : slv(5 downto 0);
   begin
      v := r;

      ----------------------------------------------------------------------------------------------
      -- Input Stage - Register the inputs. Probably unnecessary but might help timing
      ----------------------------------------------------------------------------------------------
      -- sample.data elements transition a lot between valids, so do this to make simulation cleaner
      if (dataIn.valid = '1') then
         v.input.sample := dataIn;
      end if;
      v.input.sample.valid := dataIn.valid;

      ----------------------------------------------------------------------------------------------
      -- Mem stage - Read threshold data from ram and register it
      ----------------------------------------------------------------------------------------------
      v.mem.sample     := r.input.sample;
      v.mem.threshold1 := thresholdMemData(15 downto 0);
      v.mem.threshold2 := thresholdMemData(31 downto 16);

      ----------------------------------------------------------------------------------------------
      -- First Threshold Stage - Look for N consecutive samples exceeding the threshold
      ----------------------------------------------------------------------------------------------
      v.threshold1       := r.mem;      -- Pass everything unchanged by default
      threshold1Exceeded := (others => '0');
      if (febConfig.threshold1CutEn = '1' and r.mem.sample.valid = '1' and r.mem.sample.head = '0' and r.mem.sample.tail = '0') then
         v.threshold1.sample.valid := '0';
         for i in 5 downto 0 loop
            if (r.mem.sample.data(i) > r.mem.threshold1) then
               threshold1Exceeded(i) := '1';
            end if;
         end loop;
         case (febConfig.threshold1CutNum) is
            when "001" =>
               -- Only 1 sample exceeding threshold req'd
               v.threshold1.sample.valid := uOr(threshold1Exceeded);
            when "010" =>
               -- 2 consecutive samples exceeding threshold req'd
               for i in 5 downto 1 loop
                  if (threshold1Exceeded(i downto i-1) = "11") then
                     v.threshold1.sample.valid := '1';
                  end if;
               end loop;
            when "011" =>
               -- Look for 3 consecutive exceedes
               for i in 5 downto 2 loop
                  if (threshold1Exceeded(i downto i-2) = "111") then
                     v.threshold1.sample.valid := '1';
                  end if;
               end loop;
            when "100" =>
               -- Look for 4 consecutive exceedes
               for i in 5 downto 3 loop
                  if (threshold1Exceeded(i downto i-3) = "1111") then
                     v.threshold1.sample.valid := '1';
                  end if;
               end loop;
            when "101" =>
               -- Look for 5 consecutive exceedes
               v.threshold1.sample.valid := uAnd(threshold1Exceeded(5 downto 1)) or
                                            uAnd(threshold1Exceeded(4 downto 0));
            when "110" =>

            when others => null;
         end case;
         v.threshold1.sample.filter := not v.threshold1.sample.valid;
         if (febConfig.threshold1MarkOnly = '1') then
            v.threshold1.sample.valid := '1';
         end if;

      end if;

      ----------------------------------------------------------------------------------------------
      -- Second Threshold Stage - Look for N consecutive samples exceeding the threshold
      ----------------------------------------------------------------------------------------------
      v.threshold2       := r.threshold1;  -- Pass everything unchanged by default
      threshold2Exceeded := (others => '0');
      if (febConfig.threshold2CutEn = '1' and r.threshold1.sample.valid = '1' and r.threshold1.sample.head = '0' and r.threshold1.sample.tail = '0') then
         v.threshold1.sample.valid := '0';
         for i in 5 downto 0 loop
            if (r.threshold1.sample.data(i) > r.threshold1.threshold1) then
               threshold1Exceeded(i) := '1';
            end if;
         end loop;
         case (febConfig.threshold2CutNum) is
            when "001" =>
               -- Only 1 sample exceeding threshold req'd
               v.threshold2.sample.valid := uOr(threshold2Exceeded);
            when "010" =>
               -- 2 consecutive samples exceeding threshold req'd
               for i in 5 downto 1 loop
                  if (threshold2Exceeded(i downto i-1) = "11") then
                     v.threshold2.sample.valid := '1';
                  end if;
               end loop;
            when "011" =>
               -- Look for 3 consecutive exceedes
               for i in 5 downto 2 loop
                  if (threshold2Exceeded(i downto i-2) = "111") then
                     v.threshold2.sample.valid := '1';
                  end if;
               end loop;
            when "100" =>
               -- Look for 4 consecutive exceedes
               for i in 5 downto 3 loop
                  if (threshold2Exceeded(i downto i-3) = "1111") then
                     v.threshold2.sample.valid := '1';
                  end if;
               end loop;
            when "101" =>
               -- Look for 5 consecutive exceedes
               v.threshold2.sample.valid := uAnd(threshold2Exceeded(5 downto 1)) or
                                            uAnd(threshold2Exceeded(4 downto 0));
            when "110" =>

            when others => null;
         end case;
         v.threshold2.sample.filter := not v.threshold2.sample.valid;
         if (febConfig.threshold2MarkOnly = '1') then
            v.threshold2.sample.valid := '1';
         end if;

      end if;

      ----------------------------------------------------------------------------------------------
      -- Slope Stage - Check for upward slope.  Sample 3 greater than 2 or 4 greater than 3.
      ----------------------------------------------------------------------------------------------
--       v.slope := r.threshold2;
--       if (febConfig.slopeCutEn = '1' and r.threshold.sample.valid = '1' and r.mem.sample.head = '0' and r.threshold.sample.tail = '0') then
--          v.slope.sample.valid := '0';
--          if (r.threshold.sample.data(4) > r.threshold.sample.data(3) or
--              r.threshold.sample.data(3) > r.threshold.sample.data(2)) then
--             v.slope.sample.valid := '1';
--          end if;
--       end if;

      ----------------------------------------------------------------------------------------------
      -- Calgroup stage - Check that channel is from the selected calibration group
      ----------------------------------------------------------------------------------------------
      v.cal := r.threshold2;
      if (febConfig.calEn = '1' and r.slope.sample.valid = '1' and r.slope.sample.head = '0' and r.slope.sample.tail = '0') then
         v.cal.sample.valid := '0';
         if (r.slope.sample.apvChannel(2 downto 0) = febConfig.calGroup) then
            v.cal.sample.valid := '1';
         end if;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Error stage - filter out non-head/tail samples with the readError bit set.
      ----------------------------------------------------------------------------------------------
      v.error := r.cal;
      if (febConfig.errorFilterEn = '1' and r.cal.sample.valid = '1' and r.cal.sample.head = '0' and r.cal.sample.tail = '0') then
         if (r.cal.sample.readError = '1') then
            v.error.sample.valid := '0';
         end if;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Output Stage - Register one more time to ease timing
      ----------------------------------------------------------------------------------------------
      v.output := r.error;

      ----------------------------------------------------------------------------------------------
      -- Synchronous reset
      ----------------------------------------------------------------------------------------------
      if (sysRst = '1' or sysPipelineRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      ----------------------------------------------------------------------------------------------
      -- Assign outputs
      ----------------------------------------------------------------------------------------------
      dataOut <= r.output.sample;

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end Threshold;

