-------------------------------------------------------------------------------
-- Title         : ADC Data Formatter
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : DataPath.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/08/2011
-------------------------------------------------------------------------------
-- Description:
-- Formats the data from one Hybrid (1 ADC, 5 APV25s).
-------------------------------------------------------------------------------
-- Copyright (c) 2011 by SLAC. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 08/09/2011: created.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;


library ldmx;
use ldmx.HpsPkg.all;
use ldmx.DataPathPkg.all;
use ldmx.AdcReadoutPkg.all;
use ldmx.RceConfigPkg.all;
use ldmx.FebConfigPkg.all;

entity DataPath is
   generic (
      TPD_G           : time             := 1 ns;
      AXI_BASE_ADDR_G : slv(31 downto 0) := X"00000000";
      THRESHOLD_EN_G  : boolean          := true;
      APVS_PER_HYBRID_G : integer := 5;
      ADF_DEBUG_EN_G  : boolean          := false;
      PACK_APV_DATA_G : boolean          := true);
   port (

      -- Data clock dependent on link speed with FEB
      dataClk         : in sl;
      dataClkRst      : in sl;
      dataPipelineRst : in sl;

      -- Incomming Data FEB
      hybridApvDataAxisMaster : in  AxiStreamMasterType;
      hybridApvDataAxisSlave  : out AxiStreamSlaveType;

      syncStatus                 : in  slv(APVS_PER_HYBRID_G-1 downto 0);
      hybridStatusDataAxisMaster : in  AxiStreamMasterType;
      hybridStatusDataAxisSlave  : out AxiStreamSlaveType;

      -- System clock
      sysClk         : in sl;
      sysRst         : in sl;
      sysPipelineRst : in sl;

      -- AXI interface for configuration and status
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- Control, config and status
      trigger    : in  sl;
      rceConfig  : in  RceConfigType;
      hybridInfo : out HybridInfoType;

      -- Processed Output data
      dataOut  : out MultiSampleArray(APVS_PER_HYBRID_G-1 downto 0);
      dataRdEn : in  slv(APVS_PER_HYBRID_G-1 downto 0));

end DataPath;

architecture DataPath of DataPath is


   -------------------------------------------------------------------------------------------------
   -- AXI signals
   -------------------------------------------------------------------------------------------------
   constant AXI_LOCAL_OFFSET_C          : slv(31 downto 0) := X"00000000";
   constant AXI_THRESHOLD_OFFSET_C      : slv(31 downto 0) := X"00008000";
   constant AXI_DATA_FORMATTER_OFFSET_C : slv(31 downto 0) := X"00009000";

   constant AXI_NUM_SLAVES_C  : natural := 1;
   constant AXI_NUM_MASTERS_C : natural := 12;
   constant AXI_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray := (
      0               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_LOCAL_OFFSET_C,
         addrBits     => 8,
         connectivity => X"0001"),
      1               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_THRESHOLD_OFFSET_C + X"000",
         addrBits     => 9,
         connectivity => X"0001"),
      2               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_THRESHOLD_OFFSET_C + X"200",
         addrBits     => 9,
         connectivity => X"0001"),
      3               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_THRESHOLD_OFFSET_C + X"400",
         addrBits     => 9,
         connectivity => X"0001"),
      4               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_THRESHOLD_OFFSET_C + X"600",
         addrBits     => 9,
         connectivity => X"0001"),
      5               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_THRESHOLD_OFFSET_C + X"800",
         addrBits     => 9,
         connectivity => X"0001"),
      -- Sample Extractors
      6               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_DATA_FORMATTER_OFFSET_C + X"000",
         addrBits     => 9,
         connectivity => X"0001"),
      7               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_DATA_FORMATTER_OFFSET_C + X"200",
         addrBits     => 9,
         connectivity => X"0001"),
      8               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_DATA_FORMATTER_OFFSET_C + X"400",
         addrBits     => 9,
         connectivity => X"0001"),
      9               => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_DATA_FORMATTER_OFFSET_C + X"600",
         addrBits     => 9,
         connectivity => X"0001"),
      10              => (
         baseAddr     => AXI_BASE_ADDR_G + AXI_DATA_FORMATTER_OFFSET_C + X"800",
         addrBits     => 9,
         connectivity => X"0001"),
      11              => (
         baseAddr     => AXI_BASE_ADDR_G + X"A000",
         addrBits     => 12,
         connectivity => X"0001"));
--      12              => (
--         baseAddr     => AXI_BASE_ADDR_G + X"B000",
--         addrBits     => 12,
--         connectivity => X"0001"));

   signal threshAxiReadMasters  : AxiLiteReadMasterArray(APVS_PER_HYBRID_G-1 downto 0);
   signal threshAxiWriteMasters : AxiLiteWriteMasterArray(APVS_PER_HYBRID_G-1 downto 0);
   signal threshAxiReadSlaves   : AxiLiteReadSlaveArray(APVS_PER_HYBRID_G-1 downto 0);
   signal threshAxiWriteSlaves  : AxiLiteWriteSlaveArray(APVS_PER_HYBRID_G-1 downto 0);

   signal dfAxiReadMasters  : AxiLiteReadMasterArray(APVS_PER_HYBRID_G-1 downto 0);
   signal dfAxiWriteMasters : AxiLiteWriteMasterArray(APVS_PER_HYBRID_G-1 downto 0);
   signal dfAxiReadSlaves   : AxiLiteReadSlaveArray(APVS_PER_HYBRID_G-1 downto 0);
   signal dfAxiWriteSlaves  : AxiLiteWriteSlaveArray(APVS_PER_HYBRID_G-1 downto 0);

   signal logAxiReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal logAxiWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal logAxiReadSlaves   : AxiLiteReadSlaveArray(1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal logAxiWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   signal localAxiReadMaster  : AxiLiteReadMasterType;
   signal localAxiWriteMaster : AxiLiteWriteMasterType;
   signal localAxiReadSlave   : AxiLiteReadSlaveType;
   signal localAxiWriteSlave  : AxiLiteWriteSlaveType;

   -- Local Signals
   signal hybridInfoLoc : HybridInfoType;

   signal hybridApvDataAxisSlaveLoc : AxiStreamSlaveType;
   signal hybridApvDataAxisCtrlLoc  : AxiStreamCtrlType;

   -- Data streams
   signal efHybridApvDataAxisMaster : AxiStreamMasterType;
   signal efHybridApvDataAxisSlave  : AxiStreamSlaveType;
   signal efHybridApvDataAxisCtrl   : AxiStreamCtrlType;


   signal unpackedHybridApvDataAxisMaster : AxiStreamMasterType;
   signal unpackedHybridApvDataAxisSlave  : AxiStreamSlaveType;
   signal unpackedHybridApvDataAxisCtrl   : AxiStreamCtrlType;

   signal apvFrameAxisMasters : AxiStreamMasterArray(APVS_PER_HYBRID_G-1 downto 0);
   signal apvFrameAxisSlaves  : AxiStreamSlaveArray(APVS_PER_HYBRID_G-1 downto 0);
   signal apvFrameAxisCtrl    : AxiStreamCtrlArray(APVS_PER_HYBRID_G-1 downto 0);

   signal buffApvFrameAxisMasters : AxiStreamMasterArray(APVS_PER_HYBRID_G-1 downto 0);
   signal buffApvFrameAxisSlaves  : AxiStreamSlaveArray(APVS_PER_HYBRID_G-1 downto 0);
   signal buffApvFrameAxisCtrl    : AxiStreamCtrlArray(APVS_PER_HYBRID_G-1 downto 0);

   signal sampleExtractorOut : MultiSampleArray(APVS_PER_HYBRID_G-1 downto 0);
   signal thresholdFilterOut : MultiSampleArray(APVS_PER_HYBRID_G-1 downto 0);
   signal filterFifoOut      : slv128Array(APVS_PER_HYBRID_G-1 downto 0);
   signal filterFifoValid    : slv(APVS_PER_HYBRID_G-1 downto 0);

--   signal missedFrames : slv(15 downto 0);
--   signal lastFrameNum : slv(13 downto 0);

   type RegType is record
      localAxiReadSlave  : AxiLiteReadSlaveType;
      localAxiWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      localAxiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      localAxiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal sysRstLoc  : sl;
   signal dataRstLoc : sl;

begin

   hybridInfo <= hybridInfoLoc;

   sysRstLoc  <= sysRst or sysPipelineRst;
   dataRstLoc <= dataClkRst or dataPipelineRst;

   -------------------------------------------------------------------------------------------------
   -- Axi Crossbar
   -------------------------------------------------------------------------------------------------

   AxiLiteCrossbar_DataPath : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => AXI_NUM_SLAVES_C,
         NUM_MASTER_SLOTS_G => AXI_NUM_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_MASTERS_CONFIG_C)
      port map (
         axiClk                        => sysClk,
         axiClkRst                     => sysRst,
         sAxiWriteMasters(0)           => axiWriteMaster,
         sAxiWriteSlaves(0)            => axiWriteSlave,
         sAxiReadMasters(0)            => axiReadMaster,
         sAxiReadSlaves(0)             => axiReadSlave,
         mAxiWriteMasters(0)           => localAxiWriteMaster,
         mAxiWriteMasters(5 downto 1)  => threshAxiWriteMasters,
         mAxiWriteMasters(10 downto 6) => dfAxiWriteMasters,
         mAxiWriteMasters(11)          => logAxiWriteMasters(0),
         mAxiWriteSlaves(0)            => localAxiWriteSlave,
         mAxiWriteSlaves(5 downto 1)   => threshAxiWriteSlaves,
         mAxiWriteSlaves(10 downto 6)  => dfAxiWriteSlaves,
         mAxiWriteSlaves(11)           => logAxiWriteSlaves(0),
         mAxiReadMasters(0)            => localAxiReadMaster,
         mAxiReadMasters(5 downto 1)   => threshAxiReadMasters,
         mAxiReadMasters(10 downto 6)  => dfAxiReadMasters,
         mAxiReadMasters(11)           => logAxiReadMasters(0),
         mAxiReadSlaves(0)             => localAxiReadSlave,
         mAxiReadSlaves(5 downto 1)    => threshAxiReadSlaves,
         mAxiReadSlaves(10 downto 6)   => dfAxiReadSlaves,
         mAxiReadSlaves(11)            => logAxiReadSlaves(0));


--   -- If no threshold filters, don't need crossbar
--   -- Connect directly to local AXI signals
   NO_THRESHOLD_CROSSBAR : if (not THRESHOLD_EN_G) generate

      threshAxiReadSlaves  <= (others => AXI_LITE_READ_SLAVE_INIT_C);
      threshAxiWriteSlaves <= (others => AXI_LITE_WRITE_SLAVE_INIT_C);

   end generate NO_THRESHOLD_CROSSBAR;

   -------------------------------------------------------------------------------------------------
   -- Local Registers
   -------------------------------------------------------------------------------------------------
   comb : process (hybridInfoLoc, localAxiReadMaster, localAxiWriteMaster, r, sysRst) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      axiSlaveWaitTxn(localAxiWriteMaster, localAxiReadMaster, v.localAxiWriteSlave, v.localAxiReadSlave, axiStatus);

      if (axiStatus.writeEnable = '1') then
         -- Send Axi response
         axiSlaveWriteResponse(v.localAxiWriteSlave);
      end if;

      if (axiStatus.readEnable = '1') then
         -- Decode address and assign read data
         v.localAxiReadSlave.rdata := (others => '0');
         if (localAxiReadMaster.araddr(3 downto 0) = X"0") then
            v.localAxiReadSlave.rdata(15 downto 0) := toSlv(hybridInfoLoc);
         end if;
         -- Send Axi Response
         axiSlaveReadResponse(v.localAxiReadSlave);
      end if;

      if (sysRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      localAxiReadSlave  <= r.localAxiReadSlave;
      localAxiWriteSlave <= r.localAxiWriteSlave;

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -------------------------------------------------------------------------------------------------
   -- Extract statuses and ADC Samples from incomming VC Frames
   -------------------------------------------------------------------------------------------------
   HybridStatusDeframer_1 : entity ldmx.HybridStatusDeframer
      generic map (
         TPD_G             => TPD_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         axisClk                    => dataClk,
         axisRst                    => dataRstLoc,  --dataClkRst,
         syncStatus                 => syncStatus,
         hybridStatusDataAxisMaster => hybridStatusDataAxisMaster,
         hybridStatusDataAxisSlave  => hybridStatusDataAxisSlave,
         sysClk                     => sysClk,
         sysRst                     => sysRstLoc,
         hybridInfo                 => hybridInfoLoc);

   -------------------------------------------------------------------------------------------------
   -- Optionall unpack the APV data stream
   -------------------------------------------------------------------------------------------------
--    hybridApvDataAxisSlave <= hybridApvDataAxisSlaveLoc;
--    hybridApvDataAxisCtrl  <= hybridApvDataAxisCtrlLoc;
--    SsiFrameLogger_Packed : entity ldmx.SsiFrameLogger
--       generic map (
--          TPD_G            => TPD_G,
--          MEMORY_TYPE_G        => "block",
--          RAM_ADDR_WIDTH_G => 11,
--          AXIS_CONFIG_G    => APV_DATA_SSI_CONFIG_C)
--       port map (
--          axilClk        => sysClk,
--          axilRst        => sysRst,
--          axiReadMaster  => logAxiReadMasters(0),
--          axiReadSlave   => logAxiReadSlaves(0),
--          axiWriteMaster => logAxiWriteMasters(0),
--          axiWriteSlave  => logAxiWriteSlaves(0),
--          axisClk        => dataClk,
--          axisRst        => dataRstLoc,
--          sAxisMaster    => hybridApvDataAxisMaster,
--          sAxisSlave     => hybridApvDataAxisSlaveLoc,
--          sAxisCtrl      => hybridApvDataAxisCtrlLoc);

--    SsiErrorFilter_1 : entity ldmx.SsiErrorFilter
--       generic map (
--          TPD_G         => TPD_G,
--          FRAME_SIZE_G  => 129,
--          AXIS_CONFIG_G => APV_DATA_SSI_CONFIG_C)
--       port map (
--          axisClk     => dataClk,
--          axisRst     => dataRstLoc,
--          sAxisMaster => hybridApvDataAxisMaster,
--          sAxisSlave  => hybridApvDataAxisSlaveLoc,
--          sAxisCtrl   => hybridApvDataAxisCtrlLoc,
--          mAxisMaster => efHybridApvDataAxisMaster,
--          mAxisSlave  => efHybridApvDataAxisSlave);


   UNPACK_APV_GEN : if (PACK_APV_DATA_G) generate
      AxiStreamUnpacker_1 : entity surf.AxiStreamGearboxUnpack
         generic map (
            TPD_G               => TPD_G,
            AXI_STREAM_CONFIG_G => APV_DATA_SSI_CONFIG_C,
            RANGE_HIGH_G        => 13,
            RANGE_LOW_G         => 2)
         port map (
            axisClk          => dataClk,
            axisRst          => dataRstLoc,               --dataClkRst,
            packedAxisMaster => hybridApvDataAxisMaster,  --efHybridApvDataAxisMaster,
            packedAxisSlave  => hybridApvDataAxisSlave,   -- efHybridApvDataAxisSlave,
--            packedAxisCtrl   => efHybridApvDataAxisCtrl,
            rawAxisMaster    => unpackedHybridApvDataAxisMaster,
            rawAxisSlave     => unpackedHybridApvDataAxisSlave,
            rawAxisCtrl      => unpackedHybridApvDataAxisCtrl);
   end generate UNPACK_APV_GEN;

   NO_UNPACK_APV_GEN : if (not PACK_APV_DATA_G) generate
      unpackedHybridApvDataAxisMaster <= hybridApvDataAxisMaster;  --efHybridApvDataAxisMaster;
      hybridApvDataAxisSlave          <= unpackedHybridApvDataAxisSlave;
   end generate NO_UNPACK_APV_GEN;

--   SsiFrameLogger_Unpacked : entity ldmx.SsiFrameLogger
--      generic map (
--         TPD_G            => TPD_G,
--         MEMORY_TYPE_G        => "block",
--         RAM_ADDR_WIDTH_G => 11,
--         AXIS_CONFIG_G    => APV_DATA_SSI_CONFIG_C)
--      port map (
--         axilClk        => sysClk,
--         axilRst        => sysRst,
--         axiReadMaster  => logAxiReadMasters(1),
--         axiReadSlave   => logAxiReadSlaves(1),
--         axiWriteMaster => logAxiWriteMasters(1),
--         axiWriteSlave  => logAxiWriteSlaves(1),
--         axisClk        => dataClk,
--         axisRst        => dataRstLoc,
--         sAxisMaster    => unpackedHybridApvDataAxisMaster,
--         sAxisSlave     => unpackedHybridApvDataAxisSlave,
--         sAxisCtrl      => unpackedHybridApvDataAxisCtrl);

   -------------------------------------------------------------------------------------------------
   -- Demultiplex the APV frames into a separate stream per APV
   -------------------------------------------------------------------------------------------------
   ApvFrameDemux_1 : entity ldmx.ApvFrameDemux
      generic map (
         TPD_G      => TPD_G,
         NUM_APVS_G => APVS_PER_HYBRID_G)
      port map (
         axisClk              => dataClk,
         axisRst              => dataRstLoc,  --dataClkRst,
         hybridDataAxisMaster => unpackedHybridApvDataAxisMaster,
         hybridDataAxisSlave  => unpackedHybridApvDataAxisSlave,
         apvFrameAxisMasters  => apvFrameAxisMasters,
         apvFrameAxisSlaves   => apvFrameAxisSlaves);

   -------------------------------------------------------------------------------------------------
   -- Create processing pipeline for each APV
   -------------------------------------------------------------------------------------------------
   GenChannel : for i in APVS_PER_HYBRID_G-1 downto 0 generate

      --Fifo to convert to system clock
      CLOCK_CONV_FIFO : entity surf.AxiStreamFifoV2
         generic map (
            TPD_G               => TPD_G,
            INT_PIPE_STAGES_G   => 1,
            PIPE_STAGES_G       => 1,
            SYNTH_MODE_G        => "xpm",
            MEMORY_TYPE_G       => "distributed",
            GEN_SYNC_FIFO_G     => false,
            FIFO_ADDR_WIDTH_G   => 4,   -- Check this
            FIFO_FIXED_THRESH_G => true,
            FIFO_PAUSE_THRESH_G => 2**4-3,
            SLAVE_AXI_CONFIG_G  => APV_DATA_SSI_CONFIG_C,
            MASTER_AXI_CONFIG_G => APV_DATA_SSI_CONFIG_C)
         port map (
            sAxisClk    => dataClk,
            sAxisRst    => dataRstLoc,
            sAxisMaster => apvFrameAxisMasters(i),
            sAxisSlave  => apvFrameAxisSlaves(i),
            mAxisClk    => sysClk,
            mAxisRst    => sysRstLoc,
            mAxisMaster => buffApvFrameAxisMasters(i),
            mAxisSlave  => buffApvFrameAxisSlaves(i));

      -- Each trigger produces 6 APV frames from each APV
      -- Group the data from all 6 frames by channel
      ApvDataFormatter_1 : entity ldmx.ApvDataFormatter
         generic map (
            TPD_G           => TPD_G,
            APV_NUM_G       => i,
            AXI_DEBUG_EN_G  => ADF_DEBUG_EN_G,
            AXI_BASE_ADDR_G => AXI_MASTERS_CONFIG_C(i+6).baseAddr)
         port map (
            sysClk             => sysClk,
            sysRst             => sysRst,
            sysPipelineRst     => sysPipelineRst,
            axiReadMaster      => dfAxiReadMasters(i),
            axiReadSlave       => dfAxiReadSlaves(i),
            axiWriteMaster     => dfAxiWriteMasters(i),
            axiWriteSlave      => dfAxiWriteSlaves(i),
            apvFrameAxisMaster => buffApvFrameAxisMasters(i),
            apvFrameAxisSlave  => buffApvFrameAxisSlaves(i),
            apvFrameAxisCtrl   => buffApvFrameAxisCtrl(i),
            trigger            => trigger,
            rceConfig          => rceConfig,
            hybridInfo         => hybridInfoLoc,
            dataOut            => sampleExtractorOut(i));

      ----------------------------------------------------------------------------------------------
      -- Threshold Filter
      -- Remove channels whose adc samples don't meet the thresholds
      ----------------------------------------------------------------------------------------------
      THRESHOLD_GEN : if (THRESHOLD_EN_G) generate
         Threshold_1 : entity ldmx.Threshold
            generic map (
               TPD_G => TPD_G)
            port map (
               sysClk         => sysClk,
               sysRst         => sysRst,
               sysPipelineRst => sysPipelineRst,
               axiReadMaster  => threshAxiReadMasters(i),
               axiReadSlave   => threshAxiReadSlaves(i),
               axiWriteMaster => threshAxiWriteMasters(i),
               axiWriteSlave  => threshAxiWriteSlaves(i),
               rceConfig      => rceConfig,
               dataIn         => sampleExtractorOut(i),
               dataOut        => thresholdFilterOut(i));
      end generate THRESHOLD_GEN;

      NO_THRESHOLD_GEN : if (not THRESHOLD_EN_G) generate
         thresholdFilterOut(i) <= sampleExtractorOut(i);
      end generate NO_THRESHOLD_GEN;


      ----------------------------------------------------------------------------------------------
      -- Buffer data until it can be read by EventBuilder
      ----------------------------------------------------------------------------------------------
      FILTERED_DATA_FIFO : entity surf.Fifo
         generic map (
            TPD_G           => TPD_G,
            GEN_SYNC_FIFO_G => true,
            MEMORY_TYPE_G   => "distributed",
            FWFT_EN_G       => true,
            PIPE_STAGES_G   => 1,
            DATA_WIDTH_G    => 128,
            ADDR_WIDTH_G    => 4)       -- check this
         port map (
            rst          => sysRstLoc,
            wr_clk       => sysClk,
            wr_en        => thresholdFilterOut(i).valid,
            din          => toSlv(thresholdFilterOut(i)),
            prog_full    => open,
            almost_full  => open,
            full         => open,
            rd_clk       => sysClk,
            rd_en        => dataRdEn(i),
            dout         => filterFifoOut(i),
            valid        => filterFifoValid(i),
            prog_empty   => open,
            almost_empty => open,
            empty        => open);

   end generate;

   FORMAT_OUTPUT : process (filterFifoOut, filterFifoValid) is
   begin
      for i in APVS_PER_HYBRID_G-1 downto 0 loop
         dataOut(i) <= toMultiSample(filterFifoOut(i), filterFifoValid(i));
      end loop;
   end process FORMAT_OUTPUT;


end DataPath;

