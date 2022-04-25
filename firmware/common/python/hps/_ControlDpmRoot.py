import pyrogue
import rogue
import hps

##### This module is way out of date ################

class ControlDpmRoot(pyrogue.Root):
    def __init__(self, hostConfig, bootloader=False, pollEn=False, **kwargs):
        super().__init__(**kwargs)

        febSrps = [rogue.protocols.srp.SrpV3() for x in hostConfig.febLinkMap]
        self.febStreams = [rogue.interfaces.stream.TcpClient(hostConfig.controlDpmHost, hostConfig.controlDpmFebSrpPorts[link]) for link in hostConfig.febLinkMap]
        for srp, stream in zip(febSrps, self.febStreams):
            pyrogue.streamConnectBiDir(srp, stream)

        # Feb Loopback DMA/PGP streams
        febLoopbackStreams = [rogue.interfaces.stream.TcpClient(hostConfig.controlDpmHost, port) for port in hostConfig.controlDpmFebLoopbackPorts]

        # Control DPM Mem access
        controlDpmMem = rogue.interfaces.memory.TcpClient(hostConfig.controlDpmHost, hostConfig.controlDpmMemPort)

        #Add the ControlDpm device
        self.add(hps.ControlDpm(
            memBase = controlDpmMem,
            febMemBases = febSrps,
            loopbackStreams = febLoopbackStreams,
            febLinkMap = hostConfig.febLinkMap,
            bootloader=bootloader))

        # Start
        self.start(pollEn=pollEn)

    def stop(self):
        for s in self.febStreams:
            s.close()
        super().stop()
