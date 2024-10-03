import rogue
import pyrogue as pr
import surf.xilinx
import surf.protocols.pgp
import ldmx_tdaq

class LdmxPgpFcLane(pr.Device):
    def __init__(self, numVc, **kwargs):
        super().__init__(**kwargs)


        self.add(surf.protocols.pgp.Pgp2fcAxi(
            name   = "Pgp2Fc",
            statusCountBits = 32,
            errorCountBits  = 32,
            offset = 0x4000))

        self.add(ldmx_tdaq.Pgp2fcGtyCoreWrapper(
            name   = "GTY",
            offset = 0x0000))

        if numVc > 0:
            self.add(surf.axi.AxiStreamMonAxiL(
                name = "TxStreamMon",
                offset = 0x8000,
                numberLanes = numVc,
                hideConfig = False,
                chName = None))

            self.add(surf.axi.AxiStreamMonAxiL(
                name = "RxStreamMon",
                offset = 0xC000,
                numberLanes = numVc,
                hideConfig = False,
                chName = None))
