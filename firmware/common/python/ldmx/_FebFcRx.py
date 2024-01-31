import pyrogue as pr

class FebFcRx(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name='DaqAligned',
            offset=0x0,
            bitOffset=0,
            bitSize=1,
            mode='RO',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name='TriggerCount',
            offset=0x04,
            bitSize=16,
            mode='RO',
            disp='{:d}'))

        self.add(pr.RemoteVariable(
            name='AlignCount',
            offset=0x08,
            bitSize=16,
            mode='RO',
            disp='{:d}'))

        self.add(pr.RemoteVariable(
            name='HySoftRstCount',
            offset=0x0C,
            bitSize=16,
            mode='RO',
            disp='{:d}'))

        self.add(pr.RemoteVariable(
            name = 'LastTimingMessage',
            offset = 0x10,
            bitSize = 80,
            bitOffset = 0,
            base = pr.UInt))

        self.add(pr.RemoteVariable(
            name = 'FcClkRst',
            offset = 0x24,
            bitSize = 1,
            bitOffset = 0,
            base = pr.UInt))
