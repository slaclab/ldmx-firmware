import pyrogue as pr
import surf.xilinx
import lmdx_tdaq
import ldmx_ts

class TsRxLogic(pr.Device):
    def __init__(self, **kwargs)
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'Loopback',
            bitSize = 3,
            enum = {
                'Off': 0b000,
                'Near-end PMA': 0b010}))
