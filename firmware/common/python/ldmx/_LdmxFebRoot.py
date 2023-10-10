import pyrogue as pr
import pyrogue.interfaces.simulation

import rogue

import ldmx

class LdmxFebRoot(pr.Root):
    def __init__(self, **kwargs):
        super().__init__(dev, sim, pollEn=False, timeout=1000, **kwargs)

        if sim is True:
            SIM_SRP_PORT = 9000

            srpStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT)
            dataStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+2)
            waveformStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+4)
#          sideband = pyrogue.interfaces.simulation.SideBandSim('localhost', SIM_SRP_PORT+8)
        else:
            # Map PCIe Core
            pcieMap = rogue.hardware.axi.AxiMemMap(dev)
            self.addInterface(pcieMap)
            self.add(pcie.AxiPcieCore(
                offset      = 0x00000000,
                memBase     = pcieMap,
                numDmaLanes = numLanes,
                expand      = True,
            ))
            
            srpStream = 


        srp = rogue.protocols.srp.SrpV3()

        srpStream == srp

        dataDebug = rogue.interfaces.stream.Slave()
        dataDebug.setDebug(100, "EventStream")
        dataStream >> dataDebug

        self.addInterface(srpStream, dataStream, srp)

        # Zmq Server
        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
        self.addInterface(self.zmqServer)
        

        self.add(ldmx.LdmxFeb(
            memBase = srp,
            number = 0,
            sim = True,
            expand = True,
            numHybrids = 8))

        self.add(ldmx.WaveformCaptureReceiver(
            apvs_per_hybrid = 6,
            num_hybrids = 8))

        waveformStream >> self.WaveformCaptureReceiver
            

