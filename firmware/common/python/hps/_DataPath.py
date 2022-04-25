import pyrogue as pr

import hps


class DataPath(pr.Device):
    def __init__ (self, enSampleExtractors=True, **kwargs):
        super().__init__(description="RCE Hybrid DataPath Object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="SyncStatus",
            offset=0x00,
            bitSize=5,
            bitOffset=0,
            mode='RO',
            pollInterval=5,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="HybridType",
            offset=0x00,
            bitSize=2,
            bitOffset=5,
            mode='RO',
            base=pr.UInt,
            enum = {
                0: 'Unknown',
                1: 'Old',
                2: 'New',
                3: 'Layer0'}))

        self.add(pr.RemoteVariable(
            name="HybridNum",
            offset=0x00,
            bitSize=2,
            bitOffset=7,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="FebNum",
            offset=0x00,
            bitSize=8,
            bitOffset=9,
            mode='RO',
            base=pr.UInt))

        if enSampleExtractors:
            self.addNodes(
                nodeClass=hps.ApvDataFormatter,
                name='SampleExtractor',
                number=5,
                stride=0x200,
                offset = 0x9000)

        for i in range(5):
            self.add(pr.MemoryDevice(
                name = f"ApvThresholds[{i}]",
                offset = 0x8000 + (i*0x200),
                size = 0x200,
                hidden = True,
                wordBitSize = 32,
                stride = 4,))

#         self.add(hps.StreamLogger(
#             offset = 0xA000))
