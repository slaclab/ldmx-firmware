import pyrogue as pr

import hps
import RceG3 as rce
import time

class PcieTiDtm(pr.Device):
    def __init__ (self, sim=False, **kwargs):
        super().__init__(description="Trigger DTM Registers.", **kwargs)

        if sim is False:
            self.add(rce.RceVersion(expand=False))

        self.add(rce.DtmTiming(offset=0xA0000000, expand=False))
        #self.add(rce.RceEthernet(offset=0xB0000000, expand=False)

        self.add(hps.JLabTimingPcie(offset=0xA0010000, expand=False))

        @self.command()
        def Trigger():
            self.DtmTiming.TxCmd0.set(0x05A, write=True)

        @self.command()
        def ApvClkAlign():
            self.DtmTiming.TxCmd0.set(0x0A5, write=True)

        @self.command()
        def ApvReset101():
            self.DtmTiming.TxCmd0.set(0x01F, write=True)

        @self.command()
        def RunStart():
            self.DtmTiming.TxCmd0.set(0x3E0, write=True)

    def initialize(self):
        #  self.ApvClkAlign()
        self.ApvReset101()
        super().initialize()

class PcieTiDtmArray(pr.Device):
    def __init__(self, memBases, sim=False, **kwargs):
        super().__init__(**kwargs)

        for i, mem in enumerate(memBases):
            self.add(PcieTiDtm(
                name = f'PcieTiDtm[{i}]',
                sim=sim,
                enabled=True,
                expand=True,
                memBase=mem))

        @self.command()
        def Trigger():
            # In theroy this gets the triggers closer together in time between the two COBs
            # Need to make sure that the COB with the controlDpm is triggered last
            # This way all dataDpm will have received the trigger before data starts arriving from the febs
            for dtm in self.PcieTiDtm.values():
                time.sleep(.1)
                dtm.Trigger()

        @self.command()
        def ApvClkAlign():
            for dtm in self.PcieTiDtm.values():
                time.sleep(.1)
                dtm.ApvClkAlign()

        @self.command()
        def ApvReset101():
            for dtm in self.PcieTiDtm.values():
                time.sleep(.1)
                dtm.ApvReset101()

        @self.command()
        def RunStart():
            for dtm in self.PcieTiDtm.values():
                time.sleep(.1)
                dtm.RunStart()
