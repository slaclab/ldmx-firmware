-------------------------------------------------------------------------------
-- Title      : WaveformCapture 
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of Warm TDM. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of Warm TDM, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library unisim;
use unisim.vcomponents.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
use surf.AxiLitePkg.all;
use surf.Ad9249Pkg.all;
use surf.Pgp2FcPkg.all;

library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;

entity WaveformCapture is

   generic (
      TPD_G             : time                 := 1 ns;
      HYBRIDS_G         : integer range 1 to 8 := 8;
      APVS_PER_HYBRID_G : integer range 1 to 8 := 6);
   port (
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_DECERR_C;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C;

      -- Adc Streams (axilClk)
      adcStreams : in AdcStreamArray := ADC_STREAM_ARRAY_INIT_C;

      -- Captured Waveform Stream
      axisMaster : out AxiStreamMasterType;
      axisSlave  : in  AxiStreamSlaveType);


end entity WaveformCapture;

architecture rtl of WaveformCapture is

   constant RESIZE_SLAVE_CFG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 2,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   constant RESIZE_MASTER_CFG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => APVS_PER_HYBRID_G * 2,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_FIXED_C,
      TUSER_BITS_C  => 0,
      TUSER_MODE_C  => TUSER_NONE_C);

   constant INT_AXIS_CONFIG_C : AxiStreamConfigType := ssiAxiStreamConfig(
      dataBytes => APVS_PER_HYBRID_G * 2,
      tKeepMode => TKEEP_FIXED_C,
      tUserMode => TUSER_FIRST_LAST_C,
      tUserBits => 2,
      tDestBits => 0);

--    type signed32array is array (natural range <>) of signed(31 downto 0);
--    type signed16array is array (natural range <>) of signed(31 downto 0);

   type RegType is record
      reset                : sl;
      average              : slv32Array(APVS_PER_HYBRID_G-1 downto 0);
      alpha                : slv(3 downto 0);
      pauseThresh          : slv(13 downto 0);
      waveformTrigger      : sl;
      doWaveform           : sl;
      decimation           : slv(15 downto 0);
      decCnt               : slv(15 downto 0);
      selectedApv          : slv(2 downto 0);
      selectedHybrid       : slv(2 downto 0);
      allApvs              : sl;
      selectedHybridStream : AxiStreamMasterArray(5 downto 0);
      decimatedStreams     : AxiStreamMasterArray(APVS_PER_HYBRID_G-1 downto 0);
      selectedApvStream    : AxiStreamMasterType;
      combinedStream       : AxiStreamMasterType;
      bufferStream         : AxiStreamMasterType;
      axilWriteSlave       : AxiLiteWriteSlaveType;
      axilReadSlave        : AxiLiteReadSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      reset                => '0',
      average              => (others => (others => '0')),
      alpha                => toSlv(15, 4),
      pauseThresh          => toSlv(2**14-8, 14),
      waveformTrigger      => '0',
      doWaveform           => '0',
      decimation           => (others => '0'),
      decCnt               => (others => '0'),
      selectedApv          => (others => '0'),
      selectedHybrid       => (others => '0'),
      allApvs              => '1',
      selectedHybridStream => (others => axiStreamMasterInit(RESIZE_SLAVE_CFG_C)),
      decimatedStreams     => (others => axiStreamMasterInit(RESIZE_SLAVE_CFG_C)),
      selectedApvStream    => axiStreamMasterInit(RESIZE_SLAVE_CFG_C),
      combinedStream       => axiStreamMasterInit(RESIZE_MASTER_CFG_C),
      bufferStream         => axiStreamMasterInit(INT_AXIS_CONFIG_C),
      axilWriteSlave       => AXI_LITE_WRITE_SLAVE_INIT_C,
      axilReadSlave        => AXI_LITE_READ_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal bufferCtrl    : AxiStreamCtrlType;
   signal resizedStream : AxiStreamMasterType := axiStreamMasterInit(RESIZE_MASTER_CFG_C);

begin


   -------------------------------------------------------------------------------------------------
   -- Resize channel ADC stream to 8 samples wide (16 bytes)
   -------------------------------------------------------------------------------------------------
   U_AxiStreamResize_1 : entity surf.AxiStreamResize
      generic map (
         TPD_G               => TPD_G,
         READY_EN_G          => false,
         PIPE_STAGES_G       => 0,
         SLAVE_AXI_CONFIG_G  => RESIZE_SLAVE_CFG_C,
         MASTER_AXI_CONFIG_G => RESIZE_MASTER_CFG_C)
      port map (
         axisClk     => axilClk,                    -- [in]
         axisRst     => axilRst,                    -- [in]
         sAxisMaster => r.selectedApvStream,        -- [in]
         sAxisSlave  => open,                       -- [out]
         mAxisMaster => resizedStream,              -- [out]
         mAxisSlave  => AXI_STREAM_SLAVE_FORCE_C);  -- [in]

   -------------------------------------------------------------------------------------------------
   -- Main Logic
   -------------------------------------------------------------------------------------------------
   comb : process (adcStreams, axilReadMaster, axilRst, axilWriteMaster, bufferCtrl, r,
                   resizedStream) is
      variable v              : RegType;
      variable selectedApv    : integer;
      variable selectedHybrid : integer;
      variable axilEp         : AxiLiteEndpointType;
      variable average        : signed(31 downto 0);
      variable avgDiv         : signed(31 downto 0);
      variable sample         : signed(31 downto 0);
      variable alpha          : integer range 0 to 15;
   begin
      v := r;

      v.waveformTrigger := '0';
      v.reset           := '0';

      ----------------------------------------------------------------------------------------------
      -- AXI-Lite Registers
      ----------------------------------------------------------------------------------------------
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      axiSlaveRegister(axilEp, X"00", 0, v.selectedApv);
      axiSlaveRegister(axilEp, X"00", 3, v.allApvs);
      axiSlaveRegister(axilEp, X"00", 8, v.selectedHybrid);
      axiSlaveRegister(axilEp, X"04", 0, v.waveformTrigger);
      axiSlaveRegister(axilEp, X"04", 1, v.reset);
      axiSlaveRegister(axilEp, X"08", 0, v.decimation);
      axiSlaveRegister(axilEp, X"08", 16, v.pauseThresh);
      axiSlaveRegister(axilEp, X"0C", 0, v.alpha);


      for i in 0 to APVS_PER_HYBRID_G-1 loop
         axiSlaveRegisterR(axilEp, slv(X"10" + to_unsigned(i*4, 8)), 0, r.average(i));
      end loop;

      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      ----------------------------------------------------------------------------------------------
      -- Multiplex Hybrid ADC streams
      ----------------------------------------------------------------------------------------------
      selectedHybrid         := to_integer(unsigned(r.selectedHybrid));
      v.selectedHybridStream := adcStreams(selectedHybrid);

      ----------------------------------------------------------------------------------------------
      -- Pedastal
      ----------------------------------------------------------------------------------------------
      alpha := to_integer(unsigned(r.alpha));
      if (r.selectedHybridStream(0).tValid = '1') then
         for i in APVS_PER_HYBRID_G-1 downto 0 loop
            average      := signed(r.average(i));
            avgDiv       := shift_right(average, alpha);
            sample       := resize(signed(r.selectedHybridStream(i).tData(15 downto 0)), 32);
            sample       := shift_right(shift_left(sample, 16), alpha);
            average      := average - avgDiv + sample;
            v.average(i) := slv(average);
         end loop;
      end if;
      if (r.reset = '1') then
         v.average := (others => (others => '0'));
      end if;

      ----------------------------------------------------------------------------------------------
      -- Decimator
      ----------------------------------------------------------------------------------------------
      if (r.selectedHybridStream(0).tValid = '1') then
         v.decCnt := slv(unsigned(r.decCnt) + 1);

         for i in APVS_PER_HYBRID_G-1 downto 0 loop
            v.decimatedStreams(i).tValid := '0';
            if (r.selectedHybridStream(i).tValid = '1' and (unsigned(r.decCnt) = unsigned(r.decimation)-1 or unsigned(r.decimation) = 0)) then
               v.decimatedStreams(i).tValid             := '1';
               v.decimatedStreams(i).tData(15 downto 0) := r.selectedHybridStream(i).tData(15 downto 0);
               v.decCnt                                 := (others => '0');
            end if;
         end loop;
      end if;

      ----------------------------------------------------------------------------------------------
      -- Multiplex decimated stream to resizer
      ----------------------------------------------------------------------------------------------
      selectedApv               := to_integer(unsigned(r.selectedApv));
      v.selectedApvStream       := r.decimatedStreams(selectedApv);
--      v.selectedApvStream.tDest := toSlv(8, 8);  --resize(r.selectedApv, 8);

      ----------------------------------------------------------------------------------------------
      -- Create a combined stream of all channels
      ----------------------------------------------------------------------------------------------
      v.combinedStream.tValid := r.decimatedStreams(0).tValid;
      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         v.combinedStream.tData(i*16+15 downto i*16) := r.decimatedStreams(i).tData(15 downto 0);
      end loop;
--      v.combinedStream.tDest := toSlv(8, 8);

      ----------------------------------------------------------------------------------------------
      -- Dump data info FIFO when triggered
      -- Multiplex combined or resized channel streams
      ----------------------------------------------------------------------------------------------
      if (r.waveformTrigger = '1') then
         v.doWaveform                       := '1';
         v.bufferStream.tValid              := '1';
         v.bufferStream.tData(2 downto 0)   := r.selectedApv;
         v.bufferStream.tData(3)            := r.allApvs;
         v.bufferStream.tData(10 downto 8)  := r.selectedHybrid;
         v.bufferStream.tData(13 downto 11) := toSlv(APVS_PER_HYBRID_G, 3);
         v.bufferStream.tData(31 downto 16) := r.decimation;

         ssiSetUserSof(INT_AXIS_CONFIG_C, v.bufferStream, '1');
      end if;

      if (r.doWaveform = '1') then
         if (r.allApvs = '1') then
            v.bufferStream := r.combinedStream;
         else
            v.bufferStream := resizedStream;
         end if;
      end if;

      if (r.bufferStream.tvalid = '1') then
         ssiSetUserSof(INT_AXIS_CONFIG_C, v.bufferStream, '0');
      end if;

      if (bufferCtrl.pause = '1' and v.bufferStream.tvalid = '1') then
         v.bufferStream.tLast := '1';
      end if;

      if (r.bufferStream.tLast = '1') then
         v.doWaveform          := '0';
         v.bufferStream.tValid := '0';
         v.bufferStream.tLast  := '0';
      end if;


      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

   end process;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_AxiStreamFifoV2_1 : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         INT_PIPE_STAGES_G   => 1,
         PIPE_STAGES_G       => 0,
         VALID_THOLD_G       => 0,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => true,
         FIFO_FIXED_THRESH_G => false,
         FIFO_ADDR_WIDTH_G   => 14,
         FIFO_PAUSE_THRESH_G => 2**14-8,
--           SYNTH_MODE_G           => SYNTH_MODE_G,
--           MEMORY_TYPE_G          => MEMORY_TYPE_G,
--           INT_WIDTH_SELECT_G     => INT_WIDTH_SELECT_G,
--           INT_DATA_WIDTH_G       => INT_DATA_WIDTH_G,
         SLAVE_AXI_CONFIG_G  => INT_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => PGP2FC_AXIS_CONFIG_C)
      port map (
         sAxisClk        => axilClk,         -- [in]
         sAxisRst        => axilRst,         -- [in]
         sAxisMaster     => r.bufferStream,  -- [in]
         sAxisCtrl       => bufferCtrl,      -- [out]
         fifoPauseThresh => r.pauseThresh,   -- [in]
         mAxisClk        => axilClk,         -- [in]
         mAxisRst        => axilRst,         -- [in]
         mAxisMaster     => axisMaster,      -- [out]
         mAxisSlave      => axisSlave);      -- [in]
end architecture rtl;


