import pyrogue as pr
import ldmx_ts

class S30xlApxEthCore(pr.Device):
    def __init__(self, **kwargs)
        super().__init__(**kwargs)

        self.add(surf.protocols.rssi.RssiCore(
            enabled = False,
            name = "SRP_RSSI",
            offset = 0x11000,
            expand = False))

        self.add(surf.protocols.rssi.RssiCore(
            enabled = False,
            name = "RawData_RSSI",
            offset = 0x12000,
            expand = False))

        self.add(surf.protocols.rssi.RssiCore(
            enabled = False,
            name = "TrigData_RSSI",
            offset = 0x13000,
            expand = False))
        
        self.add(surf.ethernet.udp.UdpEngine(
            enabled = False,
            offset = 0x10000,
            numSrv = 2))

        self.add(surf.ethernet.ten_gig.TenGigEthReg(
            enabled = False,
            gtxe2_read_only = True,
            offset = 0x00000))
        
