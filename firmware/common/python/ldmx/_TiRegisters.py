import pyrogue as pr

class TiRegisters(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name="CrateId",
            description='Crate ID Value',
            offset=0x04,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BusySrcEn",
            description='Busy Source Enable',
            offset=0x08,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BoardId",
            description='Board ID Value',
            offset=0x14,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="RocEn",
            description='ROC Enable',
            offset=0x18,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BoardActive",
            description='Board Active',
            offset=0x1C,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="DataFormat",
            description='Data Format',
            offset=0x24,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="SyncCode",
            description='Sync Code',
            offset=0x44,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="SyncMonitor",
            description='Sync Monitor',
            offset=0x4C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="SyncMonOut",
            description='Sync Mon Out',
            offset=0x50,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="IrqCount",
            description='Irq Count',
            offset=0x54,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="DgFull",
            description='DG Full Value',
            offset=0x58,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="DataBusy",
            description='Data Busy Value',
            offset=0x5C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrigSyncBusy",
            description='Trig Sync Busy',
            offset=0x60,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrgSrcEn",
            description='Trig Source Enable',
            offset=0x68,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.addRemoteVariables(
            number=8,
            stride=4,
            name='AckDelayRaw',
            description='Ack Delay',
            offset=0x70,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt)

        for i in range(8):
            self.add(pr.LinkVariable(
                name=f'AckDelay[{i}]',
                description='Ack Delay',
                units= 'ns',
                linkedGet=lambda: self.AckDelayRaw[i].value() * 8,
                dependencies=[self.AckDelayRaw[i]]))


        self.add(pr.RemoteVariable(
            name="Trig1Count",
            description='Trigger 1 Counter',
            offset=0x90,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrigRawCount",
            description='Trigger 1 Counter',
            offset=0x94,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Trig2Count",
            description='Trigger 2 Counter',
            offset=0xA4,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="ReadCount",
            description='Read Trigger Counter',
            offset=0xA8,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.addRemoteVariables(
            number=8,
            stride=4,
            name='AckCount',
            description='Ack Counter',
            offset=0xAC,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt)

        self.add(pr.RemoteVariable(
            name="TrgSrc",
            description='Trig Source Enable',
            offset=0xE0,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt,
            enum={0:'Diable',1:'Trigger 1',2:'Trigger 2',3:'RawCode'}))

        self.add(pr.RemoteVariable(
            name="LocBusy",
            description='ROC Busy Status',
            offset=0xE8,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BusyCount",
            description='Busy Counter',
            offset=0xEC,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrigTxCount",
            description='Trigger TX Counter',
            offset=0xF0,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrigEnable",
            description='Trigger Enable',
            offset=0xF4,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="BlockLevel",
            description='Block Level',
            offset=0x110,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="LocalClkEn",
            description='Local Clock Enable',
            offset=0x11C,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="PllLocked",
            offset=0x130,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="TiBusySync",
            offset=0x130,
            bitSize=32,
            bitOffset=1,
            mode='RO',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="TrgSendEn",
            offset=0x130,
            bitSize=32,
            bitOffset=2,
            mode='RO',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="SReset",
            description='sReset vector state',
            offset=0x134,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="SResetReg",
            description='sReset vector registered state',
            offset=0x138,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="ForceBusy",
            description='Force Busy State',
            offset=0x13C,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="MinTrigPeriodRaw",
            description='Min Trigger Period',
            offset=0x140,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.LinkVariable(
            name='MinTrigPeriod',
            description='Min Trigger Period',
            units= 'uS',
            linkedGet=lambda: self.MinTrigPeriodRaw.value() * 8e-3,
            dependencies=[self.MinTrigPeriodRaw]))

        self.add(pr.RemoteVariable(
            name="DistClkPhase",
            description='Phase alignment of distributed 125 MHz clock',
            offset=0x148,
            bitSize=1,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Clk41AlignDelay",
            description='Delay after sReset(2) before sending clk41 align code.',
            offset=0x148,
            bitSize=6,
            bitOffset=1,
            base=pr.UInt,
            minimum=0,
            maximum=32))

        self.add(pr.RemoteVariable(
            name="SyncCount",
            description='Number of TI Sync pulses received.',
            offset=0x14C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="SyncSentCount",
            description='Number of TI Sync flags in data stream',
            offset=0x150,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="FilterBusyCount",
            description='Number of times the trigger filter has asserted busy.',
            offset=0x154,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="FilterBusyRateRaw",
            description='Number of 8 ns cycles filter busy has been asserted in last second',
            hidden=True,
            offset=0x158,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.LinkVariable(
            name='FilterBusyRate',
            description='Number of 8 ns cycles filter busy has been asserted in last second',
            mode='RO',
            units= '%',
            linkedGet=lambda: self.FilterBusyRateRaw.value() * 8e-7,
            dependencies=[self.FilterBusyRateRaw]))

        self.add(pr.RemoteVariable(
            name="TrigDelayRaw",
            description='Additional trigger delay before distributing to rest of system.',
            hidden=True,
            offset=0x15C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.LinkVariable(
            name='TrigDelay',
            description='Additional trigger delay before distributing to rest of system.',
            mode='RO',
            units= 'ns',
            linkedGet=lambda: self.TrigDelayRaw * 8.0,
            dependencies=[self.TrigDelayRaw]))

        self.add(pr.LocalVariable(
            name="RocEnValue",
            description='ROC Enable Value',
            value=0))

        self.add(pr.LocalVariable(
            name="TrgSrcEnValue",
            description='Trig Source Enable Value',
            value=0))


        self.add(pr.RemoteCommand(
            name='SRstReqSw',
            description='Sync Reset Request',
            offset=0x30,
            function=pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name='ScalerReset',
            description='Scaler Reset',
            offset=0x38,
            function=pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name='VmeReset',
            description='Sync Align',
            offset=0x64,
            function=pr.BaseCommand.createTouch(0x800)))

        self.add(pr.RemoteCommand(
            name='SwGtpRst',
            description='GTP Reset',
            offset=0xD0,
            function=pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name='MonRst',
            description='MonRst',
            offset=0xD4,
            function=pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name='ApvReset101',
            description='Issue Reset101 command to all APVs',
            offset=0x128,
            function=pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name='PllSwRst',
            description='Issue Reset to core pll',
            offset=0x12C,
            function=pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name='Clk41Align',
            description='Issue Clk41Align command to all FEBs',
            offset=0x144,
            function=pr.BaseCommand.toggle))
