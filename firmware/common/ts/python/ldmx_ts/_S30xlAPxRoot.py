import pyrogue as pr
import pyrogue.interfaces.simulation

import axipcie

import rogue

import ldmx_ts


class S30xlAPxRoot(pr.Root):
    def __init__(self, sim=True, emu=False, host='192.168.0.10', **kwargs):
        super().__init__(timeout=100000, **kwargs)

        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        self.srp = rogue.protocols.srp.SrpV3()
        self.addInterface(self.srp)
        
        if sim is True:
            SIM_SRP_PORT = 10000
            SIM_RAW_DATA_PORT = 11000
            SIM_TRIG_DATA_PORT = 12000

            self.srpStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT)
            self.srp == self.srpStream
            self.addInterface(self.srpStream)

            self.rawDataStream = rogue.interfaces.stream.TcpClient('localhost', SIM_RAW_DATA_PORT)
            self.trigDataStream = rogue.interfaces.stream.TcpClient('localhost', SIM_TRIG_DATA_PORT)

            self.addInterface(self.rawDataStream, self.trigDataStream)

        else:
            self.srpUdp = pyrogue.protocols.UdpRssiPack(host=host, port=8192, packVer=2, name='SrpRssi')
            self.rawDataUdp = pyrogue.protocols.UdpRssiPack(host=host, port=8193, packVer=2, name='RawDataRssi')
            self.trigDataUdp = pyrogue.protocols.UdpRssiPack(host=host, port=8193, packVer=2, name='TrigDataRssi')            
            self.srpStream = self.srpUdp.application(dest=0)
            self.rawDataStream = self.rawDataUdp.application(dest=0)
            self.trigDataStream = self.trigDataUdp.application(dest=0)

        self.add(ldmx_ts.S30xlAPx(
            memBase = self.srp,
            expand = True))
