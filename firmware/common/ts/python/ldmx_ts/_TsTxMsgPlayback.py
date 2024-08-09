import pyrogue as pr
import surf.xilinx
import ldmx_tdaq
import ldmx_ts

class TsTxMsgPlayback(pr.Device):
    def __init__(self, lanes=2, **kwargs):
        super().__init__(**kwargs)

        for i in range(lanes):
            self.add(ldmx_ts.TsTxMsgPlaybackLane(
                name = f'Lane[{i}]',
                offset = 0x10_0000*i))
        
