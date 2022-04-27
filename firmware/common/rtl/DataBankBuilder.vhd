-------------------------------------------------------------------------------
-- Title         : Data Bank Builder For DPM
-- File          : DataBankBuilder.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/10/2013
-------------------------------------------------------------------------------
-- Description:
-- Data bank builder for HPS.
-- Version 2. This version gets one event block and one trigger block for each
-- trigger. These blocks are formed into a single readout block for dma. 
-- Final dma block is not wrapped in an EVIO frame.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 12/10/2013: created.
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
use surf.AxiPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library ldmx;
use ldmx.HpsPkg.all;

entity DataBankBuilder is
   generic (
      TPD_G   : time    := 1 ns;
      DATA_EN : boolean := true
      );
   port (

      -- Clock
      axisClk    : in sl;
      axisClkRst : in sl;

      -- Config
      emulateEnable : in sl;
      countReset    : in sl;
      rocId         : in slv(7 downto 0);
      trigEnable    : in sl;

      -- Status
      blockCount : out slv(31 downto 0);
      eventCount : out slv(31 downto 0);
      eventState : out slv(3 downto 0);

      -- Slave Ports
      trgIbMaster : in  AxiStreamMasterType;
      trgIbSlave  : out AxiStreamSlaveType;
      eventMaster : in  AxiStreamMasterType;
      eventSlave  : out AxiStreamSlaveType;
      emuMaster   : in  AxiStreamMasterType;
      emuSlave    : out AxiStreamSlaveType;

      -- Master Port
      dmaIbMaster : out AxiStreamMasterType;
      dmaIbSlave  : in  AxiStreamSlaveType

      );
end DataBankBuilder;

architecture STRUCTURE of DataBankBuilder is

   type StateType is (TRIG_DIS_S, TRIG_HEAD_S, TRIG_READ0_S, TRIG_READ1_S, OB_CALC_S,
                      OB_HEAD_S, OB_TRIG0_S, OB_TRIG1_S, OB_TRIG2_S, OB_DATA_S, OB_NEXT_S);

   type RegType is record
      state       : StateType;
      inFrame     : sl;
      obSize      : slv(31 downto 0);
      eventCount  : slv(31 downto 0);
      blockCount  : slv(31 downto 0);
      evioHeader  : slv(31 downto 0);
      trigData0   : slv(63 downto 0);
      trigData1   : slv(63 downto 0);
      intIbMaster : AxiStreamMasterType;
      trgIbSlave  : AxiStreamSlaveType;
      dataSlave   : AxiStreamSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state       => TRIG_DIS_S,
      inFrame     => '0',
      obSize      => (others => '0'),
      eventCount  => (others => '0'),
      blockCount  => (others => '0'),
      evioHeader  => (others => '0'),
      trigData0   => (others => '0'),
      trigData1   => (others => '0'),
      intIbMaster => AXI_STREAM_MASTER_INIT_C,
      trgIbSlave  => AXI_STREAM_SLAVE_INIT_C,
      dataSlave   => AXI_STREAM_SLAVE_INIT_C
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal muxMaster      : AxiStreamMasterType;
   signal muxSlave       : AxiStreamSlaveType;
   signal dataMaster     : AxiStreamMasterType;
   signal dataSlave      : AxiStreamSlaveType;
   signal icountReset    : sl;
   signal iemulateEn     : sl;
   signal iemulateEnable : sl;
   signal intIbCtrl      : AxiStreamCtrlType;
   signal intIbMaster    : AxiStreamMasterType;
   signal irocId         : slv(7 downto 0);
   signal itrigEnable    : sl;
   signal dataHeader     : slv(31 downto 0);

begin

   U_CountRst : entity surf.RstSync
      generic map (
         TPD_G           => TPD_G,
         IN_POLARITY_G   => '1',
         OUT_POLARITY_G  => '1',
         BYPASS_SYNC_G   => false,
         RELEASE_DELAY_G => 3
         ) port map (
            clk      => axisClk,
            asyncRst => countReset,
            syncRst  => icountReset
            );

   U_Sync : entity surf.SynchronizerVector
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         OUT_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 2,
         BYPASS_SYNC_G  => false,
         WIDTH_G        => 10,
         INIT_G         => "0"
         ) port map (
            clk                 => axisClk,
            rst                 => axisClkRst,
            dataIn(7 downto 0)  => rocId,
            dataIn(8)           => emulateEnable,
            dataIn(9)           => trigEnable,
            dataOut(7 downto 0) => irocId,
            dataOut(8)          => iemulateEnable,
            dataOut(9)          => itrigEnable
            );


   ----------------------------------------
   -- Data MUX and EVIO wrapper
   ----------------------------------------

   -- MUX
   muxMaster  <= eventMaster when iemulateEnable = '0' else emuMaster;
   eventSlave <= muxSlave    when iemulateEnable = '0' else AXI_STREAM_SLAVE_FORCE_C;
   emuSlave   <= muxSlave    when iemulateEnable = '1' else AXI_STREAM_SLAVE_FORCE_C;

   -- Data header
   dataHeader(31 downto 16) <= x"0003";
   dataHeader(15 downto 14) <= "00";
   dataHeader(13 downto 8)  <= "000001";
   dataHeader(7 downto 0)   <= irocId;

   -- EVIO conversion & FIFO for events
   U_DataEvio : entity ldmx.AxisToEvio
      generic map (
         TPD_G             => TPD_G,
         IB_CASCADE_SIZE_G => 12
         )
      port map (
         axisClk     => axisClk,
         axisClkRst  => axisClkRst,
         evioHeader  => dataHeader,
         sAxisMaster => muxMaster,
         sAxisSlave  => muxSlave,
         mAxisMaster => dataMaster,
         mAxisSlave  => dataSlave
         );


   ----------------------------------------
   -- Data Mover
   ----------------------------------------
   eventState <= x"0" when r.state = TRIG_DIS_S else
                 x"1" when r.state = TRIG_HEAD_S else
                 x"2" when r.state = TRIG_READ0_S else
                 x"3" when r.state = TRIG_READ1_S else
                 x"4" when r.state = OB_CALC_S else
                 x"5" when r.state = OB_HEAD_S else
                 x"6" when r.state = OB_TRIG0_S else
                 x"7" when r.state = OB_TRIG1_S else
                 x"8" when r.state = OB_TRIG2_S else
                 x"9" when r.state = OB_DATA_S else
                 x"A" when r.state = OB_NEXT_S else
                 x"F";

   -- Sync
   process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process;

   -- Async
   process (axisClkRst, r, trgIbMaster, dataMaster, intIbCtrl, icountReset, itrigEnable, irocId)
      variable v : RegType;
   begin
      v := r;

      -- Init
      v.intIbMaster := AXI_STREAM_MASTER_INIT_C;
      v.trgIbSlave  := AXI_STREAM_SLAVE_INIT_C;
      v.dataSlave   := AXI_STREAM_SLAVE_INIT_C;

      -- State Machine
      case r.state is

         -- Trigger disabled, end in progress frames
         when TRIG_DIS_S =>
            v.inFrame            := '0';
            v.intIbMaster.tLast  := '1';
            v.trgIbSlave         := AXI_STREAM_SLAVE_FORCE_C;
            v.dataSlave          := AXI_STREAM_SLAVE_FORCE_C;
            v.state              := TRIG_HEAD_S;
            v.intIbMaster.tValid := r.inFrame;

         -- Waiting on trigger head
         -- Header 0 (appears in 31:0):
         --    bit(31:27): 10000, block header indicator;
         --    Bit(26:22): BoardID, the VME64x geographic address (slot number);
         --    Bit(21:18): 0000, ID for TI board;
         --    Bit(17:08): block number, lower ten bits;
         --    Bit(07:00): block size (as set by A24 register 0x14);
         -- Header 1 (appears in 63:32):
         --    Bit(31:17): 1111,1111,0001,000X; or 0xFF1X;
         --    Bit(16)   : TimeStamp, 1 if timestamp is available, 0 if not;
         --    Bit(15:08): 0010,0000, or 0x20;
         --    Bit(07:00): Block size;
         when TRIG_HEAD_S =>
            v.trigData0         := (others => '0');
            v.trigData1         := (others => '0');
            v.trgIbSlave.tReady := '1';

            -- Trigger is ready and FIFO is not paused
            if trgIbMaster.tValid = '1' then
               v.state := TRIG_READ0_S;
            end if;

         -- Read trigger event word 0
         -- Event 0 (appears in 31:0):
         --    Bit(31:24): Trigger Type;
         --    Bit(23:16): 0000,0001, or 0x01;
         --    Bit(15)   : SYNC FLAG (SVT override)
         --    Bit(14:00): Event wordcount; Event header is excluded from the count
         -- Event 1 (appears in 63:32):
         --    Bit(31:0): Trigger Number
         when TRIG_READ0_S =>
            v.trigData0         := trgIbMaster.tData(63 downto 0);
            v.trgIbSlave.tReady := '1';

            if trgIbMaster.tValid = '1' then
               if trgIbMaster.tData(14 downto 0) > 1 then  -- Just in case
                  v.state := TRIG_READ1_S;
               else
                  v.state := OB_CALC_S;
               end if;
            end if;

         -- Event 2 (appears in 31:0  if enabled):
         --    Bit(31:0): trigger timing; 4ns step
         -- Event 3 (appears in 63:32 if enabled):
         --    Bit(31:16): trigger number bit(47:32), to form 48 bit counter with word2;
         --    Bit(15:0): trigger timing bit(47:32), to form 48 bit counter with word3;
         when TRIG_READ1_S =>
            v.trigData1         := trgIbMaster.tData(63 downto 0);
            v.trgIbSlave.tReady := '1';

            if trgIbMaster.tValid = '1' then
               v.state := OB_CALC_S;
            end if;

         -- Compute outbound size
         -- Add data evio size + 1 for data evio header word 0 + 6 for trig data + 1 for event header word 1
         when OB_CALC_S =>
            if DATA_EN = true then
               v.obSize := dataMaster.tData(31 downto 0) + 8;

               if dataMaster.tValid = '1' and intIbCtrl.pause = '0' then
                  v.state := OB_HEAD_S;
               end if;
            else
               v.obSize := x"00000007";
               v.state  := OB_HEAD_S;
            end if;

         -- Event header word
         -- Word 0:
         --   31:0: Exclusive size
         -- Word 1:
         --    31:24: Sync flag?
         --    23:16: Event type from TI
         --    15:08: Time stamp from TI
         --     7:00: Event number from TI
         when OB_HEAD_S =>
            v.intIbMaster.tData(63 downto 57) := (others => '0');            -- sync flag 
            v.intIbMaster.tData(56)           := r.trigData0(15);            -- sync flag 
            v.intIbMaster.tData(55 downto 48) := r.trigData0(31 downto 24);  -- event type
            v.intIbMaster.tData(47 downto 40) := r.trigData1(7 downto 0);    -- time stamp
            v.intIbMaster.tData(39 downto 32) := r.trigData0(39 downto 32);  -- event number
            v.intIbMaster.tData(31 downto 0)  := r.obSize;                   -- Size
            v.intIbMaster.tValid              := '1';
            v.inFrame                         := '1';
            v.state                           := OB_TRIG0_S;

         -- Trigger EVIO header
         --    word 0: size = 5
         --    word 1, 31:16 = x"e10A"
         --    word 1, 15:14 = "00"
         --    word 1, 13:8  = "000001"
         --    word 1, 7:0   = rocId
         when OB_TRIG0_S =>
            v.intIbMaster.tData(63 downto 48) := x"e10A";
            v.intIbMaster.tData(47 downto 40) := "00000001";
            v.intIbMaster.tData(39 downto 32) := irocId;
            v.intIbMaster.tData(31 downto 0)  := x"00000005";
            v.intIbMaster.tValid              := '1';
            v.state                           := OB_TRIG1_S;

         -- Trigger event word 0
         when OB_TRIG1_S =>
            v.intIbMaster.tData(63 downto 0) := r.trigData0;
            v.intIbMaster.tData(15)          := '0';  -- override bit 15 used for sync by svt
            v.intIbMaster.tValid             := '1';
            v.state                          := OB_TRIG2_S;

         -- Trigger event word 1
         when OB_TRIG2_S =>
            v.intIbMaster.tData(63 downto 0) := r.trigData1;

            if DATA_EN = true then
               v.intIbMaster.tValid := '1';
               v.state              := OB_DATA_S;
            else
               v.intIbMaster.tValid := '0';
               v.state              := OB_NEXT_S;
            end if;

         -- Move data
         when OB_DATA_S =>
            v.intIbMaster.tData  := dataMaster.tData;
            v.intIbMaster.tValid := dataMaster.tValid and not intIbCtrl.pause;
            v.dataSlave.tReady   := not intIbCtrl.pause;

            if dataMaster.tValid = '1' and intIbCtrl.pause = '0' and dataMaster.tLast = '1' then
               v.intIbMaster.tValid := '0';
               v.state              := OB_NEXT_S;
            end if;

         -- Wait for next event, check for end of block
         when OB_NEXT_S =>

            -- Hold onto last data
            v.intIbMaster.tData  := r.intIbMaster.tData;
            v.intIbMaster.tValid := trgIbMaster.tValid;

            if trgIbMaster.tValid = '1' then
               v.eventCount := r.eventCount + 1;

               -- Last word of TI frame, close input frame
               if trgIbMaster.tLast = '1' then
                  v.blockCount        := r.blockCount + 1;
                  v.intIbMaster.tLast := '1';
                  v.inFrame           := '0';
                  v.trgIbSlave.tReady := '1';
                  v.state             := TRIG_HEAD_S;
               else
                  v.state := TRIG_READ0_S;
               end if;
            end if;

         when others =>
            v.state := TRIG_HEAD_S;

      end case;

      -- Force buffer drain if trigger is disabled
      if itrigEnable = '0' then
         v.state := TRIG_DIS_S;
      end if;

      if icountReset = '1' then
         v.eventCount := (others => '0');
         v.blockCount := (others => '0');
      end if;

      -- Reset
      if (axisClkRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Next register assignment
      rin <= v;

      -- Outbound
      eventCount  <= r.eventCount;
      blockCount  <= r.blockCount;
      intIbMaster <= r.intIbMaster;
      trgIbSlave  <= v.trgIbSlave;
      dataSlave   <= v.dataSlave;

   end process;

   -- Outbound FIFO
   U_ObFifo : entity surf.AxiStreamFifo
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 400,
         SLAVE_AXI_CONFIG_G  => HPS_DMA_DATA_CONFIG_C,
         MASTER_AXI_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C)
      port map (
         sAxisClk    => axisClk,
         sAxisRst    => axisClkRst,
         sAxisMaster => r.intIbMaster,
         sAxisSlave  => open,
         sAxisCtrl   => intIbCtrl,
         mAxisClk    => axisClk,
         mAxisRst    => axisClkRst,
         mAxisMaster => dmaIbMaster,
         mAxisSlave  => dmaIbSlave);

end architecture STRUCTURE;

