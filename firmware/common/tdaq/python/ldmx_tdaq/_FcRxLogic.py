
import pyrogue as pr
import ldmx_tdaq

class FcRxLogic(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'BunchClkAligned',
            mode = 'RO',
            base = pr.Bool,
            offset = 0x00,
            bitSize = 1))

        self.add(pr.RemoteVariable(
            name = 'RoRCount',
            mode = 'RO',
            base = pr.UInt,
            offset = 0x04,
            bitSize = 32))

        self.add(pr.RemoteVariable(
            name = 'LastFcBusWord',
            mode = 'RO',
            base = pr.UInt,
            offset = 0x10,
            bitSize = 80))

        self.add(pr.RemoteVariable(
            name = 'FcClkRst',
            description = 'Hold the recovered bunch clock reset high',
            base = pr.Bool,
            offset = 0x24,
            bitSize = 1))
            
            
