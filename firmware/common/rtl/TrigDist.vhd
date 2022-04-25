-------------------------------------------------------------------------------
-- Title         : JLAB TI Wrapper
-- File          : TrigDist.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 07/16/2014
-------------------------------------------------------------------------------
-- Description:
-- Trigger / Timing Distribution
-------------------------------------------------------------------------------
-- Copyright (c) 2014 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 07/16/2014: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.STD_LOGIC_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library hps_daq;
use hps_daq.JlabTiPkg.all;
use hps_daq.HpsTiPkg.all;

entity TrigDist is
   generic (
      TPD_G     : time    := 1 ns;
      NEW_RTM_G : boolean := false
      );
   port (

      -- AXI Interface
      axilClk         : in  sl;
      axilClkRst      : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- System Clocks
      sysClk200    : in sl;
      sysClk200Rst : in sl;
      sysClk125    : in sl;
      sysClk125Rst : in sl;

      -- Ref Clock
      locRefClkP : in sl;
      locRefClkM : in sl;

      -- TS Signals
      dtmToRtmLsP : inout slv(5 downto 0);
      dtmToRtmLsM : inout slv(5 downto 0);

      -- Spare Signals
      plSpareP : inout slv(4 downto 0);
      plSpareM : inout slv(4 downto 0);

      -- Timing Codes
      distClk    : out sl;
      distClkRst : out sl;
      txData     : out Slv10Array(1 downto 0);
      txDataEn   : out slv(1 downto 0);
      txReady    : in  slv(1 downto 0);
      rxData     : in  Slv10Array(7 downto 0);
      rxDataEn   : in  slv(7 downto 0);

      -- Serial IO
      gtTxP : out sl;
      gtTxN : out sl;
      gtRxP : in  sl;
      gtRxN : in  sl
      );

begin
end TrigDist;

architecture STRUCTURE of TrigDist is

   -- Signals
   signal daqDataEn      : sl;
   signal daqDataEnInt   : sl;
   signal daqData        : slv(71 downto 0);
   signal tiDistClk      : sl;
   signal tiDistClkRst   : sl;
   signal apvClkSync     : sl;
   signal trigger1       : sl;
   signal trigger2       : sl;
   signal trigRaw        : sl;
   signal dpmBusy        : sl;
   signal dpmBusyDly     : sl;
   signal filterBusyDly  : sl;
   signal rocAckIn       : slv(7 downto 0);
   signal rocBusyIn      : slv(7 downto 0);
   signal readTimeCount  : slv(31 downto 0);
   signal trigger1Dly    : sl;
   signal trigger2Dly    : sl;
   signal trigRawDly     : sl;
   signal trigger1Edge   : sl;
   signal trigger2Edge   : sl;
   signal trigRawEdge    : sl;
   signal tiConfig       : JlabTiConfigType;
   signal tiStatus       : JlabTiStatusType;
   signal tiDistStatus   : TiDistStatusType;
   signal tiDistConfig   : TiDistConfigType;
   signal trigPulse      : slv(7 downto 0);
   signal readPause      : sl;
   signal readDone       : sl;
   signal trigTxDone     : sl;
   signal tiClkInP       : sl;
   signal tiClkInM       : sl;
   signal apvRst101Dly   : sl;
   signal apvRst101Edge  : sl;
   signal clk41AlignDly  : sl;
   signal clk41AlignEdge : sl;
   signal syncOut        : sl;
   signal syncOutEdge    : sl;
   signal trigPeriod     : slv(31 downto 0);
   signal syncSentCount  : slv(15 downto 0);
   signal trigFilterBusy : sl;
   signal filterBusyRate : slv(31 downto 0);

   attribute dont_touch : string;
   attribute dont_touch of apvClkSync : signal is "true";
   attribute dont_touch of trigger1   : signal is "true";
   attribute dont_touch of trigger2   : signal is "true";
   attribute dont_touch of trigRaw    : signal is "true";
   attribute dont_touch of dpmBusy    : signal is "true";
   attribute dont_touch of rocAckIn   : signal is "true";
   attribute dont_touch of rocBusyIn  : signal is "true";
   attribute dont_touch of daqDataEn  : signal is "true";
   attribute dont_touch of daqData    : signal is "true";

begin

   U_OldRtmGen : if NEW_RTM_G = false generate
      tiClkInP <= dtmToRtmLsP(0);
      tiClkInM <= dtmToRtmLsM(0);
   end generate;

   U_NewRtmGen : if NEW_RTM_G = true generate
      tiClkInP <= dtmToRtmLsP(1);
      tiClkInM <= dtmToRtmLsM(1);
   end generate;

   -- TI
   U_JlabTi : entity hps_daq.JlabTi
      generic map (
         TPD_G => TPD_G
         )
      port map (
         sysClk200    => sysClk200,
         sysClk200Rst => sysClk200Rst,
         tiConfig     => tiConfig,
         tiStatus     => tiStatus,
         gtTxP        => gtTxP,
         gtTxN        => gtTxN,
         gtRxP        => gtRxP,
         gtRxN        => gtRxN,
         clkRefInP    => locRefClkP,
         clkRefInM    => locRefClkM,
         tiClk250P    => tiClkInP,
         tiClk250M    => tiClkInM,
         syncFpN      => plSpareM(0),
         syncFpP      => plSpareP(0),
         syncInN      => dtmToRtmLsM(5),
         syncInP      => dtmToRtmLsP(5),
         syncSubN     => plSpareM(1),
         syncSubP     => plSpareP(1),
         syncCodedN   => plSpareM(2),
         syncCodedP   => plSpareP(2),
         busyAN       => plSpareM(3),
         busyAP       => plSpareP(3),
         busyBN       => plSpareM(4),
         busyBP       => plSpareP(4),
         daqDataEn    => daqDataEn,
         daqData      => daqData,
         tiDistClk    => tiDistClk,
         tiDistClkRst => tiDistClkRst,
         apvClkSync   => apvClkSync,
         trigger1     => trigger1,
         trigger2     => trigger2,
         trigRaw      => trigRaw,
         syncOut      => syncOut,
         dpmBusy      => dpmBusy,
         rocAckIn     => rocAckIn
         );

   distClk      <= tiDistClk;
   distClkRst   <= tiDistClkRst;
   daqDataEnInt <= daqDataEn when (tiDistConfig.trigEnable = '1' and tiDistConfig.readSrc = 0) else '0';


   -- TI Data
   U_TiDataSend : entity hps_daq.TiDataSend
      generic map (
         TPD_G => TPD_G
         )
      port map (
         tiDistClk     => tiDistClk,
         tiDistClkRst  => tiDistClkRst,
         daqDataEn     => daqDataEnInt,
         daqData       => daqData,
         blockLevel    => tiStatus.blockLevel,
         syncEvent     => syncOutEdge,
         txData        => txData(1),
         txDataEn      => txDataEn(1),
         txReady       => txReady(1),
         readPause     => readPause,
         readDone      => readDone,
         trigTxDone    => trigTxDone,
         syncSentCount => syncSentCount
         );

   TriggerFilter_1 : entity hps_daq.TriggerFilter
      generic map (
         TPD_G             => TPD_G,
         CLK_PERIOD_G      => 8.0E-9,
         TRIGGER_TIME_G    => 21.0E-6,
         MAX_OUTSTANDING_G => 5)
      port map (
         clk     => tiDistClk,
         rst     => tiDistClkRst,
         trigger => trigger1Edge,
         busy    => trigFilterBusy);

   SyncTrigRate_1: entity surf.SyncTrigRate
      generic map (
         TPD_G          => TPD_G,
         COMMON_CLK_G   => true,
         IN_POLARITY_G  => '1',
         REF_CLK_FREQ_G => 125.0E6,
         REFRESH_RATE_G => 1.0E0,
         USE_DSP48_G    => "no",
         CNT_WIDTH_G    => 32)
      port map (
         trigIn          => trigFilterBusy,
         trigRateUpdated => open,
         trigRateOut     => filterBusyRate,
         locClkEn        => '1',
         locClk          => tiDistClk,
         refClk          => tiDistClk);

   SynchronizerEdge_1 : entity surf.SynchronizerEdge
      generic map (
         TPD_G => TPD_G)
      port map (
         clk        => tiDistClk,
         rst        => tiDistClkRst,
         dataIn     => syncOut,
         risingEdge => syncOutEdge);


   -- Trigger processing
   process (tiDistClk)
   begin
      if rising_edge(tiDistClk) then
         if tiDistClkRst = '1' then
            tiDistStatus   <= TI_DIST_STATUS_INIT_C after TPD_G;
            rocBusyIn      <= (others => '0')       after TPD_G;
            rocAckIn       <= (others => '0')       after TPD_G;
            dpmBusy        <= '0'                   after TPD_G;
            dpmBusyDly     <= '0'                   after TPD_G;
            trigger1Dly    <= '0'                   after TPD_G;
            trigger2Dly    <= '0'                   after TPD_G;
            trigRawDly     <= '0'                   after TPD_G;
            trigger1Edge   <= '0'                   after TPD_G;
            trigger2Edge   <= '0'                   after TPD_G;
            trigRawEdge    <= '0'                   after TPD_G;
            trigPulse      <= (others => '0')       after TPD_G;
            readTimeCount  <= (others => '0')       after TPD_G;
            txData(0)      <= (others => '0')       after TPD_G;
            txDataEn(0)    <= '0'                   after TPD_G;
            apvRst101Dly   <= '0'                   after TPD_G;
            apvRst101Edge  <= '0'                   after TPD_G;
            clk41AlignDly  <= '0'                   after TPD_G;
            clk41AlignEdge <= '0'                   after TPD_G;
            trigPeriod     <= (others => '0')       after TPD_G;
         else
            tiDistStatus.filterBusyRate <= filterBusyRate after TPD_G;

            -- sReset history
            if tiDistConfig.countReset = '1' then
               tiDistStatus.sResetReg <= (others => '0') after TPD_G;
            else
               tiDistStatus.sResetReg <= tiDistStatus.sResetReg or tiStatus.sReset after TPD_G;
            end if;

            -- Each DPM
            for i in 0 to 7 loop
               rocAckIn(i) <= '0' after TPD_G;

               -- Busy / Ack Generation
               if tiDistConfig.countReset = '1' then
                  rocBusyIn(i) <= '0' after TPD_G;
               elsif rxDataEn(i) = '1' then
                  if rxData(i) = TI_ACK_CODE_C then
                     rocAckIn(i) <= '1' after TPD_G;
                  elsif rxData(i) = TI_BUSY_ON_CODE_C then
                     rocBusyIn(i) <= '1' after TPD_G;
                  elsif rxData(i) = TI_BUSY_OFF_CODE_C then
                     rocBusyIn(i) <= '0' after TPD_G;
                  end if;
               end if;

               -- Ack count and delay
               if tiDistConfig.countReset = '1' then
                  tiDistStatus.ackCount(i) <= (others => '0') after TPD_G;
                  tiDistStatus.ackDelay(i) <= (others => '0') after TPD_G;
               elsif rocAckIn(i) = '1' then
                  tiDistStatus.ackCount(i) <= tiDistStatus.ackCount(i) + 1 after TPD_G;
                  tiDistStatus.ackDelay(i) <= readTimeCount                after TPD_G;
               end if;
            end loop;

            -- Combine busy signals
            if rocBusyIn = 0 and readPause = '0' and tiDistConfig.forceBusy = '0' and trigFilterBusy = '0' then
               dpmBusy <= '0' after TPD_G;
            else
               dpmBusy <= '1' after TPD_G;
            end if;
            tiDistStatus.locBusy <= (readPause & rocBusyIn) after TPD_G;
            dpmBusyDly           <= dpmBusy                 after TPD_G;
            filterBusyDly        <= trigFilterBusy          after TPD_G;

            -- Delay
            trigger1Dly <= trigger1 after TPD_G;
            trigger2Dly <= trigger2 after TPD_G;
            trigRawDly  <= trigRaw  after TPD_G;

            -- Edge
            trigger1Edge <= (not trigger1) and trigger1Dly after TPD_G;
            trigger2Edge <= trigger2 and (not trigger2Dly) after TPD_G;
            trigRawEdge  <= trigRaw and (not trigRawDly)   after TPD_G;

            -- Counters
            if tiDistConfig.countReset = '1' then
               tiDistStatus.trigger1Count   <= (others => '0') after TPD_G;
               tiDistStatus.trigger2Count   <= (others => '0') after TPD_G;
               tiDistStatus.trigRawCount    <= (others => '0') after TPD_G;
               tiDistStatus.readCount       <= (others => '0') after TPD_G;
               tiDistStatus.busyCount       <= (others => '0') after TPD_G;
               tiDistStatus.filterBusyCount <= (others => '0') after TPD_G;
               tiDistStatus.trigTxCount     <= (others => '0') after TPD_G;
               tiDistStatus.trigMin         <= (others => '1') after TPD_G;
               tiDistStatus.syncCount       <= (others => '0') after TPD_G;
               tiDistStatus.syncSentCount   <= (others => '0') after TPD_G;
            else
               tiDistStatus.syncSentCount <= syncSentCount after TPD_G;

               if trigger1Edge = '1' then
                  tiDistStatus.trigger1Count <= tiDistStatus.trigger1Count + 1 after TPD_G;

                  if trigPeriod < tiDistStatus.trigMin then
                     tiDistStatus.trigMin <= trigPeriod after TPD_G;
                  end if;

                  trigPeriod <= (others => '0') after TPD_G;
               else
                  trigPeriod <= trigPeriod + 1 after TPD_G;
               end if;

               if trigger2Edge = '1' then
                  tiDistStatus.trigger2Count <= tiDistStatus.trigger2Count + 1 after TPD_G;
               end if;

               if trigRawEdge = '1' then
                  tiDistStatus.trigRawCount <= tiDistStatus.trigRawCount + 1 after TPD_G;
               end if;

               if (syncOutEdge = '1') then
                  tiDistStatus.syncCount <= tiDistStatus.syncCount +1 after TPD_G;
               end if;

               if readDone = '1' then
                  tiDistStatus.readCount <= tiDistStatus.readCount + 1 after TPD_G;
               end if;

               if trigTxDone = '1' then
                  tiDistStatus.trigTxCount <= tiDistStatus.trigTxCount + 1 after TPD_G;
               end if;

               if dpmBusy = '1' and dpmBusyDly = '0' then
                  tiDistStatus.busyCount <= tiDistStatus.busyCount + 1 after TPD_G;
               end if;

               if trigFilterBusy = '1' and filterBusyDly = '0' then
                  tiDistStatus.filterBusyCount <= tiDistStatus.filterBusyCount + 1 after TPD_G;
               end if;
            end if;

            -- Software Gen
            apvRst101Dly   <= tiDistConfig.apvRst101                          after TPD_G;
            apvRst101Edge  <= tiDistConfig.apvRst101 and (not apvRst101Dly)   after TPD_G;
            clk41AlignDly  <= tiDistConfig.clk41Align                         after TPD_G;
            clk41AlignEdge <= tiDistConfig.clk41Align and (not clk41AlignDly) after TPD_G;

            -- Trig source selection
            trigPulse(7 downto 1) <= trigPulse(6 downto 0) after TPD_G;            
            if tiDistConfig.trigEnable = '1' then
               case tiDistConfig.trigSrc is
                  when "000"  => trigPulse(0) <= '0'          after TPD_G;
                  when "001"  => trigPulse(0) <= trigger1Edge after TPD_G;
                  when "010"  => trigPulse(0) <= trigger2Edge after TPD_G;
                  when "011"  => trigPulse(0) <= trigRawEdge  after TPD_G;
                  when others => trigPulse(0) <= '0'          after TPD_G;
               end case;
            else
               trigPulse(0) <= '0' after TPD_G;
            end if;


            -- Read time count
            if tiDistConfig.countReset = '1' or readDone = '1' then
               readTimeCount <= (others => '0') after TPD_G;
            else
               readTimeCount <= readTimeCount + 1 after TPD_G;
            end if;

            -- Send Trig Pulse   
            if apvClkSync = '1' then
               txData(0)   <= TI_ALIGN_CODE_C after TPD_G;
               txDataEn(0) <= '1'             after TPD_G;
            elsif trigPulse(conv_integer(tiDistConfig.trigDelay)) = '1' then
               txData(0)   <= TI_TRIG_CODE_C after TPD_G;
               txDataEn(0) <= '1'            after TPD_G;
            elsif (apvRst101Edge = '1') then
               txData(0)   <= TI_APV_RESET_101_C after TPD_G;
               txDataEn(0) <= '1'                after TPD_G;
            else
               txDataEn(0) <= '0' after TPD_G;
            end if;
         end if;
      end if;
   end process;


   -- TI Registers
   U_TiReg : entity hps_daq.TiRegisters
      generic map (
         TPD_G => TPD_G
         ) port map (
            axilClk         => axilClk,
            axilClkRst      => axilClkRst,
            axilReadMaster  => axilReadMaster,
            axilReadSlave   => axilReadSlave,
            axilWriteMaster => axilWriteMaster,
            axilWriteSlave  => axilWriteSlave,
            tiDistClk       => tiDistClk,
            tiConfig        => tiConfig,
            tiStatus        => tiStatus,
            tiDistConfig    => tiDistConfig,
            tiDistStatus    => tiDistStatus
            );

end architecture STRUCTURE;

