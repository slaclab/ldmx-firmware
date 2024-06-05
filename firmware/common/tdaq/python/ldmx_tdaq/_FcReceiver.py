
import pyrogue as pr
import ldmx_tdaq

class FcReceiver(pr.Device):
    def __init__(self, numVc, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.LdmxPgpFcLane(
            name = f'PgpFcLane',
            numVc = numVc,
            offset = 0x0_0000))

        self.add(ldmx_tdaq.FcRxLogic(
            offset = 0x1_0000))

        self.add(ldmx_tdaq.FcEmu(
            offset = 0x2_0000))
