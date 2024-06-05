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

entity LdmxHybridPowerI2cArray is
   generic (
      TPD_G            : time                 := 1 ns;
      HYBRIDS_G        : integer range 1 to 8 := 8;
      I2C_SCL_FREQ_G   : real                 := 100.0E+3;  -- units of Hz
      I2C_MIN_PULSE_G  : real                 := 100.0E-9;  -- units of seconds
      AXIL_BASE_ADDR_G : slv(31 downto 0)     := X"00000000";
      AXIL_CLK_FREQ_G  : real                 := 125.0e6);
   port (
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType  := AXI_LITE_READ_SLAVE_EMPTY_OK_C;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType := AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;
      scl             : inout slv(HYBRIDS_G-1 downto 0);
      sda             : inout slv(HYBRIDS_G-1 downto 0));
end LdmxHybridPowerI2cArray;

architecture rtl of LdmxHybridPowerI2cArray is


   constant XBAR_I2C_CONFIG_C : AxiLiteCrossbarMasterConfigArray(HYBRIDS_G-1 downto 0) := genAxiLiteConfig(HYBRIDS_G, AXIL_BASE_ADDR_G, 16, 12);

   signal i2cReadMasters  : AxiLiteReadMasterArray(HYBRIDS_G-1 downto 0);
   signal i2cReadSlaves   : AxiLiteReadSlaveArray(HYBRIDS_G-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_DECERR_C);
   signal i2cWriteMasters : AxiLiteWriteMasterArray(HYBRIDS_G-1 downto 0);
   signal i2cWriteSlaves  : AxiLiteWriteSlaveArray(HYBRIDS_G-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_DECERR_C);

begin

   -------------------------------------------------------------------------------------------------
   -- Crossbar
   -------------------------------------------------------------------------------------------------
   U_AxiLiteCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => HYBRIDS_G,
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


   I2C_GEN : for i in HYBRIDS_G-1 downto 0 generate
      U_LdmxHybridPowerI2c_1 : entity ldmx_tracker.LdmxHybridPowerI2c
         generic map (
            TPD_G            => TPD_G,
            I2C_SCL_FREQ_G   => I2C_SCL_FREQ_G,
            I2C_MIN_PULSE_G  => I2C_MIN_PULSE_G,
            AXIL_BASE_ADDR_G => XBAR_I2C_CONFIG_C(i).baseAddr,
            AXIL_CLK_FREQ_G  => AXIL_CLK_FREQ_G)
         port map (
            axilClk         => axilClk,             -- [in]
            axilRst         => axilRst,             -- [in]
            axilReadMaster  => i2cReadMasters(i),   -- [in]
            axilReadSlave   => i2cReadSlaves(i),    -- [out]
            axilWriteMaster => i2cWriteMasters(i),  -- [in]
            axilWriteSlave  => i2cWriteSlaves(i),   -- [out]
            scl             => scl(i),              -- [inout]
            sda             => sda(i));             -- [inout]
   end generate I2C_GEN;
end architecture rtl;
