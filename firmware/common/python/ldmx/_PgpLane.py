import rogue

import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx
        

class PgpLane(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # self.add(surf.xilinx.Gtye4Channel(
        #     offset = 0x0000))

        self.add(ldmx.PgpFcGtyCoreWrapper(
            offset = 0x0_0000))

        self.add(surf.protocols.pgp.Pgp2fcAxi(
            offset = 0x1_0000))

        self.add(surf.axi.AxiStreamMonAxiL(
            name = "TxStreamMon",
            offset = 0x2_0000,
            numberLanes = 4,
            hideConfig = False,
            chName = None))

        self.add(surf.axi.AxiStreamMonAxiL(
            name = "RxStreamMon",
            offset = 0x3_0000,
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
        
