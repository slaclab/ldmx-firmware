import pyrogue as pr
import axipcie
import ldmx_tdaq
import ldmx_tracker

class TrackerBittware(pr.Device):
    def __init__(self, pgp_quads, sim, **kwargs):
        super().__init__(**kwargs)

        # FC Receiver
        self.add(ldmx_tdaq.FcReceiver(
            offset = 0x0080_0000,
            numVc = 0))

        # FEB PGP FC Array
        self.add(ldmx_tracker.TrackerPgpFcArray(
            offset = 0x0090_0000,
            numPgpQuads = pgp_quads,
            numVc = 4))        

        # Bittware PCIE
        self.add(axipcie.AxiPcieCore(
            offset = 0x0,
            numDmaLanes = pgp_quads,
            expand = True,
            sim = sim))   
