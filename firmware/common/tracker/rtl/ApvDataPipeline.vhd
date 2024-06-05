-------------------------------------------------------------------------------
-- Title      : Apv Data Pipeline
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of LDMX. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LDMX, including this file, may be
-- copied, modified, propagated, or distributed except according to the terms
-- contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;


library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;
use ldmx_tracker.FebConfigPkg.all;
use ldmx_tracker.DataPathPkg.all;

entity ApvDataPipeline is
   generic (
      TPD_G            : time                 := 1 ns;
      AXIL_BASE_ADDR_G : slv(31 downto 0)     := (others => '0');
      HYBRID_NUM_G     : integer range 0 to 8 := 0;
      APV_NUM_G        : integer range 0 to 8 := 5;
      THRESHOLD_EN_G   : boolean              := true);
   port (
      -- Master system clock, 125Mhz
      axilClk : in sl;
      axilRst : in sl;

      -- Axi-Lite interface for configuration and status
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Configuration
      febConfig : in FebConfigType;

      -- Incomming raw ADC data from one hybrid
      adcReadoutStream : in AxiStreamMasterType;

      -- Trigger
      readoutReq : in sl;

      -- Status outputs
      syncDetected  : out sl;
      syncBase      : out slv(15 downto 0);
      syncPeak      : out slv(15 downto 0);
      frameCount    : out slv(31 downto 0);
      pulseStream   : out slv(63 downto 0);
      minSamples    : out slv(15 downto 0);
      maxSamples    : out slv(15 downto 0);
      lostSyncCount : out slv(31 downto 0);
      countReset    : in  sl;

      -- Processed multisamples out
      dataOut  : out MultiSampleType;
      dataRdEn : in  sl);

end ApvDataPipeline;

architecture rtl of ApvDataPipeline is

   constant XBAR_NUM_MASTERS_C : integer                          := 2;
   constant XBAR_CFG_C         : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(XBAR_NUM_MASTERS_C, AXIL_BASE_ADDR_G, 16, 12);

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(XBAR_NUM_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(XBAR_NUM_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);


   -- Sync status for each APV
   signal syncDetectedLoc : sl;


   -- Extracted frame data for each APV
   signal apvFrameAxisMaster : AxiStreamMasterType;

   -- Buffered data from each APV 
   signal buffApvFrameAxisMaster : AxiStreamMasterType;
   signal buffApvFrameAxisSlave  : AxiStreamSlaveType;

   -- Output of sample extractor and threshold filter
   signal sampleExtractorOut : MultiSampleType;
   signal thresholdFilterOut : MultiSampleType;

   -- Filtered data fifo signals
   signal filterFifoOut   : slv(MULTI_SAMPLE_LENGTH_C-1 downto 0);
   signal filterFifoValid : sl;

begin

   syncDetected <= syncDetectedLoc;

   AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => XBAR_NUM_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   ApvFrameExtractor_1 : entity ldmx_tracker.ApvFrameExtractor
      generic map (
         TPD_G        => TPD_G,
         HYBRID_NUM_G => HYBRID_NUM_G,
         APV_NUM_G    => APV_NUM_G)
      port map (
         sysClk             => axilClk,
         sysRst             => axilRst,
         adcValid           => adcReadoutStream.tvalid,
         adcData            => adcReadoutStream.tdata(15 downto 0),
         febConfig          => febConfig,
         syncBase           => syncBase,
         syncPeak           => syncPeak,
         syncDetected       => syncDetectedLoc,
         frameCount         => frameCount,
         countReset         => countReset,
         pulseStream        => pulseStream,
         minSample          => minSamples,
         maxSample          => maxSamples,
         lostSyncCount      => lostSyncCount,
         apvFrameAxisMaster => apvFrameAxisMaster);

   -- Pipeline so that ApvDataFormatter can momentarily backpressure
   U_AxiStreamPipeline_1 : entity surf.AxiStreamPipeline
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => 4)                     -- Check this
      port map (
         axisClk     => axilClk,                 -- [in]
         axisRst     => axilRst,                 -- [in]
         sAxisMaster => apvFrameAxisMaster,      -- [in]
         sAxisSlave  => open,                    -- [out]
         mAxisMaster => buffApvFrameAxisMaster,  -- [out]
         mAxisSlave  => buffApvFrameAxisSlave);  -- [in]

   -- Each trigger produces 3 APV frames from each APV
   -- Group the data from all 3 frames by channel
   -- Needs 9 AXI address bits
   ApvDataFormatter_1 : entity ldmx_tracker.ApvDataFormatter
      generic map (
         TPD_G           => TPD_G,
         HYBRID_NUM_G    => HYBRID_NUM_G,
         APV_NUM_G       => APV_NUM_G,
         AXI_DEBUG_EN_G  => false,
         AXI_BASE_ADDR_G => XBAR_CFG_C(0).baseAddr)  -- 9 address bits
      port map (
         axilClk            => axilClk,
         axilRst            => axilRst,
         sysPipelineRst     => '0',
         axiReadMaster      => locAxilReadMasters(0),
         axiReadSlave       => locAxilReadSlaves(0),
         axiWriteMaster     => locAxilWriteMasters(0),
         axiWriteSlave      => locAxilWriteSlaves(0),
         apvFrameAxisMaster => buffApvFrameAxisMaster,
         apvFrameAxisSlave  => buffApvFrameAxisSlave,
         readoutReq         => readoutReq,
         febConfig          => febConfig,
         syncStatus         => syncDetectedLoc,
         dataOut            => sampleExtractorOut);

   ----------------------------------------------------------------------------------------------
   -- Threshold Filter
   -- Remove channels whose adc samples don't meet the thresholds
   -- Needs AXI address bits
   ----------------------------------------------------------------------------------------------
   THRESHOLD_GEN : if (THRESHOLD_EN_G) generate
      Threshold_1 : entity ldmx_tracker.Threshold
         generic map (
            TPD_G => TPD_G)             -- 9 address bits
         port map (
            sysClk         => axilClk,
            sysRst         => axilRst,
            sysPipelineRst => '0',
            axiReadMaster  => locAxilReadMasters(1),
            axiReadSlave   => locAxilReadSlaves(1),
            axiWriteMaster => locAxilWriteMasters(1),
            axiWriteSlave  => locAxilWriteSlaves(1),
            febConfig      => febConfig,
            dataIn         => sampleExtractorOut,
            dataOut        => thresholdFilterOut);
   end generate THRESHOLD_GEN;

   NO_THRESHOLD_GEN : if (not THRESHOLD_EN_G) generate
      thresholdFilterOut <= sampleExtractorOut;
   end generate NO_THRESHOLD_GEN;


   ----------------------------------------------------------------------------------------------
   -- Buffer data until it can be read by EventBuilder
   -- Want to buffer a whole trigger/readout w/o threshold filters
   -- 129 Multi-samples = 2**7
   ----------------------------------------------------------------------------------------------
   FILTERED_DATA_FIFO : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => "block",
         SYNTH_MODE_G    => "xpm",
         FWFT_EN_G       => true,
         PIPE_STAGES_G   => 1,
         DATA_WIDTH_G    => MULTI_SAMPLE_LENGTH_C,
         ADDR_WIDTH_G    => 7)
      port map (
         rst          => axilRst,
         wr_clk       => axilClk,
         wr_en        => thresholdFilterOut.valid,
         din          => toSlv(thresholdFilterOut),
         prog_full    => open,
         almost_full  => open,
         full         => open,
         rd_clk       => axilClk,
         rd_en        => dataRdEn,
         dout         => filterFifoOut,
         valid        => filterFifoValid,
         prog_empty   => open,
         almost_empty => open,
         empty        => open);

   dataOut <= toMultiSample(filterFifoOut, filterFifoValid);

end rtl;
