import pyrogue as pr
import surf.xilinx
import ldmx_tdaq
import ldmx_ts

class TsDataRxLane(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_ts.TsRxLogic(
            offset = 0x2000))

#         self.add(ldmx_ts.TsTxLogic(
#             offset = 0x4100))

        self.add(surf.xilinx.Gtye4Channel(
            offset = 0x0_0000))

        
