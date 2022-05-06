-------------------------------------------------------------------------------
-- Title      : HPS FEB Hardware Peripherals
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

library UNISIM;
use UNISIM.VCOMPONENTS.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.I2cPkg.all;

library ldmx;
use ldmx.HpsPkg.all;
use ldmx.HpsFebHwPkg.all;
use ldmx.AdcReadoutPkg.all;

entity HpsFebHw is

   generic (
      TPD_G             : time                 := 1 ns;
      SIMULATION_G      : boolean              := false;
      HYBRIDS_G         : integer range 1 to 8 := 8;
      APVS_PER_HYBRID_G : integer range 1 to 8 := 6;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := X"00000000");
   port (
      ----------------------------------------------------------------------------------------------
      -- FPGA IO pins
      ----------------------------------------------------------------------------------------------
      -- ADC DDR Interface 
      adcClkP  : out slv(HYBRIDS_G-1 downto 0);  -- 37 MHz clock to ADC
      adcClkN  : out slv(HYBRIDS_G-1 downto 0);
      adcFClkP : in  slv(HYBRIDS_G-1 downto 0);
      adcFClkN : in  slv(HYBRIDS_G-1 downto 0);
      adcDClkP : in  slv(HYBRIDS_G-1 downto 0);
      adcDClkN : in  slv(HYBRIDS_G-1 downto 0);
      adcDataP : in  slv5Array(HYBRIDS_G-1 downto 0);
      adcDataN : in  slv5Array(HYBRIDS_G-1 downto 0);

      -- ADC Config Interface
      adcCsb  : out   slv(HYBRIDS_G-1 downto 0);
      adcSclk : out   slv(HYBRIDS_G-1 downto 0);
      adcSdio : inout slv(HYBRIDS_G-1 downto 0);

      -- Amplifier powerdown I2C
      ampI2cScl : inout sl;
      ampI2cSda : inout sl;

      -- Board I2C Interface
      boardI2cScl : inout sl;
      boardI2cSda : inout sl;


      -- Board SPI Interface
      boardSpiSclk : out sl;
      boardSpiSdi  : out sl;
      boardSpiSdo  : in  sl;
      boardSpiCsL  : out slv(4 downto 0);

      -- Interface to Hybrids
      hyClkP      : out slv(HYBRIDS_G-1 downto 0);
      hyClkN      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgP      : out slv(HYBRIDS_G-1 downto 0);
      hyTrgN      : out slv(HYBRIDS_G-1 downto 0);
      hyRstL      : out slv(HYBRIDS_G-1 downto 0);
      hyI2cScl    : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaOut : out slv(HYBRIDS_G-1 downto 0);
      hyI2cSdaIn  : in  slv(HYBRIDS_G-1 downto 0);

      -- XADC Interface
      vPIn  : in sl;
      vNIn  : in sl;
      vAuxP : in slv(15 downto 0);
      vAuxN : in slv(15 downto 0);

      -- Regulator power good signals
      powerGood : in PowerGoodType;

      leds : out slv(7 downto 0);       -- Test outputs

      -- Boot PROM interface
      bootCsL  : out sl;
      bootMosi : out sl;
      bootMiso : in  sl;


      ----------------------------------------------------------------------------------------------
      -- FebCore and application ports
      ----------------------------------------------------------------------------------------------
      -- 200 MHz clock for IODELAYs
      clk200 : in sl;
      rst200 : in sl;

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

      -- 37Mhz clock
      daqClk37    : in  sl;
      daqClk37Rst : in  sl;
      hyClk       : out slv(HYBRIDS_G-1 downto 0) := (others => '0');
      hyClkRst    : out slv(HYBRIDS_G-1 downto 0) := (others => '0'));

end entity HpsFebHw;

architecture rtl of HpsFebHw is

   attribute IODELAY_GROUP                 : string;
   attribute IODELAY_GROUP of IDELAYCTRL_0 : label is "IDELAYCTRL0";
   attribute IODELAY_GROUP of IDELAYCTRL_1 : label is "IDELAYCTRL1";


   -------------------------------------------------------------------------------------------------
   -- AXI-Lite
   -------------------------------------------------------------------------------------------------
   constant MAIN_XBAR_MASTERS_C : natural := 10;

   -- Module AXI Addresses
   constant AXI_PGOOD_INDEX_C              : natural := 0;
   constant AXI_HYBRID_CLOCK_PHASE_INDEX_C : natural := 1;
   constant AXI_ADC_CLOCK_PHASE_INDEX_C    : natural := 2;
   constant AXI_BOARD_I2C_INDEX_C          : natural := 3;
   constant AXI_BOARD_SPI_INDEX_C          : natural := 4;
   constant AXI_XADC_INDEX_C               : natural := 5;
   constant AXI_PROM_INDEX_C               : natural := 6;
   constant AXI_AMP_I2C_INDEX_C            : natural := 7;
   constant AXI_ADC_READOUT_INDEX_C        : natural := 8;
   constant AXI_ADC_CONFIG_INDEX_C         : natural := 9;

   constant MAIN_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(MAIN_XBAR_MASTERS_C-1 downto 0) := (
      AXI_PGOOD_INDEX_C              => (
         baseAddr                    => AXI_BASE_ADDR_G + X"0000",
         addrBits                    => 8,
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
         connectivity                => X"0001"),
      AXI_BOARD_SPI_INDEX_C          => (    -- Board SPI Interface
         baseAddr                    => AXI_BASE_ADDR_G + X"4000",
         addrBits                    => 12,  -- 9FFF
         connectivity                => X"0001"),
      AXI_XADC_INDEX_C               => (
         baseAddr                    => AXI_BASE_ADDR_G + X"5000",
         addrBits                    => 12,  -- to 4FFF
         connectivity                => X"0001"),
      AXI_PROM_INDEX_C               => (
         baseAddr                    => AXI_BASE_ADDR_G + X"6000",
         addrBits                    => 12,
         connectivity                => X"0001"),
      AXI_AMP_I2C_INDEX_C            => (
         baseAddr                    => AXI_BASE_ADDR_G + X"7000",
         addrBits                    => 8,
         connectivity                => X"0001"),
      AXI_ADC_READOUT_INDEX_C        => (
         baseAddr                    => AXI_BASE_ADDR_G + X"10000",
         addrBits                    => 12,
         connectivity                => X"0001"),
      AXI_ADC_CONFIG_INDEX_C         => (
         baseAddr                    => AXI_BASE_ADDR_G + X"20000",
         addrBits                    => 16,
         connectivity                => X"0001"));

--       SEM_AXI_INDEX_C      => (
--          baseAddr          => SEM_AXI_BASE_ADDR_G,
--          addrBits          => 8,
--          connectivity      => X"0001"));

   signal mainAxilWriteMasters : AxiLiteWriteMasterArray(MAIN_XBAR_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal mainAxilWriteSlaves  : AxiLiteWriteSlaveArray(MAIN_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal mainAxilReadMasters  : AxiLiteReadMasterArray(MAIN_XBAR_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal mainAxilReadSlaves   : AxiLiteReadSlaveArray(MAIN_XBAR_MASTERS_C-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   constant ADC_READOUT_AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(HYBRIDS_G, MAIN_XBAR_CFG_C(AXI_ADC_READOUT_INDEX_C).baseAddr, 12, 8);

   signal adcReadoutAxilWriteMasters : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal adcReadoutAxilWriteSlaves  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal adcReadoutAxilReadMasters  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal adcReadoutAxilReadSlaves   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   constant ADC_CONFIG_AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray := genAxiLiteConfig(HYBRIDS_G, MAIN_XBAR_CFG_C(AXI_ADC_CONFIG_INDEX_C).baseAddr, 16, 12);

   signal adcConfigAxilWriteMasters : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0) := (others => AXI_LITE_WRITE_MASTER_INIT_C);
   signal adcConfigAxilWriteSlaves  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);
   signal adcConfigAxilReadMasters  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_READ_MASTER_INIT_C);
   signal adcConfigAxilReadSlaves   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0)   := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);

   ----------------------------------------------------------------------------------------------------
   -- ADC signals
   ----------------------------------------------------------------------------------------------------
   signal adcChips : AdcChipOutArray(HYBRIDS_G-1 downto 0);

   -------------------------------------------------------------------------------------------------
   -- Hybrid and ADC Shifted Clocks and thier resets
   -------------------------------------------------------------------------------------------------
   signal hyClkInt    : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal hyClkRstInt : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal adcClk      : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal adcClkRst   : slv(HYBRIDS_G-1 downto 0) := (others => '0');
   signal hyPwrEnL    : slv(HYBRIDS_G-1 downto 0);

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

   signal boardI2cIn  : i2c_in_type;
   signal boardI2cOut : i2c_out_type;



   constant AMP_I2C_DEV_MAP_C : I2cAxiLiteDevArray := (
      0              => (
         i2cAddress  => "0000100010",
         i2cTenbit   => '0',
         dataSize    => 8,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'));

   signal bootSck : sl;

   signal ledEn : sl;

begin

   -------------------------------------------------------------------------------------------------
   -- 2 IDELAYCTRL Instances Needed
   -------------------------------------------------------------------------------------------------
   IDELAYCTRL_0 : IDELAYCTRL
      port map (
         RDY    => open,
         REFCLK => clk200,
         RST    => rst200);

   IDELAYCTRL_1 : IDELAYCTRL
      port map (
         RDY    => open,
         REFCLK => clk200,
         RST    => rst200);


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
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
         MASTERS_CONFIG_G   => ADC_READOUT_AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXI_ADC_READOUT_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXI_ADC_READOUT_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXI_ADC_READOUT_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXI_ADC_READOUT_INDEX_C),
         mAxiWriteMasters    => adcReadoutAxilWriteMasters,
         mAxiWriteSlaves     => adcReadoutAxilWriteSlaves,
         mAxiReadMasters     => adcReadoutAxilReadMasters,
         mAxiReadSlaves      => adcReadoutAxilReadSlaves);

   AdcConfigCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
         MASTERS_CONFIG_G   => ADC_CONFIG_AXIL_XBAR_CFG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => mainAxilWriteMasters(AXI_ADC_CONFIG_INDEX_C),
         sAxiWriteSlaves(0)  => mainAxilWriteSlaves(AXI_ADC_CONFIG_INDEX_C),
         sAxiReadMasters(0)  => mainAxilReadMasters(AXI_ADC_CONFIG_INDEX_C),
         sAxiReadSlaves(0)   => mainAxilReadSlaves(AXI_ADC_CONFIG_INDEX_C),
         mAxiWriteMasters    => adcConfigAxilWriteMasters,
         mAxiWriteSlaves     => adcConfigAxilWriteSlaves,
         mAxiReadMasters     => adcConfigAxilReadMasters,
         mAxiReadSlaves      => adcConfigAxilReadSlaves);



   -------------------------------------------------------------------------------------------------
   -- Power Good signals
   -------------------------------------------------------------------------------------------------
   U_HpsFebPGoodMon_1 : entity ldmx.HpsFebPGoodMon
      generic map (
         TPD_G => TPD_G)
      port map (
         axilClk         => axilClk,                                  -- [in]
         axilRst         => axilRst,                                  -- [in]
         axilReadMaster  => mainAxilReadMasters(AXI_PGOOD_INDEX_C),   -- [in]
         axilReadSlave   => mainAxilReadSlaves(AXI_PGOOD_INDEX_C),    -- [out]
         axilWriteMaster => mainAxilWriteMasters(AXI_PGOOD_INDEX_C),  -- [in]
         axilWriteSlave  => mainAxilWriteSlaves(AXI_PGOOD_INDEX_C),   -- [out]
         ledEn           => ledEn,                                    -- [out]
         powerGood       => powerGood);                               -- [in]

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
         axiClk         => axilClk,                                               -- [in]
         axiRst         => axilRst,                                               -- [in]
         axiReadMaster  => mainAxilReadMasters(AXI_HYBRID_CLOCK_PHASE_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXI_HYBRID_CLOCK_PHASE_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXI_HYBRID_CLOCK_PHASE_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXI_HYBRID_CLOCK_PHASE_INDEX_C),   -- [out]
         refClk         => daqClk37,                                              -- [in]
         refClkRst      => daqClk37Rst,                                           -- [in]
         clkOut         => hyClkInt,                                              -- [out]
         rstOut         => hyClkRstInt);                                          -- [out]

   -- Assign to outputs for FebCore
   hyClk    <= hyClkInt;
   hyClkRst <= hyClkRstInt;

   U_ClockPhaseShifter_ADCS : entity ldmx.ClockPhaseShifter
      generic map (
         TPD_G           => TPD_G,
         NUM_OUTCLOCKS_G => HYBRIDS_G,
         CLKIN_PERIOD_G  => 26.923,
         DIVCLK_DIVIDE_G => 1,
         CLKFBOUT_MULT_G => 27,
         CLKOUT_DIVIDE_G => 27)
      port map (
         axiClk         => axilClk,                                            -- [in]
         axiRst         => axilRst,                                            -- [in]
         axiReadMaster  => mainAxilReadMasters(AXI_ADC_CLOCK_PHASE_INDEX_C),   -- [in]
         axiReadSlave   => mainAxilReadSlaves(AXI_ADC_CLOCK_PHASE_INDEX_C),    -- [out]
         axiWriteMaster => mainAxilWriteMasters(AXI_ADC_CLOCK_PHASE_INDEX_C),  -- [in]
         axiWriteSlave  => mainAxilWriteSlaves(AXI_ADC_CLOCK_PHASE_INDEX_C),   -- [out]
         refClk         => daqClk37,                                           -- [in]
         refClkRst      => daqClk37Rst,                                        -- [in]
         clkOut         => adcClk,                                             -- [out]
         rstOut         => adcClkRst);                                         -- [out]

--   adcClkOut <= adcClk(HYBRIDS_G-1 downto 0);

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

   -- Board I2C Buffers
   BOARD_SDA_IOBUFT : IOBUF
      port map (
         I  => boardI2cOut.sda,
         O  => boardI2cIn.sda,
         IO => boardI2cSda,
         T  => boardI2cOut.sdaoen);

   BOARD_SCL_IOBUFT : IOBUF
      port map (
         I  => boardI2cOut.scl,
         O  => boardI2cIn.scl,
         IO => boardI2cScl,
         T  => boardI2cOut.scloen);



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
   -- FLASH Interface
   -------------------------------------------------------------------------------------------------
   U_SpiProm : entity surf.AxiMicronN25QCore
      generic map (
         TPD_G          => TPD_G,
         AXI_CLK_FREQ_G => 125.0E+6,
         SPI_CLK_FREQ_G => (125.0E+6/12.0))
      port map (
         -- FLASH Memory Ports
         csL            => bootCsL,
         sck            => bootSck,
         mosi           => bootMosi,
         miso           => bootMiso,
         -- AXI-Lite Register Interface
         axiReadMaster  => mainAxilReadMasters(AXI_PROM_INDEX_C),
         axiReadSlave   => mainAxilReadSlaves(AXI_PROM_INDEX_C),
         axiWriteMaster => mainAxilWriteMasters(AXI_PROM_INDEX_C),
         axiWriteSlave  => mainAxilWriteSlaves(AXI_PROM_INDEX_C),
         -- Clocks and Resets
         axiClk         => axilClk,
         axiRst         => axilRst);

   -----------------------------------------------------
   -- Using the STARTUPE2 to access the FPGA's CCLK port
   -----------------------------------------------------
   U_STARTUPE2 : STARTUPE2
      port map (
         CFGCLK    => open,             -- 1-bit output: Configuration main clock output
         CFGMCLK   => open,  -- 1-bit output: Configuration internal oscillator clock output
         EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
         PREQ      => open,             -- 1-bit output: PROGRAM request to fabric output
         CLK       => '0',              -- 1-bit input: User start-up clock input
         GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
         GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
         KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
         PACK      => '0',              -- 1-bit input: PROGRAM acknowledge input
         USRCCLKO  => bootSck,          -- 1-bit input: User CCLK input
         USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
         USRDONEO  => '1',              -- 1-bit input: User DONE pin output control
         USRDONETS => '1');             -- 1-bit input: User DONE 3-state enable output   


   -------------------------------------------------------------------------------------------------
   -- Map ADC pins to records
   -------------------------------------------------------------------------------------------------
   ADC_MAP : for i in HYBRIDS_G-1 downto 0 generate

      -------------------------------------------------------------------------------------------------
      -- ADC Readout
      -------------------------------------------------------------------------------------------------
      AdcReadout_1 : entity ldmx.AdcReadout7
         generic map (
            TPD_G           => TPD_G,
            SIMULATION_G    => SIMULATION_G,
            NUM_CHANNELS_G  => APVS_PER_HYBRID_G,
            IODELAY_GROUP_G => ite(i >= 2, "IDELAYCTRL0", "IDELAYCTRL1"))
         port map (
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilWriteMaster => adcReadoutAxilWriteMasters(i),
            axilWriteSlave  => adcReadoutAxilWriteSlaves(i),
            axilReadMaster  => adcReadoutAxilReadMasters(i),
            axilReadSlave   => adcReadoutAxilReadSlaves(i),
            adcClkRst       => adcClkRst(i),
            adc             => adcChips(i),
            adcStreamClk    => axilClk,
            adcStreams      => adcReadoutStreams(i)(APVS_PER_HYBRID_G-1 downto 0));


      -- IO Assignment to records
      adcChips(i).fClkP <= adcFClkP(i);
      adcChips(i).fClkN <= adcFClkN(i);
      adcChips(i).dClkP <= adcDClkP(i);
      adcChips(i).dClkN <= adcDClkN(i);
      adcChips(i).chP   <= "000" & adcDataP(i);
      adcChips(i).chN   <= "000" & adcDataN(i);

      ----------------------------------------------------------------------------------------------
      -- AdcConfig Module
      ----------------------------------------------------------------------------------------------
      U_AdcConfig_1 : entity ldmx.AdcConfig
         generic map (
            TPD_G => TPD_G)
         port map (
            axiClk         => axilClk,                       -- [in]
            axiRst         => axilRst,                       -- [in]
            axiReadMaster  => adcConfigAxilReadMasters(i),   -- [in]
            axiReadSlave   => adcConfigAxilReadSlaves(i),    -- [out]
            axiWriteMaster => adcConfigAxilWriteMasters(i),  -- [in]
            axiWriteSlave  => adcConfigAxilWriteSlaves(i),   -- [out]
--         adcPdwn        => open,                                      -- [out]
            adcSclk        => adcSclk(i),                    -- [out]
            adcSdio        => adcSdio(i),                    -- [inout]
            adcCsb         => adcCsb(i));                    -- [out]

   end generate ADC_MAP;

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
   DIFF_BUFF_GEN : for i in HYBRIDS_G-1 downto 0 generate
      hyRstL(i)   <= hyRstOutL(i) when hyPwrEn(i) = '1' else 'Z';
      hyPwrEnL(i) <= not hyPwrEn(i);

      HY_TRG_BUFF_DIFF : OBUFTDS
         port map (
            I  => hyTrgOut(i),
            T  => hyPwrEnL(i),
            O  => hyTrgP(i),
            OB => hyTrgN(i));

      HY_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
         port map (
            outEnL  => hyPwrEnL(i),
            clkIn   => hyClkInt(i),
            clkOutP => hyClkP(i),
            clkOutN => hyClkN(i));

      ADC_CLK_OUT_BUF_DIFF : entity surf.ClkOutBufDiff
         port map (
            clkIn   => adcClk(i),
            clkOutP => adcClkP(i),
            clkOutN => adcClkN(i));
   end generate;




end architecture rtl;
