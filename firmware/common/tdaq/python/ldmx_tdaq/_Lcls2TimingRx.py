import rogue
import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx_tdaq
import LclsTimingCore

class Lcls2TimingRx(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.TimingGtCoreWrapper(
            name   = "GTY",
            offset = 0x00000))

        self.add(LclsTimingCore.TPGMiniCore(
            name   = "TPGMini",
            offset = 0x40000))
