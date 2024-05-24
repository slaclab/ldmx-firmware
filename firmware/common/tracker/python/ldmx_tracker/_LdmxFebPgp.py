import ldmx_tdaq

import pyrogue as pr

import surf.xilinx
import surf.protocols.pgp


class LdmxFebPgp(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.FcReceiver(
            offset = 0x00000
            numVc = 3))


