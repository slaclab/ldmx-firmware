import numpy as np
import pyrogue as pr
import surf.xilinx
import ldmx_tdaq
import ldmx_ts

class TsTxMsgPlaybackLane(pr.Device):
    def __init__(self,  **kwargs):
        super().__init__(**kwargs)

#         self.add(pr.RemoteVariable(
#             name = f'RAM',
#             offset = 0,
#             hidden = True,
#             base = pr.UInt,
#             valueBits = 8,
#             valueStride = 8,
#             numValues = 2**12))

#         self.add(pr.RemoteVariable(
#             name = f'RAM_B',
#             offset = 8,
#             hidden = True,
#             base = pr.UInt,
#             valueBits = 64,
#             valueStride = 128,
#             numValues = 2**12))

        for i in range(6):
            self.add(pr.RemoteVariable(
                name = f'ADC[{i}]',
                offset = 0,
                bitOffset = i*8,                
                hidden = True,
                base = pr.UInt,
                valueBits = 8,
                valueStride = 128,
                numValues = 2**8))

        for i in range(6):
            self.add(pr.RemoteVariable(
                name = f'TDC[{i}]',
                offset = 0,
                bitOffset = 64 + (i*8),
                hidden = True,
                base = pr.UInt,
                valueBits = 6,
                valueStride = 128,
                numValues = 2**8))

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
            for sample in range(len(tdcs)):
                for channel in range(6):
                    #print(f'Set adc value {adcs[sample, channel]:x} at index {sample*16+channel:x}')
                    #self.RAM.set(value = int(adcs[sample, channel]), index=sample*16+channel, write=False)
                    print(f'Set adc value {adcs[sample, channel]:x} at index ADC[{channel}][{sample}]')
                    self.ADC[channel].set(int(adcs[sample, channel]), index=sample, write=False)
                for channel in range(6):
#                     print(f'Set tdc value {tdcs[sample, channel]:x} at index {sample*16+(channel+6):x}')
#                     self.RAM.set(value = int(tdcs[sample, channel]), index=sample*16+(6+channel), write=False)
                    print(f'Set tdc value {tdcs[sample, channel]:x} at index TDC[{channel}][{sample}]')
                    self.TDC[channel].set(int(tdcs[sample, channel])&0x3f, index=sample, write=False)
                    
#                 for channel in range(12, 16):
#                     self.RAM.set(value = 0, index=sample*16+channel, write=False)

            self.writeBlocks()
            self.verifyBlocks()

