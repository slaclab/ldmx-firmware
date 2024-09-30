import pyrogue as pr
import pyrogue.interfaces.simulation

import axipcie

import rogue

import ldmx_tdaq
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
            SIM_DAQ_EVENT_PORT = 11000
            SIM_TRIG_EVENT_PORT = 12000

            self.srpStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT)
            self.tsDaqEventStream = rogue.interfaces.stream.TcpClient('localhost', SIM_DAQ_EVENT_PORT)
            self.tsTrigEventStream = rogue.interfaces.stream.TcpClient('localhost', SIM_TRIG_EVENT_PORT)

        else:
            # Open rUDP connections
            self.srpUdp = pyrogue.protocols.UdpRssiPack(host=host, port=8192, packVer=2, name='SrpRssi')
            self.tsDaqUdp = pyrogue.protocols.UdpRssiPack(host=host, port=8193, packVer=2, name='TsDaqEventRssi')
            self.trigDataUdp = pyrogue.protocols.UdpRssiPack(host=host, port=8194, packVer=2, name='TsTrigEventRssi')

            self.addInterface(self.srpUdp, self.tsDaqUdp, self.trigDataUdp)
            
            self.srpStream = self.srpUdp.application(dest=0)
            self.tsDaqEventStream = self.rawDataUdp.application(dest=0)
            self.tsTrigEventStream = self.trigDataUdp.application(dest=0)

        # Add stream interfaces for clean exit
        self.addInterface(self.srpStream, self.tsDaqEventStream, self.tsTrigEventStream)
            
        # Connect srp stream to srp protocol
        self.srp == self.srpStream

        # Instantiate the FPGA Device Tree
        self.add(ldmx_ts.S30xlAPx(
            memBase = self.srp,
            expand = True))

        self.tsDaqEventReceiver = ldmx_ts.TsDaqEventReceiver()
        self.addInterface(self.rawEventReceiver)

        self.tsDaqEventStream >> self.rawEventReceiver
#        self.trigDataStream >> self.dataReceiver
