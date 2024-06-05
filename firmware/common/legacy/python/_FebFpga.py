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
            self.add(hps.FebFpga(
                name=f'FebFpga[{i}]',
                number=i,
                memBase = memBases[i],))
#                enableDeps = [controlDpms[link[0]].PgpStatus.Pgp2bAxi[link[1]].RxRemLinkReady]))


# def adjustPolling(dev):
#     # Adjust the poll interval of several variables to reduce poll volume
#     for v in noPoll:
#         dev.node(v).pollInterval = 0
#     for v in longPoll:
#         dev.node(v).pollInterval = 5


class FebPgp(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        noPoll = ['RxLinkPolarity', 'RxRemPause', 'TxLocPause', 'RxRemOverflow', 'TxLocOverflow', 'RxRemLinkData',
                  'LastTxOpCode', 'LastRxOpCode', 'TxOpCodeCount', 'RxOpCodeCount']
        longPoll = ['RxLinkErrorCount', 'RxLinkDownCount', 'RxCellErrorCount', 'RxFrameCount', 'RxFrameErrorCount', 'TxFrameCount']

        self.add(pgp.Pgp2bAxi(
            name='CtrlPgp',
            expand=False,
            offset=0x0))

        self.CtrlPgp.setPollInterval(0) #, noPoll)
        self.CtrlPgp.setPollInterval(5, longPoll)

        for i in range(4):
            self.add(pgp.Pgp2bAxi(
                name=f'DataPgp[{i}]',
                expand=False,
                offset=0x100 + (i*0x100)))

            self.DataPgp[i].setPollInterval(0)#, noPoll)
            self.DataPgp[i].setPollInterval(5, longPoll)


        self.add(pr.RemoteVariable(
            name = 'TxPreCursor',
            base = pr.UInt,
            mode = 'RW',
            offset = 0x500,
            bitSize = 5,
            disp = '{:#05b}'))

        self.add(pr.RemoteVariable(
            name = 'TxPostCursor',
            base = pr.UInt,
            mode = 'RW',
            offset = 0x504,
            bitSize = 5,
            disp = '{:#05b}'))


class FebFpga(pr.Device):
    def __init__(self, number, sim=False, **kwargs):
        super().__init__(
            description="Front End FPGA", **kwargs)

        self.number = number

        self.add(axi.AxiVersion(
            expand=True,
            offset=0x200000,
        ))
        self.AxiVersion.UpTimeCnt.pollInterval = 3

        self.add(hps.FebCore(
            number=number,
            offset=0x000000,
            expand=True,
            hybridNum=4,
            enabled=True
        ))

        if sim is False:
            self.add(FebPgp(
                offset=0x210000,
                enabled=True))

        self.add(micron.AxiMicronN25Q(
            offset=0x800000,
            expand=False,
            enabled=False,
            name='AxiMicronN25Q'))

        self.add(hps.FebSem(
            offset=0x801000,
            name='FebSem'))


#         def s(value):
#             print(f'{self.path}.Test.set: {value}')

#         def g():
#             print(f'{self.path}.Test.get enable={self.enable.value()}')
#             if self.enable.value() is True:
#                 print('Reading')
#                 self.readBlocks()
#                 self.checkBlocks()
#                 print('Set Feb address')
#                 self.FebCore.FebConfig.FebAddress.set(self.number)
#                 print('Configure LTC2991')
#                 self.FebCore.ConfigureLtc2991()
#             return ''

#         self.add(pr.LinkVariable(
#             name = 'Test',
#             dependencies = [self.enable],
#             hidden = True,
#             linkedGet = g,
#             linkedSet = s))


    def enableChanged(self, value):
        if value is True:
            time.sleep(5)
            self.readBlocks(recurse=True, variable=None, index=-1)
            self.checkBlocks()
            self.FebCore.FebConfig.FebAddress.set(self.number)
            self.FebCore.ConfigureLtc2991()
            self.FebCore.Tca6424a.writeBlocks()


#     def readBlocks(self, recurse=True, variable=None, checkEach=True):
#         self.root.checkBlocks(recurse=True)
#         pr.Device.readBlocks(self, recurse=recurse, variable=variable, checkEach=True)

#     def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=True):
#         self.root.checkBlocks(recurse=True)
#         pr.Device.writeBlocks(self, force=force, recurse=recurse, variable=variable, checkEach=True)

#     def verifyBlocks(self, recurse=True, variable=None, checkEach=True):
#         self.root.checkBlocks(recurse=True)
#         pr.Device.verifyBlocks(self, recurse=recurse, variable=variable, checkEach=True)
