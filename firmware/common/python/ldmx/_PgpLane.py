import rogue

import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx


class PgpLane(pr.Device):
    def __init__(self, numVc, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx.PgpFcGtyCoreWrapper(
            name   = "PgpFcGtyCoreWrapper",
            offset = 0x0000))

        self.add(surf.protocols.pgp.Pgp2fcAxi(
            name   = "Pgp2fcAxi",
            offset = 0x2000))

        if numVc > 0:
            self.add(surf.axi.AxiStreamMonAxiL(
                name = "TxStreamMon",
                offset = 0x4000,
                numberLanes = numVc,
                hideConfig = False,
                chName = None))

            self.add(surf.axi.AxiStreamMonAxiL(
                name = "RxStreamMon",
                offset = 0x6000,
                numberLanes = numVc,
                hideConfig = False,
                chName = None))

        self.add(ldmx.FcEmu(
            name   = "FcEmu",
            offset = 0x8000))

class PgpLaneTb(pr.Root):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.memMap = rogue.interfaces.memory.TcpClient('localhost', 11000)

        self.addInterface(self.memMap)

        self.add(PgpLane(
            memBase = self.memMap))
        
