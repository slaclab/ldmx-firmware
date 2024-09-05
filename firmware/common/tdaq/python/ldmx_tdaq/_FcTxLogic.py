import pyrogue as pr

class FcTxLogic(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'FcState',
            offset = 0x00,
            bitSize = 5,
            bitOffset = 0,
            base = pr.UInt,
            enum = {
                0b00000 : 'RESET',
                0b00001 : 'IDLE',
                0b00010 : 'BC0',
                0b00011 : 'PRESTART',
                0b00100 : 'RUNNING',
                0b00101 : 'STOPPED',                
            }))

        @self.command()
        def AdvanceRunState():
            state = self.FcState.value()
            state += 1
            self.FcState.set(state, write=True)

        @self.command()
        def StopRun():
            self.FcState.setDisp('STOPPED')

        @self.command()
        def ResetRun():
            self.FcState.setDisp('RESET')
