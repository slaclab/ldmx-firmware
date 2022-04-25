import pyrogue as pr

import hps
import surf.protocols.pgp as pgp
import surf.protocols.batcher
import surf.protocols.rssi
import surf.ethernet.udp
import RceG3



class DataDpm(pr.Device):
    def __init__ (self, sim=False, **kwargs):
        super().__init__(description="Data DPM Registers.", **kwargs)

        if sim is False:
            self.add(RceG3.RceVersion(offset=0x80000000))

        self.add(hps.RceCore(offset=0xA0100000, hybridNum=4))

        self.add(surf.protocols.batcher.AxiStreamBatcherAxil(
            name = 'Batcher',
            offset = 0xA0300000))

        self.add(RceG3.DpmTiming(
            offset=0xA0000000,
            expand=False))
        self.DpmTiming.setPollInterval(7)

        self.add(pr.ArrayDevice(
            name='PgpStatus',
            arrayClass=pgp.Pgp2bAxi,
            number=4,
            stride=0x10000,
            offset=0xA0200000,
            expand=False))

        noPoll = ['RxLinkPolarity', 'RxRemPause', 'TxLocPause', 'RxRemOverflow', 'TxLocOverflow', 'RxRemLinkData',
                  'LastTxOpCode', 'LastRxOpCode', 'TxOpCodeCount', 'RxOpCodeCount']
        longPoll = ['RxLinkErrorCount', 'RxLinkDownCount', 'RxCellErrorCount', 'RxFrameCount', 'RxFrameErrorCount', 'TxFrameCount', 'RxRemLinkReady', 'RxLocalLinkReady', 'RxRemLinkReadyCount']
        for i, d in self.PgpStatus.Pgp2bAxi.items():
            d.setPollInterval(0) #, noPoll)
            d.setPollInterval(5, longPoll)

        if sim is False:
            self.add(RceG3.RceEthernet(hidden=True))

            #self.add(surf.ethernet.udp.UdpEngineServer(offset = 0xA8000000))

            #self.add(surf.protocols.rssi.RssiCore(offset=0xA8001000))



class DataDpmArray(pr.Device):
    def __init__ (self, memBases, sim=False, **kwargs):
        super().__init__(**kwargs)

        for i, mem, in enumerate(memBases):
            self.add(hps.DataDpm(
                name = f'DataDpm[{i}]',
                sim=sim,
                enabled=True,
                memBase = mem,
                expand = False))

        @self.command()
        def ResetDataPipelines():
            for dpm in self.DataDpm.values():
                dpm.RceCore.DataPipelineReset()

    def hardReset(self):
        self.ResetDataPipelines()

    def setCalibrationMode(self, value):
        for dpm in self.DataDpm.values():
            dpm.RceCore.CalibrationEn.set(value)

    def setCalibrationGroup(self, group):
        for dpm in self.DataDpm.values():
            dpm.RceCore.CalibrationGroup.set(group)

    def setMaxBatchFrames(self, frames):
        for dpm in self.DataDpm.values():
            dpm.Batcher.MaxSubFrames.set(frames)
