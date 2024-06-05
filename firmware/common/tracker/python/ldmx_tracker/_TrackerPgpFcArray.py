
import pyrogue as pr
import ldmx_tdaq

class TrackerPgpFcArray(pr.Device):
    def __init__(self, numPgpQuads, numVc, **kwargs):
        super().__init__(**kwargs)

        for quad in range(numPgpQuads):
            # number of lanes is always 4
            # *not* the same as DMA lanes
            for lane in range(4):
                self.add(ldmx_tdaq.LdmxPgpFcLane(
                    name = f'PgpFcLane[{quad*4+lane}]',
                    numVc = numVc,
                    offset = 0x1_0000 * (quad*4+lane)))
