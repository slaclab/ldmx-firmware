import rogue
import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx_tdaq

class FcHub(pr.Device):
    def __init__(self, numQuads=1, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.Lcls2TimingRx(
            name   = 'Lcls2TimingRx',
            offset = 0x000000))

        # FcTxLogic has no AXI registers
        # self.add(ldmx_tdaq.FcTxLogic(
        #     name   = "FcTxLogic",
        #     numVc  = 0,
        #     offset = 0x010000))

        for i in range(numQuads*4):
            self.add(ldmx_tdaq.LdmxPgpFcLane(
                name   = f'FcSenderLane[{i}]',
                numVc  = 0,
                offset = 0x200000 + 0x10000*i))
