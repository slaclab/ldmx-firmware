import pyrogue as pr
import pyrogue.interfaces.simulation

import axipcie

import rogue

import ldmx

class LdmxFebRoot(pr.Root):
    def __init__(self, sim=True, **kwargs):
        super().__init__(pollEn=False, timeout=100000, **kwargs)

        if sim is True:
            # Map fake PCIe space
            SIM_SRP_PORT = 11000            
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', SIM_SRP_PORT)

            srpStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+2)
            dataStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+4)
            waveformStream = rogue.interfaces.stream.TcpClient('localhost', SIM_SRP_PORT+6)

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



        srp = rogue.protocols.srp.SrpV3()

        srpStream == srp

        dataDebug = rogue.interfaces.stream.Slave()
        dataDebug.setDebug(100, "EventStream")
        dataStream >> dataDebug

        self.addInterface(self.memMap, srpStream, dataStream, srp)

        # Zmq Server
        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
        self.addInterface(self.zmqServer)

        self.add(axipcie.AxiPcieCore(
            offset = 0x0,
            memBase = self.memMap,
            numDmaLanes = 1,
            expand = True,
            sim = sim))        

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
            

