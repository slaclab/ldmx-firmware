import pyrogue

import time

class CodaDummyRoot(pyrogue.Root):
    def __init__(self, **kwargs):
        super().__init__(name='HpsSvtDaqRoot')

        self.add(pyrogue.LocalCommand(name='CodaInit', value='', function=self._codaInit,
                                 description='CODA Init State'))

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

        self.add(pyrogue.LocalVariable(name='SvtRunType', value=0, mode='RW',
            description='Run Type'))

        self.add(pyrogue.LocalCommand(name='SetThrCutEn', value=False, function=self._setThrCutEn,
            description='Set Threshold Cut Enable'))

        self.add(pyrogue.LocalCommand(name='SetCalibMode', value=False, function=self._setCalibMode,
            description='Set Calibration Mode '))

        self.add(pyrogue.LocalCommand(name='SetCalibGroup', value=0, function=self._setCalibGroup,
            description='Set Calibration Group'))

        self.add(pyrogue.LocalCommand(name='SetCalibDelay', value=0, function=self._setCalibDelay,
            description='Set Calibration Delay'))

        self.add(pyrogue.LocalCommand(name='SetCalibLevel', value=0, function=self._setCalibLevel,
            description='Set Calibration Level'))

        self.add(pyrogue.LocalVariable(name='LibRogueLiteVersion', value='', mode='RW',
            description=''))

        self.add(pyrogue.LocalVariable(name='RogueCodaVersion', value='', mode='RW',
            description=''))


    def _codaInit(self, arg):
        print("Rogue Coda Init Called")
        self.CodaState.set('Init')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))

    def _codaDownload(self, arg):
        print("Rogue Coda Download Called")

        # Determine run mode from filename

        # Gain calibration run
        if 'injection' in arg:
            self.SvtRunType.set(1)

        # t0 calibration run, single cal group
        elif 't0Single' in arg:
            self.SvtRunType.set(3)

        # t0 calibration run
        elif 't0' in arg:
            self.SvtRunType.set(2)

        # Normal run
        else:
            self.SvtRunType.set(0)

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
                        if fields[0] == "RCE_EB_1_CONFIG_FILE":
                            self.SvtEbConfigFile.set(fields[1])

        except Exception as e:
            return str(e)

        print("EB Config File: {}".format(self.SvtEbConfigFile.value()))
        print("SVT Run Type: {}".format(self.SvtRunType.value()))
        self.CodaState.set('Download')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))
        return "OK"

    def _codaPrestart(self):
        print("Rogue Coda Prestart Called")
        self.CodaState.set('Prestart')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))
        return "OK"

    def _codaGo(self):
        print("Rogue Coda Go Called")
        self.CodaState.set('Go')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))
        return "OK"

    def _codaEnd(self):
        print("Rogue Coda End Called")
        self.CodaState.set('End')
        self.CodaStateTime.set(time.strftime("%Y-%m-%d %H:%M:%S %Z", time.localtime(time.time())))
        return "OK"

    def _setThrCutEn(self,arg):
        print("Threshold cut enable set to {}".format(arg))

    def _setCalibMode(self,arg):
        print("Calibration mode set to {}".format(arg))

    def _setCalibGroup(self,arg):
        print("Calibration group set to {}".format(arg))

    def _setCalibDelay(self,arg):
        print("Calibration delay set to {}".format(arg))

    def _setCalibLevel(self,arg):
        print("Calibration level set to {}".format(arg))
