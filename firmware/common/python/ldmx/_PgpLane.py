import rogue

import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx
        

class PgpLane(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.xilinx.Gtye4Channel(
            offset = 0x0000))

        self.add(surf.protocols.pgp.Pgp2fcAxi(
            offset = 0x1000))

        self.add(ldmx.PgpMiscCtrl(
            offset = 0x2000))

        self.add(surf.axi.AxiStreamMonAxiL(
            name = "TxStreammMon",
            offset = 0x3000,
            numberLanes = 4,
            hideConfig = False,
            chName = None))

        self.add(surf.axi.AxiStreamMonAxiL(
            name = "RxStreammMon",
            offset = 0x4000,
            numberLanes = 4,
            hideConfig = False,
            chName = None))

class PgpLaneTb(pr.Root):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.memMap = rogue.interfaces.memory.TcpClient('localhost', 11000)

        self.addInterface(self.memMap)

        self.add(PgpLane(
            memBase = self.memMap))
        
