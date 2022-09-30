
import pyrogue as pr
import ldmx

class PgpFcAlveo(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        for i in range(8):
            self.add(ldmx.PgpLane(
                name = f'PgpLane[{i}]',
                offset = 0x10000 * i))
    
