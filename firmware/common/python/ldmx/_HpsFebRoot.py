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

        sideband = pyrogue.interfaces.simulation.SideBandSim('localhost', SIM_SRP_PORT+8)

        srp = rogue.protocols.srp.SrpV3()

        srpStream == srp

        dataDebug = rogue.interfaces.stream.Slave()
        dataDebug.setDebug(100, "EventStream")
        dataStream >> dataDebug

        self.addInterface(srpStream, dataStream, srp, sideband)
        

        self.add(ldmx.HpsFeb(
            memBase = srp,
            number = 0,
            sim = False,
            expand = True,
            numHybrids = 4))

        @self.command()
        def Trigger():
            sideband.send(opCode=0x5A)

        @self.command()
        def RunStart():
            sideband.send(opCode=0xF0)

        @self.command()
        def ApvClkAlign():
            sideband.send(opCode=0xA5)

        @self.command()
        def ApvReset101():
            sideband.send(opCode=0x1F)
