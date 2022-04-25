import threading
import time
import datetime
import parse
import subprocess
import os

import hps

import pyrogue
#import pyrogue.interfaces.simulation as pis
import pyrogue.utilities.fileio
import pyrogue.utilities.prbs
import pyrogue.protocols
import pyrogue.protocols.epics
import pyrogue.gui

import rogue

class CfgDebug(rogue.interfaces.stream.Slave):
    def __init__(self):
        rogue.interfaces.stream.Slave.__init__(self)

    def _acceptFrame(self, frame):
        ba = bytearray(frame.getPayload())
        frame.read(ba, 0)
        yaml = bytearray(ba).rstrip(bytearray(1)).decode('utf-8')
        print(yaml)
        print('------------------')

class SemDebug(rogue.interfaces.stream.Slave, rogue.interfaces.stream.Master):
    def __init__(self, name):
        rogue.interfaces.stream.Slave.__init__(self)
        rogue.interfaces.stream.Master.__init__(self)
        self.name = name


    def _acceptFrame(self, frame):
        # Add feb number to the message
        ba = bytearray(frame.getPayload())
        frame.read(ba, 0)
        s = ba.rstrip(bytearray(1))
        s = s.decode('utf8')
        s = f'{self.name}: {s}'

        # write new string back out
        ba = bytearray(s, 'utf8')
        frame = self._reqFrame(len(ba)+1, True)
        frame.write(ba, 0)
        self._sendFrame(frame)

class AsciiFileWriter(rogue.interfaces.stream.Slave):
    def __init__(self):
        rogue.interfaces.stream.Slave.__init__(self)

        now = datetime.datetime.now()
        cpath = os.path.dirname(os.path.abspath(__file__))
        print(cpath)
        fpath = os.path.abspath(now.strftime(f'{cpath}/../../seu/SEU_Monitor-%Y%m%d_%H%M%S.dat'))
        print(f'fpath: {fpath}')
        if (not os.path.exists(f'{cpath}/../../seu/')):
            print("Create directory", f'{cpath}/../../seu/')
            os.mkdir(f'{cpath}/../../seu/')

        self.dataFile = open(fpath, 'a')
        self.lock = threading.Lock()

    def close(self):
        self.dataFile.close()

    def _acceptFrame(self, frame):
        with self.lock:
            ba = bytearray(frame.getPayload())
            frame.read(ba, 0)
            s = ba.rstrip(bytearray(1))
            s = s.decode('utf8')
            s = f'{datetime.datetime.now()} - {s}'
            print('SEU:', s)
            self.dataFile.write(s)



class HpsSvtDaqRoot(pyrogue.Root):
    def __init__(self, *,
                 hostConfig,
                 extDataHandler=False,
                 sim=False,
                 pollEn=False,
                 epicsEn=False,
                 timeout=1.0,
                 **kwargs):
        super().__init__(pollEn=pollEn, timeout=timeout, **kwargs)

        self.hostConfig = hostConfig

        ###############################################
        # Run info and configuration
        ###############################################
        self.add(pyrogue.LocalVariable(
            name = 'RunNumber',
            value = ''))

        self.add(pyrogue.LocalVariable(
            name = 'DumpConfig',
            value = False))

        ############################################
        # Software version reporting
        ############################################
        self.add(pyrogue.LocalVariable(
            name = 'GitVersion',
            mode = 'RO',
            value = '',
            localGet = lambda: str(subprocess.check_output(['git', 'describe']).strip(), 'utf-8')))

        self.add(pyrogue.LocalVariable(
            name = 'LibRogueVersion',
            value = pyrogue.__version__))

        # These are set bt rogue_coda
        self.add(pyrogue.LocalVariable(
            name = 'RogueCodaVersion',
            value = ''))

        self.add(pyrogue.LocalVariable(
            name = 'LibRogueLiteVersion',
            value = ''))

        #########################################
        # Calibration Configuration
        ########################################
        self._calGen = None

        self.add(pyrogue.LocalVariable(
            name = 'CalibrationMode',
            description = 'Enable or disable calibration mode',
            hidden = True,
            value = False))

        self.add(pyrogue.LocalVariable(
            name = 'CalibrationDelaySweep',
            description = 'Sweep through the 8 CSEL values on the APVs',
            hidden = True,
            value = False))

        self.add(pyrogue.LocalVariable(
            name = 'CalibrationLevelSweep',
            description = 'A list of the [start, stop, step] of ICAL injections to sweep through',
            hidden = True,
            value = [0]))

        self.add(pyrogue.LocalVariable(
            name = 'CalibrationGroups',
            description = 'APV calibration groups to sweep through',
            hidden = True,
            value = [0, 1, 2, 3, 4, 5, 6, 7]))

        self.add(pyrogue.LocalVariable(
            name = 'CalibrationSampleCount',
            description = 'Number of events to take at each calibration point',
            hidden = True,
            value = 1))

        self.add(pyrogue.LocalVariable(
            name = 'DpmCalibrationFilterEn',
            value = True))

        self.add(pyrogue.LocalVariable(
            name = 'doBaseline',
            value = False,
            hidden = False))



        ########################
        # Control DPM
        ########################
        # Control DPM Mem access
        controlDpmMem = [rogue.interfaces.memory.TcpClient(host, hostConfig.controlDpmMemPort) for host in hostConfig.controlDpmHost]
        self.addInterface(controlDpmMem)

        # ControlDpm
        # Includes Febs
        for i, mem in enumerate(controlDpmMem):
            self.add(hps.ControlDpm(
                name = f'ControlDpm[{i}]',
                sim=sim,
                expand = False,
                memBase = mem))

#         self.add(pyrogue.ArrayDevice(
#             name='LinkStatus',
#             arrayClass=pyrogue.LinkVariable,
#             number=24,
#             arrayArgs=[
#                 {'name': f'Link[{i}][{j}]',
#                  'mode': 'RO',
#                  'variable': self.ControlDpm[i].PgpStatus.Pgp2bAxi[j].RxRemLinkReady}
#                 for i in range(2) for j in range(12)]))


        #########################
        # FEBS
        ########################
        #Feb SRP DMA PGP streams
        febSrps = [rogue.protocols.srp.SrpV3() for x in hostConfig.febLinkMap]
        febStreams = [rogue.interfaces.stream.TcpClient(hostConfig.controlDpmHost[link[0]], hostConfig.controlDpmFebSrpPorts[link[1]]) for link in hostConfig.febLinkMap]
        self.addInterface(febSrps, febStreams)
        for srp, stream in zip(febSrps, febStreams):
            srp == stream

        # SEM monitor streams
        febSemDataWriter = AsciiFileWriter()
        febSemStreams = [rogue.interfaces.stream.TcpClient(hostConfig.controlDpmHost[link[0]], hostConfig.controlDpmFebSemPorts[link[1]]) for link in hostConfig.febLinkMap]
        febSemDebugs = [SemDebug(f'FEB{i}') for i in range(len(hostConfig.febLinkMap))]
        self.addInterface(febSemDataWriter, febSemStreams, febSemDebugs)
        for i, (stream, debug) in enumerate(zip(febSemStreams, febSemDebugs)):
            stream >> debug
            debug >> febSemDataWriter #self.febSemDataWriter.getChannel(i))


        # Feb Loopback DMA/PGP streams
        febLoopbackStreams = [rogue.interfaces.stream.TcpClient(hostConfig.controlDpmHost[0], hostConfig.controlDpmFebLoopbackPorts[link[1]]) for link in hostConfig.febLinkMap]
        self.addInterface(febLoopbackStreams)

        self.add(pyrogue.ArrayDevice(
            name='FebLinkStatus',
            expand=True,
            arrayClass=pyrogue.LinkVariable,
            number=len(hostConfig.febLinkMap),
            arrayArgs= [
                {'name': f'Link[{i}]',
                 'mode': 'RO',
                 'variable' : self.ControlDpm[link[0]].PgpStatus.Pgp2bAxi[link[1]].RxRemLinkReady}
                for i, link in enumerate(hostConfig.febLinkMap)]))

        if epicsEn is True:
            print("WARNING:: FebPowerStatus monitoring is disabled. Please check _FebStatus.py")
            #self.add(hps.FebPowerStatus())


        #if bootloader:
        #    febClass = hps.FebBootloaderFpga
        #else:
        #    febClass = hps.FebFpga

        self.add(pyrogue.ArrayDevice(
            name='FebArray',
            expand=True,
            arrayClass=hps.FebFpga,
            number=len(hostConfig.febLinkMap),
            arrayArgs = [
                {'number' : i,
                 'memBase': febSrps[i],
                 'expand': False,
                 'enabled': True,
                 'enableDeps': [self.ControlDpm[link[0]].PgpStatus.Pgp2bAxi[link[1]].RxRemLinkReady]}
                for i, link in enumerate(hostConfig.febLinkMap)]))


        def setAllHybridPwr(value, write):
            for feb in self.FebArray.FebFpga.values():
                feb.FebCore.FebConfig.HybridPwrAll.set(value, write=write)

        def getAllHybridPwr(read):
            for feb in self.FebArray.FebFpga.values():
                for hyPwr in feb.FebCore.FebConfig.HybridPwrEn.values():
                    if hyPwr.get(read=read) == 0:
                        return 0
            return 1

        self.add(pyrogue.LinkVariable(
            name = 'GlobalHybridPwrSwich',
            hidden = False,
            enum = {0: 'Off', 1: 'On'},
            dependencies = [hyPwr for feb in self.FebArray.FebFpga.values() for hyPwr in feb.FebCore.FebConfig.HybridPwrEn.values()],
            linkedSet = setAllHybridPwr,
            linkedGet = getAllHybridPwr))

        @self.command()
        def ReloadAllFebFpgas():
            print('Reloading all FEBs')
            self.GlobalHybridPwrSwich.set(0)
            print('Hybrids are off')
            self.PollEn.set(False)
            print('Polling disabled')
            time.sleep(5)
            for i, feb in self.FebArray.FebFpga.items():
                print(f'Reloading FPGA {i}')
                feb.AxiVersion.FpgaReload()

            print('Waiting for reload')
            time.sleep(14)
            for i, feb in self.FebArray.FebFpga.items():
                print(f'Re-establishing contact with FEB {i}')
                self.readBlocks()
                self.checkBlocks()
                print(f'Initial config of FEB {i}')
                feb.FebCore.FebConfig.FebAddress.set(i)
                feb.FebCore.ConfigureLtc2991()
                print(f'Done with FEB {i}')

            self.PollEn.set(True)
            print('Done reloading FEBs')

#        self.add(FebLoopbackArray(
#            name='LoopbackTest',
#            expand=False,
#            streams=loopbackStreams))


        ##########################
        # Data DPMs
        ##########################
        dataDpmMems = [rogue.interfaces.memory.TcpClient(host, hostConfig.dataDpmMemPort) for host in hostConfig.dataDpmHosts]
        self.addInterface(dataDpmMems)

        self.add(hps.DataDpmArray(
            expand=True,
            memBases = dataDpmMems,
            sim = sim))

        ##########################
        # DAQ Map
        ##########################
        self.add(hps.DaqMap(
            febs = self.FebArray.FebFpga,
            dataDpms = self.DataDpmArray.DataDpm,
            expand = False))


        ##########################
        # DTMs
        ##########################
        dtmMems = [rogue.interfaces.memory.TcpClient(host, hostConfig.dtmMemPort) for host in hostConfig.dtmHosts]
        self.addInterface(dtmMems)

        self.add(hps.PcieTiDtmArray(
            expand=True,
            sim=sim,
            memBases = dtmMems,
            enabled = True))



        if extDataHandler is False:
            ############################################
            # Data Writer
            ###########################################
            dataWriter = hps.HpsSvtDataWriter(name='DataWriter')

            # Config on channel 0
            self >> dataWriter.getConfigChannel()
            #        cfgDebug = CfgDebug()
            #        pyrogue.streamTap(self, cfgDebug)

            # # Event data streams arrive over RSSI from each DataDpm
            if sim is False:
                dataDpmEventStreams = [pyrogue.protocols.UdpRssiPack(host=host, port=hps.constants.DATA_PORT, packVer=2, name=host) for host in hostConfig.dataDpmHosts]
                #self.add(dataDpmEventStreams)
                dataDpmEventDests0 = [rssi.application(dest=0) for rssi in dataDpmEventStreams]
            else:
                # RTL Sim uses TCP streams for data
                dataDpmEventStreams = [rogue.interfaces.stream.TcpClient(host, hostConfig.dataDpmDmaPort) for host in hostConfig.dataDpmHosts]
                dataDpmEventDests0 = dataDpmEventStreams

            unbatchers = [rogue.protocols.batcher.SplitterV1() for host in hostConfig.dataDpmHosts]
            fakes = [rogue.interfaces.stream.Master() for host in hostConfig.dataDpmHosts]
            self.addInterface(dataDpmEventStreams, unbatchers, fakes)

            debugs = [rogue.interfaces.stream.Slave() for host in hostConfig.dataDpmHosts]
            debugs2 = [rogue.interfaces.stream.Slave() for host in hostConfig.dataDpmHosts]
            for i, (stream, unbatcher, fake, debug, debug2) in enumerate(zip(dataDpmEventDests0, unbatchers, fakes, debugs, debugs2)):
                print(f'Connecting DPM {i}')
                stream >> unbatcher
                #debug2.setDebug(2, f'RSSI {i} debug')
                #pyrogue.streamTap(stream, debug2)
                unbatcher >> dataWriter.getEventChannel(i)
                #pyrogue.streamConnect(fake, stream)
                #debug.setDebug(2, f'unBatcher {i} Debug')
                #pyrogue.streamTap(unbatcher, debug)


            @self.command()
            def FakeDma():
                for i, fake in enumerate(fakes):
                    frame = fake._reqFrame(100, True)
                    ba = bytearray((i for i in range(10)))
                    self._log.debug(f"Sending frame {ba} to DataDpm[{i}]")
                    frame.write(ba, 0)
                    fake._sendFrame(frame)

            # SEM streams arrive via Tcp from the ControlDpm
            #         febSemStreams = [rogue.interfaces.stream.TcpClient(CONTROL_DPM_HOST, port) for port in FEB_SEM_PORTS]
            #         for i, stream in enumerate(febSemStreams):
            #             pyrogue.streamConnect(stream, dataWriter.getSemChannel(i))
            #             dbg = rogue.interfaces.stream.Slave()
            #             dbg.setDebug(100, 'SEM {i} Debug')
            #             pyrogue.streamTap(stream, dbg)

            self.add(dataWriter)
            self.add(HpsSvtRunControl())

        self.add(pyrogue.LocalVariable(
            name = 'StackedTriggers',
            value = 1,
            minimum = 1,
            maximum = 5))

        @self.command()
        def Trigger():
            self.PcieTiDtmArray.Trigger()
            #self.FakeDma()

        @self.command()
        def MultiTrigger(arg):
            for i in range(arg):
                self.PcieTiDtmArray.Trigger()

        @self.command(value='')
        def LoadApvThresholds(arg):
            self.DataDpmArray.ReadDevice(True)

            with open(arg) as f:
                for line in f:
                    split = line.split()
                    feb, hybrid, apv = (int(split[x]) for x in range(3))
                    values = [int(x, 16) for x in split[3:131]]
                    dpmPath = self.DaqMap.node(f'Feb[{feb}]Hybrid[{hybrid}]').value()
                    print(f'Loading thresholds for Feb[{feb}]Hybrid[{hybrid}]Apv[{apv}] - dpmPath: {dpmPath}')
                    if dpmPath != 'NotFound':
                        dpm,path = parse.parse('DataDpm[{:d}]Path[{:d}]', dpmPath)
                        threshDev = self.DataDpmArray.DataDpm[dpm].RceCore.DataPath[path].ApvThresholds[apv]
                        threshDev.set(offset=0, values=values, write=True)
                    else:
                        print(f'No data path found in daq map for feb {feb}, hybrid {hybrid}')
            return True

        @self.command()
        def ReportApvSyncStatus():
            for f, feb in self.FebArray.FebFpga.items():
                if feb.enable.valueDisp() != "True":
                    print(f'FEB {f}: Disabled')
                else:
                    print(f'FEB {f}:')
                    apvEn = feb.FebCore.FebConfig.ApvDataStreamEn.get(read=True)
                    hyPwr = [feb.FebCore.FebConfig.HybridPwrEn[x].get() for x in range(4)]
                    hyApvEn = [(apvEn >> (5*x))&0x1F if pwr else 0 for x, pwr in enumerate(hyPwr)]
                    print('  Enabled APVs: ', ' '.join([f'{x:02x}' for x in reversed(hyApvEn)]))
                    syncStatus = [hss.SyncDetected.get(read=True) for hss in feb.FebCore.HybridSyncStatus.values()]
                    print('  Synced APVs: ', ' '.join([f'{x:02x}' for x in reversed(syncStatus)]))

        @self.command()
        def ReportLinkErrors():
            varList = [
                'RxRemLinkReadyCount',
                'RxLinkErrorCount',
                'RxFrameErrorCount',
                'RxCellErrorCount',
                'RxLinkDownCount',
                'BurnCount']

            for name in varList:
                for v in self.find(name=name):
                    value = v.get()
                    if value != 0:
                        print(v.path, v.getDisp())


        @self.command(value=False)
        def SetThresholdCutEn(arg):
            for dpm in self.DataDpmArray.DataDpm.values():
                dpm.RceCore.ThresholdCutEn.set(arg)

        self.add(pyrogue.LocalCommand(
            name = 'UpdateCalibration',
            value = '',
            function = self._updateCalibration))

        self.epicsEn = epicsEn


    def start(self):
        super().start()

        if self.epicsEn is True:
            pvMap = hps.createPvMap('SVT', self)
            self.epics = pyrogue.protocols.epics.EpicsCaServer(base='SVT', root=self, pvMap=pvMap)
            self.epics.start()
            #self.epics.dump()


#    def stop(self):
#        self.febSemDataWriter.close()

#        for i, s in enumerate(self.febStreams):
#             print(f'Stopping FEB Stream {i}')
#             s.close()
#         # for s in self.febLoopbackStreams:
#         #     s.close()
#         for i, s in enumerate(self.controlDpmMem):
#             print(f'Stoping ControlDpm[{i}] TCP Client')
#             s.close()
#         for i, s in enumerate(self.dataDpmMems):
#             print(f'Stoping DataDpm[{i}] TCP Client')
#             s.close()
#         for i, s in enumerate(self.dtmMems):
#             print(f'Stoping DTM[{i}] TCP Client')
#             s.close()
#         if hasattr(self, 'dataDpmEventStreams'):
#             for i, s in enumerate(self.dataDpmEventStreams):
#                 if isinstance(s, pyrogue.protocols.UdpRssiPack):
#                     print(f'Stoping DataDpm[{i}] RSSI')
#                     s._stop()
#                 else: # TcpClient
#                     print(f'Stoping DataDpm[{i}] TCP Data stream')
#                     s.close()

#         print('Done closing streams')
#         super().stop()

#    def _loadConfig(self, arg):
        #self._pollQueue.stop()
#        super()._loadConfig(arg)
        #self._pollQueue._start()


    def setCalibrationMode(self, value):
        for feb in self.FebArray.FebFpga.values():
            feb.FebCore.FebConfig.CalEn.set(value, write=True)
            for hybrid in feb.FebCore.Hybrid.values():
                for apv in hybrid.Apv25.values():
                    apv.CalibrationInhibit.set(not value, write=True)

#    def setCalibrationMode(self, value):
#        for feb in self.FebArray.FebFpga.values():
#            feb.FebCore.FebConfig.CalEn.set(value, write=False)
#            for hybrid in feb.FebCore.Hybrid.values():
#                for apv in hybrid.Apv25.values():
#                    apv.CalibrationInhibit.set(not value, write=False)
#        self.writeAndVerifyBlocks()

    def setCalibrationGroup(self, value):
        value = hps.Apv25.CALGROUP_REV_ENUM[value]
        for apv in self._allApvs():
            apv.CalGroup.set(value, write=True)

    def setCalibrationDelay(self, value):
        for apv in self._allApvs():
            apv.Csel.set(value, write=True)

    def setCalibrationLevel(self, value):
        for apv in self._allApvs():
            apv.Ical.set(value, write=True)

    def _allHybrids(self):
        """Get an iterator of all the Hybrid Devices"""
        for feb in self.FebArray.FebFpga.values():
            for hybrid in feb.FebCore.Hybrid.values():
                yield hybrid

    def _allApvs(self):
        """Get an iterator of all the APVs"""
        for hybrid in self._allHybrids():
            for apv in hybrid.Apv25.values():
                yield apv

    def _updateCalibration(self):
        if self._calGen is None:
            self._calGen = self._updateCalibrationGen()

        ret = next(self._calGen)

        if ret == 'Done':
            self._calGen = None
        return ret

    def _updateCalibrationGen(self):
        # Put firmware in calibration mode
        self.setCalibrationMode(True)
        self.DataDpmArray.setCalibrationMode(self.DpmCalibrationFilterEn.value())

        cfgChanged = False

        calLevels = list(range(*self.CalibrationLevelSweep.value()))
        if len(calLevels) == 0:
            calLevels = [0x1d]

        calDelays = hps.Apv25.CSEL_ENUM if self.CalibrationDelaySweep.value() else {0b11111110: 'Dly_1x3_125ns'}
        if 0 in calDelays:
            calDelays.pop(0) # Pop the invalid enum

        for calgroup in self.CalibrationGroups.value():
            print(f'Setting Calibration Group: {calgroup}')
            self.setCalibrationGroup(calgroup)
            self.DataDpmArray.setCalibrationGroup(calgroup)
            cfgChanged = True

            for ical in calLevels:
                print(f'Setting ICAL: {ical}')
                self.setCalibrationLevel(ical)
                cfgChanged = True
                for k, v in calDelays.items():
                    print(f'Setting CSEL: {v}')
                    self.setCalibrationDelay(k)
                    cfgChanged = True
                    for count in range(self.CalibrationSampleCount.value()):
                        yield 'Config' if cfgChanged else 'Sample'
                        cfgChanged = False
        yield 'Done'

class HpsSvtDataWriter(pyrogue.utilities.fileio.StreamWriter):

    CONFIG_CHANNEL = 0
    EVENT_CHANNELS = [0x10+i for i in range(16)]
#    SEM_CHANNELS = [0x20+i for i in range(10)]

    def __init__(self, **kwargs):
        super().__init__(configEn=True, **kwargs)

        #self.configChannel = self.getChannel(CONFIG_CHANNEL)
        #self.eventChannels = [self.getChannel(ch) for ch in EVENT_CHANNELS]
        #self.semChannels = [self.getChannel(ch) for ch in SEM_CHANNELS]

    def getConfigChannel(self):
        return self.getChannel(self.CONFIG_CHANNEL)

    def getEventChannel(self, channel):
        return self.getChannel(self.EVENT_CHANNELS[channel])

#    def getSemChannel(self, channel):
#        return self.getChannel(self.SEM_CHANNELS[channel])

    def resetChannels(self):
        for channel in self.EVENT_CHANNELS:
            self.getChannel(channel).setFrameCount(0)

class HpsSvtRunControl(pyrogue.RunControl):
    def __init__(self, **kwargs):
        rates = {1:'1 Hz', 10:'10 Hz', 30:'30 Hz', 50: '50 Hz', 100: '100 Hz', 0:'Auto'}
        states = {0: 'Stopped', 1: 'Running', 2: 'Calibration'}
        pyrogue.RunControl.__init__(self, name='RunControl', rates=rates, states=states, **kwargs)

        self.add(pyrogue.LocalVariable(
            name = 'MaxRunCount',
            value = 2**31-1))

    def _setRunState(self,value,changed):
        """
        Set run state. Reimplement in sub-class.
        Enum of run states can also be overriden.
        Underlying run control must update runCount variable.
        """
        if changed:
            # First stop old threads to avoid overlapping runs
            # but not if we are calling from the running thread
            if self._thread is not None and self._thread != threading.current_thread():
                self._thread.join()
                self.thread = None
                #self.root.ReadAll()

            if self.runState.valueDisp() == 'Running':
                #print("Starting run")
                self._thread = threading.Thread(target=self._run)
                self._thread.start()
            elif self.runState.valueDisp() == 'Calibration':
                self._thread = threading.Thread(target=self._calibrate)
                self._thread.start()

    def waitStopped(self):
        self._thread.join()

    def __prestart(self):
        print("Run prestart: Reading state")
        self.root.ReadAll()

        for feb in self.root.FebArray.FebFpga.values():
            feb.FebCore.FebConfig.AllowResync.set(True)

        # make sure FEB APV clocks are aligned
        print("Run prestart: ClkAlign")
        self.root.PcieTiDtmArray.ApvClkAlign()
        time.sleep(1)

        # Soft reset the APVs
        print("Run Prestart: Reset101")

        self.root.PcieTiDtmArray.ApvReset101()
        time.sleep(1)

        print("Run Prestart: Reset Data Pipelines")
        self.root.DataDpmArray.ResetDataPipelines()
        time.sleep(1)

        self.root.CountReset()


        for feb in self.root.FebArray.FebFpga.values():
            feb.FebCore.FebConfig.AllowResync.set(False)

        self.root.ReportApvSyncStatus()
        time.sleep(.1)

        self.root.PcieTiDtmArray.RunStart()

        time.sleep(.1)

        self.runCount.set(0)
        self.root.DataWriter.resetChannels()

    def __triggerAndWait(self):
        time.sleep(.1)
        triggers = self.root.StackedTriggers.value()
        self.root.MultiTrigger(triggers)
        print(f'Sending trigger number {self.runCount.value()}')
        #print(f'TxCount0: {self.root.PcieTiDtm[1].DtmTiming.TxCount0.get(read=True)}')

        if self.runRate.valueDisp() == 'Auto':
            # Wait for all DataDpms to respond before issuing next trigger
            for i, host in enumerate(self.root.hostConfig.dataDpmHosts):
                good = self.root.DataWriter.getEventChannel(i).waitFrameCount(self.runCount.value()+triggers, 200000)
                if good is False:
                    print(f'Timed out waiting for data from channel host {host}')
        else:
            delay = 1.0 / self.runRate.value()
            time.sleep(delay)

        self.runCount += triggers


    def _run(self):
        self.__prestart()

        while (self.runState.valueDisp() == 'Running' and self.runCount.value() < self.MaxRunCount.value()):
            self.__triggerAndWait()

        #time.sleep(1.0)

        #print("Reading status at end of run")
        #self.root.ReadAll()

        #print("Checking Sync status at end of run")
        #for f, feb in self.root.FebArray.FebFpga.items():
        #    if feb.enable.valueDisp() != "True":
        #        print(f'FEB {f}: Disabled')
        #    else:
        #        print(f'FEB {f}:')
        #        apvEn = feb.FebCore.FebConfig.ApvDataStreamEn.get(read=True)
        #        hyPwr = [feb.FebCore.FebConfig.HybridPwrEn[x].get() for x in range(4)]
        #        hyApvEn = [(apvEn >> (5*x))&0x1F if pwr else 0 for x, pwr in enumerate(hyPwr)]
        #        print('  Enabled APVs: ', ' '.join([f'{x:02x}' for x in reversed(hyApvEn)]))
        #        syncStatus = [hss.SyncDetected.get(read=True) for hss in feb.FebCore.HybridSyncStatus.values()]
        #        print('  Synced APVs: ', ' '.join([f'{x:02x}' for x in reversed(syncStatus)]))

        #print("Checking for link errors at end of run")
        #varList = [
        #    'RxRemLinkReadyCount',
        #    'RxLinkErrorCount',
        #    'RxFrameErrorCount',
        #    'RxCellErrorCount',
        #    'RxLinkDownCount',
        #    'BurnCount']

        #for name in varList:
        #    for v in self.root.find(name=name):
        #        value = v.get()
        #        if value != 0:
        #            print(v.path, v.getDisp())

    def _calibrate(self):

        self.__prestart()
        controlDpm = self.root.ControlDpm
        dataDpmArray = self.root.DataDpmArray

        # Calibrations need just 1 subframe per batch
        dataDpmArray.setMaxBatchFrames(1)
        self.runRate.setDisp('Auto')

        if (self.root.doBaseline.value()):
            # First do normal baseline
            print("Running baseline")
            controlDpm.setCalibrationMode(False)
            dataDpmArray.setCalibrationMode(False)
            for event in range(self.root.CalibrationSampleCount.value()):
                if self.runState.valueDisp() != 'Calibration':
                    return
                self.__triggerAndWait()
        # Then do calibration
        # Loop over cal groups, icals, csels and calCount
        print("Running Injection")

        #Put firmware in calibration mode
        self.root.setCalibrationMode(True)
        self.root.DataDpmArray.setCalibrationMode(self.root.DpmCalibrationFilterEn.value())

        calLevels = list(range(*self.root.CalibrationLevelSweep.value()))
        if len(calLevels) == 0:
            calLevels = [0x1d]

        calDelays = hps.Apv25.CSEL_ENUM if self.root.CalibrationDelaySweep.value() else {0b11111110: 'Dly_1x3_125ns'}
        if 0 in calDelays:
            calDelays.pop(0) # Pop the invalid enum

        print("calDelays",calDelays)

        for calgroup in self.root.CalibrationGroups.value(): #groups loop
            print(f'Setting Calibration Group: {calgroup}')
            self.root.setCalibrationGroup(calgroup)
            self.root.DataDpmArray.setCalibrationGroup(calgroup)

            for ical in calLevels:                           #ical loop
                print(f'Setting ICAL: {ical}')
                self.root.setCalibrationLevel(ical)
                for k,v in calDelays.items():                #cal delays loop
                    print(f'Setting CSEL: {v}')
                    self.root.setCalibrationDelay(k)
                    for count in range(self.root.CalibrationSampleCount.value()):
                        if self.runState.valueDisp() != 'Calibration':
                            return
                        self.__triggerAndWait()


        self.runState.setDisp('Stopped')
        print('Calibration Done')
