import rogue
import rogue.interfaces.memory
import rogue.interfaces.stream
import rogue.hardware.axi

import pyrogue as pr

import ZccmApplication as zCCM
import axi_soc_ultra_plus_core as socCore

rogue.Version.minVersion('6.0.0')

class ZccmRoot(pr.Root):
    def __init__(self,
            ip       = None, # ETH Host Name (or IP address)
            **kwargs):
        super().__init__(**kwargs)

        # Check if running local on SoC
        if ip != None:

            # Check if we can ping the device and TCP socket not open
            socCore.connectionTest(ip)

            # Start a TCP Bridge Client, Connect remote server at 'ethReg' ports 9000 & 9001.
            self.memMap = rogue.interfaces.memory.TcpClient(ip,9000)

            # DMA[lane=0][TDEST=0] = ports 10000 & 10001
            self.tcpStream = rogue.interfaces.stream.TcpClient(ip,10000)

        else:
            # Use the memory map driver
            self.memMap = rogue.hardware.axi.AxiMemMap('/dev/axi_memory_map')

        # Added the devices
        self.add(socCore.AxiSocCore(
            memBase      = self.memMap,
            offset       = 0x04_0000_0000,
            numDmaLanes  = 1,
        ))
        
        self.add(zCCM.Application(
            memBase = self.memMap,
            offset  = 0x04_8000_0000,
            expand  = True,
        ))
