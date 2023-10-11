import pyrogue as pr
import surf.xilinx

class PgpFcGtyCoreWrapper(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.xilinx.GtRxAlignCheck(
            offset = 0x0000))

        self.add(surf.xilinx.Gtye4Channel(
            offset = 0x1000))
