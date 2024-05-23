-------------------------------------------------------------------------------
-- Title      : LDMX FEB Hybrid Power I2C
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
use surf.I2cPkg.all;
use surf.I2cMuxPkg.all;

library ldmx_tracker;

entity LdmxHybridPowerI2c is
   generic (
      TPD_G            : time             := 1 ns;
      I2C_SCL_FREQ_G   : real             := 100.0E+3;  -- units of Hz
      I2C_MIN_PULSE_G  : real             := 100.0E-9;  -- units of seconds
      AXIL_BASE_ADDR_G : slv(31 downto 0) := X"00000000";
      AXIL_CLK_FREQ_G  : real             := 125.0e6);
   port (
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_OK_C;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;
      scl             : inout sl;
      sda             : inout sl);
end LdmxHybridPowerI2c;

architecture rtl of LdmxHybridPowerI2c is


   -- Note: PRESCALE_G = (clk_freq / (5 * i2c_freq)) - 1
   --       FILTER_G = (min_pulse_time / clk_period) + 1
   constant I2C_SCL_5xFREQ_C : real    := 5.0 * I2C_SCL_FREQ_G;
   constant PRESCALE_C       : natural := (getTimeRatio(AXIL_CLK_FREQ_G, I2C_SCL_5xFREQ_C)) - 1;
   constant FILTER_C         : natural := natural(AXIL_CLK_FREQ_G * I2C_MIN_PULSE_G) + 1;

   signal i2ci : i2c_in_type;
   signal i2co : i2c_out_type;

   signal i2cRegMastersIn  : I2cRegMasterInArray(1 downto 0);
   signal i2cRegMastersOut : I2cRegMasterOutArray(1 downto 0);

   signal i2cRegMasterIn  : I2cRegMasterInType;
   signal i2cRegMasterOut : I2cRegMasterOutType;

   constant XBAR_I2C_CONFIG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := (
      0               => (              -- LTC2991 Near and Far
         baseAddr     => AXIL_BASE_ADDR_G + "000",
         addrBits     => 11,
         connectivity => X"0001"),
      1               => (              -- AD5144
         baseAddr     => AXIL_BASE_ADDR_G + X"800",
         addrBits     => 10,
         connectivity => X"0001"));

   signal i2cReadMasters  : AxiLiteReadMasterArray(1 downto 0);
   signal i2cReadSlaves   : AxiLiteReadSlaveArray(1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal i2cWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal i2cWriteSlaves  : AxiLiteWriteSlaveArray(1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

   constant I2C_DEV_MAP_C : I2cAxiLiteDevArray := (
      0              => (               -- LTC2991 Near
         i2cAddress  => "0001001000",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'),
      1              => (               -- LTC2991 Far
         i2cAddress  => "0001001001",
         i2cTenbit   => '0',
         dataSize    => 16,
         addrSize    => 8,
         endianness  => '1',
         repeatStart => '0'));

begin

   -------------------------------------------------------------------------------------------------
   -- Crossbar
   -------------------------------------------------------------------------------------------------
   U_AxiLiteCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => 2,
         MASTERS_CONFIG_G   => XBAR_I2C_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => i2cWriteMasters,
         mAxiWriteSlaves     => i2cWriteSlaves,
         mAxiReadMasters     => i2cReadMasters,
         mAxiReadSlaves      => i2cReadSlaves);

   U_I2cRegMasterAxiBridge : entity surf.I2cRegMasterAxiBridge
      generic map (
         TPD_G        => TPD_G,
         DEVICE_MAP_G => I2C_DEV_MAP_C)
      port map (
         axiClk          => axilClk,
         axiRst          => axilRst,
         axiReadMaster   => i2cReadMasters(0),
         axiReadSlave    => i2cReadSlaves(0),
         axiWriteMaster  => i2cWriteMasters(0),
         axiWriteSlave   => i2cWriteSlaves(0),
         i2cRegMasterIn  => i2cRegMastersIn(0),
         i2cRegMasterOut => i2cRegMastersOut(0),
         i2cSelectOut    => open);

   U_Ad5144I2cAxiBridge_1 : entity ldmx_tracker.Ad5144I2cAxiBridge
      generic map (
         TPD_G      => TPD_G,
         I2C_ADDR_G => "0100000")
      port map (
         axiClk          => axilClk,               -- [in]
         axiRst          => axilRst,               -- [in]
         axiReadMaster   => i2cReadMasters(1),     -- [in]
         axiReadSlave    => i2cReadSlaves(1),      -- [out]
         axiWriteMaster  => i2cWriteMasters(1),    -- [in]
         axiWriteSlave   => i2cWriteSlaves(1),     -- [out]
         i2cRegMasterIn  => i2cRegMastersIn(1),    -- [out]
         i2cRegMasterOut => i2cRegMastersOut(1));  -- [in]

   U_I2cRegMasterMux_1 : entity surf.I2cRegMasterMux
      generic map (
         TPD_G        => TPD_G,
         NUM_INPUTS_C => 2)
      port map (
         clk       => axilClk,           -- [in]
         srst      => axilRst,           -- [in]
         regIn     => i2cRegMastersIn,   -- [in]
         regOut    => i2cRegMastersOut,  -- [out]
         masterIn  => i2cRegMasterIn,    -- [out]
         masterOut => i2cRegMasterOut);  -- [in]

   U_I2cRegMaster : entity surf.I2cRegMaster
      generic map(
         TPD_G                => TPD_G,
         OUTPUT_EN_POLARITY_G => 0,
         FILTER_G             => FILTER_C,
         PRESCALE_G           => PRESCALE_C)
      port map (
         clk    => axilClk,
         srst   => axilRst,
         regIn  => i2cRegMasterIn,
         regOut => i2cRegMasterOut,
         i2ci   => i2ci,
         i2co   => i2co);

   IOBUF_SCL : entity surf.IoBufWrapper
      port map (
         O  => i2ci.scl,                -- Buffer output
         IO => scl,                     -- Buffer inout port (connect directly to top-level port)
         I  => i2co.scl,                -- Buffer input
         T  => i2co.scloen);            -- 3-state enable input, high=input, low=output

   IOBUF_SDA : entity surf.IoBufWrapper
      port map (
         O  => i2ci.sda,                -- Buffer output
         IO => sda,                     -- Buffer inout port (connect directly to top-level port)
         I  => i2co.sda,                -- Buffer input
         T  => i2co.sdaoen);            -- 3-state enable input, high=input, low=output


end architecture rtl;
