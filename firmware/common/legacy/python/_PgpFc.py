
import pyrogue as pr
import ldmx

class PgpFc(pr.Device):
    def __init__(self, numQuads, numLinks, numVc, **kwargs):
        super().__init__(**kwargs)

        for quad in range(numQuads):
            # number of lanes is always 4
            # *not* the same as DMA lanes
            for lane in range(numLinks):
                self.add(ldmx.PgpLane(
                    name = f'PgpLane[{quad}][{lane}]',
                    numVc = numVc,
                    offset = 0x1_0000 * (quad*numLinks+lane)))
