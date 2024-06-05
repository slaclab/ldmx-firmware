-------------------------------------------------------------------------------
-- Title      : LDMX FEB Hardware
-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-- Platform   : 
-- Standard   : VHDL'08
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

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.I2cPkg.all;
use surf.Ad9249Pkg.all;

library ldmx_tracker;
use ldmx_tracker.LdmxPkg.all;

entity LdmxFebHw is

   generic (
      TPD_G             : time                 := 1 ns;
      BUILD_INFO_G      : BuildInfoType        := BUILD_INFO_DEFAULT_SLV_C;
      SIMULATION_G      : boolean              := false;
      XIL_DEVICE_G      : string               := "ULTRASCALE_PLUS";
      ADCS_G            : integer range 1 to 4 := 4;
      HYBRIDS_G         : integer range 1 to 8 := 8;
      APVS_PER_HYBRID_G : integer range 1 to 8 := 6;
      AXIL_CLK_FREQ_G   : real                 := 125.0e6;
      AXIL_BASE_ADDR_G  : slv(31 downto 0)     := X"00000000");
   port (
      ----------------------------------------------------------------------------------------------
      -- FPGA IO pins
      ----------------------------------------------------------------------------------------------
      -- ADC DDR Interface 
      adcFClkP : in slv(HYBRIDS_G-1 downto 0);
      adcFClkN : in slv(HYBRIDS_G-1 downto 0);
      adcDClkP : in slv(HYBRIDS_G-1 downto 0);
      adcDClkN : in slv(HYBRIDS_G-1 downto 0);
      adcDataP : in slv6Array(HYBRIDS_G-1 downto 0);
      adcDataN : in slv6Array(HYBRIDS_G-1 downto 0);

      -- ADC Clock
      adcClkP : out slv(ADCS_G-1 downto 0);  -- 37 MHz clock to ADC
      adcClkN : out slv(ADCS_G-1 downto 0);

      -- ADC Config Interface
      adcCsb  : out   slv(ADCS_G*2-1 downto 0);
      adcSclk : out   slv(ADCS_G-1 downto 0);
      adcSdio : inout slv(ADCS_G-1 downto 0);
      adcPdwn : out   slv(ADCS_G-1 downto 0);

      -- I2C Interfaces
      locI2cScl : inout sl;
      locI2cSda : inout sl;

      sfpI2cScl : inout sl;
      sfpI2cSda : inout sl;

      qsfpI2cScl    : inout sl;
      qsfpI2cSda    : inout sl;
      qsfpI2cResetL : inout sl := '1';

      digPmBusScl    : inout sl;
      digPmBusSda    : inout sl;
      digPmBusAlertL : in    sl;

      anaPmBusScl    : inout sl;
      anaPmBusSda    : inout sl;
      anaPmBusAlertL : in    sl;

      hyPwrI2cScl : inout slv(HYBRIDS_G-1 downto 0);
      hyPwrI2cSda : inout slv(HYBRIDS_G-1 downto 0);

      hyPwrEnOut : out slv(HYBRIDS_G-1 downto 0);

      -- Interface to Hybrids
      hyClkP      : out slv(HYBRIDS_G-1 downto 0);
      hyClkN      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgP      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgN      : out slv(HYBRIDS_G-1 downto 0);
      hyRstL      : out slv(HYBRIDS_G-1 downto 0);
      hyI2cScl    : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaOut : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaIn  : in  slv(HYBRIDS_G-1 downto 0);

      vauxp : in slv(3 downto 0);
      vauxn : in slv(3 downto 0);

      leds : out slv(7 downto 0);       -- Test outputs

      ----------------------------------------------------------------------------------------------
      -- FebCore and application ports
      ----------------------------------------------------------------------------------------------
      -- Axi Clock and Reset
      axilClk : in sl;
      axilRst : in sl;

      -- Slave Interface to AXI Crossbar
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;

      -- Hybrid power control
      hyPwrEn : in slv(HYBRIDS_G-1 downto 0);

      -- Hybrid CLK, TRG and RST
      hyTrgOut  : in slv(HYBRIDS_G-1 downto 0);
      hyRstOutL : in slv(HYBRIDS_G-1 downto 0);

      -- Hybrid I2C Interfaces
      hyI2cIn  : out i2c_in_array(HYBRIDS_G-1 downto 0);
      hyI2cOut : in  i2c_out_array(HYBRIDS_G-1 downto 0);

      -- ADC streams
      adcReadoutStreams : out AdcStreamArray := ADC_STREAM_ARRAY_INIT_C;

      -- Waveform capture stream
      waveformAxisMaster : out AxiStreamMasterType;
      waveformAxisSlave  : in  AxiStreamSlaveType;

      -- 37Mhz clock
      fcClk37    : in  sl;
      fcClk37Rst : in  sl;
      hyClk      : out slv(HYBRIDS_G-1 downto 0) := (others => '0');
      hyClkRst   : out slv(HYBRIDS_G-1 downto 0) := (others => '0'));

end entity LdmxFebHw;

architecture rtl of LdmxFebHw is
   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------
   constant AXIL_CLK_FREQ_C : real := 1.0/AXIL_CLK_FREQ_G;

   constant MAIN_XBAR_MASTERS_C : natural := 15;

   -- Module AXI Addresses
   constant AXIL_VERSION_INDEX_C              : natural := 0;
   constant AXIL_HYBRID_A_CLOCK_PHASE_INDEX_C : natural := 1;
   constant AXIL_HYBRID_B_CLOCK_PHASE_INDEX_C : natural := 2;
   constant AXIL_ADC_CLOCK_PHASE_INDEX_C      : natural := 3;
   constant AXIL_LOC_I2C_INDEX_C              : natural := 4;
   constant AXIL_SFP_I2C_INDEX_C              : natural := 5;
   constant AXIL_QSFP_I2C_INDEX_C             : natural := 6;
   constant AXIL_SYSMON_INDEX_C               : natural := 7;
   constant AXIL_PROM_INDEX_C                 : natural := 8;
   constant AXIL_HY_PWR_I2C_INDEX_C           : natural := 9;
   constant AXIL_DIG_PM_INDEX_C               : natural := 10;
   constant AXIL_ANA_PM_INDEX_C               : natural := 11;
   constant AXIL_ADC_READOUT_INDEX_C          : natural := 12;
   constant AXIL_ADC_CONFIG_INDEX_C           : natural := 13;
   constant AXIL_WAVEFORM_INDEX_C             : natural := 14;

   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(MAIN_XBAR_MASTERS_C-1 downto 0) := (
      AXIL_VERSION_INDEX_C              => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"0000",
         addrBits                       => 12,
         connectivity                   => X"0001"),
      AXIL_HYBRID_A_CLOCK_PHASE_INDEX_C => (    -- Hybrid (APV) Clock Phase Adjustment
         baseAddr                       => AXIL_BASE_ADDR_G + X"1000",
         addrBits                       => 9,
         connectivity                   => X"0001"),
      AXIL_HYBRID_B_CLOCK_PHASE_INDEX_C => (    -- Hybrid (APV) Clock Phase Adjustment
         baseAddr                       => AXIL_BASE_ADDR_G + X"2000",
         addrBits                       => 9,
         connectivity                   => X"0001"),
      AXIL_ADC_CLOCK_PHASE_INDEX_C      => (    -- ADC Clock Phase Adjustment
         baseAddr                       => AXIL_BASE_ADDR_G + X"3000",
         addrBits                       => 9,
         connectivity                   => X"0001"),
      AXIL_SFP_I2C_INDEX_C              => (    -- Board I2C Interface
         baseAddr                       => AXIL_BASE_ADDR_G + X"4000",
         addrBits                       => 12,
         connectivity                   => X"0001"),
      AXIL_QSFP_I2C_INDEX_C             => (    -- Board I2C Interface
         baseAddr                       => AXIL_BASE_ADDR_G + X"5000",
         addrBits                       => 12,
         connectivity                   => X"0001"),
      AXIL_PROM_INDEX_C                 => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"6000",
         addrBits                       => 10,
         connectivity                   => X"0001"),
      AXIL_WAVEFORM_INDEX_C             => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"7000",
         addrBits                       => 8,
         connectivity                   => X"0001"),
      AXIL_SYSMON_INDEX_C               => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"1_0000",
         addrBits                       => 13,
         connectivity                   => X"0001"),
      AXIL_HY_PWR_I2C_INDEX_C           => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"2_0000",
         addrBits                       => 16,
         connectivity                   => X"0001"),
      AXIL_DIG_PM_INDEX_C               => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"3_0000",
         addrBits                       => 16,  -- Might be 14 but this is fine
         connectivity                   => X"0001"),
      AXIL_ANA_PM_INDEX_C               => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"4_0000",
         addrBits                       => 16,  -- Probably less than 12
         connectivity                   => X"0001"),
      AXIL_ADC_READOUT_INDEX_C          => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"5_0000",
         addrBits                       => 12,
         connectivity                   => X"0001"),
      AXIL_ADC_CONFIG_INDEX_C           => (
         baseAddr                       => AXIL_BASE_ADDR_G + X"6_0000",
         addrBits                       => 16,
         connectivity                   => X"0001"),
      AXIL_LOC_I2C_INDEX_C              => (    -- Board I2C Interface
         baseAddr                       => AXIL_BASE_ADDR_G + X"10_0000",
         addrBits                       => 20,
         connectivity                   => X"0001"));

--       SEM_AXIL_INDEX_C      => (
--          baseAddr          => SEM_AXIL_BASE_ADDR_G,
--          addrBits          => 8,
--          connectivity      => X"0001"));

   signal mainAxilWriteMasters : AxiLiteWriteMasterArray(MAIN_XBAR_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mainAxilWriteSlaves  : AxiLiteWriteSlaveArray(MAIN_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal mainAxilReadMasters  : AxiLiteReadMasterArray(MAIN_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mainAxilReadSlaves   : AxiLiteReadSlaveArray(MAIN_XBAR_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   constant ADC_READOUT_AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(ADCS_G*2, MAIN_XBAR_CFG_C(AXIL_ADC_READOUT_INDEX_C).baseAddr, 12, 8);

   signal adcReadoutAxilWriteMasters : AxiLiteWriteMasterArray(ADCS_G*2-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal adcReadoutAxilWriteSlaves  : AxiLiteWriteSlaveArray(ADCS_G*2-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal adcReadoutAxilReadMasters  : AxiLiteReadMasterArray(ADCS_G*2-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal adcReadoutAxilReadSlaves   : AxiLiteReadSlaveArray(ADCS_G*2-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   constant ADC_CONFIG_AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(ADCS_G, MAIN_XBAR_CFG_C(AXIL_ADC_CONFIG_INDEX_C).baseAddr, 16, 13);

   signal adcConfigAxilWriteMasters : AxiLiteWriteMasterArray(ADCS_G-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal adcConfigAxilWriteSlaves  : AxiLiteWriteSlaveArray(ADCS_G-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal adcConfigAxilReadMasters  : AxiLiteReadMasterArray(ADCS_G-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal adcConfigAxilReadSlaves   : AxiLiteReadSlaveArray(ADCS_G-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   -- I2C 
   constant I2C_SCL_FREQ_C  : real := ite(SIMULATION_G, 2.0e6, 100.0E+3);
   constant I2C_MIN_PULSE_C : real := ite(SIMULATION_G, 50.0e-9, 100.0E-9);

   -- ADC
   constant ADC_SCLK_PERIOD_C : real := ite(SIMULATION_G, 50.0e-9, 1.0e-6);

   signal adcSerial            : Ad9249SerialGroupArray(HYBRIDS_G-1 downto 0);
   signal adcReadoutStreamsInt : AdcStreamArray;

   signal hyClkInt    : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal hyClkRstInt : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal adcClk      : slv(ADCS_G-1 downto 0)    := (others => '0');
   signal adcClkRst   : slv(ADCS_G-1 downto 0)    := (others => '0');
   signal hyPwrEnL    : slv(HYBRIDS_G-1 downto 0);


begin

   -------------------------------------------------------------------------------------------------
   -- Main Axi Crossbar
   -------------------------------------------------------------------------------------------------
   HpsAxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => MAIN_XBAR_MASTERS_C,
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

   AdcReadoutCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => ADCS_G*2,
         MASTERS_CONFIG_G   => ADC_READOUT_AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXIL_ADC_READOUT_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXIL_ADC_READOUT_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXIL_ADC_READOUT_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXIL_ADC_READOUT_INDEX_C),
         mAxiWriteMasters    => adcReadoutAxilWriteMasters,
         mAxiWriteSlaves     => adcReadoutAxilWriteSlaves,
         mAxiReadMasters     => adcReadoutAxilReadMasters,
         mAxiReadSlaves      => adcReadoutAxilReadSlaves);

   AdcConfigCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => ADCS_G,
         MASTERS_CONFIG_G   => ADC_CONFIG_AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXIL_ADC_CONFIG_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXIL_ADC_CONFIG_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXIL_ADC_CONFIG_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXIL_ADC_CONFIG_INDEX_C),
         mAxiWriteMasters    => adcConfigAxilWriteMasters,
         mAxiWriteSlaves     => adcConfigAxilWriteSlaves,
         mAxiReadMasters     => adcConfigAxilReadMasters,
         mAxiReadSlaves      => adcConfigAxilReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- Put version info on AXI Bus
   -------------------------------------------------------------------------------------------------
   AxiVersion_1 : entity surf.AxiVersion
      generic map (
         TPD_G           => TPD_G,
         BUILD_INFO_G    => BUILD_INFO_G,
         DEVICE_ID_G     => X"FEB00000",
         XIL_DEVICE_G    => XIL_DEVICE_G,
         EN_DEVICE_DNA_G => true,
         EN_DS2411_G     => false,
         EN_ICAP_G       => true)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => mainAxilReadMasters(AXIL_VERSION_INDEX_C),
         axiReadSlave   => mainAxilReadSlaves(AXIL_VERSION_INDEX_C),
         axiWriteMaster => mainAxilWriteMasters(AXIL_VERSION_INDEX_C),
         axiWriteSlave  => mainAxilWriteSlaves(AXIL_VERSION_INDEX_C),
         fpgaReload     => open,
         fpgaReloadAddr => open,
         fdSerSdio      => open);



   -------------------------------------------------------------------------------------------------
   -- Clock Phase Shifts
   -------------------------------------------------------------------------------------------------
   U_ClockManagerUltraScale_HY_A : entity surf.ClockManagerUltraScale
      generic map (
         TPD_G              => TPD_G,
         SIMULATION_G       => false,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 4,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 26.923,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 32.0,
--         CLKFBOUT_MULT_G        => CLKFBOUT_MULT_G,
         CLKOUT0_DIVIDE_F_G => 32.0,
--         CLKOUT0_DIVIDE_G       => CLKOUT0_DIVIDE_G,
         CLKOUT1_DIVIDE_G   => 32,
         CLKOUT2_DIVIDE_G   => 32,
         CLKOUT3_DIVIDE_G   => 32)
      port map (
         clkIn           => fcClk37,                                                  -- [in]
         rstIn           => fcClk37Rst,                                               -- [in]
         clkOut          => hyClkInt(3 downto 0),                                     -- [out]
         rstOut          => hyClkRstInt(3 downto 0),                                  -- [out]
         axilClk         => axilClk,                                                  -- [in]
         axilRst         => axilRst,                                                  -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_HYBRID_A_CLOCK_PHASE_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_HYBRID_A_CLOCK_PHASE_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_HYBRID_A_CLOCK_PHASE_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_HYBRID_A_CLOCK_PHASE_INDEX_C));  -- [out]

   U_ClockManagerUltraScale_HY_B : entity surf.ClockManagerUltraScale
      generic map (
         TPD_G              => TPD_G,
         SIMULATION_G       => false,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 4,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 26.923,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 32.0,
--         CLKFBOUT_MULT_G        => CLKFBOUT_MULT_G,
         CLKOUT0_DIVIDE_F_G => 32.0,
--         CLKOUT0_DIVIDE_G       => CLKOUT0_DIVIDE_G,
         CLKOUT1_DIVIDE_G   => 32,
         CLKOUT2_DIVIDE_G   => 32,
         CLKOUT3_DIVIDE_G   => 32)
      port map (
         clkIn           => fcClk37,                                                  -- [in]
         rstIn           => fcClk37Rst,                                               -- [in]
         clkOut          => hyClkInt(7 downto 4),                                     -- [out]
         rstOut          => hyClkRstInt(7 downto 4),                                  -- [out]
         axilClk         => axilClk,                                                  -- [in]
         axilRst         => axilRst,                                                  -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_HYBRID_B_CLOCK_PHASE_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_HYBRID_B_CLOCK_PHASE_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_HYBRID_B_CLOCK_PHASE_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_HYBRID_B_CLOCK_PHASE_INDEX_C));  -- [out]

   -- Assign to outputs for FebCore
   hyClk    <= hyClkInt;
   hyClkRst <= hyClkRstInt;


   U_ClockManagerUltraScale_ADC : entity surf.ClockManagerUltraScale
      generic map (
         TPD_G              => TPD_G,
         SIMULATION_G       => false,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         NUM_CLOCKS_G       => 4,
         BANDWIDTH_G        => "OPTIMIZED",
         CLKIN_PERIOD_G     => 26.923,
         DIVCLK_DIVIDE_G    => 1,
         CLKFBOUT_MULT_F_G  => 32.0,
--         CLKFBOUT_MULT_G        => CLKFBOUT_MULT_G,
         CLKOUT0_DIVIDE_F_G => 32.0,
--         CLKOUT0_DIVIDE_G       => CLKOUT0_DIVIDE_G,
         CLKOUT1_DIVIDE_G   => 32,
         CLKOUT2_DIVIDE_G   => 32,
         CLKOUT3_DIVIDE_G   => 32)
      port map (
         clkIn           => fcClk37,                                             -- [in]
         rstIn           => fcClk37Rst,                                          -- [in]
         clkOut          => adcClk,                                              -- [out]
         rstOut          => adcClkRst,                                           -- [out]
         axilClk         => axilClk,                                             -- [in]
         axilRst         => axilRst,                                             -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_ADC_CLOCK_PHASE_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_ADC_CLOCK_PHASE_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_ADC_CLOCK_PHASE_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_ADC_CLOCK_PHASE_INDEX_C));  -- [out]


   -------------------------------------------------------------------------------------------------
   -- Local I2C
   -------------------------------------------------------------------------------------------------
   U_AxiI2cRegMaster_LOC : entity surf.AxiI2cRegMaster
      generic map (
         TPD_G             => TPD_G,
         AXIL_PROXY_G      => false,
         DEVICE_MAP_G      => (
            0              => MakeI2cAxiLiteDevType(                    -- 24FC64F EEPROM
               i2cAddress  => "1010100",
               dataSize    => 8,
               addrSize    => 16,
               endianness  => '1'),
            1              => MakeI2cAxiLiteDevType(                    -- PCAL6524 AMP PD 0-3
               i2cAddress  => "0100010",
               dataSize    => 8,
               addrSize    => 8,
               endianness  => '1',
               repeatStart => '0'),
            2              => MakeI2cAxiLiteDevType(                    -- PCAL6524 AMP PD 4-7
               i2cAddress  => "0100011",
               dataSize    => 8,
               addrSize    => 8,
               endianness  => '1',
               repeatStart => '0')),
         I2C_SCL_FREQ_G    => I2C_SCL_FREQ_C,
         I2C_MIN_PULSE_G   => I2C_MIN_PULSE_C,
         AXI_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
         axiClk         => axilClk,                                     -- [in]
         axiRst         => axilRst,                                     -- [in]
         axiReadMaster  => mainAxilReadMasters(AXIL_LOC_I2C_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXIL_LOC_I2C_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXIL_LOC_I2C_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXIL_LOC_I2C_INDEX_C),   -- [out]
--         sel            => sel,             -- [out]
         scl            => locI2cScl,                                   -- [inout]
         sda            => locI2cSda);                                  -- [inout]

   -------------------------------------------------------------------------------------------------
   -- SFP I2C
   -------------------------------------------------------------------------------------------------
   U_Sff8472_SFP : entity surf.Sff8472
      generic map (
         TPD_G           => TPD_G,
         I2C_SCL_FREQ_G  => I2C_SCL_FREQ_C,
         I2C_MIN_PULSE_G => I2C_MIN_PULSE_C,
         AXI_CLK_FREQ_G  => AXIL_CLK_FREQ_G)
      port map (
         scl             => sfpI2cScl,                                   -- [inout]
         sda             => sfpI2cSda,                                   -- [inout]
         axilReadMaster  => mainAxilReadMasters(AXIL_SFP_I2C_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_SFP_I2C_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_SFP_I2C_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_SFP_I2C_INDEX_C),   -- [out]
         axilClk         => axilClk,                                     -- [in]
         axilRst         => axilRst);                                    -- [in]

   -------------------------------------------------------------------------------------------------
   -- SFP I2C
   -------------------------------------------------------------------------------------------------
   U_Sff8472_QSFP : entity surf.Sff8472
      generic map (
         TPD_G           => TPD_G,
         I2C_SCL_FREQ_G  => I2C_SCL_FREQ_C,
         I2C_MIN_PULSE_G => I2C_MIN_PULSE_C,
         AXI_CLK_FREQ_G  => AXIL_CLK_FREQ_G)
      port map (
         scl             => qsfpI2cScl,                                   -- [inout]
         sda             => qsfpI2cSda,                                   -- [inout]
         axilReadMaster  => mainAxilReadMasters(AXIL_QSFP_I2C_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_QSFP_I2C_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_QSFP_I2C_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_QSFP_I2C_INDEX_C),   -- [out]
         axilClk         => axilClk,                                      -- [in]
         axilRst         => axilRst);                                     -- [in]


   -------------------------------------------------------------------------------------------------
   -- Hybrid Power Monitor and Trim
   -------------------------------------------------------------------------------------------------
   U_LdmxHybridPowerI2C_1 : entity ldmx_tracker.LdmxHybridPowerI2cArray
      generic map (
         TPD_G            => TPD_G,
         HYBRIDS_G        => HYBRIDS_G,
         I2C_SCL_FREQ_G   => I2C_SCL_FREQ_C,
         I2C_MIN_PULSE_G  => I2C_MIN_PULSE_C,
         AXIL_BASE_ADDR_G => MAIN_XBAR_CFG_C(AXIL_HY_PWR_I2C_INDEX_C).baseAddr,
         AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G)
      port map (
         axilClk         => axilClk,                                        -- [in]
         axilRst         => axilRst,                                        -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_HY_PWR_I2C_INDEX_C),   -- [out]
         axilReadSlave   => mainAxilReadSlaves(AXIL_HY_PWR_I2C_INDEX_C),    -- [in]
         axilWriteMaster => mainAxilWriteMasters(AXIL_HY_PWR_I2C_INDEX_C),  -- [out]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_HY_PWR_I2C_INDEX_C),   -- [in]
         scl             => hyPwrI2cScl,                                    -- [inout]
         sda             => hyPwrI2cSda);                                   -- [inout]


   -------------------------------------------------------------------------------------------------
   -- Digital PM Bus
   -------------------------------------------------------------------------------------------------
   U_AxiI2cRegMaster_DIG_PM : entity surf.AxiI2cRegMaster
      generic map (
         TPD_G             => TPD_G,
         AXIL_PROXY_G      => false,
         DEVICE_MAP_G      => (
            0              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100000",                               -- LT3815 0.85V VCCINT
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            1              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100001",                               -- LT3815 1.8V VCCAUX
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            2              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100010",                               -- LT3815 0.90V MGTAVCC
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            3              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100011",                               -- LT3815 1.2V MGTAVTT
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            4              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100100",                               -- LT3815 1.8V MGTVCAUX
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            5              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100101",                               -- LT3815 2.5V VCCO
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            6              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100111",                               -- LT3815 3.3V VCCO
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            7              => MakeI2cAxiLiteDevType(                   -- LTC2991 voltage monitor
               i2cAddress  => "1001000",
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '1')),
         I2C_SCL_FREQ_G    => I2C_SCL_FREQ_C,
         I2C_MIN_PULSE_G   => I2C_MIN_PULSE_C,
         AXI_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
         axiClk         => axilClk,                                    -- [in]
         axiRst         => axilRst,                                    -- [in]
         axiReadMaster  => mainAxilReadMasters(AXIL_DIG_PM_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXIL_DIG_PM_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXIL_DIG_PM_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXIL_DIG_PM_INDEX_C),   -- [out]
--         sel            => sel,             -- [out]
         scl            => digPmBusScl,                                -- [inout]
         sda            => digPmBusSda);                               -- [inout]

   -------------------------------------------------------------------------------------------------
   -- Analog PM Bus
   -------------------------------------------------------------------------------------------------
   U_AxiI2cRegMaster_ANA_PM : entity surf.AxiI2cRegMaster
      generic map (
         TPD_G             => TPD_G,
         AXIL_PROXY_G      => false,
         DEVICE_MAP_G      => (
            0              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100000",  -- LT3815 2.2V 
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1'),
            1              => MakeI2cAxiLiteDevType(
               i2cAddress  => "0100001",  -- LT3815 2.8V Hybrid Intermediate
               dataSize    => 16,
               addrSize    => 8,
               endianness  => '0',
               repeatStart => '1')),
         I2C_SCL_FREQ_G    => I2C_SCL_FREQ_C,
         I2C_MIN_PULSE_G   => I2C_MIN_PULSE_C,
         AXI_CLK_FREQ_G    => AXIL_CLK_FREQ_G)
      port map (
         axiClk         => axilClk,     -- [in]
         axiRst         => axilRst,     -- [in]
         axiReadMaster  => mainAxilReadMasters(AXIL_ANA_PM_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXIL_ANA_PM_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXIL_ANA_PM_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXIL_ANA_PM_INDEX_C),   -- [out]
--         sel            => sel,             -- [out]
         scl            => anaPmBusScl,   -- [inout]
         sda            => anaPmBusSda);  -- [inout]

   -------------------------------------------------------------------------------------------------
   -- SYSMON
   -------------------------------------------------------------------------------------------------
   U_LdmxFebSysmonWrapper_1 : entity ldmx_tracker.LdmxFebSysmonWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         axilClk         => axilClk,                                    -- [in]
         axilRst         => axilRst,                                    -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_SYSMON_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_SYSMON_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_SYSMON_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_SYSMON_INDEX_C),   -- [out]
         vauxp           => vauxp,                                      -- [in]
         vauxn           => vauxn);                                     -- [in]


   -------------------------------------------------------------------------------------------------
   -- FLASH Interface
   -------------------------------------------------------------------------------------------------
   U_LdmxFebBootProm_1 : entity ldmx_tracker.LdmxFebBootProm
      generic map (
         TPD_G           => TPD_G,
         AXIL_CLK_FREQ_G => AXIL_CLK_FREQ_G,
         SPI_CLK_FREQ_G  => (AXIL_CLK_FREQ_G/12.0))
      port map (
         axilClk         => axilClk,                                  -- [in]
         axilRst         => axilRst,                                  -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_PROM_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_PROM_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_PROM_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_PROM_INDEX_C));  -- [out]

   -------------------------------------------------------------------------------------------------
   -- ADC Readout 
   -------------------------------------------------------------------------------------------------
   ADC_READOUT_MAP : for i in ADCS_G*2-1 downto 0 generate
      U_Ad9249ReadoutGroup2_1 : entity surf.Ad9249ReadoutGroup2
         generic map (
            TPD_G          => TPD_G,
            SIM_DEVICE_G   => "ULTRASCALE_PLUS",
            NUM_CHANNELS_G => APVS_PER_HYBRID_G,
            SIMULATION_G   => SIMULATION_G)
         port map (
            axilClk         => axilClk,                                                 -- [in]
            axilRst         => axilRst,                                                 -- [in]
            axilWriteMaster => adcReadoutAxilWriteMasters(i),                           -- [in]
            axilWriteSlave  => adcReadoutAxilWriteSlaves(i),                            -- [out]
            axilReadMaster  => adcReadoutAxilReadMasters(i),                            -- [in]
            axilReadSlave   => adcReadoutAxilReadSlaves(i),                             -- [out]
            adcClkRst       => adcClkRst(i/2),                                          -- [in]
            adcSerial       => adcSerial(i),                                            -- [in]
            adcStreamClk    => axilClk,                                                 -- [in]
            adcStreams      => adcReadoutStreamsInt(i)(APVS_PER_HYBRID_G-1 downto 0));  -- [out]

      -- IO Assignment to records      
      adcSerial(i).fClkP <= adcFClkP(i);
      adcSerial(i).fClkN <= adcFClkN(i);
      adcSerial(i).dClkP <= adcDClkP(i);
      adcSerial(i).dClkN <= adcDClkN(i);
      adcSerial(i).chP   <= "00" & adcDataP(i);
      adcSerial(i).chN   <= "00" & adcDataN(i);
   end generate;
   adcReadoutStreams <= adcReadoutStreamsInt;

   -------------------------------------------------------------------------------------------------
   -- ADC Waveform capture
   -------------------------------------------------------------------------------------------------
   U_WaveformCapture_1 : entity ldmx_tracker.WaveformCapture
      generic map (
         TPD_G             => TPD_G,
         HYBRIDS_G         => HYBRIDS_G,
         APVS_PER_HYBRID_G => APVS_PER_HYBRID_G)
      port map (
         axilClk         => axilClk,                                      -- [in]
         axilRst         => axilRst,                                      -- [in]
         axilReadMaster  => mainAxilReadMasters(AXIL_WAVEFORM_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXIL_WAVEFORM_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXIL_WAVEFORM_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXIL_WAVEFORM_INDEX_C),   -- [out]
         adcStreams      => adcReadoutStreamsInt,                         -- [in]
         axisMaster      => waveformAxisMaster,                           -- [out]
         axisSlave       => waveformAxisSlave);                           -- [in]

   -------------------------------------------------------------------------------------------------
   -- ADC Config
   -------------------------------------------------------------------------------------------------
   ADC_CONFIG_MAP : for i in ADCS_G-1 downto 0 generate
      U_Ad9249Config_1 : entity surf.Ad9249Config
         generic map (
            TPD_G             => TPD_G,
            NUM_CHIPS_G       => 1,
            SCLK_PERIOD_G     => ADC_SCLK_PERIOD_C,
            AXIL_CLK_PERIOD_G => 1.0/AXIL_CLK_FREQ_G)
         port map (
            axilClk         => axilClk,                       -- [in]
            axilRst         => axilRst,                       -- [in]
            axilReadMaster  => adcConfigAxilReadMasters(i),   -- [in]
            axilReadSlave   => adcConfigAxilReadSlaves(i),    -- [out]
            axilWriteMaster => adcConfigAxilWriteMasters(i),  -- [in]
            axilWriteSlave  => adcConfigAxilWriteSlaves(i),   -- [out]
            adcPdwn(0)      => adcPdwn(i),                    -- [out]
            adcSclk         => adcSclk(i),                    -- [out]
            adcSdio         => adcSdio(i),                    -- [inout]
            adcCsb          => adcCsb(i*2+1 downto i*2));     -- [out]
   end generate ADC_CONFIG_MAP;

   -------------------------------------------------------------------------------------------------
   -- Hybrid I2C drivers
   -- Board has special I2C buffers needed to drive APV25 I2C, so do this wierd thing
   -- Output enable signals are active high
   -------------------------------------------------------------------------------------------------
   HY_I2C_DRIVERS : for i in HYBRIDS_G-1 downto 0 generate
      hyI2cIn(i).scl <= hyI2cOut(i).scl when hyI2cOut(i).scloen = '1' else '1';
      hyI2cIn(i).sda <= to_x01z(hyI2cSdaIn(i));
      hyI2cSdaOut(i) <= hyI2cOut(i).sdaoen;
      hyI2cScl(i)    <= hyI2cOut(i).scloen;
   end generate HY_I2C_DRIVERS;

   -------------------------------------------------------------------------------------------------
   -- IO Buffers for Shifted hybrid and ADC clocks, and triggers
   -------------------------------------------------------------------------------------------------
   HY_DIFF_BUFF_GEN : for i in HYBRIDS_G-1 downto 0 generate
      hyRstL(i)     <= hyRstOutL(i) when hyPwrEn(i) = '1' else 'Z';
      hyPwrEnL(i)   <= not hyPwrEn(i);
      hyPwrEnOut(i) <= hyPwrEn(i);

      HY_TRG_BUFF_DIFF : OBUFTDS
         port map (
            I  => hyTrgOut(i),
            T  => hyPwrEnL(i),
            O  => hyTrgP(i),
            OB => hyTrgN(i));

      HY_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
         generic map (
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            outEnL  => hyPwrEnL(i),
            clkIn   => hyClkInt(i),
            clkOutP => hyClkP(i),
            clkOutN => hyClkN(i));
   end generate;

   ADC_DIFF_BUFF_GEN : for i in ADCS_G-1 downto 0 generate
      ADC_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
         generic map (
            XIL_DEVICE_G => "ULTRASCALE_PLUS")
         port map (
            clkIn   => adcClk(i),
            clkOutP => adcClkP(i),
            clkOutN => adcClkN(i));
   end generate;


end architecture rtl;
