import pyrogue as pr
import hps
import RceG3 as rce


class TiDtm(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="Trigger DTM Registers.", **kwargs)

        #self.setupMapMemory()

        self.add(hps.TiRegisters(offset=0xA0010000))

        self.add(rce.DtmTiming(offset=0xA0000000))

        self.add(rce.RceVersion(offset=0x80000000))

        self.add(rce.RceBsi(offset=0x84000000))

#     def setupMapMemory(self):
#         if isinstance(self._memBase, rogue.hardware.rce.MapMemory):
#             self._memBase.addMap(0x80000000, 0x2000) # Core Registers
#             self._memBase.addMap(0x84000000, 0x2000) # BSI Registers
#             self._memBase.addMap(0xA0000000, 0x10000) # Timing registers
#             self._memBase.addMap(0xA0010000, 0x10000) # Ti Registers
