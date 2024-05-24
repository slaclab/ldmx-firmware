import ldmx_tdaq

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

class LdmxFebPgpLane(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.protocols.pgp.Pgp2fcAxi(
            name='Pgp2Fc',
            expand=False,
            offset=0x0000))

        # Add PgpMiscCtrl

        self.add(surf.xilinx.Gtye4Channel(
            name='GTY',
            expand=False,
            offset=0x10000))
        
        

class LdmxFebPgp(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)

        noPoll = ['RxLinkPolarity', 'RxRemPause', 'TxLocPause', 'RxRemOverflow', 'TxLocOverflow', 'RxRemLinkData',
                  'LastTxOpCode', 'LastRxOpCode', 'TxOpCodeCount', 'RxOpCodeCount']
        longPoll = ['RxLinkErrorCount', 'RxLinkDownCount', 'RxCellErrorCount', 'RxFrameCount', 'RxFrameErrorCount', 'TxFrameCount']

        if sim is False:

            self.add(LdmxFebPgpLane(
                name='SFP_PGP',
                offset = 0x00_0000))

            self.add(LdmxFebPgpLane(
                name='QSFP_PGP',
                offset = 0x10_0000))

            self.add(LdmxFebPgpLane(
                name='SAS_PGP',
                offset = 0x20_0000))

#            self.Pgp2Fc.setPollInterval(0) #, noPoll)
#            self.Pgp2Fc.setPollInterval(5, longPoll)

        else:

            self.add(ldmx_tdaq.FcEmu(
                offset = 0x30_0000))

