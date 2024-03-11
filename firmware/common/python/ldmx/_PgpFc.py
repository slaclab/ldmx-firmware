
import pyrogue as pr
import ldmx

class PgpFc(pr.Device):
    def __init__(self, numQuads, numLinks, numVc, **kwargs):
        super().__init__(**kwargs)

        for quad in range(numQuads):
            # number of lanes is always 4
            # *not* the same as DMA lanes
            for lane in range(numLinks):
                _offset = 0x1_0000 * (quad*numLinks+lane)
                self.add(ldmx.PgpLane(
                    name = f'PgpLane[{quad}][{lane}]',
                    numVc = numVc,
                    offset = _offset))
                print(f"PgpLane Offset = {hex(_offset)}")

        _offset = 0x1_0000 * ((numQuads-1)*numLinks+numLinks) + 0x1_0000
        self.add(ldmx.FcEmu(
            name   = "Fc Emulator",
            offset = _offset))
        print(f"Emulator Offset = {hex(_offset)}")
