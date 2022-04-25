import hps
import hps.constants
import pyrogue
import rogue
import RceG3

import socket
import ipaddress
import time



class RceRoot(pyrogue.Root):
    def __init__(self, memBase, **kwargs):
        super().__init__(**kwargs)
        print('Building RceRoot')

        self.add(RceG3.RceVersion(memBase=memBase)) # Statically mapped at 0x80000000
        self.add(RceG3.RceEthernet(memBase=memBase, offset=0xB0000000))


class RceTcpServer(object):

    def __init__(self):

        rogue.Logging.setFilter('pyrogue.stream.TcpCore', rogue.Logging.Debug)
        rogue.Logging.setFilter('pyrogue.memory.TcpServer', rogue.Logging.Debug)


        print('Starting RceTcpServer')

        #rogue.Logging.setFilter('pyrogue.stream.TcpCore', rogue.Logging.Debug)

        # Define the memory map
        self.memMap = rogue.hardware.axi.AxiMemMap('/dev/rce_memmap')

        # Memory server on port 9000
        self.memServer = rogue.interfaces.memory.TcpServer('*', hps.constants.RCE_MEM_MAP_PORT)
        pyrogue.busConnect(self.memServer, self.memMap)
        print(f'Opened Memory TcpServer on port {hps.constants.RCE_MEM_MAP_PORT}')

        # Spin up a Root to querry the BSI and set the IP address for firmware
        with RceRoot(memBase=self.memMap) as root:
            # Set the IP address
            buildStamp = root.RceVersion.BuildStamp.get(read=True)
            time.sleep(1)
            imageName = root.RceVersion.ImageName.get(read=True)
            print(f'RCE Firmware: {buildStamp}')
            print(f'image name: {imageName}')

            if imageName == 'DataDpm':
                ipAddress = ipaddress.IPv4Address(socket.gethostbyname(socket.gethostname())).exploded
                root.RceEthernet.IpAddress.set(ipAddress, write=True)
                print(f'RceEthernet.IpAddress: {ipAddress}')

            #self.dpmDataDmaChannel = rogue.hardware.axi.AxiStreamDma('/dev/axi_stream_dma_0', 0, True)

#             self.rssiServer = rogue.protocols.rssi.Server(segSize=1024)
#             self.udpServer = rogue.protocols.udp.Server(hps.constants.DATA_PORT, False)
#             self.rssiPacketizer = rogue.protocols.packetizer.CoreV2(False, False, True)

#             # Connect DMA stream to packetizer
#             self.rssiPacketizer.transport()._setSlave(self.dpmDataDmaChannel)
#             self.dpmDataDmaChannel._setSlave(self.rssiPacketizer.transport())

#             # Connect packetizer to rssi
#             self.udpServer._setSlave(self._rssi.transport())
#             self.rssiServer.transport()._setSlave(self._udp)

#             # Connect rssi to udp
#             self.udpServer._setSlave(self.rssiServer.transport())
#             self.rssiServer.transport()._setSlave(self.rssiServer.application())

            #self.dpmDataTcpServer = rogue.interfaces.stream.TcpServer('*', hps.constants.DATA_PORT)
            #self.dpmDataDebug = rogue.interfaces.stream.Slave()
            #pyrogue.streamConnectBiDir(self.dpmDataDmaChannel, self.dpmDataTcpServer)
            #pyrogue.streamTap(self.dpmDataDmaChannel, self.dpmDataDebug)

        if imageName == 'ControlDpm':

            # FEBs are on DMA
            print('Setting up FEB Stream Servers')

            # Set up SRP streams
            self.febSrpTdests = [i*16 for i in range(12)] #hps.constants.FEB_LINK_MAP]
            self.febSrpServers = [rogue.interfaces.stream.TcpServer('*', port) for port in hps.constants.FEB_SRP_PORTS]
            self.febSrpDmaChannels = [rogue.hardware.axi.AxiStreamDma('/dev/axi_stream_dma_0', dest, True) for dest in self.febSrpTdests]

            self.srpServerDebug = [rogue.interfaces.stream.Slave() for i in range(len(self.febSrpServers))]
            self.srpDmaDebug = [rogue.interfaces.stream.Slave() for i in range(len(self.febSrpDmaChannels))]

            for feb, (server, dma, port, dest, serverDbg, dmaDbg) in enumerate(zip(
                    self.febSrpServers, self.febSrpDmaChannels, hps.constants.FEB_SRP_PORTS, self.febSrpTdests,
                    self.srpServerDebug, self.srpDmaDebug)):
                pyrogue.streamConnectBiDir(server, dma)
                print(f'Opened Stream TcpServer for FEB {feb} SRP at DMA0 DEST {dest:#x} on port {port}')
                #pyrogue.streamTap(server, serverDbg)
                #serverDbg.setDebug(100, f'FEB{feb} Tcp:')
                #pyrogue.streamTap(dma, dmaDbg)
                #dmaDbg.setDebug(100, f'FEB{feb} DMA:')

            # Set up SEM streams
            self.febSemTdests = [(i*16)+1 for i in range(12)]
            #print(f'febSemTdests: {febSemTdests}')
            self.febSemServers = [rogue.interfaces.stream.TcpServer('*', port) for port in hps.constants.FEB_SEM_PORTS]
            self.febSemDmaChannels = [rogue.hardware.axi.AxiStreamDma('/dev/axi_stream_dma_0', dest, True) for dest in self.febSemTdests]

            self.semServerDebug = [rogue.interfaces.stream.Slave() for i in range(len(self.febSemServers))]
            self.semDmaDebug = [rogue.interfaces.stream.Slave() for i in range(len(self.febSemDmaChannels))]

            for feb, (server, dma, port, dest, serverDbg, dmaDbg) in enumerate(zip(
                    self.febSemServers, self.febSemDmaChannels, hps.constants.FEB_SEM_PORTS, self.febSemTdests, self.semServerDebug, self.semDmaDebug)):
                pyrogue.streamConnectBiDir(server, dma)
                print(f'Opened Stream TcpServer for FEB {feb} SEM at DMA0 DEST {dest:#x} on port {port}')
                pyrogue.streamTap(server, serverDbg)
                serverDbg.setDebug(100, f'FEB{feb} Tcp:')
                pyrogue.streamTap(dma, dmaDbg)
                dmaDbg.setDebug(100, f'FEB{feb} DMA:')




            self.loopbackTdests = [(i*16)+3 for i in range(12)]
            self.febLoopbackServers = [rogue.interfaces.stream.TcpServer('*', port) for port in hps.constants.FEB_LOOPBACK_PORTS]
            self.febLoopbackDmaChannels = [rogue.hardware.axi.AxiStreamDma('/dev/axi_stream_dma_0', dest, True) for dest in self.loopbackTdests]

            self.loopbackServerDebug = [rogue.interfaces.stream.Slave() for i in range(len(self.febLoopbackServers))]
            self.loopbackDmaDebug = [rogue.interfaces.stream.Slave() for i in range(len(self.febLoopbackDmaChannels))]

            for feb, (server, dma, port, dest, serverDbg, dmaDbg) in enumerate(zip(
                    self.febLoopbackServers, self.febLoopbackDmaChannels, hps.constants.FEB_LOOPBACK_PORTS, self.loopbackTdests,
                    self.loopbackServerDebug, self.loopbackDmaDebug)):
                pyrogue.streamConnectBiDir(server, dma)
                print(f'Opened Stream TcpServer for FEB {feb} LOOPBACK at DMA0 DEST {dest:x} on port {port}')
                #pyrogue.streamTap(server, serverDbg)
                #serverDbg.setDebug(100, f'Loopback{feb} Tcp:')
                #pyrogue.streamTap(dma, dmaDbg)
                #dmaDbg.setDebug(100, f'Loopback{feb} DMA:')
