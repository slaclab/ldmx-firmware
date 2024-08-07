import pyrogue as pr
import ldmx_tdaq
import ldmx_ts

class TsDataRxLaneArray(pr.Device):
    def __init__(self, lanes=2, **kwargs):
        super().__init__(**kwargs)

        for i in range(lanes):
            self.add(ldmx_ts.TsDataRxLane(
                name = f'TsDataRxLane[{i}]',
                offset = 0x8000 * i))
