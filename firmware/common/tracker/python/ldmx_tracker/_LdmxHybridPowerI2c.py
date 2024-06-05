import pyrogue as pr

import ldmx_tracker

class LdmxHybridPowerI2c(pr.Device):
    def __init__(self, numHybrids, **kwargs):
        super().__init__(**kwargs)
        
        for i in range(numHybrids):
            self.add(ldmx_tracker.HybridPower(
                name = f'HybridPower[{i}]',
                offset = i*0x1000))

        @self.command()
        def ConfigureLtc2991():
            for dev in self.find(typ=ldmx_tracker.HybridPower):
                dev.ConfigureLtc2991()
            
        @self.command(description='Save all voltage trim values to AD5144 EEPROM')
        def SaveTrims():
            for dev in self.find(typ=ldmx_tracker.Ad5144):
                dev.SaveToEeprom()

        @self.command(description='Load all voltage trims with values from EEPROM')
        def LoadTrims():
            for i in self.find(typ=ldmx_tracker.Ad5144):
                dev.LoadFromEeprom()
        
class HybridPower(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        ltcConfig = {
            'TInternalVccEnable' : 'True',
            'V1V2Enable' : 'True',
            'V3V4Enable' : 'True',
            'V5V6Enable' : 'True',
            'V7V8Enable' : 'True',
            'V1V2Diff' : 'Differential',
            'V3V4Diff' : 'Differential',
            'V5V6Diff' : 'Differential',
            'V7V8Diff' : 'Differential',
            'AcquisitionMode' : 'Repeated',}            
        

        self.add(ldmx_tracker.Ltc2991(
            name='Ltc2991Near',
            description='Near Hybrid Voltage Monitor',
            offset=0x0000,
            expand=False,
            hidden=False,
            enabled=True,
            defaults= None))

        self.add(ldmx_tracker.Ltc2991(
            name='Ltc2991Far',
            description='Far Hybrid Voltage Monitor',
            offset=0x0400,
            expand=False,
            hidden=False,
            enabled=True,
            defaults= None))
        
        self.add(ldmx_tracker.Ad5144(
            name='Ad5144',
            offset=0x800,
            expand=False,
            hidden=False,
            enabled=True))

        @self.command()
        def ConfigureLtc2991():
            for dev in self.find(typ=ldmx_tracker.Ltc2991):
                dev._setDict(ltcConfig, writeEach=False, modes=['RW', 'WO'], incGroups=None, excGroups='NoConfig', keys=None)
                dev.writeAndVerifyBlocks(force=True, recurse=False)

