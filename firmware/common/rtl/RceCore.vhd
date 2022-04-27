 -------------------------------------------------------------------------------
-- Title      : RceCore
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Main data processing module for a DataDpm.
-------------------------------------------------------------------------------
-- This file is part of HPS. It is subject to
-- the license terms in the LICENSE.txt file found in the top-level directory
-- of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of HPS, including this file, may be
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
use surf.SsiPkg.all;


library ldmx;
use ldmx.DataPathPkg.all;
use ldmx.RceConfigPkg.all;
use ldmx.HpsPkg.all;

entity RceCore is

   generic (
      TPD_G             : time                  := 1 ns;
      HYBRIDS_G         : natural range 1 to 12 := 4;
      APVS_PER_HYBRID_G : integer               := 5;
      AXI_BASE_ADDR_G   : slv(31 downto 0)      := X"00000000";
      THRESHOLD_EN_G    : boolean               := true;
      ADF_DEBUG_EN_G    : boolean               := false;  -- ApvDataFormatter Debug
      PACK_APV_DATA_G   : boolean               := true);
   port (
      -- APV frames from each hybrid
      dataClk               : in  sl;
      dataClkRst            : in  sl;
      syncStatuses          : in  slv8Array(HYBRIDS_G-1 downto 0);
      hybridDataAxisMasters : in  AxiStreamQuadMasterArray(HYBRIDS_G-1 downto 0);
      hybridDataAxisSlaves  : out AxiStreamQuadSlaveArray(HYBRIDS_G-1 downto 0);

      -- System clock
      sysClk : in sl;
      sysRst : in sl;

      -- Axi-lite slave interface
      sAxiReadMaster  : in  AxiLiteReadMasterType;
      sAxiReadSlave   : out AxiLiteReadSlaveType;
      sAxiWriteMaster : in  AxiLiteWriteMasterType;
      sAxiWriteSlave  : out AxiLiteWriteSlaveType;

      -- Trigger Interface
      trigger          : in  sl;
      triggerFifoValid : in  sl;
      triggerFifoData  : in  slv(63 downto 0);
      triggerFifoRdEn  : out sl;

      -- Processed event data stream
      eventAxisMaster : out AxiStreamMasterType;
      eventAxisSlave  : in  AxiStreamSlaveType;
      eventAxisCtrl   : in  AxiStreamCtrlType);


end entity RceCore;

architecture rtl of RceCore is

   -------------------------------------------------------------------------------------------------
   -- AXI signals
   -------------------------------------------------------------------------------------------------
   constant AXI_NUM_SLAVES_C  : natural := 1;
   constant AXI_NUM_MASTERS_C : natural := HYBRIDS_G + 2;

   constant CONFIG_AXI_INDEX_C    : natural      := 0;
   constant EB_AXI_INDEX_C        : natural      := 1;
   constant DATA_PATH_AXI_INDEX_C : IntegerArray := list(2, HYBRIDS_G, 1);

   function getDataPathAxiBase (hybrid : natural) return slv is
      variable ret : slv(31 downto 0) := AXI_BASE_ADDR_G;
   begin
      ret(19 downto 16) := toSlv(hybrid+1, 4);
      return ret;
   end function getDataPathAxiBase;

   impure function makeMastersConfig return AxiLiteCrossbarMasterConfigArray is
      variable ret  : AxiLiteCrossbarMasterConfigArray(0 to AXI_NUM_MASTERS_C-1);
      variable base : slv(31 downto 0);
   begin
      ret(0) := (
         baseAddr     => AXI_BASE_ADDR_G,
         addrBits     => 8,
         connectivity => X"0001");
      ret(1) := (
         baseAddr     => AXI_BASE_ADDR_G + X"100",
         addrBits     => 8,
         connectivity => X"0001");
      for i in 0 to HYBRIDS_G-1 loop
         ret(i+2) := (
            baseAddr     => getDataPathAxiBase(i),
            addrBits     => 16,
            connectivity => X"0001");
      end loop;
      return ret;
   end function;

   constant AXI_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray := makeMastersConfig;

   signal locAxiReadMasters  : AxiLiteReadMasterArray(AXI_NUM_MASTERS_C-1 downto 0);
   signal locAxiWriteMasters : AxiLiteWriteMasterArray(AXI_NUM_MASTERS_C-1 downto 0);
   signal locAxiReadSlaves   : AxiLiteReadSlaveArray(AXI_NUM_MASTERS_C-1 downto 0);
   signal locAxiWriteSlaves  : AxiLiteWriteSlaveArray(AXI_NUM_MASTERS_C-1 downto 0);

   signal rceConfig   : RceConfigType;
   signal dataPathOut : DataPathOutArray(HYBRIDS_G-1 downto 0);
   signal dataPathIn  : DataPathInArray(HYBRIDS_G-1 downto 0);

   -- Trigger must be synchronized to local clock


   signal hybridInfo : HybridInfoArray(HYBRIDS_G-1 downto 0);

   -- Resets
   signal dataPipelineRst   : sl;
   signal sysPipelineRst    : sl;
   signal sysPipelineRstTmp : sl;
   signal sysRstLoc         : sl;
begin

   -------------------------------------------------------------------------------------------------
   -- Hold pipeline elements in reset while daqTriggerEn = '0'
   -- These should go into each module and reset everything except the AXI-Lite logic.
   -------------------------------------------------------------------------------------------------
   RstSync_DataPipelineRst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 20)
      port map (
         clk      => dataClk,
         asyncRst => rceConfig.dataPipelineRst,
         syncRst  => dataPipelineRst);

   sysPipelineRstTmp <= sysRst or rceConfig.dataPipelineRst;
   RstSync_SysPipelineRst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         RELEASE_DELAY_G => 5)
      port map (
         clk      => sysClk,
         asyncRst => sysPipelineRstTmp,
         syncRst  => sysPipelineRst);
   sysRstLoc <= sysPipelineRst;

   -------------------------------------------------------------------------------------------------
   -- AxiLite crossbar
   -------------------------------------------------------------------------------------------------
   AxiLiteCrossbar_RceCore : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => AXI_NUM_SLAVES_C,
         NUM_MASTER_SLOTS_G => AXI_NUM_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_MASTERS_CONFIG_C)
      port map (
         axiClk              => sysClk,
         axiClkRst           => sysRst,
         sAxiWriteMasters(0) => sAxiWriteMaster,
         sAxiWriteSlaves(0)  => sAxiWriteSlave,
         sAxiReadMasters(0)  => sAxiReadMaster,
         sAxiReadSlaves(0)   => sAxiReadSlave,
         mAxiWriteMasters    => locAxiWriteMasters,
         mAxiWriteSlaves     => locAxiWriteSlaves,
         mAxiReadMasters     => locAxiReadMasters,
         mAxiReadSlaves      => locAxiReadSlaves);

   RceConfig_1 : entity ldmx.RceConfig
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => sysClk,
         axiClkRst      => sysRst,
         axiReadMaster  => locAxiReadMasters(CONFIG_AXI_INDEX_C),
         axiReadSlave   => locAxiReadSlaves(CONFIG_AXI_INDEX_C),
         axiWriteMaster => locAxiWriteMasters(CONFIG_AXI_INDEX_C),
         axiWriteSlave  => locAxiWriteSlaves(CONFIG_AXI_INDEX_C),
         rceConfig      => rceConfig);



   DATA_PATHS : for i in HYBRIDS_G-1 downto 0 generate

      DataPath_1 : entity ldmx.DataPath
         generic map (
            TPD_G             => TPD_G,
            AXI_BASE_ADDR_G   => getDataPathAxiBase(i),
            THRESHOLD_EN_G    => THRESHOLD_EN_G,
            ADF_DEBUG_EN_G    => ADF_DEBUG_EN_G,
            APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
            PACK_APV_DATA_G   => PACK_APV_DATA_G)
         port map (
            dataClk                    => dataClk,
            dataClkRst                 => dataClkRst,
            dataPipelineRst            => dataPipelineRst,
            hybridApvDataAxisMaster    => hybridDataAxisMasters(i)(APV_PGP_VC_C),
            hybridApvDataAxisSlave     => hybridDataAxisSlaves(i)(APV_PGP_VC_C),
            syncStatus                 => syncStatuses(i)(APVS_PER_HYBRID_G-1 downto 0),
            hybridStatusDataAxisMaster => hybridDataAxisMasters(i)(STATUS_PGP_VC_C),
            hybridStatusDataAxisSlave  => hybridDataAxisSlaves(i) (STATUS_PGP_VC_C),
            sysClk                     => sysClk,
            sysRst                     => sysRst,
            sysPipelineRst             => sysPipelineRst,
            axiReadMaster              => locAxiReadMasters(DATA_PATH_AXI_INDEX_C(i)),
            axiReadSlave               => locAxiReadSlaves(DATA_PATH_AXI_INDEX_C(i)),
            axiWriteMaster             => locAxiWriteMasters(DATA_PATH_AXI_INDEX_C(i)),
            axiWriteSlave              => locAxiWriteSlaves(DATA_PATH_AXI_INDEX_C(i)),
            trigger                    => trigger,
            rceConfig                  => rceConfig,
            hybridInfo                 => hybridInfo(i),
            dataOut                    => dataPathOut(i)(APVS_PER_HYBRID_G-1 downto 0),
            dataRdEn                   => dataPathIn(i)(APVS_PER_HYBRID_G-1 downto 0));
   end generate DATA_PATHS;

   EventBuilder_1 : entity ldmx.EventBuilder
      generic map (
         TPD_G             => TPD_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         sysClk           => sysClk,
         sysRst           => sysRst,
         sysPipelineRst   => sysPipelineRst,
         axiReadMaster    => locAxiReadMasters(EB_AXI_INDEX_C),
         axiReadSlave     => locAxiReadSlaves(EB_AXI_INDEX_C),
         axiWriteMaster   => locAxiWriteMasters(EB_AXI_INDEX_C),
         axiWriteSlave    => locAxiWriteSlaves(EB_AXI_INDEX_C),
         trigger          => trigger,
         triggerFifoValid => triggerFifoValid,
         triggerFifoData  => triggerFifoData,
         triggerFifoRdEn  => triggerFifoRdEn,
         rceConfig        => rceConfig,
         dataPathOut      => dataPathOut,
         dataPathIn       => dataPathIn,
         eventAxisMaster  => eventAxisMaster,
         eventAxisSlave   => eventAxisSlave,
         eventAxisCtrl    => eventAxisCtrl);



end architecture rtl;
