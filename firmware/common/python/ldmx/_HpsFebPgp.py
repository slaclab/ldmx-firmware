import pyrogue as pr

import surf.xilinx
import surf.protocols.pgp

class GtpWrapper(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.xilinx.Gtpe2Channel(
            name = 'Gtp',
            offset = 0x0000,
            enabled = False))
        
        self.add(surf.xilinx.Gtpe2Common(
            name = 'Qpll',
            offset = 0x1000,
            enabled = False))
        

class HpsFebPgp(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        noPoll = ['RxLinkPolarity', 'RxRemPause', 'TxLocPause', 'RxRemOverflow', 'TxLocOverflow', 'RxRemLinkData',
                  'LastTxOpCode', 'LastRxOpCode', 'TxOpCodeCount', 'RxOpCodeCount']
        longPoll = ['RxLinkErrorCount', 'RxLinkDownCount', 'RxCellErrorCount', 'RxFrameCount', 'RxFrameErrorCount', 'TxFrameCount']

        self.add(surf.protocols.pgp.Pgp2fcAxi(
            name='Pgp2Fc',
            expand=False,
            offset=0x0000))

        self.add(GtpWrapper(
            offset = 0x10000))

        self.Pgp2Fc.setPollInterval(0) #, noPoll)
        self.Pgp2Fc.setPollInterval(5, longPoll)

