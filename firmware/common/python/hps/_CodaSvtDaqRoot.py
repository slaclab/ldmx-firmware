import pyrogue

import time
import datetime
import hps
import os

class CodaSvtDaqRoot(hps.HpsSvtDaqRoot):
    def __init__(self, pollEn, name='HpsSvtDaqRoot', **kwargs):
        super().__init__(name=name, extDataHandler=True, **kwargs)

        self.add(pyrogue.LocalCommand(name='CodaInit', value='', function=self._codaInit,
                                 description='CODA Init'))

        self.add(pyrogue.LocalCommand(name='CodaDownload', value='', function=self._codaDownload,
                                 description='CODA Download State'))

        self.add(pyrogue.LocalCommand(name='CodaPrestart', function=self._codaPrestart,
                                 description='CODA Prestart State'))

        self.add(pyrogue.LocalCommand(name='CodaGo', function=self._codaGo,
                                 description='CODA Go State'))

        self.add(pyrogue.LocalCommand(name='CodaEnd', function=self._codaEnd,
                                 description='CODA End State'))

        self.add(pyrogue.LocalVariable(name='SvtConfigFile', value='', mode='RW',
            description='String containing SVT Configuration File Path'))

        self.add(pyrogue.LocalVariable(name='SvtThresholdFile', value='', mode='RW',
            description='String containing SVT Threshold File Path'))

        self.add(pyrogue.LocalVariable(name='SvtEbConfigFile', value='', mode='RW',
            description='String containing SVT Event Builder Config File Path'))

        self.add(pyrogue.LocalVariable(name='CodaState', value='None', mode='RW',
            description='Current Coda State'))

        self.add(pyrogue.LocalVariable(name='CodaStateTime', value='', mode='RW',
            description='Last Coda State Change Timestamp'))

        # Coda verision always starts with polling, zmqServer and epics
        #self.start(pollEn=pollEn, zmqPort=9099, epicsEn=True)

    def _codaInit(self, arg):
        # Need to use local clock until the end of download as TI clock is unstable during this time
        #self.PcieTiDtm.JLabTimingPcie.Mode.setDisp('LocalClk')
        print('Rogue Coda Init Called')
        self.PcieTiDtmArray.PcieTiDtm[0].JLabTimingPcie.CodaState.setDisp('INIT')
        self.PcieTiDtmArray.PcieTiDtm[1].JLabTimingPcie.CodaState.setDisp('INIT')
        return "OK"

    def _codaDownload(self, arg):
        print("Rogue Coda Download Called")

        # Extract RCE specific configuration lines
        try:
            with open(arg,'r') as f:
                inRce = False
                self.SvtThresholdFile.set('')
                self.SvtConfigFile.set('')
                self.SvtEbConfigFile.set('')

                for line in f.readlines():
                    if line.strip() == "RCE_CRATE all":
                        inRce = True
                    elif line.strip() == "RCE_CRATE end":
                        inRce = False
                    elif inRce:
                        fields = line.split()
                        if fields[0] == "RCE_THR_CONFIG_FILE":
                            print(f'_codaDownload found threshold file: {fields[1]}')
                            self.SvtThresholdFile.set(fields[1])
                        elif fields[0] == "RCE_CONFIG_FILE":
                            self.SvtConfigFile.set(fields[1])
                        elif fields[0] == "RCE_EB_0_CONFIG_FILE":
                            self.SvtEbConfigFile.set(fields[1])

        except Exception as e:
            return str(e)

        print("Threshold File: {}".format(self.SvtThresholdFile.value()))
        print("Config File: {}".format(self.SvtConfigFile.value()))
        print("EB Config File: {}".format(self.SvtEbConfigFile.value()))
        print("SVT Calibration Run: {}".format(self.CalibrationMode.value()))
        self.CodaState.set('Download')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))
        #self.PcieTiDtm.JLabTimingPcie.Mode.setDisp('TiClk')
        self.PcieTiDtmArray.PcieTiDtm[0].JLabTimingPcie.CodaState.setDisp('DOWNLOAD')
        self.PcieTiDtmArray.PcieTiDtm[1].JLabTimingPcie.CodaState.setDisp('DOWNLOAD')
        print("Rogue Coda Download Done")
        return "OK"

    def _codaPrestart(self):
        print("Rogue Coda Prestart Called")

        # Allow APV reset until run start
        for feb in self.FebArray.FebFpga.values():
            feb.FebCore.FebConfig.AllowResync.set(True)

        time.sleep(.5)

        # Send feb align commands
        #for dtm in self.PcieTiDtmArray.PcieTiDtm.values():
        #    dtm.JLabTimingPcie.ApvClkAlign()

        #time.sleep(1)

        #self.PcieTiDtm.JLabTimingPcie.Mode.setDisp('LocalClk')

        # Load configuration if it is available
        if self.SvtConfigFile.value() != '':
            print(f"Loading configuration file: {self.SvtConfigFile.value()}")
            if not self.LoadConfig(self.SvtConfigFile.value()):
                return f"Failed to load config file: {self.SvtConfigFile.value()}"

        time.sleep(.5)
        # Load threshold file if it is available
        if self.SvtThresholdFile.value() != '':
            print(f"Loading thresholds file: {self.SvtThresholdFile.value()}")
            if not self.LoadApvThresholds(self.SvtThresholdFile.value()):
                return "Failed to load threshold: " + self.SvtThresholdFile.value()

            self.SetThresholdCutEn(True)
        else:
            self.SetThresholdCutEn(False)

        time.sleep(0.5)

        # Send feb align commands
        for dtm in self.PcieTiDtmArray.PcieTiDtm.values():
            dtm.JLabTimingPcie.ApvClkAlign()

        time.sleep(1)

        # Once config is loaded, send reset101 to APVs
        print('Sending Reset101')
        for dtm in self.PcieTiDtmArray.PcieTiDtm.values():
            dtm.JLabTimingPcie.ApvReset101()

        time.sleep(.2)

        # Disable resync once config is done
        for feb in self.FebArray.FebFpga.values():
            feb.FebCore.FebConfig.AllowResync.set(False)

        print('Resetting DPM Data Pipelines')
        self.DataDpmArray.ResetDataPipelines()
        time.sleep(1)

        print('Resetting Counters')
        time.sleep(.2)
        self.CountReset()

        # No longer necessary to send RunStart(), the SYNC timing signal triggers it in the DTM
        #print('Sending RunStart() for DPM count sync')
        #self.PcieTiDtmArray.RunStart()
        time.sleep(.2)

        # Should maybe check sync status here before continuing?
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


        self.CodaState.set('Prestart')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))
        self.PcieTiDtmArray.PcieTiDtm[0].JLabTimingPcie.CodaState.setDisp("PRESTART")
        self.PcieTiDtmArray.PcieTiDtm[1].JLabTimingPcie.CodaState.setDisp("PRESTART")



        print("Rogue Coda Prestart Done")
        return "OK"

    def _codaGo(self,debug=True):
        print("Rogue Coda Go Called")
        #for feb in self.ControlDpm.FebArray.FebFpga.values():
        #    feb.FebCore.FebConfig.AllowResync.set(False)

        self.CodaState.set('Go')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))

        if (debug):
            # Dump the current config state
            outfile = os.path.abspath(datetime.datetime.now().strftime(f"/usr/clas12/release/1.4.0/slac_svt/rogue_state/Run_{self.RunNumber.get()}_go_state_%Y%m%d_%H%M%S.yml"))
            self.SaveState(outfile)


        self.PcieTiDtmArray.PcieTiDtm[0].JLabTimingPcie.CodaState.setDisp('GO')
        self.PcieTiDtmArray.PcieTiDtm[1].JLabTimingPcie.CodaState.setDisp('GO')
        return "OK"

    def _codaEnd(self,debug=True):
        print("Rogue Coda End Called")
        self.CodaState.set('End')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))

        if (debug):
            # Dump the current config state
            outfile = os.path.abspath(datetime.datetime.now().strftime(f"/usr/clas12/release/1.4.0/slac_svt/rogue_state/Run_{self.RunNumber.get()}_end_state_%Y%m%d_%H%M%S.yml"))
            self.SaveState(outfile)


        self.PcieTiDtmArray.PcieTiDtm[0].JLabTimingPcie.CodaState.setDisp('END')
        self.PcieTiDtmArray.PcieTiDtm[1].JLabTimingPcie.CodaState.setDisp('END')
        return "OK"
