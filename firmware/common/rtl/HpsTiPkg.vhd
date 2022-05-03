-------------------------------------------------------------------------------
-- Title         : HPS TI Package
-- File          : HpsTiPkg.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 08/21/2014
-------------------------------------------------------------------------------
-- Description:
-- HPS TI package file
-------------------------------------------------------------------------------
-- Copyright (c) 2014 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 08/21/2014: created.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;

package HpsTiPkg is

   -------------------------------------------------------------------------------------------------
   -- HPS OpCodes
   -------------------------------------------------------------------------------------------------
   constant TI_ALIGN_CODE_C    : slv(9 downto 0) := "0010100101";  -- 0x0a5
   constant TI_TRIG_CODE_C     : slv(9 downto 0) := "0001011010";  -- 0x05a
   constant TI_ACK_CODE_C      : slv(9 downto 0) := "0001011010";  -- 0x05a
   constant TI_BUSY_ON_CODE_C  : slv(9 downto 0) := "0010101010";  -- 0x0aa
   constant TI_BUSY_OFF_CODE_C : slv(9 downto 0) := "0001010101";  -- 0x055
   constant TI_APV_RESET_101_C : slv(9 downto 0) := "0000011111";  -- 0x01F
   constant TI_START_CODE_C    : slv(9 downto 0) := "1111100000";   -- 0x3E0

   -- FIFO Configurations
   constant TRG_8B_DATA_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 1,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_LAST_C);

   -------------------------------------------------------------------------------------------------
   -- TI Dist Status
   -------------------------------------------------------------------------------------------------
   type TiDistStatusType is record
      trigger1Count   : slv(31 downto 0);
      trigger2Count   : slv(31 downto 0);
      trigRawCount    : slv(31 downto 0);
      readCount       : slv(31 downto 0);
      ackCount        : Slv32Array(7 downto 0);
      ackDelay        : Slv32Array(7 downto 0);
      locBusy         : slv(8 downto 0);
      busyCount       : slv(31 downto 0);
      filterBusyCount : slv(31 downto 0);
      filterBusyRate  : slv(31 downto 0);
      trigTxCount     : slv(31 downto 0);
      sResetReg       : slv(15 downto 0);
      trigMin         : slv(31 downto 0);
      syncCount       : slv(15 downto 0);
      syncSentCount   : slv(15 downto 0);
   end record;

   constant TI_DIST_STATUS_INIT_C : TiDistStatusType := (
      trigger1Count   => (others => '0'),
      trigger2Count   => (others => '0'),
      trigRawCount    => (others => '0'),
      readCount       => (others => '0'),
      ackCount        => (others => (others => '0')),
      ackDelay        => (others => (others => '0')),
      locBusy         => (others => '0'),
      busyCount       => (others => '0'),
      filterBusyCount => (others => '0'),
      filterBusyRate  => (others => '0'),
      trigTxCount     => (others => '0'),
      sResetReg       => (others => '0'),
      trigMin         => (others => '0'),
      syncCount       => (others => '0'),
      syncSentCount   => (others => '0')
      );

   constant TI_DIST_STATUS_SIZE_C : integer := 857;

   function toSlv (status : TiDistStatusType) return slv;

   function toTiDistStatusType (vector : slv(TI_DIST_STATUS_SIZE_C-1 downto 0)) return TiDistStatusType;

   -------------------------------------------------------------------------------------------------
   -- TI Dist Config
   -------------------------------------------------------------------------------------------------
   type TiDistConfigType is record
      trigEnable    : sl;
      countReset    : sl;
      trigSrc       : slv(2 downto 0);
      trigDelay     : slv(2 downto 0);
      readSrc       : slv(2 downto 0);
      dmaTestSize   : slv(31 downto 0);
      dmaTestEnable : sl;
      swRead        : sl;
      apvRst101     : sl;
      clk41Align    : sl;
      forceBusy     : sl;
   end record;

   constant TI_DIST_CONFIG_INIT_C : TiDistConfigType := (
      trigEnable    => '0',
      countReset    => '0',
      trigSrc       => (others => '0'),
      trigDelay     => (others => '0'),
      readSrc       => (others => '0'),
      dmaTestSize   => (others => '0'),
      dmaTestEnable => '0',
      swRead        => '0',
      apvRst101     => '0',
      clk41Align    => '0',
      forceBusy     => '0'
      );

   constant TI_DIST_CONFIG_SIZE_C : integer := 47;

   function toSlv (config : TiDistConfigType) return slv;

   function toTiDistConfigType (vector : slv(TI_DIST_CONFIG_SIZE_C-1 downto 0)) return TiDistConfigType;


end package HpsTiPkg;

package body HpsTiPkg is

   function toSlv (status : TiDistStatusType) return slv is
      variable vector : slv(TI_DIST_STATUS_SIZE_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
   begin
      assignSlv(i, vector, status.trigger1Count);
      assignSlv(i, vector, status.trigger2Count);
      assignSlv(i, vector, status.trigRawCount);
      assignSlv(i, vector, status.readCount);
      for j in 7 downto 0 loop
         assignSlv(i, vector, status.ackCount(j));
      end loop;
      for j in 7 downto 0 loop
         assignSlv(i, vector, status.ackDelay(j));
      end loop;
      assignSlv(i, vector, status.locBusy);
      assignSlv(i, vector, status.busyCount);
      assignSlv(i, vector, status.filterBusyCount);
      assignSlv(i, vector, status.filterBusyRate);
      assignSlv(i, vector, status.trigTxCount);
      assignSlv(i, vector, status.sResetReg);
      assignSlv(i, vector, status.trigMin);
      assignSlv(i, vector, status.syncCount);
      assignSlv(i, vector, status.syncSentCount);
      return vector;
   end function;

   function toTiDistStatusType (vector : slv(TI_DIST_STATUS_SIZE_C-1 downto 0)) return TiDistStatusType is
      variable status : TiDistStatusType := TI_DIST_STATUS_INIT_C;
      variable i      : integer          := 0;
   begin
      assignRecord(i, vector, status.trigger1Count);
      assignRecord(i, vector, status.trigger2Count);
      assignRecord(i, vector, status.trigRawCount);
      assignRecord(i, vector, status.readCount);
      for j in 7 downto 0 loop
         assignRecord(i, vector, status.ackCount(j));
      end loop;
      for j in 7 downto 0 loop
         assignRecord(i, vector, status.ackDelay(j));
      end loop;
      assignRecord(i, vector, status.locBusy);
      assignRecord(i, vector, status.busyCount);
      assignRecord(i, vector, status.filterBusyCount);
      assignRecord(i, vector, status.filterBusyRate);
      assignRecord(i, vector, status.trigTxCount);
      assignRecord(i, vector, status.sResetReg);
      assignRecord(i, vector, status.trigMin);
      assignRecord(i, vector, status.syncCount);
      assignRecord(i, vector, status.syncSentCount);
      return status;
   end function;

   -------------------------------------------------------------------------------------------------

   function toSlv (config : TiDistConfigType) return slv is
      variable vector : slv(TI_DIST_CONFIG_SIZE_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
   begin
      assignSlv(i, vector, config.trigEnable);
      assignSlv(i, vector, config.countReset);
      assignSlv(i, vector, config.trigSrc);
      assignSlv(i, vector, config.trigDelay);
      assignSlv(i, vector, config.readSrc);
      assignSlv(i, vector, config.dmaTestSize);
      assignSlv(i, vector, config.dmaTestEnable);
      assignSlv(i, vector, config.apvRst101);
      assignSlv(i, vector, config.clk41Align);
      assignSlv(i, vector, config.forceBusy);
      return vector;
   end function;

   function toTiDistConfigType (vector : slv(TI_DIST_CONFIG_SIZE_C-1 downto 0)) return TiDistConfigType is
      variable config : TiDistConfigType := TI_DIST_CONFIG_INIT_C;
      variable i      : integer          := 0;
   begin
      assignRecord(i, vector, config.trigEnable);
      assignRecord(i, vector, config.countReset);
      assignRecord(i, vector, config.trigSrc);
      assignRecord(i, vector, config.trigDelay);
      assignRecord(i, vector, config.readSrc);
      assignRecord(i, vector, config.dmaTestSize);
      assignRecord(i, vector, config.dmaTestEnable);
      assignRecord(i, vector, config.apvRst101);
      assignRecord(i, vector, config.clk41Align);
      assignRecord(i, vector, config.forceBusy);
      return config;
   end function;

end package body HpsTiPkg;

