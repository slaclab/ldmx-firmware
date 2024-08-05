import pyrogue as pr
import ldmx_tdaq
import ldmx_ts

class TsDataRx(pr.Device):
    def __init__(self, lanes=2, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx_ts.TsDataRxLaneArray(
            offset = 0x00_0000,
            lanes = lanes))

#         self.add(ldmx_ts.TsRxAligner(
#             offset = 0x10_0000))

        self.add(ldmx_ts.TsTxMsgPlayback(
            offset = 0x1000_0000,
            lanes = lanes))
