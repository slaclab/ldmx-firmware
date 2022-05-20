import pyrogue as pr

from surf.devices.micron import _AxiMicronN25Q as micron
import surf.xilinx

import ldmx

class HpsFebHw(pr.Device):
    def __init__(self, numHybrids, febCore, **kwargs):
        super().__init__(**kwargs)

        self.add(ldmx.HpsFebPGoodMon(
            offset = 0x0000))

        self.add(ldmx.PhaseShifter(
            name='HybridClkPhaseShift',
            offset=0x1000,
            clocks=4,
            expand=False,
        ))

        self.add(ldmx.PhaseShifter(
            name='AdcClkPhaseShift',
            offset=0x2000,
            clocks=4,
            expand=False,
        ))

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
            'AcquisitionMode' : 'Repeated',
        }

        self.addNodes(
            name='Ltc2991',
            nodeClass=ldmx.Ltc2991,
            number=5,
            description='Hybrid Voltage Monitor',
            stride=0x0400,
            offset=0x30000,
            expand=False,
            hidden=False,
            enabled=True,
            defaults= None,)#ltcConfig)

        self.addNodes(
            name='Ad5144',
            nodeClass=ldmx.Ad5144,
            number=5,
            stride=0x0400,
            offset=0x4000,
            expand=False,
            hidden=False,
            enabled=True)

        for i in range(numHybrids):
            self.add(ldmx.HybridPowerControl(
                numHybrids=i,
                febHw=self,
                febCore=febCore,
                name=f'HybridPowerControl[{i}]',
                expand=True))

        self.addNodes(
            nodeClass=ldmx.Ad9252Readout,
            number=numHybrids,
            stride=0x100,
            offset=0x10000,            
            expand=False,
            name='AdcReadout')

            

        self.addNodes(
            nodeClass=ldmx.Ad9252Config,
            number=4,
            stride=0x1000,
            offset=0x20000,
            expand=False,
            hidden=False,
            enabled=False,
            name='Ad9252')

        self.add(surf.xilinx.Xadc(
            offset=0x5000,
            name='Xadc',
            auxChannels=16,
            expand=False,
            hidden=False,
        ))

#         self.add(ldmx.Tca6424a(
#             offset=0xB000,
#             enabled=False))
        

        self.add(micron.AxiMicronN25Q(
            offset=0x6000,
            expand=False,
            enabled=False,
            name='AxiMicronN25Q'))

        self.add(ldmx.SoftPowerMonitor(
            name='BoardPowerMonitor',
            expand=False,
            parent=self))
        self.BoardPowerMonitor.setPollInterval(5)

        self.add(ldmx.IntermediatePowerControl(
            name = 'IntermediatePowerControl',
            ad5144 = self.Ad5144[4],
            pm = self.BoardPowerMonitor))



        @self.command(description='Save all voltage trim values to AD5144 EEPROM')
        def SaveTrims():
            for i in range(5):
                self.Ad5144[i].SaveToEeprom()

        @self.command(description='Load all voltage trims with values from EEPROM')
        def LoadTrims():
            for i in range(5):
                self.Ad5144[i].LoadFromEeprom()


        @self.command()
        def ConfigureLtc2991():
            for dev in self.find(name="Ltc2991"):
                dev._setDict(ltcConfig, writeEach=False, modes=['RW', 'WO'], incGroups=None, excGroups='NoConfig', keys=None)
                dev.writeAndVerifyBlocks(force=True, recurse=False)
