import pyrogue as pr

import ldmx_tracker

class HybridDataCore(pr.Device):
    def __init__(self, apvsPerHybrid, **kwargs):
        super().__init__(**kwargs)


        self.add(ldmx_tracker.HybridSyncStatus(
            offset = 0x0000,
            apvsPerHybrid = apvsPerHybrid))

        for i in range(apvsPerHybrid):
            self.add(ldmx_tracker.ApvDataPipeline(
                name = f'ApvDataPipeline[{i}]',
                offset = 0x10000 * (i+1)))

        
