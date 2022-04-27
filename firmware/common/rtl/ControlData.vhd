-------------------------------------------------------------------------------
-- Title         : Data Emulator For DPM
-- File          : ControlData.vhd
-- Author        : Ryan Herbst, rherbst@slac.stanford.edu
-- Created       : 12/10/2013
-------------------------------------------------------------------------------
-- Description:
-- Clock & Trigger sink module for COB
-------------------------------------------------------------------------------
-- Copyright (c) 2013 by Ryan Herbst. All rights reserved.
-------------------------------------------------------------------------------
-- Modification history:
-- 12/10/2013: created.
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library ldmx;
use ldmx.HpsTiPkg.all;
use ldmx.HpsPkg.all;

entity ControlData is
   generic (
      TPD_G        : time    := 1 ns
   );
   port (

      -- Local Bus
      axiClk                   : in  sl;
      axiClkRst                : in  sl;
      axiReadMaster            : in  AxiLiteReadMasterType;
      axiReadSlave             : out AxiLiteReadSlaveType;
      axiWriteMaster           : in  AxiLiteWriteMasterType;
      axiWriteSlave            : out AxiLiteWriteSlaveType;

      -- Reference Clock
      sysClk200                : in  sl;
      sysClk200Rst             : in  sl;

      -- DMA Interfaces
      dmaClk                   : out sl;
      dmaClkRst                : out sl;
      dmaState                 : in  RceDmaStateType;
      dmaObMaster              : in  AxiStreamMasterType;
      dmaObSlave               : out AxiStreamSlaveType;
      dmaIbMaster              : out AxiStreamMasterType;
      dmaIbSlave               : in  AxiStreamSlaveType;

      -- Timing bus
      distClk                  : in  sl;
      distClkRst               : in  sl;
      rxData                   : in  Slv10Array(1 downto 0);
      rxDataEn                 : in  slv(1 downto 0);
      txData                   : out slv(9 downto 0);
      txDataEn                 : out sl;
      txReady                  : in  sl
   );
end ControlData;

architecture STRUCTURE of ControlData is

   type RegType is record
      trigEnable        : sl;
      countReset        : sl;
      rocId             : slv(7 downto 0);
      axiReadSlave      : AxiLiteReadSlaveType;
      axiWriteSlave     : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      trigEnable       => '0',
      countReset       => '0',
      rocId            => (others=>'0'),
      axiReadSlave     => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave    => AXI_LITE_WRITE_SLAVE_INIT_C
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal tiDataCount  : slv(31 downto 0);
   signal tiTrigCount  : slv(31 downto 0);
   signal tiBusyCount  : slv(31 downto 0);
   signal tiAckCount   : slv(31 downto 0);
   signal tiAlignCount : slv(31 downto 0);
   signal pauseStatus  : slv(1  downto 0);
   signal trigOverFlow : sl;
   signal blockCount   : slv(31 downto 0);
   signal eventCount   : slv(31 downto 0);
   signal eventState   : slv(3  downto 0);
   signal trgIbMaster  : AxiStreamMasterType;
   signal trgIbSlave   : AxiStreamSlaveType;
   signal blockLevel   : slv(7 downto 0);

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
            eventState, pauseStatus, r, tiAckCount, tiAlignCount, tiBusyCount, tiDataCount,
            tiTrigCount, trigOverFlow) is
      variable v         : RegType;
      variable axiStatus : AxiLiteStatusType;
   begin
      v := r;

      v.countReset := '0';

      axiSlaveWaitTxn(axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave, axiStatus);

      -- Write
      if (axiStatus.writeEnable = '1') then

         -- Trigger Enable, 0x00
         if axiWriteMaster.awaddr(7 downto 0) = x"00" then
            v.trigEnable := axiWriteMaster.wdata(0);

         -- Count Reset, 0x08
         elsif axiWriteMaster.awaddr(7 downto 0) = x"08" then
            v.countReset := axiWriteMaster.wdata(0);

         -- Trig Counter 0x0C

         -- Ack Counter 0x10

         -- Data Counter 0x14

         -- Busy Counter 0x18

         -- Pause Status 0x1C

         -- TrigOverFlow 0x20

         -- ROC ID 0x24
         elsif axiWriteMaster.awaddr(7 downto 0) = x"24" then
            v.rocId := axiWriteMaster.wdata(7 downto 0);

         -- blockCount 0x28

         -- eventCount 0x2C

         -- eventState 0x30

         -- blockLevel 0x34

         end if;

         -- Send Axi Response
         axiSlaveWriteResponse(v.axiWriteSlave);

      end if;

      -- Read
      if (axiStatus.readEnable = '1') then
         v.axiReadSlave.rdata := (others => '0');

         -- Trigger Enable 0x00
         if axiReadMaster.araddr(7 downto 0) = x"00" then
            v.axiReadSlave.rdata(0) := r.trigEnable;

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

         -- TrigOverFlow 0x20
         elsif axiReadMaster.araddr(7 downto 0) = x"20" then
            v.axiReadSlave.rdata(0) := trigOverFlow;

         -- ROC ID 0x24
         elsif axiReadMaster.araddr(7 downto 0) = x"24" then
            v.axiReadSlave.rdata(7 downto 0) := r.rocId;

         -- blockCount 0x28
         elsif axiReadMaster.araddr(7 downto 0) = x"28" then
            v.axiReadSlave.rdata := blockCount;

         -- eventCount 0x2C
         elsif axiReadMaster.araddr(7 downto 0) = x"2C" then
            v.axiReadSlave.rdata := eventCount;

         -- eventState 0x30
         elsif axiReadMaster.araddr(7 downto 0) = x"30" then
            v.axiReadSlave.rdata(3 downto 0) := eventState;

         -- blockLevel 0x34
         elsif axiReadMaster.araddr(7 downto 0) = x"34" then
            v.axiReadSlave.rdata(7 downto 0) := blockLevel;

         elsif (axiReadMaster.araddr(7 downto 0) = X"38") then
            v.axiReadSlave.rdata := tiAlignCount;

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


   ----------------------------------------
   -- Trigger Data
   ----------------------------------------
   U_TiDataRx : entity ldmx.TiDataRx
      generic map (
         TPD_G  => TPD_G
      ) port map (
         axisClk      => sysCLk200,
         axisClkRst   => sysCLk200Rst,
         trgIbMaster  => trgIbMaster,
         trgIbSlave   => trgIbSlave,
         dmaState     => dmaState,
         trigEnable   => r.trigEnable,
         countReset   => r.countReset,
         tiDataCount  => tiDataCount,
         tiTrigCount  => tiTrigCount,
         tiBusyCount  => tiBusyCount,
         tiAckCount   => tiAckCount,
         tiAlignCount => tiAlignCount,
         pauseStatus  => pauseStatus,
         trigOverFlow => trigOverFlow,
         extDataPause => '0',
         blockLevel   => blockLevel,
         distClk      => distClk,
         distClkRst   => distClkRst,
         extDataTrig  => open,
         rxData       => rxData,
         rxDataEn     => rxDataEn,
         txData       => txData,
         txDataEn     => txDataEn,
         txReady      => txReady
      );

   U_DataBank : entity ldmx.DataBankBuilder
      generic map (
         TPD_G   => TPD_G,
         DATA_EN => false
         )
      port map (
         axisClk       => sysClk200,
         axisClkRst    => sysClk200Rst,
         emulateEnable => '0',
         countReset    => r.countReset,
         rocId         => r.rocId,
         trigEnable    => r.trigEnable,
         blockCount    => blockCount,
         eventCount    => eventCount,
         eventState    => eventState,
         trgIbMaster   => trgIbMaster,
         trgIbSlave    => trgIbSlave,
         eventMaster   => AXI_STREAM_MASTER_INIT_C,
         eventSlave    => open,
         emuMaster     => AXI_STREAM_MASTER_INIT_C,
         emuSlave      => open,
         dmaIbMaster   => dmaIbMaster,
         dmaIbSlave    => dmaIbSlave
         );

   dmaClk     <= sysClk200;
   dmaClkRst  <= sysClk200Rst;
   dmaObSlave <= AXI_STREAM_SLAVE_INIT_C;

end architecture STRUCTURE;

