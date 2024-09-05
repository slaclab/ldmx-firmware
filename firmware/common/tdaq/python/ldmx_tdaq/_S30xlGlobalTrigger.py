import pyrogue as pr

import ldmx_tdaq
#import ldmx_ts

class S30xlGlobalTrigger(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.FcRxLogic(
            offset = 0x000))

        self.add(ldmx_tdaq.SyntheticTrigger(
            offset = 0x100))

        self.add(ldmx_tdaq.S30xlGlobalTriggerLogic(
            offset = 0x300))
