-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
library UNISIM;
use UNISIM.VCOMPONENTS.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.I2cPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;
--use surf.Ad9249Pkg.all;


library ldmx;
use ldmx.FebConfigPkg.all;
use ldmx.HpsPkg.all;
use ldmx.DataPathPkg.all;
use ldmx.AdcReadoutPkg.all;

entity FebCore is

   generic (
      TPD_G             : time                 := 1 ns;
      BUILD_INFO_G      : BuildInfoType        := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G      : boolean              := false;
      HYBRIDS_G         : integer range 1 to 8 := 8;
      APVS_PER_HYBRID_G : integer range 1 to 8 := 6;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := X"00000000");

   port (
      -- Recovered Clock and Opcode Interface
      daqClk185  : in sl;
      daqRst185  : in sl;
      daqFcWord  : in slv(79 downto 0);
      daqFcValid : in sl;

      -- Axi Clock and Reset
      axilClk : in sl;
      axilRst : in sl;

      -- Slave Interface to AXI Crossbar
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;

      -- Processed event data stream
      eventAxisMaster : out AxiStreamMasterType;
      eventAxisSlave  : in  AxiStreamSlaveType;
      eventAxisCtrl   : in  AxiStreamCtrlType;

      -- Hybrid power control
      hyPwrEn : out slv(HYBRIDS_G-1 downto 0);

      -- Hybrid CLK, TRG and RST
      hyTrgOut  : out slv(HYBRIDS_G-1 downto 0);
      hyRstOutL : out slv(HYBRIDS_G-1 downto 0);

      -- Hybrid I2C Interfaces
      hyI2cIn  : in  i2c_in_array(HYBRIDS_G-1 downto 0);
      hyI2cOut : out i2c_out_array(HYBRIDS_G-1 downto 0);

      -- 37Mhz clock
      daqClk37    : out sl;
      daqClk37Rst : out sl;
      hyClk       : in  slv(HYBRIDS_G-1 downto 0) := (others => '0');
      hyClkRst    : in  slv(HYBRIDS_G-1 downto 0) := (others => '0');

      -- ADC streams
      adcReadoutStreams : in AdcStreamArray
      );
end entity FebCore;

architecture rtl of FebCore is


   -------------------------------------------------------------------------------------------------
   -- Recovered Clock & Opcode Signals
   -------------------------------------------------------------------------------------------------
   signal daqClkLost : sl;
   signal daqTrigger : sl;
   signal hySoftRst  : slv(HYBRIDS_G-1 downto 0);
   signal hyRstL     : slv(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AXI Crossbar configuration and signals
   -------------------------------------------------------------------------------------------------
   -- Module AXI Addresses
   constant MAIN_XBAR_NUM_MASTERS_C : natural := 6;
   constant AXI_VERSION_INDEX_C     : natural := 0;
   constant AXI_CONFIG_REGS_INDEX_C : natural := 1;
   constant AXI_DAQ_TIMING_INDEX_C  : natural := 2;
   constant AXI_EB_INDEX_C          : natural := 3;
   constant AXI_HYBRID_I2C_INDEX_C  : natural := 4;
   constant AXI_HYBRID_DATA_INDEX_C : natural := 5;



   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0) := (
      AXI_VERSION_INDEX_C     => (
         baseAddr             => AXI_BASE_ADDR_G + X"0000",
         addrBits             => 12,
         connectivity         => X"0001"),
      AXI_CONFIG_REGS_INDEX_C => (      -- General Configuration Registers
         baseAddr             => AXI_BASE_ADDR_G + X"1000",
         addrBits             => 8,     -- to 00FF
         connectivity         => X"0001"),
      AXI_DAQ_TIMING_INDEX_C  => (
         baseAddr             => AXI_BASE_ADDR_G + X"2000",
         addrBits             => 8,
         connectivity         => X"0001"),
      AXI_EB_INDEX_C          => (
         baseAddr             => AXI_BASE_ADDR_G + X"3000",
         addrBits             => 8,
         connectivity         => X"0001"),
      AXI_HYBRID_I2C_INDEX_C  => (
         baseAddr             => AXI_BASE_ADDR_G + X"00100000",
         addrBits             => 20,
         connectivity         => X"0001"),
      AXI_HYBRID_DATA_INDEX_C => (
         baseAddr             => AXI_BASE_ADDR_G + X"01000000",
         addrBits             => 24,
         connectivity         => X"0001"));

   signal mainAxilWriteMasters : AxiLiteWriteMasterArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mainAxilWriteSlaves  : AxiLiteWriteSlaveArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal mainAxilReadMasters  : AxiLiteReadMasterArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mainAxilReadSlaves   : AxiLiteReadSlaveArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);


   constant HYBRID_I2C_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(HYBRIDS_G, MAIN_XBAR_CFG_C(AXI_HYBRID_I2C_INDEX_C).baseAddr, 20, 16);

   signal hybridI2cAxilWriteMasters : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal hybridI2cAxilWriteSlaves  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal hybridI2cAxilReadMasters  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal hybridI2cAxilReadSlaves   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   constant HYBRID_DATA_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(HYBRIDS_G, MAIN_XBAR_CFG_C(AXI_HYBRID_DATA_INDEX_C).baseAddr, 24, 20);

   signal hybridDataAxilWriteMasters : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal hybridDataAxilWriteSlaves  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal hybridDataAxilReadMasters  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal hybridDataAxilReadSlaves   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   -------------------------------------------------------------------------------------------------
   -- Main Regs IO
   -------------------------------------------------------------------------------------------------
   signal febConfig : FebConfigType;

   -------------------------------------------------------------------------------------------------
   -- Trigger FIFO signal
   -------------------------------------------------------------------------------------------------
   signal trigger          : sl;
   signal triggerFifoValid : sl;
   signal triggerFifoData  : slv(63 downto 0);
   signal triggerFifoRdEn  : sl;

   signal daqFcWordLong : slv(9 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Data path outputs
   -------------------------------------------------------------------------------------------------
   signal dataPathOut : DataPathOutArray(HYBRIDS_G-1 downto 0);
   signal dataPathIn  : DataPathInArray(HYBRIDS_G-1 downto 0);


begin

   -------------------------------------------------------------------------------------------------
   -- Create trigger FIFO
   -------------------------------------------------------------------------------------------------
   U_TriggerFifo_1 : entity ldmx.TriggerFifo
      generic map (
         TPD_G => TPD_G)
      port map (
         distClk    => daqClk185,         -- [in]
         distClkRst => daqRst185,         -- [in]
         rxData     => daqFcWord(9 downto 0),     -- [in]
         rxDataEn   => daqFcValid,        -- [in]
         sysClk     => axilClk,           -- [in]
         sysRst     => axilRst,           -- [in]
         trigger    => trigger,           -- [out]
         valid      => triggerFifoValid,  -- [out]
         data       => triggerFifoData,   -- [out]
         rdEn       => triggerFifoRdEn);  -- [in]


   -------------------------------------------------------------------------------------------------
   -- Main Axi Crossbar
   -------------------------------------------------------------------------------------------------
   HpsAxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => MAIN_XBAR_NUM_MASTERS_C,
         MASTERS_CONFIG_G   => MAIN_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => sAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave,
         mAxiWriteMasters    => mainAxilWriteMasters,
         mAxiWriteSlaves     => mainAxilWriteSlaves,
         mAxiReadMasters     => mainAxilReadMasters,
         mAxiReadSlaves      => mainAxilReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- Put version info on AXI Bus
   -------------------------------------------------------------------------------------------------
   AxiVersion_1 : entity surf.AxiVersion
      generic map (
         TPD_G           => TPD_G,
         BUILD_INFO_G    => BUILD_INFO_G,
         DEVICE_ID_G     => X"FEB00000",
         EN_DEVICE_DNA_G => true,
         EN_DS2411_G     => false,
         EN_ICAP_G       => true)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => mainAxilReadMasters(AXI_VERSION_INDEX_C),
         axiReadSlave   => mainAxilReadSlaves(AXI_VERSION_INDEX_C),
         axiWriteMaster => mainAxilWriteMasters(AXI_VERSION_INDEX_C),
         axiWriteSlave  => mainAxilWriteSlaves(AXI_VERSION_INDEX_C),
         fpgaReload     => open,
         fpgaReloadAddr => open,
         fdSerSdio      => open);

   -------------------------------------------------------------------------------------------------
   -- Generate APV clock from distributed DAQ clock
   -- Use Pgp FC bus to to control phase alignment
   -- Also use FC bus for triggers and resets
   -------------------------------------------------------------------------------------------------
   DaqTiming_1 : entity ldmx.DaqTiming
      generic map (
         TPD_G         => TPD_G,
         HYBRIDS_G     => HYBRIDS_G)
      port map (
         daqClk185      => daqClk185,
         daqRst185      => daqRst185,
         daqFcWord      => daqFcWord(7 downto 0),
         daqFcValid     => daqFcValid,
         daqClk37       => daqClk37,
         daqClk37Rst    => daqClk37Rst,
         daqTrigger     => daqTrigger,
         hySoftRst      => hySoftRst,
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => mainAxilReadMasters(AXI_DAQ_TIMING_INDEX_C),
         axiReadSlave   => mainAxilReadSlaves(AXI_DAQ_TIMING_INDEX_C),
         axiWriteMaster => mainAxilWriteMasters(AXI_DAQ_TIMING_INDEX_C),
         axiWriteSlave  => mainAxilWriteSlaves(AXI_DAQ_TIMING_INDEX_C));

   -------------------------------------------------------------------------------------------------
   -- General configuration Registers
   -------------------------------------------------------------------------------------------------
   FebConfig_1 : entity ldmx.FebConfig
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => mainAxilReadMasters(AXI_CONFIG_REGS_INDEX_C),
         axiReadSlave   => mainAxilReadSlaves(AXI_CONFIG_REGS_INDEX_C),
         axiWriteMaster => mainAxilWriteMasters(AXI_CONFIG_REGS_INDEX_C),
         axiWriteSlave  => mainAxilWriteSlaves(AXI_CONFIG_REGS_INDEX_C),
         febConfig      => febConfig);

   hyPwrEn <= febConfig.hyPwrEn(HYBRIDS_G-1 downto 0);






   -------------------------------------------------------------------------------------------------
   -- Create crossbars for mdoules below
   -------------------------------------------------------------------------------------------------
   HYBRID_I2C_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
         MASTERS_CONFIG_G   => HYBRID_I2C_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXI_HYBRID_I2C_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXI_HYBRID_I2C_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXI_HYBRID_I2C_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXI_HYBRID_I2C_INDEX_C),
         mAxiWriteMasters    => hybridI2cAxilWriteMasters,
         mAxiWriteSlaves     => hybridI2cAxilWriteSlaves,
         mAxiReadMasters     => hybridI2cAxilReadMasters,
         mAxiReadSlaves      => hybridI2cAxilReadSlaves);

   HYBRID_DATA_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
         MASTERS_CONFIG_G   => HYBRID_DATA_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXI_HYBRID_DATA_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXI_HYBRID_DATA_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXI_HYBRID_DATA_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXI_HYBRID_DATA_INDEX_C),
         mAxiWriteMasters    => hybridDataAxilWriteMasters,
         mAxiWriteSlaves     => hybridDataAxilWriteSlaves,
         mAxiReadMasters     => hybridDataAxilReadMasters,
         mAxiReadSlaves      => hybridDataAxilReadSlaves);


   -------------------------------------------------------------------------------------------------
   -- Create modules to support each hybrid
   -------------------------------------------------------------------------------------------------
   HYBRIDS_GEN : for i in HYBRIDS_G-1 downto 0 generate
      ----------------------------------------------------------------------------------------------
      -- Synchronize Hybrid Hard Resets to each hybrid clock
      ----------------------------------------------------------------------------------------------
      PwrUpRst_1 : entity surf.PwrUpRst
         generic map (
            TPD_G          => TPD_G,
            SIM_SPEEDUP_G  => SIMULATION_G,
            IN_POLARITY_G  => '1',
            OUT_POLARITY_G => '0',
            DURATION_G     => 4166666)
         port map (
            arst   => febConfig.hyHardRst(i),
            clk    => hyClk(i),
            rstOut => hyRstL(i));

      hyRstOutL(i) <= hyRstL(i);

      ----------------------------------------------------------------------------------------------
      -- Generate triggers that are synced to each hybrid clock
      ----------------------------------------------------------------------------------------------
      TrigControl_1 : entity ldmx.TrigControl
         generic map (
            TPD_G => TPD_G)
         port map (
            axiClk     => axilClk,
            axiRst     => axilRst,
            febConfig  => febConfig,
            daqTrigger => daqTrigger,
            hySoftRst  => hySoftRst(i),
            hyClk      => hyClk(i),
            hyClkRst   => hyClkRst(i),
            hyTrigOut  => hyTrgOut(i));

      -------------------------------------------------------------------------------------------------
      -- Hybrid IO Core
      -------------------------------------------------------------------------------------------------
      HybridIoCore_1 : entity ldmx.HybridI2c
         generic map (
            TPD_G           => TPD_G,
            SIMULATION_G    => SIMULATION_G,
            AXIL_BASE_ADDR_G => HYBRID_I2C_XBAR_CFG_C(i).baseAddr)
         port map (
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => hybridI2cAxilReadMasters(i),
            axilReadSlave   => hybridI2cAxilReadSlaves(i),
            axilWriteMaster => hybridI2cAxilWriteMasters(i),
            axilWriteSlave  => hybridI2cAxilWriteSlaves(i),
            hyI2cIn         => hyI2cIn(i),
            hyI2cOut        => hyI2cOut(i));


      ----------------------------------------------------------------------------------------------
      -- Hybrid Data core
      ----------------------------------------------------------------------------------------------
      HybridDataCore_1 : entity ldmx.HybridDataCore
         generic map (
            TPD_G             => TPD_G,
            AXIL_BASE_ADDR_G  => HYBRID_DATA_XBAR_CFG_C(i).baseAddr,
            HYBRID_NUM_G      => i,
            APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
         port map (
            sysClk            => axilClk,
            sysRst            => axilRst,
            axiReadMaster     => hybridDataAxilReadMasters(i),
            axiReadSlave      => hybridDataAxilReadSlaves(i),
            axiWriteMaster    => hybridDataAxilWriteMasters(i),
            axiWriteSlave     => hybridDataAxilWriteSlaves(i),
            febConfig         => febConfig,
            trigger           => trigger,
            adcReadoutStreams => adcReadoutStreams(i)(APVS_PER_HYBRID_G-1 downto 0),
            dataOut           => dataPathOut(i)(APVS_PER_HYBRID_G-1 downto 0),
            dataRdEn          => dataPathIn(i)(APVS_PER_HYBRID_G-1 downto 0));
   end generate;

   EventBuilder_1 : entity ldmx.EventBuilder
      generic map (
         TPD_G             => TPD_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         sysClk           => axilClk,
         sysRst           => axilRst,
         axiReadMaster    => mainAxilReadMasters(AXI_EB_INDEX_C),
         axiReadSlave     => mainAxilReadSlaves(AXI_EB_INDEX_C),
         axiWriteMaster   => mainAxilWriteMasters(AXI_EB_INDEX_C),
         axiWriteSlave    => mainAxilWriteSlaves(AXI_EB_INDEX_C),
         trigger          => trigger,
         triggerFifoValid => triggerFifoValid,
         triggerFifoData  => triggerFifoData,
         triggerFifoRdEn  => triggerFifoRdEn,
         febConfig        => febConfig,
         dataPathOut      => dataPathOut,
         dataPathIn       => dataPathIn,
         eventAxisMaster  => eventAxisMaster,
         eventAxisSlave   => eventAxisSlave,
         eventAxisCtrl    => eventAxisCtrl);



end architecture rtl;
