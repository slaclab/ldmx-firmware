import pyrogue as pr

class DaqTiming(pr.Device):
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
