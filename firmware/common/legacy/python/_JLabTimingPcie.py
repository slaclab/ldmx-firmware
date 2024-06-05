import pyrogue as pr

class JLabTimingPcie(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'Mode',
            offset = 0x1C,
            bitOffset = 0,
            bitSize = 1,
            mode = 'RW',
            base = pr.UInt,
            enum = {
                0: 'LocalClk',
                1: 'TiClk'}))

        self.add(pr.RemoteVariable(
            name = 'CodaState',
            offset = 0x28,
            bitSize = 3,
            bitOffset = 0,
            mode = 'RW',
            enum = {
                0b000: 'END',
                0b001: 'DOWNLOAD',
                0b011: 'PRESTART',
                0b010: 'GO',
                0b100: 'INIT'}))

        self.add(pr.RemoteVariable(
            name = 'SyncAlignDelay',
            description = 'Number of cycles between sync edge and clk41 Align command',
            offset = 0x20,
            bitOffset = 0,
            bitSize = 2,
            mode = 'RW',
            disp = '{:d}',
            base = pr.UInt))

        self.add(pr.RemoteCommand(
            name = "ApvClkAlign",
            offset = 0x40,
            bitOffset = 0,
            bitSize = 1,
            function = pr.RemoteCommand.touchOne))

        self.add(pr.RemoteCommand(
            name = "ApvReset101",
            offset = 0x64,
            bitOffset = 0,
            bitSize = 1,
            function = pr.RemoteCommand.touchOne))


        self.add(pr.RemoteCommand(
            name = 'CountReset',
            offset = 0x24,
            bitSize = 1,
            bitOffset = 0,
            base = pr.UInt,
            function = pr.RemoteCommand.toggle))

        self.add(pr.RemoteCommand(
            name = "CtrlTranceiverReset",
            offset = 0x70,
            bitOffset = 0,
            bitSize = 1,
            function = pr.RemoteCommand.createToggle([0, 1])))

        self.add(pr.RemoteCommand(
            name = "DataTranceiverReset",
            offset = 0x70,
            bitOffset = 1,
            bitSize = 1,
            function = pr.RemoteCommand.createToggle([0, 1])))



        self.add(pr.RemoteVariable(
            name = 'TiSyncCount',
            offset = 0x14,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            disp = '{:d}',
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name = 'TiDownloadSyncCount',
            offset = 0x2C,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            disp = '{:d}',
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name = 'TiPrestartSyncCount',
            offset = 0x30,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            disp = '{:d}',
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name = 'TiTriggerCount',
            offset = 0x18,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            pollInterval=1,
            disp = '{:d}',
            mode = 'RO'))


        self.add(pr.RemoteVariable(
            name = 'BusyTimeRaw',
            offset = 0x34,
            bitOffset = 0,
            bitSize = 32,
            pollInterval=1,
            base = pr.UInt,
            mode = 'RO',
            hidden = False))

        self.add(pr.LinkVariable(
            name = 'BusyTime',
            dependencies = [self.BusyTimeRaw],
            linkedGet = lambda: (self.BusyTimeRaw.value()*100) / 125.0e6,
            value = 0.0,
            units = '%',
            disp = '{:1.3f}'))


        self.add(pr.RemoteVariable(
            name = 'BusyTimeMaxRaw',
            offset = 0x38,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            mode = 'RO',
            hidden = True))

        self.add(pr.LinkVariable(
            name = 'BusyTimeMax',
            dependencies = [self.BusyTimeMaxRaw],
            linkedGet = lambda: (self.BusyTimeMaxRaw.value()*100) / 125.0e6,
            value = 0.0,
            units = '%',
            disp = '{:1.3f}'))


        self.add(pr.RemoteVariable(
            name = 'BusyRate',
            offset = 0x00,
            bitOffset = 0,
            bitSize = 32,
            pollInterval=1,
            base = pr.UInt,
            mode = 'RO',
            disp = '{:d}',
            units = 'per second'
        ))

        self.add(pr.RemoteVariable(
            name = 'BusyRateMax',
            offset = 0x04,
            bitOffset = 0,
            bitSize = 32,
            pollInterval=1,
            base = pr.UInt,
            mode = 'RO',
            disp = '{:d}',
            units = 'per second'
        ))

        self.add(pr.RemoteVariable(
            name = 'TiClk0FreqRaw',
            offset = 0x0C,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            hidden = False,
            mode = 'RO'))

        self.add(pr.LinkVariable(
            name = 'TiClk0Freq',
            dependencies = [self.TiClk0FreqRaw],
            linkedGet = lambda: self.TiClk0FreqRaw.value() * 1.0e-6,
            value = 0.0,
            pollInterval=1,
            units = 'MHz',
            disp = '{:1.3f}'))


        self.add(pr.RemoteVariable(
            name = 'TiClk1FreqRaw',
            offset = 0x10,
            bitOffset = 0,
            bitSize = 32,
            base = pr.UInt,
            hidden = False,
            mode = 'RO'))

        self.add(pr.LinkVariable(
            name = 'TiClk1Freq',
            dependencies = [self.TiClk1FreqRaw],
            linkedGet = lambda: self.TiClk1FreqRaw.value() * 1.0e-6,
            value = 0.0,
            pollInterval=1,
            units = 'MHz',
            disp = '{:1.3f}'))

        self.add(pr.RemoteVariable(
            name = "LastSyncPhase",
            offset = 0x60,
            bitOffset = 0,
            bitSize = 2,
            disp = '{:02b}'))

        self.add(pr.RemoteVariable(
            name = "LastTriggerPhase",
            offset = 0x60,
            bitOffset = 2,
            bitSize = 2,
            disp = '{:02b}'))

        self.add(pr.RemoteVariable(
            name = 'TriggerDelay',
            offset = 0x50,
            bitOffset = 0,
            bitSize = 5,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'SyncDelay',
            offset = 0x54,
            bitOffset = 0,
            bitSize = 5,
            disp = '{:d}'))


    def countReset(self):
        self.CountReset()
