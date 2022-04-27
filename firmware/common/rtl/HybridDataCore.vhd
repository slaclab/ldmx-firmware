-------------------------------------------------------------------------------
-- Title         : APV25 Sync Pulse Detect
-- Project       : Heavy Photon Tracker
-------------------------------------------------------------------------------
-- File          : HybridDataCore.vhd
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
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ldmx;
use ldmx.HpsPkg.all;
use ldmx.DataPathPkg.all;
use ldmx.FebConfigPkg.all;

entity HybridDataCore is
   generic (
      TPD_G             : time                 := 1 ns;
      AXIL_BASE_ADDR_G  : slv(31 downto 0)     := (others => '0');
      HYBRID_NUM_G      : integer range 0 to 8 := 0;
      APVS_PER_HYBRID_G : integer range 4 to 6 := 6);
   port (
      -- Master system clock, 125Mhz
      sysClk : in sl;
      sysRst : in sl;

      -- Axi-Lite interface for configuration and status
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- Configuration
      febConfig : in FebConfigType;

      -- Trigger
      trigger : in sl;

      -- Incomming raw ADC data from one hybrid
      adcReadoutStreams : in AxiStreamMasterArray(APVS_PER_HYBRID_G-1 downto 0);

      -- Processed multisamples out
      dataOut  : out MultiSampleArray(APVS_PER_HYBRID_G-1 downto 0);
      dataRdEn : in  slv(APVS_PER_HYBRID_G-1 downto 0));

end HybridDataCore;

architecture rtl of HybridDataCore is

   constant XBAR_NUM_MASTERS_C : integer                          := APVS_PER_HYBRID_G + 1;
   constant XBAR_CFG_C         : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(XBAR_NUM_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(XBAR_NUM_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(XBAR_NUM_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);


   -------------------------------------------------------------------------------------------------
   -- APV path signals
   -------------------------------------------------------------------------------------------------
   -- Sync status for each APV
   signal syncDetected  : slv(APVS_PER_HYBRID_G-1 downto 0);
   signal syncBase      : Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
   signal syncPeak      : Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
   signal frameCount    : Slv32Array(APVS_PER_HYBRID_G-1 downto 0);
   signal pulseStream   : slv64Array(APVS_PER_HYBRID_G-1 downto 0);
   signal minSamples    : Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
   signal maxSamples    : Slv16Array(APVS_PER_HYBRID_G-1 downto 0);
   signal lostSyncCount : slv32Array(APVS_PER_HYBRID_G-1 downto 0);
   signal countReset    : sl;

begin

   AxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => XBAR_NUM_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CFG_C)
      port map (
         axiClk              => sysClk,
         axiClkRst           => sysRst,
         sAxiWriteMasters(0) => axiWriteMaster,
         sAxiWriteSlaves(0)  => axiWriteSlave,
         sAxiReadMasters(0)  => axiReadMaster,
         sAxiReadSlaves(0)   => axiReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Create a frame extractor and buffer for each APV
   -------------------------------------------------------------------------------------------------
   GEN_PIPELINE : for i in APVS_PER_HYBRID_G-1 downto 0 generate

      U_ApvDataPipeline_1 : entity ldmx.ApvDataPipeline
         generic map (
            TPD_G            => TPD_G,
            AXIL_BASE_ADDR_G => XBAR_CFG_C(i+1).baseAddr,
            HYBRID_NUM_G     => HYBRID_NUM_G,
            APV_NUM_G        => i)
         port map (
            sysClk           => sysClk,                    -- [in]
            sysRst           => sysRst,                    -- [in]
            axilReadMaster   => locAxilReadMasters(i+1),   -- [in]
            axilReadSlave    => locAxilReadSlaves(i+1),    -- [out]
            axilWriteMaster  => locAxilWriteMasters(i+1),  -- [in]
            axilWriteSlave   => locAxilWriteSlaves(i+1),   -- [out]
            febConfig        => febConfig,                 -- [in]
            adcReadoutStream => adcReadoutStreams(i),      -- [in]
            trigger          => trigger,                   -- [in]
            syncDetected     => syncDetected(i),           -- [out]
            syncBase         => syncBase(i),               -- [out]
            syncPeak         => syncPeak(i),               -- [out]
            frameCount       => frameCount(i),             -- [out]
            pulseStream      => pulseStream(i),            -- [out]
            minSamples       => minSamples(i),             -- [out]
            maxSamples       => maxSamples(i),             -- [out]
            lostSyncCount    => lostSyncCount(i),          -- [out]
            countReset       => countReset,                -- [in]
            dataOut          => dataOut(i),                -- [out]
            dataRdEn         => dataRdEn(i));              -- [in]


   end generate GEN_PIPELINE;


-------------------------------------------------------------------------------------------------
-- Monitor sync status and output on separate stream
-------------------------------------------------------------------------------------------------
   HybridStatusFramer_1 : entity ldmx.HybridStatusFramer
      generic map (
         TPD_G             => TPD_G,
         HYBRID_NUM_G      => HYBRID_NUM_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         sysClk         => sysClk,
         sysRst         => sysRst,
         febConfig      => febConfig,
         syncDetected   => syncDetected,
         syncBase       => syncBase,
         syncPeak       => syncPeak,
         frameCount     => frameCount,
         pulseStream    => pulseStream,
         minSamples     => minSamples,
         maxSamples     => maxSamples,
         lostSyncCount  => lostSyncCount,
         countReset     => countReset,
         axiReadMaster  => locAxilReadMasters(0),
         axiReadSlave   => locAxilReadSlaves(0),
         axiWriteMaster => locAxilWriteMasters(0),
         axiWriteSlave  => locAxilWriteSlaves(0));

end rtl;

