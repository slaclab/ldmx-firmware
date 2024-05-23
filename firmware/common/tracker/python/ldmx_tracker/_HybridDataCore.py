import pyrogue as pr

import ldmx

class HybridDataCore(pr.Device):
    def __init__(self, apvsPerHybrid, **kwargs):
        super().__init__(**kwargs)


        self.add(ldmx.HybridSyncStatus(
            offset = 0x0000,
            apvsPerHybrid = apvsPerHybrid))

        for i in range(apvsPerHybrid):
            self.add(ldmx.ApvDataPipeline(
                name = f'ApvDataPipeline[{i}]',
                offset = 0x10000 * (i+1)))

        
