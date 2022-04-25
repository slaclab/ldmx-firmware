-------------------------------------------------------------------------------
-- Title         : Trigger Data Receiver
-- File          : TiDataRx.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 02/12/2015
-------------------------------------------------------------------------------
-- Description:
-- TI Data Receiver For Data and Control DPMs
-- Version 2 which breaks trigger frame into individual evio records, one per
-- event. Data bank builder uses these to determine what data records are 
-- required. External event/block tracking FIFO no longer needed.
-- User bit 0 is set to '1' for the last trigger event in a readout block.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 02/12/2015: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library hps_daq;
use hps_daq.HpsPkg.all;
use hps_daq.HpsTiPkg.all;

entity TiDataRx is
   generic (
      TPD_G : time := 1 ns
      );
   port (

      -- Trigger Data
      axisClk     : in  sl;
      axisClkRst  : in  sl;
      trgIbMaster : out AxiStreamMasterType;
      trgIbSlave  : in  AxiStreamSlaveType;
      dmaState    : in  RceDmaStateType;

      -- Control and Status
      trigEnable   : in  sl;
      countReset   : in  sl;
      tiDataCount  : out slv(31 downto 0);
      tiTrigCount  : out slv(31 downto 0);
      tiBusyCount  : out slv(31 downto 0);
      tiAckCount   : out slv(31 downto 0);
      tiAlignCount : out slv(31 downto 0);
      pauseStatus  : out slv(1 downto 0);
      trigOverFlow : out sl;
      extDataPause : in  sl;
      blockLevel   : out slv(7 downto 0);

      -- Sync to distClk
      distClk     : in  sl;
      distClkRst  : in  sl;
      extDataTrig : out sl;
      rxData      : in  Slv10Array(1 downto 0);
      rxDataEn    : in  slv(1 downto 0);
      txData      : out slv(9 downto 0);
      txDataEn    : out sl;
      txReady     : in  sl
      );
end TiDataRx;

architecture STRUCTURE of TiDataRx is

   ----------------------------------
   -- Trig / response signals
   ----------------------------------
   signal itrigEnable   : sl;
   signal icountReset   : sl;
   signal itrigPause    : sl;
   signal itrigOverflow : sl;
   signal iextDataPause : sl;
   signal dmaAckEdge    : sl;
   signal locFifoRst    : sl;
   signal rxTrigCtrl    : AxiStreamCtrlType;
   signal rxTrigMaster  : AxiStreamMasterType;

   type TrigType is record
      txData        : slv(9 downto 0);
      txDataEn      : sl;
      ackCountEn    : sl;
      ackPending    : sl;
      extDataTrig   : sl;
      currPause     : slv(1 downto 0);
      lastPause     : slv(1 downto 0);
      busyUpdateCnt : slv(11 downto 0);
      tiTrigCount   : slv(31 downto 0);
      tiAckCount    : slv(31 downto 0);
      tiDataCount   : slv(31 downto 0);
      tiBusyCount   : slv(31 downto 0);
      tiAlignCount  : slv(31 downto 0);
      trigOverFlow  : sl;
   end record TrigType;

   constant TRIG_INIT_C : TrigType := (
      txData        => (others => '0'),
      txDataEn      => '0',
      ackCountEn    => '0',
      ackPending    => '0',
      extDataTrig   => '0',
      currPause     => (others => '0'),
      lastPause     => (others => '0'),
      busyUpdateCnt => (others => '1'),
      tiTrigCount   => (others => '0'),
      tiAckCount    => (others => '0'),
      tiDataCount   => (others => '0'),
      tiBusyCount   => (others => '0'),
      tiAlignCount  => (others => '0'),
      trigOverFlow  => '0'
      );

   signal t   : TrigType := TRIG_INIT_C;
   signal tin : TrigType;

begin

   ----------------------------------
   -- Control Sync
   ----------------------------------

   U_CountRst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         BYPASS_SYNC_G   => false,
         RELEASE_DELAY_G => 3
         ) port map (
            clk      => distClk,
            asyncRst => countReset,
            syncRst  => icountReset
            );

   U_AckSync : entity surf.SynchronizerEdge
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         OUT_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 3,
         BYPASS_SYNC_G  => false,
         INIT_G         => "0"
         ) port map (
            clk         => distClk,
            rst         => distClkRst,
            dataIn      => dmaState.user,
            dataOut     => open,
            risingEdge  => dmaAckEdge,
            fallingEdge => open
            );

   U_Sync : entity surf.SynchronizerVector
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         OUT_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 2,
         BYPASS_SYNC_G  => false,
         WIDTH_G        => 4,
         INIT_G         => "0"
         ) port map (
            clk        => distClk,
            rst        => distClkRst,
            dataIn(0)  => trigEnable,
            dataIn(1)  => extDataPause,
            dataIn(2)  => rxTrigCtrl.pause,
            dataIn(3)  => rxTrigCtrl.overflow,
            dataOut(0) => itrigEnable,
            dataOut(1) => iextDataPause,
            dataOut(2) => itrigPause,
            dataOut(3) => itrigOverflow
            );


   ----------------------------------
   -- Trig code and response links
   ----------------------------------

   -- Sync
   process (distClk) is
   begin
      if (rising_edge(distClk)) then
         t <= tin after TPD_G;
      end if;
   end process;

   -- Async
   process (distClkRst, t, rxData, rxDataEn, dmaAckEdge, icountReset, itrigEnable,
            rxTrigMaster, itrigOverflow, iextDataPause, itrigPause, txReady) is
      variable v : TrigType;
   begin
      v := t;

      -- Init
      v.extDataTrig := '0';
      v.ackCountEn  := '0';
      v.txDataEn    := '0';

      -- Ack processing
      if dmaAckEdge = '1' then
         v.ackCountEn := '1';
         v.ackPending := '1';
      end if;

      -- Pause update detection
      v.currPause(0) := itrigPause;
      v.currPause(1) := iextDataPause;
      v.lastPause    := t.currPause;

      -- Track Edges, clear counter
      if t.currPause /= t.lastPause then
         v.busyUpdateCnt := (others => '1');

         if t.currPause /= 0 then
            v.tiBusyCount := t.tiBusyCount + 1;
         end if;

      elsif t.busyUpdateCnt /= 0 then
         v.busyUpdateCnt := t.busyUpdateCnt - 1;
      end if;

      -- Determine what to transmit
      if txReady = '1' and t.txDataEn = '0' then
         if t.ackPending = '1' then
            v.txDataEn   := itrigEnable;
            v.txData     := TI_ACK_CODE_C;
            v.tiAckCount := t.tiAckCount + 1;
            v.ackPending := '0';
         elsif t.busyUpdateCnt = 0 then
            v.txDataEn      := itrigEnable;
            v.busyUpdateCnt := (others => '1');

            if t.currPause = 0 then
               v.txData := TI_BUSY_OFF_CODE_C;
            else
               v.txData := TI_BUSY_ON_CODE_C;
            end if;
         end if;
      end if;

      -- Trigger Code
      if rxData(0) = TI_TRIG_CODE_C and rxDataEn(0) = '1' and itrigEnable = '1' then
         v.tiTrigCount := t.tiTrigCount + 1;
         v.extDataTrig := '1';
      end if;

      if (rxData(0) = TI_ALIGN_CODE_C and rxDataEn(0) = '1') then
         v.tiAlignCount := t.tiAlignCount + 1;
      end if;

      -- Readout
      if rxTrigMaster.tValid = '1' and rxTrigMaster.tLast = '1' then
         v.tiDataCount := t.tiDataCount + 1;
      end if;

      -- Overflow Detect
      if itrigOverflow = '1' then
         v.trigOverFlow := '1';
      end if;


      -- Counter Reset
      if icountReset = '1' then
         v.tiTrigCount  := (others => '0');
         v.tiAckCount   := (others => '0');
         v.tiDataCount  := (others => '0');
         v.tiBusyCount  := (others => '0');
         v.tiAlignCount := (others => '0');
         v.trigOverFlow := '0';
      end if;



      -- Reset
      if (distClkRst = '1') then
         v := TRIG_INIT_C;
      end if;

      -- Next register assignment
      tin <= v;

      -- External
      extDataTrig  <= t.extDataTrig;
      tiDataCount  <= t.tiDataCount;
      tiBusyCount  <= t.tiBusyCount;
      tiTrigCount  <= t.tiTrigCount;
      tiAckCount   <= t.tiAckCount;
      tiAlignCount <= t.tiAlignCount;
      txData       <= t.txData;
      txDataEn     <= t.txDataEn;
      pauseStatus  <= t.currPause;
      trigOverFlow <= t.trigOverFlow;

   end process;

   ----------------------------------
   -- Trigger Data Processing
   ----------------------------------

   -- FIFO Setup
   process (distClk)
   begin
      if rising_edge(distClk) then
         if distClkRst = '1' then
            rxTrigMaster <= AXI_STREAM_MASTER_INIT_C after TPD_G;
            blockLevel   <= (others => '0')          after TPD_G;
            locFifoRst   <= '1'                      after TPD_G;
         else
            rxTrigMaster.tValid <= rxData(1)(9) and rxDataEn(1) and itrigEnable after TPD_G;
            rxTrigMaster.tLast  <= rxData(1)(8)                                 after TPD_G;

            rxTrigMaster.tData(7 downto 0) <= rxData(1)(7 downto 0) after TPD_G;

            if rxDataEn(1) = '1' and rxData(1)(9 downto 8) = "00" then
               blockLevel <= rxData(1)(7 downto 0) after TPD_G;
            end if;

            locFifoRst <= not itrigEnable after TPD_G;

         end if;
      end if;
   end process;


   -- FIFO to convert 8-bit stream to 64-bits, 
   -- Convert to AXIS-Clock from Dist CLock
   U_TrigIbFifo : entity surf.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         PIPE_STAGES_G       => 0,
         SLAVE_READY_EN_G    => false,
         VALID_THOLD_G       => 1,
         MEMORY_TYPE_G       => "block",
         XIL_DEVICE_G        => "7SERIES",
         USE_BUILT_IN_G      => false,
         GEN_SYNC_FIFO_G     => false,
         CASCADE_SIZE_G      => 1,
         FIFO_ADDR_WIDTH_G   => 9,      -- 512 x 64
         FIFO_FIXED_THRESH_G => true,
         FIFO_PAUSE_THRESH_G => 400,
         SLAVE_AXI_CONFIG_G  => TRG_8B_DATA_CONFIG_C,
         MASTER_AXI_CONFIG_G => HPS_DMA_DATA_CONFIG_C
         )
      port map (
         sAxisClk    => distClk,
         sAxisRst    => locFifoRst,
         sAxisMaster => rxTrigMaster,
         sAxisSlave  => open,
         sAxisCtrl   => rxTrigCtrl,
         mAxisClk    => axisClk,
         mAxisRst    => axisClkRst,
         mAxisMaster => trgIbMaster,
         mAxisSlave  => trgIbSlave
         );

end architecture STRUCTURE;

