import pyrogue as pr
import pyrogue.interfaces.simulation

import axipcie

import rogue

import ldmx_tracker

class LdmxFebRoot(pr.Root):
    def __init__(self, sim=True, emu=False, numFebs=1, pgp_quads=2, **kwargs):
        super().__init__(pollEn=False, timeout=100000, **kwargs)

        if sim is True:
            # Map fake PCIe space
            SIM_SRP_PORT = 11000            
            self.pcieMem = rogue.interfaces.memory.TcpClient('localhost', SIM_SRP_PORT)

            self.febSrpStreams = [rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT + feb*10 +2) for feb in range(numFebs)]
            self.febDataStreams = [rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+ feb*10 + 4) for feb in range(numFebs)]
            self.febWaveformStreams = [rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT + feb*10+6) for feb in range(numFebs)]
            self.febMemBase = [rogue.protocols.srp.SrpV3() for feb in range(numFebs)]

            dataDebug = [rogue.interfaces.stream.Slave() for feb in range(numFebs)]

            # connect FEB memory streams
            for srp, stream in zip(self.febSrpStreams, self.febMemBase):
                stream == srp

            # connect debugs
            for index, (debug, stream) in enumerate(zip(dataDebug, self.febDataStreams)):
                debug.setDebug(100, f'EventStream[{index}]')
                stream >> debug
            
            self.addInterface(
                *dataDebug,
                *self.febSrpStreams,
                *self.febDataStreams,
                *self.febWaveformStreams)

        elif emu is True:
            self.pcieMem = pyrogue.interfaces.simulation.MemEmulate()
            self.febMemBase = [pyrogue.interfaces.simulation.MemEmulate() for feb in range(numFebs)]

        else:
            # Map PCIe Core
            self.pcieMem = rogue.hardware.axi.AxiMemMap(dev)
            self.febMemBase = []

        # These are common to all run types
        self.addInterface(
            self.pcieMem,
            *self.febMemBase)

        # Zmq Server
        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)

        self.add(ldmx_tracker.TrackerBittware(
            offset = 0x0,
            memBase = self.pcieMem,
            pgp_quads = pgp_quads,
            sim = sim,
            expand = True))        
            
        for feb in range(numFebs):
            self.add(ldmx_tracker.LdmxFeb(
                name = f'Feb[{feb}]',
                memBase = self.febMemBase[feb],
                number = feb,
                sim = True,
                expand = True,
                numHybrids = 8))

#         self.add(ldmx.WaveformCaptureReceiver(
#             apvs_per_hybrid = 6,
#             num_hybrids = 8))

        #waveformStream >> self.WaveformCaptureReceiver
            

