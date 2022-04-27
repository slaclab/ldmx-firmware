-------------------------------------------------------------------------------
-- Title         : Data Emulator For DPM
-- File          : DataReadout.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/10/2013
-------------------------------------------------------------------------------
-- Description:
-- Data readout controller for HPS.
-- Version 2
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

entity DataReadout is
   generic (
      TPD_G : time := 1 ns
      );
   port (

      -- Local Bus
      axiClk         : in  sl;
      axiClkRst      : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- Reference Clock
      sysClk200    : in sl;
      sysClk200Rst : in sl;

      -- DMA Interface
      dmaClk      : out sl;
      dmaClkRst   : out sl;
      dmaState    : in  RceDmaStateType;
      dmaObMaster : in  AxiStreamMasterType;
      dmaObSlave  : out AxiStreamSlaveType;
      dmaIbMaster : out AxiStreamMasterType;
      dmaIbSlave  : in  AxiStreamSlaveType;

      -- Incoming Events
      eventAxisClk    : in  sl;
      eventAxisRst    : in  sl;
      eventAxisMaster : in  AxiStreamMasterType;
      eventAxisSlave  : out AxiStreamSlaveType;
      eventAxisCtrl   : out AxiStreamCtrlType;
      eventTrig       : out sl;
      eventTrigEn     : out sl;

      -- Timing bus
      distClk    : in  sl;
      distClkRst : in  sl;
      rxData     : in  Slv10Array(1 downto 0);
      rxDataEn   : in  slv(1 downto 0);
      txData     : out slv(9 downto 0);
      txDataEn   : out sl;
      txReady    : in  sl
      );
end DataReadout;

architecture STRUCTURE of DataReadout is

   type RegType is record
      emulateSize   : slv(31 downto 0);
      emulateEnable : sl;
      rocId         : slv(7 downto 0);
      countReset    : sl;
      trigEnable    : sl;
      axiReadSlave  : AxiLiteReadSlaveType;
      axiWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      emulateSize   => (others => '0'),
      emulateEnable => '0',
      rocId         => (others => '0'),
      countReset    => '0',
      trigEnable    => '0',
      axiReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal extDataTrig       : sl;
   signal tiDataCount       : slv(31 downto 0);
   signal blockCount        : slv(31 downto 0);
   signal eventCount        : slv(31 downto 0);
   signal eventState        : slv(3 downto 0);
   signal tiTrigCount       : slv(31 downto 0);
   signal tiBusyCount       : slv(31 downto 0);
   signal tiAckCount        : slv(31 downto 0);
   signal pauseStatus       : slv(1 downto 0);
   signal trigOverFlow      : sl;
   signal eventAxisMaster64 : AxiStreamMasterType;
   signal eventAxisSlave64  : AxiStreamSlaveType;
   signal eventAxisMaster1  : AxiStreamMasterType;
   signal eventAxisSlave1   : AxiStreamSlaveType;
   signal eventAxisCtrl1    : AxiStreamCtrlType;
   signal eventAxisMaster2  : AxiStreamMasterType;
   signal eventAxisSlave2   : AxiStreamSlaveType;
   signal eventAxisMaster3  : AxiStreamMasterType;
   signal eventAxisSlave3   : AxiStreamSlaveType;
   signal trgIbMaster       : AxiStreamMasterType;
   signal trgIbSlave        : AxiStreamSlaveType;
   signal emuIbMaster       : AxiStreamMasterType;
   signal emuIbSlave        : AxiStreamSlaveType;
   signal eventPause        : sl;
   signal blockLevel        : slv(7 downto 0);

begin

   ----------------------------------------
   -- Local Registers
   ----------------------------------------

   -- Sync
   process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process;

   -- Async
   process (axiClkRst, axiReadMaster, axiWriteMaster, blockCount, blockLevel, eventCount,
            eventState, pauseStatus, r, tiAckCount, tiBusyCount, tiDataCount, tiTrigCount,
            trigOverFlow) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      v.countReset              := '0';
      v.emulateSize(1 downto 0) := "01";  -- (set * 4) + 1

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- Write
      if (axiStatus.writeEnable = '1') then

         -- Trigger Enable, 0x00
         if axiWriteMaster.awaddr(7 downto 0) = x"00" then
            v.trigEnable := axiWriteMaster.wdata(0);

         -- Data Size, 0x04
         elsif axiWriteMaster.awaddr(7 downto 0) = x"04" then
            v.emulateSize(13 downto 2) := axiWriteMaster.wdata(11 downto 0);

         -- Count Reset, 0x08
         elsif axiWriteMaster.awaddr(7 downto 0) = x"08" then
            v.countReset := axiWriteMaster.wdata(0);

            -- Trig Counter 0x0C

            -- Ack Counter 0x10

            -- Data Counter 0x14

            -- Busy Counter 0x18

            -- Pause Status 0x1C

         -- Emulate Enable, 0x20
         elsif axiWriteMaster.awaddr(7 downto 0) = x"20" then
            v.emulateEnable := axiWriteMaster.wdata(0);

            -- Trigger overflow, 0x24

            -- Block counter, 0x28

            -- Event counter, 0x2C

            -- Block wait status, 0x30

         -- Roc ID, 0x34
         elsif axiWriteMaster.awaddr(7 downto 0) = x"34" then
            v.rocId := axiWriteMaster.wdata(7 downto 0);

            -- BlockLevel 0x38

         end if;

         -- Send Axi Response
         axiSlaveWriteResponse(v.axiWriteSlave);

      end if;

      -- Read
      if (axiStatus.readEnable = '1') then
         v.axiReadSlave.rdata := (others => '0');

         -- Trigger Enable, 0x00
         if axiReadMaster.araddr(7 downto 0) = x"00" then
            v.axiReadSlave.rdata(0) := r.trigEnable;

         -- Data Size, 0x04
         elsif axiReadMaster.araddr(7 downto 0) = x"04" then
            v.axiReadSlave.rdata(11 downto 0) := r.emulateSize(13 downto 2);

            -- Count Reset, 0x08

         -- Trig Counter 0x0C
         elsif axiReadMaster.araddr(7 downto 0) = x"0C" then
            v.axiReadSlave.rdata := tiTrigCount;

         -- Ack Counter 0x10
         elsif axiReadMaster.araddr(7 downto 0) = x"10" then
            v.axiReadSlave.rdata := tiAckCount;

         -- Data Counter 0x14
         elsif axiReadMaster.araddr(7 downto 0) = x"14" then
            v.axiReadSlave.rdata := tiDataCount;

         -- Busy Counter 0x18
         elsif axiReadMaster.araddr(7 downto 0) = x"18" then
            v.axiReadSlave.rdata := tiBusyCount;

         -- Pause Status 0x1C
         elsif axiReadMaster.araddr(7 downto 0) = x"1C" then
            v.axiReadSlave.rdata(1 downto 0) := pauseStatus;

         -- Emulate Enable, 0x20
         elsif axiReadMaster.araddr(7 downto 0) = x"20" then
            v.axiReadSlave.rdata(0) := r.emulateEnable;

         -- Trigger overflow, 0x24
         elsif axiReadMaster.araddr(7 downto 0) = x"24" then
            v.axiReadSlave.rdata(0) := trigOverFlow;

         -- Block counter, 0x28
         elsif axiReadMaster.araddr(7 downto 0) = x"28" then
            v.axiReadSlave.rdata := blockCount;

         -- Event counter, 0x2C
         elsif axiReadMaster.araddr(7 downto 0) = x"2C" then
            v.axiReadSlave.rdata := eventCount;

         -- EventState, 0x30
         elsif axiReadMaster.araddr(7 downto 0) = x"30" then
            v.axiReadSlave.rdata(3 downto 0) := eventState;

         -- Roc ID, 0x34
         elsif axiReadMaster.araddr(7 downto 0) = x"34" then
            v.axiReadSlave.rdata(7 downto 0) := r.rocId;

         -- BlockLevel 0x38
         elsif axiReadMaster.araddr(7 downto 0) = x"38" then
            v.axiReadSlave.rdata(7 downto 0) := blockLevel;

         end if;

         -- Send Axi Response
         axiSlaveReadResponse(v.axiReadSlave);
      end if;

      -- Reset
      if (axiClkRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Next register assignment
      rin <= v;

      -- Outputs
      axiReadSlave  <= r.axiReadSlave;
      axiWriteSlave <= r.axiWriteSlave;

   end process;


   -------------------------------------------------------------------------------------------------
   -- Convert stream from 128 bit to 64 bit
   -- Transition to sysClk200
   -------------------------------------------------------------------------------------------------

   -- First stage FIFO, 128bits, 125mhz
   -- Pause state causes event builder to truncate frames
   AxiStreamFifo_1 : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         PIPE_STAGES_G       => 1,
         SLAVE_READY_EN_G => false,
         FIFO_ADDR_WIDTH_G   => 9,
         FIFO_PAUSE_THRESH_G => 200,
         SLAVE_AXI_CONFIG_G  => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G => EVENT_SSI_CONFIG_C)
      port map (
         sAxisClk    => eventAxisClk,
         sAxisRst    => eventAxisRst,
         sAxisMaster => eventAxisMaster,
         sAxisSlave  => eventAxisSlave,
         sAxisCtrl   => eventAxisCtrl,
         mAxisClk    => eventAxisClk,
         mAxisRst    => eventAxisRst,
         mAxisMaster => eventAxisMaster1,
         mAxisSlave  => eventAxisSlave1);

   -- Second stage FIFO, 128 bits, 125Mhz
   -- Pause state asserts trigger busy
   -- Each cascade size is 1024 x 64
   -- Largest possible event is 40,960bytes = 5120x64 = 5 cascades
   -- FIFO setup to hold 4 of the largest events = cascade of 20
   -- Pause threshold to fire when 1.5 events are in the FIFO = 8 cascades
   -- Input stage is cascade 19, pause select is cascade 11
   AxiStreamFifo_2 : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => true,
         FIFO_ADDR_WIDTH_G   => 10,     -- 1024
         FIFO_PAUSE_THRESH_G => 512,    -- half of cascade
         CASCADE_SIZE_G      => 25,     -- 1024 * 20
         CASCADE_PAUSE_SEL_G => 11,     -- 0 = output, 19 = input
         SLAVE_AXI_CONFIG_G  => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G => EVENT_SSI_CONFIG_C)
      port map (
         sAxisClk    => eventAxisClk,
         sAxisRst    => eventAxisRst,
         sAxisMaster => eventAxisMaster1,
         sAxisSlave  => eventAxisSlave1,
         sAxisCtrl   => eventAxisCtrl1,
         mAxisClk    => eventAxisClk,
         mAxisRst    => eventAxisRst,
         mAxisMaster => eventAxisMaster2,
         mAxisSlave  => eventAxisSlave2);

   eventPause <= eventAxisCtrl1.pause;

   -- Third stage FIFO, 128 bits, 125Mhz in, 64-bits 250mhz out
   AxiStreamFifo_3 : entity work.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         MEMORY_TYPE_G       => "block",
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 10,     -- 1024
         FIFO_PAUSE_THRESH_G => 512,    -- Unused
         SLAVE_AXI_CONFIG_G  => EVENT_SSI_CONFIG_C,
         MASTER_AXI_CONFIG_G => HPS_DMA_DATA_CONFIG_C)
      port map (
         sAxisClk    => eventAxisClk,
         sAxisRst    => eventAxisRst,
         sAxisMaster => eventAxisMaster2,
         sAxisSlave  => eventAxisSlave2,
         sAxisCtrl   => open,
         mAxisClk    => sysClk200,
         mAxisRst    => sysClk200Rst,
         mAxisMaster => eventAxisMaster3,
         mAxisSlave  => eventAxisSlave3);

   -- Shift incoming event data
   U_DataShift : entity surf.AxiStreamShift
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => HPS_DMA_DATA_CONFIG_C
         )
      port map (
         axisClk     => sysClk200,
         axisRst     => sysClk200Rst,
         axiStart    => '1',
         axiShiftDir => '1',            -- 1 = right (msb to lsb)
         axiShiftCnt => x"4",
         sAxisMaster => eventAxisMaster3,
         sAxisSlave  => eventAxisSlave3,
         mAxisMaster => eventAxisMaster64,
         mAxisSlave  => eventAxisSlave64);

   ----------------------------------------
   -- Data Emulation Generation
   ----------------------------------------
   U_SsiPrbsTx : entity surf.SsiPrbsTxOld
      generic map (
         TPD_G                      => TPD_G,
         MEMORY_TYPE_G              => "block",
         XIL_DEVICE_G               => "7SERIES",
         USE_BUILT_IN_G             => false,
         GEN_SYNC_FIFO_G            => false,
         FIFO_ADDR_WIDTH_G          => 9,
         FIFO_PAUSE_THRESH_G        => 255,
         MASTER_AXI_STREAM_CONFIG_G => HPS_DMA_DATA_CONFIG_C,
         MASTER_AXI_PIPE_STAGES_G   => 0
         )
      port map (
         mAxisClk     => sysClk200,
         mAxisRst     => sysClk200Rst,
         mAxisSlave   => emuIbSlave,
         mAxisMaster  => emuIbMaster,
         locClk       => distClk,
         locRst       => distClkRst,
         trig         => extDataTrig,
         packetLength => r.emulateSize,
         busy         => open,
         tDest        => X"00",
         tId          => X"00"
         );

   ----------------------------------------
   -- Trigger Data
   ----------------------------------------
   U_TiDataRx : entity ldmx.TiDataRx
      generic map (
         TPD_G => TPD_G
         ) port map (
            axisClk      => sysClk200,
            axisClkRst   => sysClk200Rst,
            trgIbMaster  => trgIbMaster,
            trgIbSlave   => trgIbSlave,
            dmaState     => dmaState,
            trigEnable   => r.trigEnable,
            countReset   => r.countReset,
            tiDataCount  => tiDataCount,
            tiTrigCount  => tiTrigCount,
            tiBusyCount  => tiBusyCount,
            tiAckCount   => tiAckCount,
            pauseStatus  => pauseStatus,
            trigOverFlow => trigOverFlow,
            extDataPause => eventPause,
            blockLevel   => blockLevel,
            distClk      => distClk,
            distClkRst   => distClkRst,
            extDataTrig  => extDataTrig,
            rxData       => rxData,
            rxDataEn     => rxDataEn,
            txData       => txData,
            txDataEn     => txDataEn,
            txReady      => txReady
            );

   eventTrig   <= extDataTrig;
   eventTrigEn <= r.trigEnable;

   ----------------------------------------
   -- Data Bank Builder
   ----------------------------------------
   U_DataBank : entity ldmx.DataBankBuilder
      generic map (
         TPD_G   => TPD_G,
         DATA_EN => true
         )
      port map (
         axisClk       => sysClk200,
         axisClkRst    => sysClk200Rst,
         emulateEnable => r.emulateEnable,
         countReset    => r.countReset,
         rocId         => r.rocId,
         trigEnable    => r.trigEnable,
         blockCount    => blockCount,
         eventCount    => eventCount,
         eventState    => eventState,
         trgIbMaster   => trgIbMaster,
         trgIbSlave    => trgIbSlave,
         eventMaster   => eventAxisMaster64,
         eventSlave    => eventAxisSlave64,
         emuMaster     => emuIbMaster,
         emuSlave      => emuIbSlave,
         dmaIbMaster   => dmaIbMaster,
         dmaIbSlave    => dmaIbSlave
         );

   dmaClk     <= sysClk200;
   dmaClkRst  <= sysClk200Rst;
   dmaObSlave <= AXI_STREAM_SLAVE_INIT_C;

end architecture STRUCTURE;

