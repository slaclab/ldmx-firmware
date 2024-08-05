import pyrogue as pr
import surf.axi
import ldmx_tdaq
import ldmx_ts

class S30xlAPx(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.axi.AxiVersion(
            offset = 0x0000))

        self.add(ldmx_ts.S30xlAppCore(
            offset = 0x8000_0000,
            expand = True))

        self.add(ldmx_tdaq.FcHub(
            offset = 0x2000_0000))

        self.add(ldmx_ts.S30xlApxEthCore(
            offset = 0x1000_0000))
