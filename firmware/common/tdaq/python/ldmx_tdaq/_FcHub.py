import rogue
import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx_tdaq

class FcHub(pr.Device):
    def __init__(self, numQuads=1, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.Lcls2TimingRx(
            name   = "Lcls2TimingRx",
            offset = 0x000000))

        # FcTxLogic has no AXI registers
        # self.add(ldmx_tdaq.FcTxLogic(
        #     name   = "FcTxLogic",
        #     numVc  = 0,
        #     offset = 0x010000))

        self.add(ldmx_tdaq.LdmxPgpFcLane(
            name   = "FcSenderLane",
            numVc  = 0,
            offset = 0x200000))
