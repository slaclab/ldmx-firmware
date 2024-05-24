import pyrogue
import pyrogue as pr
import surf.axi as axi
import hps
#from surf.devices.micron import _AxiMicronP30 as micron
#import surf.protocols.pgp as pgp

class FebFpgaOld(pr.Device):
    def __init__(self, **kwargs):
        super(self.__class__, self).__init__(
            description="Front End FPGA", **kwargs)

        self.add(axi.AxiVersionLegacy(
            offset=0x200000,
            hasUpTimeCnt=False,
            hasFpgaReloadHalt=False,
            hasDeviceId=False,
            hasGitHash=False,
            dnaBigEndian=True
        ))

        self.add(hps.FebCore(
            offset=0x000000,
            hybridNum=4,
        ))

#         self.addNodes(
#             nodeClass=pgp.Pgp2bAxi,
#             number=5,
#             stride=0x1000,
#             offset=0x210000,
#             name='Pgp2bAxi')

#         self.add(micron.AxiMicronP30(
#             offset=0x800000,
#             name='AxiMicronP30'))

#         self.add(hps.FebSem(
#             offset=0x800100,
#             name='FebSem'))
