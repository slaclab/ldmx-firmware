import pyrogue
import pyrogue as pr
import surf.axi as axi
import surf.xilinx as xil
import surf.protocols.pgp as pgp
import hps
from surf.devices.micron import _AxiMicronP30 as micron

class FebBootloaderFpga(pr.Device):
    def __init__(self, number, sim=False, **kwargs):
        super(self.__class__, self).__init__(
            description="Front End FPGA", **kwargs)

        self.add(axi.AxiVersion(
            name='AxiVersion',
            enabled=True,
            offset=0x200000,
        ))

        self.add(hps.FebConfig(
            enabled=False,
            offset=0x0))

        self.add(xil.Xadc(
            enabled=False,
            offset=0x5000,
            auxChannels=16))

        self.add(pgp.Pgp2bAxi(
            enabled=False,
            offset=0x210000))

        self.add(micron.AxiMicronP30(
            enabled = False,
            offset=0x800000))

#         self.add(hps.FebSem(
#             offset=0x800100,
#             name='FebSem'))
