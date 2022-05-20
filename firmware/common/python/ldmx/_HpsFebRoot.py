import pyrogue as pr
import pyrogue.interfaces.simulation

import rogue

import ldmx

class HpsFebRoot(pr.Root):
    def __init__(self, **kwargs):
        super().__init__(pollEn=False, timeout=1000, **kwargs)

        SIM_SRP_PORT = 9000

        srpStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT)
        dataStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+2)

        srp = rogue.protocols.srp.SrpV3()

        srpStream == srp

        self.addInterface(srpStream, dataStream, srp)
        

        self.add(ldmx.HpsFeb(
            memBase = srp,
            number = 0,
            sim = False,
            expand = True,
            numHybrids = 4))
