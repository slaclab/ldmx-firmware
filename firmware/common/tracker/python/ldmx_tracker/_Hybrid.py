import pyrogue as pr
import ldmx_tracker
import math


class Hybrid(pr.Device):

    def setType(self, value, write):
        print(f'{self.path}.setType({value}, write={write})')
        self.typeVar.set(value, write=True)

        valueDisp = ldmx_tracker.HYBRID_TYPE_ENUM[value]

        if valueDisp == 'Old':
            self.Ads7924.enable.set(True)
            self.Ads1115.enable.set(False)

            for i in range(5):
                self.Apv25[i].enable.set(True)

        elif valueDisp == 'New':
            self.Ads7924.enable.set(False)
            self.Ads1115.enable.set(True)

            for i in range(5):
                self.Apv25[i].enable.set(True)

        elif valueDisp == 'Layer0':
            self.Ads7924.enable.set(False)
            self.Ads1115.enable.set(True)

            for i in range(4):
                self.Apv25[i].enable.set(True)

            self.Apv25[4].enable.set(False)

        else:
            self.Ads7924.enable.set(False)
            self.Ads1115.enable.set(False)

            for i in range(5):
                self.Apv25[i].enable.set(False)


    def __init__ (self, typeVar=None, pwrVar=None, **kwargs):
        super().__init__(description="HPS SVT Hybrid container.", **kwargs)

        self.typeVar = typeVar
        self.pwrVar = pwrVar

        # self.add(pr.LinkVariable(
        #     name="Type",
        #     description='Configures the type of hybrid that is attached',
        #     mode = 'RW',
        #     enum = ldmx_tracker.HYBRID_TYPE_ENUM,
        #     linkedSet = self.setType,
        #     linkedGet = lambda read: typeVar.get(read=read)))

        self.addNodes(
            nodeClass=ldmx_tracker.Apv25,
            number=5,
            stride=0x400,
            offset=0x8000,
            name='Apv25',
            enabled=False,
            defaults = {
                'TriggerMode': '3-Sample',
                'CalibrationInhibit': 'True',
                'ReadOutMode': 'Peak',
                'ReadOutFrequency': '40 MHz',
                'PreAmpPol': 'Inverting',
                'LatencyRaw': '0x83',
                'MuxGain': 'Mip_1_2mA',
                'Csel': 'Dly_1x3_125ns',
                'CalGroup': '0',
                'Vpsp': '0x1e',
                'Vfs': '0x3c',
                'Vfp': '0x1e',
                'Ical': '0x1d',
                'Ispare': 'False',
                'ImuxIn': '0x22',
                'Ipsp': '0x37',
                'Issf': '0x22',
                'Isha': '0x22',
                'Ipsf': '0x22',
                'Ipcasc': '0x34',
                'Ipre': '0x62',
            }
        )

        self.add(ldmx_tracker.Ads7924(
            enabled=False,
            offset = 0x9400,
            name='Ads7924',
            defaults = {
                'AcqTime': '0',
                'AlarmCount': '0',
                'CalCntl': 'CH3',
                'ConvCtrl': 'Continue',
                'Mode': 'Auto-Scan',
                'PwrConEn': 'False',
                'PwrConPol': 'Active Low',
                'PwrUpTime': '0',
                'SleepDiv4': '1',
                'SleepMult8': '1',
                'SleepTime': '2.5 ms'}
        ))

        self.add(ldmx_tracker.Ads1115(
            enabled=False,
            offset = 0xA000,
            defaults = {
                'DataRate': '860 SPS',
                'Mode' : 'Single Shot',
                'Pga' : '2.048V'},
            name='Ads1115'))

        def getAdc(channel, read):
            hyType = self.typeVar.valueDisp()
            if hyType == "Old" :
                voltage = self.Ads7924.Voltage[channel].get(read=read) #value()
                return voltage
            elif hyType == "New" or hyType == 'Layer0':
                return self.Ads1115.AIN[channel].get(read=read) #value()
            else:
                return 0.0

        def getTemp0(read):
            if self.typeVar.getDisp() == 'Unknown':
                return 0.0
            temp = self.getThermistorTemperature(getAdc(0, read))
            return temp

        def getTemp1(read):
            if self.typeVar.getDisp() != 'Old':
                return 0.0
            temp = self.getThermistorTemperature(getAdc(1, read))
            return temp


        self.add(pr.LinkVariable(
            name='Temperature0',
            disp='{:1.3f}',
            units='degC',
            mode='RO',
            dependencies = [self.Ads1115.AIN[0], self.Ads7924.Voltage[0]],
            linkedGet=getTemp0,
            pollInterval=5
        ))

        self.add(pr.LinkVariable(
            name='Temperature1',
            disp='{:1.3f}',
            units='degC',
            mode='RO',
            dependencies = [self.Ads7924.Voltage[1]],
            linkedGet=getTemp1,
            pollInterval=5
        ))

        def getVoltage(channel, multiplier):
            def f(read):
                if self.typeVar.valueDisp() == 'Old' or self.typeVar.valueDisp() == 'Unknown':
                    return 0.0
                return getAdc(channel, read) * multiplier
            return f

        self.add(pr.LinkVariable(
            name='DVDD',
            disp='{:1.3f}',
            mode='RO',
            dependencies= [self.Ads1115.AIN[1], self.Ads7924.Voltage[1]],
            linkedGet=getVoltage(1, 2.0),
            pollInterval=5
        ))

        self.add(pr.LinkVariable(
            name='V125',
            disp='{:1.3f}',
            mode='RO',
            dependencies= [self.Ads1115.AIN[3], self.Ads7924.Voltage[3]],
            linkedGet=getVoltage(3, 1.0)
        ))

        self.add(pr.LinkVariable(
            name='AVDD',
            disp='{:1.3f}',
            mode='RO',
            dependencies= [self.Ads1115.AIN[2], self.Ads7924.Voltage[2]],
            linkedGet=getVoltage(2, 2.0),
            pollInterval=5
        ))

        @self.command()
        def Configure():
            #In theory this will enable and disable things properly
            print(f'{self.path}.Configure()')
            val = self.typeVar.get(read=False)
            print(f'{self.path}.Type.get(read=Fale) = {val}')
            self.writeBlocks(force=True, recurse=True, variable=None, checkEach=True)



#    def enableChanged(self, value):
#        if value is True:
#            time.sleep(1) # wait 1 second to allow power up
#            self.writeAndVerifyBlocks(force=True, recurse=True)

    # def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
    #     print(f'{self.path}.writeBlocks(force={force}, recurse={recurse}, variable={variable}, checkEach={checkEach})')
    #     val = self.typeVar.get(read=False)
    #     print(f'{self.path}.Type.get(read=Fale) = {val}')
    #     super().writeBlocks(force, recurse, variable, checkEach)


    @staticmethod
    def getThermistorTemperature(voltage):
        vRef =2.5
        tempCelcius=5
        beta_=3750
        constA_=0.03448533
        k0_=273.15
        rdiv_=10000

        current = (2.5 - voltage) / rdiv_
        if voltage != 0:
            resistance = voltage / current
        else:
            resistance = 1
        tempKelvin = beta_ / math.log( resistance / constA_ )
        tempCelcius = tempKelvin - k0_
        return tempCelcius

#        self.add(pr.LinkVariable(
#             name='Temperature',
#             description='Temperature',
#             units='degC',
#             linkedGet=getTemp,
#             dependencies=[self.TemperatureRaw]))


#         @self.command(description='Select Device Type')
#         def writeConfig():
#             lastEn=self.enable.get()
#             currEn=self.HybridPwrEn.value()

#             if not lastEn  and currEn:
#                 force=True
#                 time.sleep(0.5)

#             self.enable.set(currEn)

#             if currEn:
#                 self.Ads7924.enable.set(self.type.value() is 'Old')
#                 self.Ads1115.enable.set(self.type.value() is 'New')
