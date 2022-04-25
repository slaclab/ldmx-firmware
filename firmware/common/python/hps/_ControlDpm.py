import pyrogue as pr
import pyrogue.utilities.prbs

import RceG3

import surf.protocols.pgp as pgp

class FebLoopback(pr.Device):
    def __init__(self, stream, **kwargs):
        super().__init__(**kwargs)
        self.add(pyrogue.utilities.prbs.PrbsTx(name='PrbsTx'))
        self.add(pyrogue.utilities.prbs.PrbsRx(name='PrbsRx'))

        pyrogue.streamConnect(self.PrbsTx, stream)
        pyrogue.streamConnect(stream, self.PrbsRx)

class FebLoopbackArray(pr.Device):
    def __init__(self, streams, **kwargs):
        super().__init__(**kwargs)
        for i in range(len(streams)):
            self.add(FebLoopback(
                name = f'Feb[{i}]',
                stream = streams[i]))

class ControlDpm(pr.Device):

    def __init__ (self, *,
                  sim = False,
                  **kwargs):
        super().__init__(description="Data DPM Registers.", **kwargs)

        numLinks = 1 if sim else 12

        self.add(pr.LocalVariable(
            name="TotalApvs",
            description='Total number of APVs',
            value=0))

        if sim is False:
            self.add(RceG3.RceVersion(
                offset=0x80000000,
                expand=False))

        self.add(pr.ArrayDevice(
            name='PgpStatus',
            arrayClass=pgp.Pgp2bAxi,
            number=numLinks,
            stride=0x10000,
            offset=0xA0100000,
            expand=False,
            arrayArgs={'expand':False}))

        noPoll = ['RxLinkPolarity', 'RxRemPause', 'TxLocPause', 'RxRemOverflow', 'TxLocOverflow', 'RxRemLinkData',
                  'LastTxOpCode', 'LastRxOpCode', 'TxOpCodeCount', 'RxOpCodeCount']
        longPoll = ['RxLinkErrorCount', 'RxLinkDownCount', 'RxCellErrorCount', 'RxFrameCount', 'RxFrameErrorCount', 'TxFrameCount', 'RxRemLinkReady', 'RxLocalLinkReady', 'RxRemLinkReadyCount']
        for i, d in self.PgpStatus.Pgp2bAxi.items():
            d.setPollInterval(0) #, noPoll)
            d.setPollInterval(5, longPoll)

        self.add(RceG3.DpmTiming(
            offset=0xA0000000,
            expand=False))
