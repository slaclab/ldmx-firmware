import pyrogue as pr

import ldmx_tdaq
#import ldmx_ts

class S30xlGlobalTriggerLogic(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'EnableSynTriggers',
            offset = 0,
            bitOffset = 0,
            bitSize = 1,
            base = pr.Bool))

        self.add(pr.RemoteVariable(
            name = 'EnableTsThresholdTriggers',
            offset = 0,
            bitOffset = 1,
            bitSize = 1,
            base = pr.Bool))

