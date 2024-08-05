import pyrogue as pr
import surf.xilinx
import ldmx_tdaq
import ldmx_ts

class TsRxLogic(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'LinkUp',
            offset = 0x0,
            mode = 'RO',
            bitOffset = 0,
            bitSize = 1,
            base = pr.Bool))

        self.add(pr.RemoteCommand(
            name = 'CountReset',
            offset = 0x0,
            bitOffset = 1,
            bitSize = 1,
            function = pr.Command.touchOne))

        self.add(pr.RemoteVariable(
            name = 'Loopback',
            offset = 0x4,
            bitSize = 3,
            enum = {
                0b000: 'Off',
                0b010: 'Near-end PMA'}))

        self.add(pr.RemoteVariable(
            name = 'RxFrameCount',
            offset = 0x08,
            bitSize = 64,
            base = pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name = 'RxErrorCount',
            offset = 0x10,
            bitSize = 32,
            base = pr.UInt,
            mode = 'RO'))
        
