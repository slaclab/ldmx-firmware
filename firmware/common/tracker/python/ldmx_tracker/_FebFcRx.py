import pyrogue as pr

class FebFcRx(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)


        self.add(pr.RemoteVariable(
            name='HySoftRstCount',
            offset=0x0C,
            bitSize=16,
            mode='RO',
            disp='{:d}'))

