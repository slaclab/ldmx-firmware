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
      SIMULATION_G      : boolean              := false;
      FPGA_ARCH_G       : string               := "artix-us+";
      HYBRIDS_G         : integer range 1 to 8 := 8;
      APVS_PER_HYBRID_G : integer range 1 to 8 := 6;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := X"00000000");  -- 21 bits of address space used

   port (
      -- Recovered Clock and Opcode Interface
      daqClk      : in sl;
      daqRst      : in sl;
      daqFcWord   : in slv(7 downto 0);
      daqFcValid : in sl;

      -- Axi Clock and Reset
      axilClk : in sl;
      axilRst : in sl;

      -- Slave Interface to AXI Crossbar
      extAxilWriteMaster : in  AxiLiteWriteMasterType;
      extAxilWriteSlave  : out AxiLiteWriteSlaveType;
      extAxilReadMaster  : in  AxiLiteReadMasterType;
      extAxilReadSlave   : out AxiLiteReadSlaveType;

      -- ADC Data Interface 
      adcChips  : in  AdcChipOutArray(HYBRIDS_G-1 downto 0);
      adcClkOut : out slv(HYBRIDS_G-1 downto 0);

      -- Processed event data stream
      eventAxisMaster : out AxiStreamMasterType;
      eventAxisSlave  : in  AxiStreamSlaveType;
      eventAxisCtrl   : in  AxiStreamCtrlType;

      -- ADC Config Interface
      adcCsb  : out   slv(HYBRIDS_G-1 downto 0);
      adcSclk : out   slv(HYBRIDS_G-1 downto 0);
      adcSdio : inout slv(HYBRIDS_G-1 downto 0);

      -- Amplifier powerdown I2C
      ampI2cScl : inout sl;
      ampI2cSda : inout sl;

      -- Board I2C Interface
      boardI2cIn  : in  i2c_in_type;
      boardI2cOut : out i2c_out_type;

      -- Board SPI Interface
      boardSpiSclk : out sl;
      boardSpiSdi  : out sl;
      boardSpiSdo  : in  sl;
      boardSpiCsL  : out slv(4 downto 0);

      -- Hybrid power control
      hyPwrEn : out slv(HYBRIDS_G-1 downto 0);

      -- Hybrid CLK, TRG and RST
      hyClkOut  : out slv(HYBRIDS_G-1 downto 0);
      hyTrgOut  : out slv(HYBRIDS_G-1 downto 0);
      hyRstOutL : out slv(HYBRIDS_G-1 downto 0);

      -- Hybrid I2C Interfaces
      hyI2cIn  : in  i2c_in_array(HYBRIDS_G-1 downto 0);
      hyI2cOut : out i2c_out_array(HYBRIDS_G-1 downto 0);

      -- XADC Interface
      vPIn : in sl;
      vNIn : in sl;
      vAuxP : in slv(15 downto 0);
      vAuxN : in slv(15 downto 0);

      powerGood : in PowerGoodType;

      ledEn : out sl);

end entity FebCore;

architecture rtl of FebCore is

   attribute keep_hierarchy        : string;
   attribute keep_hierarchy of rtl : architecture is "yes";


   -------------------------------------------------------------------------------------------------
   -- Recovered Clock & Opcode Signals
   -------------------------------------------------------------------------------------------------
   signal daqClkLost   : sl;
   signal daqClkDiv    : sl;
   signal daqClkDivRst : sl;
   signal daqTrigger   : sl;
   signal hySoftRst    : slv(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- AXI Crossbar configuration and signals
   -------------------------------------------------------------------------------------------------
   constant AXI_CROSSBAR_NUM_SLAVES_C : natural := 1;

   -- Module AXI Addresses
   constant AXI_CONFIG_REGS_INDEX_C        : natural := 0;
   constant AXI_HYBRID_CLOCK_PHASE_INDEX_C : natural := 1;
   constant AXI_ADC_CLOCK_PHASE_INDEX_C    : natural := 2;
   constant AXI_BOARD_I2C_INDEX_C          : natural := 3;
   constant AXI_BOARD_SPI_INDEX_C          : natural := 4;
   constant AXI_XADC_INDEX_C               : natural := 5;
   constant AXI_DAQ_TIMING_INDEX_C         : natural := 6;
   constant AXI_AMP_I2C_INDEX_C            : natural := 7;
   constant AXI_EB_INDEX_C                 : natural := 8;
   constant AXI_HYBRID_IO_INDEX_C          : natural := 9;
   constant AXI_HYBRID_DATA_INDEX_C        : natural := 10;


   constant MAIN_XBAR_NUM_MASTERS_C : natural := 11;

   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0) := (
      AXI_CONFIG_REGS_INDEX_C        => (    -- General Configuration Registers
         baseAddr                    => AXI_BASE_ADDR_G + X"0000",
         addrBits                    => 8,   -- to 00FF
         connectivity                => X"0001"),
      AXI_HYBRID_CLOCK_PHASE_INDEX_C => (    -- Hybrid (APV) Clock Phase Adjustment
         baseAddr                    => AXI_BASE_ADDR_G + X"1000",
         addrBits                    => 12,  -- to 01FF
         connectivity                => X"0001"),
      AXI_ADC_CLOCK_PHASE_INDEX_C    => (    -- ADC Clock Phase Adjustment
         baseAddr                    => AXI_BASE_ADDR_G + X"2000",
         addrBits                    => 12,  -- to 02FF
         connectivity                => X"0001"),
      AXI_BOARD_I2C_INDEX_C          => (    -- Board I2C Interface
         baseAddr                    => AXI_BASE_ADDR_G + X"3000",
         addrBits                    => 12,  -- 3FFF
         connectivity                => X"0003"),
      AXI_BOARD_SPI_INDEX_C          => (    -- Board SPI Interface
         baseAddr                    => AXI_BASE_ADDR_G + X"4000",
         addrBits                    => 12,  -- 9FFF
         connectivity                => X"0003"),
      AXI_XADC_INDEX_C               => (
         baseAddr                    => AXI_BASE_ADDR_G + X"5000",
         addrBits                    => 12,  -- to 4FFF
         connectivity                => X"0003"),
      AXI_DAQ_TIMING_INDEX_C         => (
         baseAddr                    => AXI_BASE_ADDR_G + X"6000",
         addrBits                    => 8,
         connectivity                => X"0001"),
      AXI_AMP_I2C_INDEX_C            => (
         baseAddr                    => AXI_BASE_ADDR_G + X"7000",
         addrBits                    => 8,
         connectivity                => X"0001"),
      AXI_EB_INDEX_C                 => (
         baseAddr                    => AXI_BASE_ADDR_G + X"8000",
         addrBits                    => 8,
         connectivity                => X"0001"),
      AXI_HYBRID_IO_INDEX_C          => (
         baseAddr                    => AXI_BASE_ADDR_G + X"00100000",
         addrBits                    => 20,
         connectivity                => X"0001"),
      AXI_HYBRID_DATA_INDEX_C        => (
         baseAddr                    => AXI_BASE_ADDR_G + X"01000000",
         addrBits                    => 24,
         connectivity                => X"0001"));

   signal mainAxilWriteMasters : AxiLiteWriteMasterArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mainAxilWriteSlaves  : AxiLiteWriteSlaveArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal mainAxilReadMasters  : AxiLiteReadMasterArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mainAxilReadSlaves   : AxiLiteReadSlaveArray(MAIN_XBAR_NUM_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);


   constant HYBRID_IO_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(HYBRIDS_G, MAIN_XBAR_CFG_C(AXI_HYBRID_IO_INDEX_C).baseAddr, 20, 16);

   signal hybridIoAxilWriteMasters : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal hybridIoAxilWriteSlaves  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal hybridIoAxilReadMasters  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal hybridIoAxilReadSlaves   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

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
   -- Hybrid and ADC Shifted Clocks and thier resets
   -------------------------------------------------------------------------------------------------
   signal hyClk     : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal hyClkRst  : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal adcClk    : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal adcClkRst : slv(HYBRIDS_G-1 downto 0) := (others => '0');

   signal hyRstL : slv(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Board I2C Constants and Signals
   -------------------------------------------------------------------------------------------------
   constant BOARD_I2C_DEV_MAP_C : I2cAxiLiteDevArray := (
      0              => (               -- LTC2991_0
         i2cAddress  => "0001001000",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'),
      1              => (               -- LTC2991_1
         i2cAddress  => "0001001001",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'),
      2              => (               -- LTC2991_2
         i2cAddress  => "0001001010",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'),
      3              => (               -- LTC2991_3
         i2cAddress  => "0001001011",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'),
      4              => (               -- LTC2991_4
         i2cAddress  => "0001001100",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'));

   signal boardI2cRegMasterIn  : I2cRegMasterInType;
   signal boardI2cRegMasterOut : I2cRegMasterOutType;

   -------------------------------------------------------------------------------------------------
   -- AdcReadout Signals
   -------------------------------------------------------------------------------------------------
   type AdcStreamArray is array (natural range <>) of AxiStreamMasterArray(APVS_PER_HYBRID_G-1 downto 0);

   signal adcReadoutStreams : AdcStreamArray(HYBRIDS_G-1 downto 0);

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


   constant AMP_I2C_DEV_MAP_C : I2cAxiLiteDevArray := (
      0              => (               -- LTC2991_0
         i2cAddress  => "0000100010",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'));



begin

   ledEn <= febConfig.ledEn;

   -------------------------------------------------------------------------------------------------
   -- Create trigger FIFO
   -------------------------------------------------------------------------------------------------
   daqFcWordLong <= "00" & daqFcWord;
   U_TriggerFifo_1 : entity ldmx.TriggerFifo
      generic map (
         TPD_G => TPD_G)
      port map (
         distClk    => daqClk,            -- [in]
         distClkRst => daqRst,            -- [in]
         rxData     => daqFcWordLong,     -- [in]
         rxDataEn   => daqFcValid,       -- [in]
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
         sAxiWriteMasters(0) => extAxilWriteMaster,
         sAxiWriteSlaves(0)  => extAxilWriteSlave,
         sAxiReadMasters(0)  => extAxilReadMaster,
         sAxiReadSlaves(0)   => extAxilReadSlave,
         mAxiWriteMasters    => mainAxilWriteMasters,
         mAxiWriteSlaves     => mainAxilWriteSlaves,
         mAxiReadMasters     => mainAxilReadMasters,
         mAxiReadSlaves      => mainAxilReadSlaves);

   -------------------------------------------------------------------------------------------------
   -- Generate APV clock from distributed DAQ clock
   -- Use Pgp FC bus to to control phase alignment
   -- Also use FC bus for triggers and resets
   -------------------------------------------------------------------------------------------------
   DaqTiming_1 : entity ldmx.DaqTiming
      generic map (
         TPD_G         => TPD_G,
         DAQ_CLK_DIV_G => 5,
         HYBRIDS_G     => HYBRIDS_G)
      port map (
         daqClk         => daqClk,
         daqRst         => daqRst,
         daqFcWord      => daqFcWord,
         daqFcValid     => daqFcValid,
         daqClkDiv     => daqClkDiv,
         daqClkDivRst  => daqClkDivRst,
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
         powerGood      => powerGood,
         febConfig      => febConfig);

   hyPwrEn <= febConfig.hyPwrEn(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Hybrid Clocks Phase Shift
   -------------------------------------------------------------------------------------------------
   -- Need output endable for hybrid clocks gated by hybrid power
   U_ClockPhaseShifter_HYBRIDS : entity ldmx.ClockPhaseShifter
      generic map (
         TPD_G           => TPD_G,
         NUM_OUTCLOCKS_G => HYBRIDS_G,
         CLKIN_PERIOD_G  => 26.923,
         DIVCLK_DIVIDE_G => 1,
         CLKFBOUT_MULT_G => 27,
         CLKOUT_DIVIDE_G => 27)
      port map (
         axiClk         => axilClk,                                                -- [in]
         axiRst         => axilRst,                                                -- [in]
         axiReadMaster  => mainAxilReadMasters(AXI_HYBRID_CLOCK_PHASE_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXI_HYBRID_CLOCK_PHASE_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXI_HYBRID_CLOCK_PHASE_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXI_HYBRID_CLOCK_PHASE_INDEX_C),   -- [out]
         refClk         => daqClkDiv,                                             -- [in]
         refClkRst      => daqClkDivRst,                                         -- [in]
         clkOut         => hyClk,                                                 -- [out]
         rstOut         => hyClkRst);                                             -- [out]

   U_ClockPhaseShifter_ADCS : entity ldmx.ClockPhaseShifter
      generic map (
         TPD_G           => TPD_G,
         NUM_OUTCLOCKS_G => HYBRIDS_G,
         CLKIN_PERIOD_G  => 26.923,
         DIVCLK_DIVIDE_G => 1,
         CLKFBOUT_MULT_G => 27,
         CLKOUT_DIVIDE_G => 27)
      port map (
         axiClk         => axilClk,                                             -- [in]
         axiRst         => axilRst,                                             -- [in]
         axiReadMaster  => mainAxilReadMasters(AXI_ADC_CLOCK_PHASE_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXI_ADC_CLOCK_PHASE_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXI_ADC_CLOCK_PHASE_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXI_ADC_CLOCK_PHASE_INDEX_C),   -- [out]
         refClk         => daqClkDiv,                                          -- [in]
         refClkRst      => daqClkDivRst,                                      -- [in]
         clkOut         => adcClk,                                             -- [out]
         rstOut         => adcClkRst);                                         -- [out]

   adcClkOut <= adcClk(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------
   -- Amplifier Powerdown I2C
   -------------------------------------------------------------------------------------------
   U_AxiI2cRegMaster_Amp : entity surf.AxiI2cRegMaster
      generic map (
         TPD_G           => TPD_G,
         DEVICE_MAP_G    => AMP_I2C_DEV_MAP_C,
         I2C_SCL_FREQ_G  => ite(SIMULATION_G, 50.0E+5, 100.0E+3),
         I2C_MIN_PULSE_G => ite(SIMULATION_G, 10.0E-9, 100.0E-9),
         AXI_CLK_FREQ_G  => 125.0E+6)
      port map (
         axiClk         => axilClk,                                    -- [in]
         axiRst         => axilRst,                                    -- [in]
         axiReadMaster  => mainAxilReadMasters(AXI_AMP_I2C_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXI_AMP_I2C_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXI_AMP_I2C_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXI_AMP_I2C_INDEX_C),   -- [out]
         scl            => ampI2cScl,                                  -- [inout]
         sda            => ampI2cSda);                                 -- [inout]


   -------------------------------------------------------------------------------------------------
   -- Hybrid Current and Near End Voltage
   -- Board I2C
   -------------------------------------------------------------------------------------------------
   -- Axi Bridge to I2cRegSlave
   BoardI2cAxiBridge : entity surf.I2cRegMasterAxiBridge
      generic map (
         TPD_G        => TPD_G,
         DEVICE_MAP_G => BOARD_I2C_DEV_MAP_C)
      port map (
         axiClk          => axilClk,
         axiRst          => axilRst,
         axiReadMaster   => mainAxilReadMasters(AXI_BOARD_I2C_INDEX_C),
         axiReadSlave    => mainAxilReadSlaves(AXI_BOARD_I2C_INDEX_C),
         axiWriteMaster  => mainAxilWriteMasters(AXI_BOARD_I2C_INDEX_C),
         axiWriteSlave   => mainAxilWriteSlaves(AXI_BOARD_I2C_INDEX_C),
         i2cRegMasterIn  => boardI2cRegMasterIn,
         i2cRegMasterOut => boardI2cRegMasterOut);

   BoardI2cRegMaster : entity surf.I2cRegMaster
      generic map (
         TPD_G                => TPD_G,
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => ite(SIMULATION_G, 2, 16),
         PRESCALE_G           => ite(SIMULATION_G, 2, 61))  -- 100 kHz, 
      port map (
         clk    => axilClk,
         srst   => axilRst,
         regIn  => boardI2cRegMasterIn,
         regOut => boardI2cRegMasterOut,
         i2ci   => boardI2cIn,
         i2co   => boardI2cOut);

   -------------------------------------------------------------------------------------------------
   -- Hybrid Voltage Trim SPI Interface
   -------------------------------------------------------------------------------------------------
   Ad5144SpiAxiBridge_1 : entity ldmx.Ad5144SpiAxiBridge
      generic map (
         TPD_G             => TPD_G,
         NUM_CHIPS_G       => 5,
         AXI_CLK_PERIOD_G  => 8.0E-9,
         SPI_SCLK_PERIOD_G => ite(SIMULATION_G, 0.28E-7, 10.0E-6))  -- 10 us SPI SCLK Period
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => mainAxilReadMasters(AXI_BOARD_SPI_INDEX_C),
         axiReadSlave   => mainAxilReadSlaves(AXI_BOARD_SPI_INDEX_C),
         axiWriteMaster => mainAxilWriteMasters(AXI_BOARD_SPI_INDEX_C),
         axiWriteSlave  => mainAxilWriteSlaves(AXI_BOARD_SPI_INDEX_C),
         spiCsL         => boardSpiCsL,
         spiSclk        => boardSpiSclk,
         spiSdi         => boardSpiSdi,
         spiSdo         => boardSpiSdo);

   -------------------------------------------------------------------------------------------------
   -- XADC Core
   -------------------------------------------------------------------------------------------------
   U_XadcSimpleCore_1 : entity surf.XadcSimpleCore
      generic map (
         TPD_G                    => TPD_G,
         SEQUENCER_MODE_G         => "CONTINUOUS",
         SAMPLING_MODE_G          => "CONTINUOUS",
         MUX_EN_G                 => false,
         ADCCLK_RATIO_G           => 5,
         SAMPLE_AVG_G             => "00",
         COEF_AVG_EN_G            => true,
         OVERTEMP_AUTO_SHDN_G     => true,
         OVERTEMP_ALM_EN_G        => true,
         OVERTEMP_LIMIT_G         => 80.0,
         OVERTEMP_RESET_G         => 30.0,
         TEMP_ALM_EN_G            => false,
         TEMP_UPPER_G             => 70.0,
         TEMP_LOWER_G             => 0.0,
         VCCINT_ALM_EN_G          => false,
         VCCAUX_ALM_EN_G          => false,
         VCCBRAM_ALM_EN_G         => false,
         ADC_OFFSET_CORR_EN_G     => false,
         ADC_GAIN_CORR_EN_G       => true,
         SUPPLY_OFFSET_CORR_EN_G  => false,
         SUPPLY_GAIN_CORR_EN_G    => true,
         SEQ_XADC_CAL_SEL_EN_G    => false,
         SEQ_TEMPERATURE_SEL_EN_G => true,
         SEQ_VCCINT_SEL_EN_G      => true,
         SEQ_VCCAUX_SEL_EN_G      => true,
         SEQ_VCCBRAM_SEL_EN_G     => true,
         SEQ_VAUX_SEL_EN_G        => (others => true))               -- All AUX voltages on
      port map (
         axilClk         => axilClk,                                 -- [in]
         axilRst         => axilRst,                                 -- [in]
         axilReadMaster  => mainAxilReadMasters(AXI_XADC_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXI_XADC_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXI_XADC_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXI_XADC_INDEX_C),   -- [out]
         vpIn            => vpIn,                                    -- [in]
         vnIn            => vnIn,                                    -- [in]
         vAuxP           => vAuxP,                                   -- [in]
         vAuxN           => vAuxN,                                   -- [in]
         alm             => open,                                    -- [out]
         ot              => open);                                   -- [out]




   -------------------------------------------------------------------------------------------------
   -- Create crossbars for mdoules below
   -------------------------------------------------------------------------------------------------
   HYBRID_IO_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
         MASTERS_CONFIG_G   => HYBRID_IO_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXI_HYBRID_IO_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXI_HYBRID_IO_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXI_HYBRID_IO_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXI_HYBRID_IO_INDEX_C),
         mAxiWriteMasters    => hybridIoAxilWriteMasters,
         mAxiWriteSlaves     => hybridIoAxilWriteSlaves,
         mAxiReadMasters     => hybridIoAxilReadMasters,
         mAxiReadSlaves      => hybridIoAxilReadSlaves);

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
      HybridIoCore_1 : entity ldmx.HybridIoCore
         generic map (
            TPD_G             => TPD_G,
            SIMULATION_G      => SIMULATION_G,
            FPGA_ARCH_G       => FPGA_ARCH_G,
            APVS_PER_HYBRID_G => APVS_PER_HYBRID_G,
            AXI_BASE_ADDR_G   => HYBRID_IO_XBAR_CFG_C(i).baseAddr,
            IODELAY_GROUP_G   => ite((i = 0 or i = 1), "IDELAYCTRL0", "IDELAYCTRL1"))
         port map (
            axilClk           => axilClk,
            axilRst           => axilRst,
            axilReadMaster    => hybridIoAxilReadMasters(i),
            axilReadSlave     => hybridIoAxilReadSlaves(i),
            axilWriteMaster   => hybridIoAxilWriteMasters(i),
            axilWriteSlave    => hybridIoAxilWriteSlaves(i),
            adcClkRst         => adcClkRst(i),
            adcChip           => adcChips(i),
            adcReadoutStreams => adcReadoutStreams(i),
            adcSclk           => adcSclk(i),
            adcSdio           => adcSdio(i),
            adcCsb            => adcCsb(i),
            hyI2cIn           => hyI2cIn(i),
            hyI2cOut          => hyI2cOut(i));


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
            adcReadoutStreams => adcReadoutStreams(i),
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
