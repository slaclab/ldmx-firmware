import pyrogue as pr

import ldmx

class ApvDataPipeline(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx.ApvDataFormatter(
            offset = 0x0000))

        self.add(pr.RemoteVariable(
            name = 'ApvThresholds',
            offset = 0x1000,
            base = pr.UInt,
            mode = 'RW',
            bitSize = 128 * 32,
            numValues = 128,
            valueBits = 32,
            valueStride = 32,
            hidden = True))
