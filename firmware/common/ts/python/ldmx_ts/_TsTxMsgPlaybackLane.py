import pyrogue as pr
import surf.xilinx
import lmdx_tdaq
import ldmx_ts

class TsTxMsgPlaybackLane(pr.Device):
    def __init__(self,  **kwargs)
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'RAM',
            offset = 0x0,
            base = pr.UInt,
            valueBits = 96,
            valueStride = 96,
            numValues = 2**14))
