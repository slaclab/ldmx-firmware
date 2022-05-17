import pyrogue
import pyrogue as pr
import surf.axi as axi
import hps
from surf.devices.micron import _AxiMicronN25Q as micron
import surf.protocols.pgp as pgp
import time

class FebGroup(pyrogue.Device):
    def __init__(self, memBases, hostConfig, controlDpms, **kwargs):


        for i in range(10): #enumerate(hostConfig.febLinkMap):
            self.add(hps.HpsFeb(
                name=f'FebFpga[{i}]',
                number=i,
                memBase = memBases[i],))
#                enableDeps = [controlDpms[link[0]].PgpStatus.Pgp2bAxi[link[1]].RxRemLinkReady]))





class HpsFeb(pr.Device):
    def __init__(self, number, sim=False, numHybrids=4, **kwargs):
        super().__init__(
            description="HPS (LDMX) Front End Board FPGA Top Level", **kwargs)

        self.number = number

        self.add(hps.FebCore(
            number=number,
            offset=0x000000,
            expand=True,
            numHybrids=numHybrids,
            enabled=True
        ))

        self.add(ldmx.HpsFebHw(
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
            self.HpsFebHw.Tca6424a.writeBlocks()


