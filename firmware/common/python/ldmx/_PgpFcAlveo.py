
import pyrogue as pr
import ldmx

class RefclkMon(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        for i in range(4):
            self.add(pr.RemoteVariable(
                name = f'Clock{i}Freq',
                offset = 0x4 * i,
                mode = 'RO',
                disp = '{:d}'))

class PgpFcAlveo(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        for i in range(8):
            self.add(ldmx.PgpLegacyLane(
                name = f'PgpLegacyLane[{i}]',
                offset = 0x10000 * i))

        self.add(RefclkMon(
            offset = 0x10000 * 8))

        
    
