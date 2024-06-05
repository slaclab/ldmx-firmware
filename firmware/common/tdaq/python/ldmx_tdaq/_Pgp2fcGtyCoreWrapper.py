import pyrogue as pr
import surf.xilinx

class Pgp2fcGtyCoreWrapper(pr.Device):
    """ Maps to PgpfcGtyCoreWrapper.vhd in surf """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.xilinx.GtRxAlignCheck(
            name   = "GtRxAlignCheck",
            offset = 0x0000))

        self.add(surf.xilinx.Gtye4Channel(
            name   = "Gtye4Channel",
            offset = 0x1000))
