-------------------------------------------------------------------------------
-- Title         : JLAB TI Registers
-- File          : TiRegisters.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 07/16/2014
-------------------------------------------------------------------------------
-- Description:
-- JLAB TI Registers
-------------------------------------------------------------------------------
-- Copyright (c) 2014 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 07/16/2014: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

library ldmx;
use ldmx.JlabTiPkg.all;
use ldmx.HpsTiPkg.all;

entity TiRegisters is
   generic (
      TPD_G : time := 1 ns
      );
   port (

      -- AXI Interface
      axilClk         : in  sl;
      axilClkRst      : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Config & Status
      tiDistClk    : in  sl;
      tiConfig     : out JlabTiConfigType;
      tiStatus     : in  JlabTiStatusType;
      tiDistConfig : out TiDistConfigType;
      tiDistStatus : in  TiDistStatusType
      );
end TiRegisters;

architecture STRUCTURE of TiRegisters is

   type RegType is record
      clearCnt       : slv(3 downto 0);
      tiConfig       : JlabTiConfigType;
      tiDistConfig   : TiDistConfigType;
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      clearCnt       => (others => '0'),
      tiConfig       => JLAB_TI_CONFIG_INIT_C,
      tiDistConfig   => TI_DIST_CONFIG_INIT_C,
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal tiStatusSyncSlv1 : slv(JLAB_TI_STATUS_SIZE_C-1 downto 0);
   signal tiStatusSyncSlv2 : slv(JLAB_TI_STATUS_SIZE_C-1 downto 0);
   signal tiStatusSync     : JlabTiStatusType;
   signal tiConfigSyncSlv  : slv(JLAB_TI_CONFIG_SIZE_C-1 downto 0);

   signal tiDistStatusSyncSlv : slv(TI_DIST_STATUS_SIZE_C-1 downto 0);
   signal tiDistStatusSync    : TiDistStatusType;
   signal tiDistConfigSyncSlv : slv(TI_DIST_CONFIG_SIZE_C-1 downto 0);
   
begin

   -------------------------------------------------------------------------------------------------
   -- Synchronization
   -------------------------------------------------------------------------------------------------
   -- Synchronize Ti Status bus to axilClk
   -- First run all signals through SynchronizerVector to break any RAM-RAM paths
   SynchronizerVector_TiStatus : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => JLAB_TI_STATUS_SIZE_C)
      port map (
         clk     => axilClk,
         rst     => axilClkRst,
         dataIn  => toSlv(tiStatus),
         dataOut => tiStatusSyncSlv1);

   tiStatusSync <= toJlabTiStatusType(tiStatusSyncSlv1);
   tiConfig     <= r.tiConfig;


   -- Synchronize TiDistStatus bus to axilClk
   SynchronizerVector_TiDistStatus : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => TI_DIST_STATUS_SIZE_C)
      port map (
         rst     => '0',
         clk     => axilClk,
         dataIn  => toSlv(tiDistStatus),
         dataOut => tiDistStatusSyncSlv);
   tiDistStatusSync <= toTiDistStatusType(tiDistStatusSyncSlv);

   -- Synchronize TiDistConfig to TiDistClk
   SynchronizerVector_TiDistConfig : entity surf.SynchronizerVector
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => TI_DIST_CONFIG_SIZE_C)
      port map (
         rst     => '0',
         clk     => tiDistClk,
         dataIn  => toSlv(r.tiDistConfig),
         dataOut => tiDistConfigSyncSlv);
   tiDistConfig <= toTiDistConfigType(tiDistConfigSyncSlv);

   ---------------------------------------
   -- Local Registers
   ---------------------------------------
   -- Sync
   process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process;

   -- Async
   process (axilClkRst, axilReadMaster, axilWriteMaster, r, tiDistStatusSync, tiStatusSync) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      axiSlaveWaitTxn(axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave, axiStatus);

      if r.clearCnt = 0 then
         v.tiConfig.vmeRst    := (others => '0');
         v.tiConfig.sendIDg   := '0';
         v.tiConfig.trgSrcSet := '0';
      else
         v.clearCnt := r.clearCnt - 1;
      end if;

      v.tiDistConfig.clk41Align := '0';

      -- Write
      if (axiStatus.writeEnable = '1') then

         -- Standard Address Space
         case axilWriteMaster.awaddr(15 downto 0) is
            when x"0004" =>
               v.tiConfig.crateID := axilWriteMaster.wdata(7 downto 0);
               v.tiConfig.sendIDg := '1';
               v.clearCnt         := (others => '1');
            when x"0008" =>
               v.tiConfig.busySrcEn := axilWriteMaster.wdata(15 downto 0);
            when x"0014" =>
               v.tiConfig.boardID := axilWriteMaster.wdata(4 downto 0);
               v.tiConfig.sendIDg := '1';
               v.clearCnt         := (others => '1');
            when x"0018" =>
               v.tiConfig.rocEn := axilWriteMaster.wdata(7 downto 0);
            when x"001C" =>
               v.tiConfig.boardActive := axilWriteMaster.wdata(0);
               v.tiConfig.trgSrcSet   := '1';
               v.clearCnt             := (others => '1');
            when x"0024" =>
               v.tiConfig.dataFormat := axilWriteMaster.wdata(7 downto 0);
            when x"0030" =>
               v.tiConfig.sRstReqSw := axilWriteMaster.wdata(0);
            when x"0038" =>
               v.tiConfig.scalerReset := axilWriteMaster.wdata(0);
            when x"0064" =>
               v.tiConfig.vmeRst := axilWriteMaster.wdata(15 downto 0);
               v.clearCnt        := (others => '1');
            when x"0068" =>
               v.tiConfig.trgSrcEn  := axilWriteMaster.wdata(15 downto 0);
               v.tiConfig.trgSrcSet := '1';
               v.clearCnt           := (others => '1');
            when x"00D0" =>
               v.tiConfig.gtpRst := axilWriteMaster.wdata(0);
            when x"00D4" =>
               v.tiConfig.monRst := axilWriteMaster.wdata(0);
            when x"00D8" =>
               v.tiDistConfig.countReset := axilWriteMaster.wdata(0);
            when x"00E0" =>
               v.tiDistConfig.trigSrc := axilWriteMaster.wdata(2 downto 0);
            when x"00F4" =>
               v.tiDistConfig.trigEnable := axilWriteMaster.wdata(0);
            when x"011C" =>
               v.tiConfig.localClkEn := axilWriteMaster.wdata(0);
            when x"0128" => 
               v.tiDistConfig.apvRst101 := axilWriteMaster.wdata(0);
            when x"012C" => 
               v.tiConfig.pllSwRst := axilWriteMaster.wdata(0);
            when x"013C" => 
               v.tiDistConfig.forceBusy := axilWriteMaster.wdata(0);
            when X"0144" =>
               v.tiDistConfig.clk41Align := axilWriteMaster.wdata(0);
            when X"0148" =>
               v.tiConfig.clk41Phase := axilWriteMaster.wdata(5 downto 1);
            when X"015C" =>
               v.tiDistConfig.trigDelay := axilWriteMaster.wdata(2 downto 0);
            when others =>
               null;
         end case;

         axiSlaveWriteResponse(v.axilWriteSlave);

      end if;

      -- Read
      if (axiStatus.readEnable = '1') then
         v.axilReadSlave.rdata := (others => '0');

         -- Standard address space
         case axilReadMaster.araddr(15 downto 0) is
            when x"0004" =>
               v.axilReadSlave.rdata(7 downto 0) := r.tiConfig.crateID;
            when x"0008" =>
               v.axilReadSlave.rdata(15 downto 0) := r.tiConfig.busySrcEn;
            when x"0014" =>
               v.axilReadSlave.rdata(4 downto 0) := r.tiConfig.boardID;
            when x"0018" =>
               v.axilReadSlave.rdata(7 downto 0) := r.tiConfig.rocEn;
            when x"001C" =>
               v.axilReadSlave.rdata(0) := r.tiConfig.boardActive;
            when x"0024" =>
               v.axilReadSlave.rdata(7 downto 0) := r.tiConfig.dataFormat;
            when x"0030" =>
               v.axilReadSlave.rdata(0) := r.tiConfig.sRstReqSw;
            when x"0038" =>
               v.axilReadSlave.rdata(0) := r.tiConfig.scalerReset;
            when x"0044" =>
               v.axilReadSlave.rdata(31 downto 0) := tiStatusSync.syncCode(31 downto 0);
            when x"0048" =>
               v.axilReadSlave.rdata(7 downto 0) := tiStatusSync.syncCode(39 downto 32);
            when x"004C" =>
               v.axilReadSlave.rdata(15 downto 0) := tiStatusSync.syncMonitor;
            when x"0050" =>
               v.axilReadSlave.rdata(31 downto 0) := tiStatusSync.syncMonOut;
            when x"0054" =>
               v.axilReadSlave.rdata(7 downto 0) := tiStatusSync.irqCount;
            when x"0058" =>
               v.axilReadSlave.rdata(1 downto 0) := tiStatusSync.dGFull;
            when x"005C" =>
               v.axilReadSlave.rdata(0) := tiStatusSync.dataBusy;
            when x"0060" =>
               v.axilReadSlave.rdata(31 downto 0) := tiStatusSync.trigSyncBusy;
            when x"0068" =>
               v.axilReadSlave.rdata(15 downto 0) := r.tiConfig.trgSrcEn;
            when x"0070" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(0);
            when x"0074" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(1);
            when x"0078" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(2);
            when x"007C" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(3);
            when x"0080" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(4);
            when x"0084" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(5);
            when x"0088" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(6);
            when x"008C" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackDelay(7);
            when x"0090" =>
               v.axilReadSlave.rdata := tiDistStatusSync.trigger1Count;
            when x"0094" =>
               v.axilReadSlave.rdata := tiDistStatusSync.trigRawCount;
            when x"00A4" =>
               v.axilReadSlave.rdata := tiDistStatusSync.trigger2Count;
            when x"00A8" =>
               v.axilReadSlave.rdata := tiDistStatusSync.readCount;
            when x"00AC" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(0);
            when x"00B0" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(1);
            when x"00B4" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(2);
            when x"00B8" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(3);
            when x"00BC" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(4);
            when x"00C0" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(5);
            when x"00C4" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(6);
            when x"00C8" =>
               v.axilReadSlave.rdata := tiDistStatusSync.ackCount(7);
            when x"00D0" =>
               v.axilReadSlave.rdata(0) := r.tiConfig.gtpRst;
            when x"00D4" =>
               v.axilReadSlave.rdata(0) := r.tiConfig.monRst;
            when x"00D8" =>
               v.axilReadSlave.rdata(0) := r.tiDistConfig.countReset;
            when x"00E0" =>
               v.axilReadSlave.rdata(2 downto 0) := r.tiDistConfig.trigSrc;
            when x"00E8" =>
               v.axilReadSlave.rdata(8 downto 0) := tiDistStatusSync.locBusy;
            when x"00EC" =>
               v.axilReadSlave.rdata := tiDistStatusSync.busyCount;
            when x"00F0" =>
               v.axilReadSlave.rdata := tiDistStatusSync.trigTxCount;
            when x"00F4" =>
               v.axilReadSlave.rdata(0) := r.tiDistConfig.trigEnable;
            when x"0110" =>
               v.axilReadSlave.rdata(7 downto 0) := tiStatusSync.blockLevel;
            when x"011C" =>
               v.axilReadSlave.rdata(0) := r.tiConfig.localClkEn;
            when x"0128" =>
               v.axilReadSlave.rdata(0) := r.tiDistConfig.apvRst101;
            when x"012C" => 
               v.axilReadSlave.rdata(0) := r.tiConfig.pllSwRst;
            when x"0130" => 
               v.axilReadSlave.rdata(0) := tiStatusSync.pllLocked;
               v.axilReadSlave.rdata(1) := tiStatusSync.tiBusySig;
               v.axilReadSlave.rdata(2) := tiStatusSync.trgSendEn;
            when x"0134" => 
               v.axilReadSlave.rdata(15 downto 0) := tiStatusSync.sReset;
            when x"0138" => 
               v.axilReadSlave.rdata(15 downto 0) := tiDistStatusSync.sResetReg;
            when x"013C" => 
               v.axilReadSlave.rdata(0) := r.tiDistConfig.forceBusy;
            when x"0140" => 
               v.axilReadSlave.rdata := tiDistStatusSync.trigMin;
            when X"0144" =>
               v.axilReadSlave.rdata(0) := r.tiDistConfig.clk41Align;
            when X"0148" =>
               v.axilReadSlave.rdata(0) := tiStatusSync.distClkPhase;
               v.axilReadSlave.rdata(5 downto 1) := r.tiConfig.clk41Phase;
            when X"014C" =>
               v.axilReadSlave.rdata(15 downto 0) := tiDistStatusSync.syncCount;
            when X"0150" =>
               v.axilReadSlave.rdata(15 downto 0) := tiDistStatusSync.syncSentCount;
            when X"0154" =>
               v.axilReadSlave.rdata := tiDistStatusSync.filterBusyCount;
            when X"0158" =>
               v.axilReadSlave.rdata := tiDistStatusSync.filterBusyRate;
            when X"015C" =>
               v.axilReadSlave.rdata(2 downto 0) := r.tiDistConfig.trigDelay;
            when others =>
               null;
         end case;

         axiSlaveReadResponse(v.axilReadSlave);

      end if;

      -- Reset
      if (axilClkRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Next register assignment
      rin <= v;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;

   end process;

end architecture STRUCTURE;

