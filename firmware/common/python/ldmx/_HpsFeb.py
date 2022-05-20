import pyrogue
import pyrogue as pr
import surf.axi as axi
import ldmx


import time

class FebGroup(pyrogue.Device):
    def __init__(self, memBases, hostConfig, controlDpms, **kwargs):


        for i in range(10): #enumerate(hostConfig.febLinkMap):
            self.add(ldmx.HpsFeb(
                name=f'FebFpga[{i}]',
                number=i,
                memBase = memBases[i],))
#                enableDeps = [controlDpms[link[0]].PgpStatus.Pgp2bAxi[link[1]].RxRemLinkReady]))





class HpsFeb(pr.Device):
    def __init__(self, number, sim=False, numHybrids=4, **kwargs):
        super().__init__(
            description="HPS (LDMX) Front End Board FPGA Top Level", **kwargs)

        self.number = number

        self.add(ldmx.FebCore(
            number=number,
            offset=0x000000,
            expand=True,
            numHybrids=numHybrids,
            apvsPerHybrid=5,
            enabled=True
        ))

        self.add(ldmx.HpsFebHw(
            numHybrids = numHybrids,
            febCore = self.FebCore,
            offset = 0x10000000))

        if sim is False:
            self.add(ldmx.HpsFebPgp(
                offset=0x20000000,
                enabled=True))

    def enableChanged(self, value):
        if value is True:
            time.sleep(5)
            self.readBlocks(recurse=True, variable=None, index=-1)
            self.checkBlocks()
            self.FebCore.FebConfig.FebAddress.set(self.number)
            self.HpsFebHw.ConfigureLtc2991()
            #self.HpsFebHw.Tca6424a.writeBlocks()


