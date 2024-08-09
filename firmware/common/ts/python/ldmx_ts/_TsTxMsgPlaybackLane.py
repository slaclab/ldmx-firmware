import numpy as np
import pyrogue as pr
import surf.xilinx
import ldmx_tdaq
import ldmx_ts

class TsTxMsgPlaybackLane(pr.Device):
    def __init__(self,  **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = f'RAM',
            offset = 0,
            hidden = True,
            base = pr.UInt,
            valueBits = 8,
            valueStride = 8,
            numValues = 2**12))

#         self.add(pr.RemoteVariable(
#             name = f'RAM_B',
#             offset = 8,
#             hidden = True,
#             base = pr.UInt,
#             valueBits = 64,
#             valueStride = 128,
#             numValues = 2**12))



#         for i in range(4):
#             self.add(pr.RemoteVariable(
#                 name = f'TDC[{i}]',
#                 offset = 5+i,
#                 hidden = True,
#                 base = pr.UInt,
#                 valueBits = 6,
#                 valueStride = 128,
#                 numValues = 4))

#         self.add(pr.RemoteVariable(
#             name = 'TxEnable',
#             offset = 0x0,
#             bitOffset = 127,
#             bitSize = 1,
#             base = pr.Bool))

        @self.command()
        def Start():
            self.RAM.set(value=0xff, index=15, write=True)

        @self.command()            
        def Stop():
            self.RAM.set(value=0x00, index=15, write=True)

        @self.command()
        def FillRam():
            adcs = np.random.normal(
                loc = [.2, .3, .4, .5, .6, .7],
                scale = .1,
                size = (2**8, 6)) * 2**8
            adcs = adcs.astype(np.uint8)

            tdcs = np.random.normal(
                loc = [.2, .3, .4, .5, .6, .7],
                scale = .1,
                size = (2**8, 6)) * 2**6
            tdcs = tdcs.astype(np.uint8)

            value = 0
            for i in range(len(tdcs)):
                for j in range(6):
                    print(f'Set adc value {adcs[i, j]:x} at index {i*16+j:x}')
                    self.RAM.set(value = int(adcs[i, j]), index=i*16+j, write=False)
                for j in range(6):
                    print(f'Set adc value {adcs[i, j]:x} at index {i*16+(j+6):x}')
                    self.RAM.set(value = int(tdcs[i, j]), index=i*16+(6+j), write=False)
                for j in range(12, 16):
                    self.RAM.set(value = 0, index=i*16+j, write=False)

            self.writeBlocks()
            self.verifyBlocks()

