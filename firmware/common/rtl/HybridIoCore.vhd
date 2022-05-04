-------------------------------------------------------------------------------
-- Title      : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.I2cPkg.all;
--use surf.Ad9249Pkg.all;

library ldmx;
use ldmx.AdcReadoutPkg.all;

entity HybridIoCore is

   generic (
      TPD_G             : time                 := 1 ns;
      SIMULATION_G      : boolean              := false;
      FPGA_ARCH_G       : string               := "artix-us+";
      APVS_PER_HYBRID_G : integer range 4 to 6 := 4;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := X"00100000";
      IODELAY_GROUP_G   : string               := "IDELAYCTRL0");

   port (
      axilClk : in sl;
      axilRst : in sl;

      -- Slave interface 
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- External Interface to ADC Readout
      adcClkRst : in sl;
      adcChip   : in AdcChipOutType;

      -- AdcReadout
      adcReadoutStreams : out AxiStreamMasterArray(APVS_PER_HYBRID_G-1 downto 0);

      -- External Adc Config Interface
      adcSclk : out   sl;
      adcSdio : inout sl;
      adcCsb  : out   sl;

      -- External Hybrid I2C Interface
      hyI2cIn  : in  i2c_in_type;
      hyI2cOut : out i2c_out_type
      );

end entity HybridIoCore;

architecture rtl of HybridIoCore is
   attribute keep_hierarchy        : string;
   attribute keep_hierarchy of rtl : architecture is "yes";

   -------------------------------------------------------------------------------------------------
   -- Axi Crossbar Constants and signals
   -------------------------------------------------------------------------------------------------
   constant AXI_ADC_READOUT_INDEX_C : natural := 0;
   constant AXI_ADC_CONFIG_INDEX_C  : natural := 1;
   constant AXI_HYBRID_I2C_INDEX_C  : natural := 2;
   constant AXI_ADS1115_INDEX_C     : natural := 3;

   constant AXI_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray := (
      AXI_ADC_READOUT_INDEX_C => (                           -- Adc Readout Config       
         baseAddr             => AXI_BASE_ADDR_G + X"0000",  -- to X"00FF"
         addrBits             => 8,
         connectivity         => X"0001"),
      AXI_ADC_CONFIG_INDEX_C  => (                           -- Adc Config         
         baseAddr             => AXI_BASE_ADDR_G + X"0400",  -- to X"07FF"
         addrBits             => 10,
         connectivity         => X"0001"),
      AXI_HYBRID_I2C_INDEX_C  => (                           -- APV I2C  
         baseAddr             => AXI_BASE_ADDR_G + X"8000",  -- to X"9FFF"
         addrBits             => 13,
         connectivity         => X"0001"),
      AXI_ADS1115_INDEX_C     => (                           -- ADS1115 I2C
         baseAddr             => AXI_BASE_ADDR_G + X"A000",  -- to X"A07F"
         addrBits             => 8,
         connectivity         => X"0001"));

   signal mAxiWriteMasters : AxiLiteWriteMasterArray(3 downto 0);
   signal mAxiWriteSlaves  : AxiLiteWriteSlaveArray(3 downto 0);
   signal mAxiReadMasters  : AxiLiteReadMasterArray(3 downto 0);
   signal mAxiReadSlaves   : AxiLiteReadSlaveArray(3 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Reg Master I2C Bridge Constants and signals
   -------------------------------------------------------------------------------------------------
   constant AXI_I2C_BRIDGE_CONFIG_C : I2cAxiLiteDevArray := (
      0              => (               -- APV0
         i2cAddress  => "0000110111",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '0',
         repeatStart => '0'),
      1              => (               -- APV1
         i2cAddress  => "0000110110",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '0',
         repeatStart => '0'),
      2              => (               -- APV2
         i2cAddress  => "0000110101",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '0',
         repeatStart => '0'),
      3              => (               -- APV3
         i2cAddress  => "0000110100",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '0',
         repeatStart => '0'),
      4              => (               -- APV4
         i2cAddress  => "0000110011",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '0',
         repeatStart => '0'),
      5              => (               -- APV4
         i2cAddress  => "0000110001",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '0',
         repeatStart => '0'),
      6              => (               -- ADS7924
         i2cAddress  => "0001001000",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'));

   signal i2cRegMastersIn  : I2cRegMasterInArray(1 downto 0);
   signal i2cRegMastersOut : I2cRegMasterOutArray(1 downto 0);
   signal i2cRegMasterIn   : I2cRegMasterInType;
   signal i2cRegMasterOut  : I2cRegMasterOutType;

   signal dummy : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- Crossbar connecting all internal components
   -------------------------------------------------------------------------------------------------
   HybridAxiCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 4,
         MASTERS_CONFIG_G   => AXI_MASTERS_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => mAxiWriteMasters,
         mAxiWriteSlaves     => mAxiWriteSlaves,
         mAxiReadMasters     => mAxiReadMasters,
         mAxiReadSlaves      => mAxiReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- ADC Readout
   -------------------------------------------------------------------------------------------------
   AdcReadout_1 : entity ldmx.AdcReadout
      generic map (
         TPD_G           => TPD_G,
         SIMULATION_G    => SIMULATION_G,
         FPGA_ARCH_G     => FPGA_ARCH_G,
         NUM_CHANNELS_G  => APVS_PER_HYBRID_G,
         IODELAY_GROUP_G => IODELAY_GROUP_G)
      port map (
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilWriteMaster => mAxiWriteMasters(AXI_ADC_READOUT_INDEX_C),
         axilWriteSlave  => mAxiWriteSlaves(AXI_ADC_READOUT_INDEX_C),
         axilReadMaster  => mAxiReadMasters(AXI_ADC_READOUT_INDEX_C),
         axilReadSlave   => mAxiReadSlaves(AXI_ADC_READOUT_INDEX_C),
         adcClkRst       => adcClkRst,
         adc             => adcChip,
         adcStreamClk    => axilClk,
         adcStreams      => adcReadoutStreams);

   ----------------------------------------------------------------------------------------------
   -- AdcConfig Module
   ----------------------------------------------------------------------------------------------
   -- This is wrong, need 1 of these for every 2 hybrids
   U_AdcConfig_1 : entity ldmx.AdcConfig
      generic map (
         TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,                                   -- [in]
         axiRst         => axilRst,                                   -- [in]
         axiReadMaster  => mAxiReadMasters(AXI_ADC_CONFIG_INDEX_C),   -- [in]
         axiReadSlave   => mAxiReadSlaves(AXI_ADC_CONFIG_INDEX_C),    -- [out]
         axiWriteMaster => mAxiWriteMasters(AXI_ADC_CONFIG_INDEX_C),  -- [in]
         axiWriteSlave  => mAxiWriteSlaves(AXI_ADC_CONFIG_INDEX_C),   -- [out]
--         adcPdwn        => open,                                      -- [out]
         adcSclk        => adcSclk,                                   -- [out]
         adcSdio        => adcSdio,                                   -- [inout]
         adcCsb         => adcCsb);                                   -- [out]



   ----------------------------------------------------------------------------------------------
   -- I2C Interface to hybrid is shared between 2 AXI Slaves
   -- First is for APV config and (on old hybrids) temp ADC
   -- Second is for new hybrids with ADS1115 ADC for temp and far end voltage monitoring
   ----------------------------------------------------------------------------------------------
   -- Axi Bridge for APVs and ADS7924
   I2cRegMasterAxiBridge_1 : entity surf.I2cRegMasterAxiBridge
      generic map (
         TPD_G        => TPD_G,
         DEVICE_MAP_G => AXI_I2C_BRIDGE_CONFIG_C)
      port map (
         axiClk          => axilClk,
         axiRst          => axilRst,
         axiReadMaster   => mAxiReadMasters(AXI_HYBRID_I2C_INDEX_C),
         axiReadSlave    => mAxiReadSlaves(AXI_HYBRID_I2C_INDEX_C),
         axiWriteMaster  => mAxiWriteMasters(AXI_HYBRID_I2C_INDEX_C),
         axiWriteSlave   => mAxiWriteSlaves(AXI_HYBRID_I2C_INDEX_C),
         i2cRegMasterIn  => i2cRegMastersIn(0),
         i2cRegMasterOut => i2cRegMastersOut(0));

   -- Axi Bridge for ADS1115
   Ads1115AxiBridge_1 : entity ldmx.Ads1115AxiBridge
      generic map (
         TPD_G          => TPD_G,
         I2C_DEV_ADDR_C => "1001000")
      port map (
         axiClk          => axilClk,
         axiRst          => axilRst,
         axiReadMaster   => mAxiReadMasters(AXI_ADS1115_INDEX_C),
         axiReadSlave    => mAxiReadSlaves(AXI_ADS1115_INDEX_C),
         axiWriteMaster  => mAxiWriteMasters(AXI_ADS1115_INDEX_C),
         axiWriteSlave   => mAxiWriteSlaves(AXI_ADS1115_INDEX_C),
         i2cRegMasterIn  => i2cRegMastersIn(1),
         i2cRegMasterOut => i2cRegMastersOut(1));

   -- Multiplexes 2 I2cRegMasterAxiBridges onto on I2cRegMaster
   I2cRegMasterMux_1 : entity surf.I2cRegMasterMux
      generic map (
         TPD_G        => TPD_G,
         NUM_INPUTS_C => 2)
      port map (
         clk       => axilClk,
         srst      => axilRst,
         regIn     => i2cRegMastersIn,
         regOut    => i2cRegMastersOut,
         masterIn  => i2cRegMasterIn,
         masterOut => i2cRegMasterOut);

   -- Finally, the I2cRegMaster
   i2cRegMaster_HybridConfig : entity surf.i2cRegMaster
      generic map (
         TPD_G                => TPD_G,
         OUTPUT_EN_POLARITY_G => 1,
         FILTER_G             => ite(SIMULATION_G, 2, 8),
         PRESCALE_G           => ite(SIMULATION_G, 8, 249))  -- 100 kHz (Simulation faster)
      port map (
         clk    => axilClk,
         srst   => axilRst,
         regIn  => i2cRegMasterIn,
         regOut => i2cRegMasterOut,
         i2ci   => hyI2cIn,
         i2co   => hyI2cOut);

end architecture rtl;










