
import pyrogue as pr
import ldmx

class PgpFc(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        for i in range(4):
            self.add(ldmx.PgpLane(
                name = f'PgpLane[{i}]',
                offset = 0x1_0000 * i))
