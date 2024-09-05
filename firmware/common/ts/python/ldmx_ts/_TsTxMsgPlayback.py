import pathlib
import numpy as np

import pyrogue as pr
import surf.xilinx
import ldmx_tdaq
import ldmx_ts

class TsTxMsgPlayback(pr.Device):
    def __init__(self, lanes=2, **kwargs):
        super().__init__(**kwargs)

        path = pathlib.Path(__file__).parent.resolve()

        self.p1 = path.joinpath('TestVecOne.npy')
        self.p5 = path.joinpath('TestVecFive.npy')
        self.p30 = path.joinpath('TestVecThirty.npy')

        self.a1 = np.load(self.p1)
        self.a5 = np.load(self.p5)
        self.a30 = np.load(self.p30)

        for i in range(lanes):
            self.add(ldmx_ts.TsTxMsgPlaybackLane(
                name = f'Lane[{i}]',
                offset = 0x10_0000*i))
        

        @self.command(hidden=True)
        def LoadNpy(arg):
            for i in range(lanes):
                self.Lane[i].LoadNpy(arg[:256,:,i])

            self.writeBlocks()
            self.verifyBlocks()


        @self.command()
        def LoadTestVecOne():
            self.LoadNpy(self.a1)

        @self.command()
        def LoadTestVecFive():
            self.LoadNpy(self.a5)

        @self.command()
        def LoadTestVecThirty():
            self.LoadNpy(self.a30)
            
