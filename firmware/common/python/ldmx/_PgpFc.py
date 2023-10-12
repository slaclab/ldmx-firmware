
import pyrogue as pr
import ldmx

class PgpFc(pr.Device):
    def __init__(self, numQuads, **kwargs):
        super().__init__(**kwargs)

        for quad in range(numQuads):
            # number of lanes is always 4
            # *not* the same as DMA lanes
            for lane in range(4):
                self.add(ldmx.PgpLane(
                    name = f'PgpLane[{quad}][{lane}]',
                    offset = 0x1_0000 * (quad*4+lane)))
