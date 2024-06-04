
import pyrogue as pr
import ldmx

class FcReceiver(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx.LdmxPgpFcLane(
            name = f'PgpFcLane',
            numVc = numVc,
            offset = 0x0_0000))

        self.add(ldmx.FcRxLogic(
            offset = 0x1_0000))

        self.add(ldmx.FcEmu(
            offset = 0x2_0000))
