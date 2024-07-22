import pyrogue as pr
import lmdx_tdaq
import ldmx_ts

class S30xlAppCore(pr.Device):
    def __init__(self, **kwargs)
        super().__init__(**kwargs)

        self.add(ldmx_tdaq.FcReceiver(
            offset = 0x0_0000))

        self.add(ldmx_ts.TsRxData(
            offset = 0x2000_0000))


