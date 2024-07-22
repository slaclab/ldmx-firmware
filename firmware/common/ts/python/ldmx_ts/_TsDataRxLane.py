import pyrogue as pr
import surf.xilinx
import lmdx_tdaq
import ldmx_ts

class TsDataRxLane(pr.Device):
    def __init__(self, **kwargs)
        super().__init__(**kwargs)

        self.add(ldmx_ts.TsRxLogic(
            offset = 0x1_0000))

#         self.add(ldmx_ts.TsTxLogic(
#             offset = 0x1_0100))

        self.add(surf.xilinx.Gtye4Channel(
            offset = 0x0_0000))

        
