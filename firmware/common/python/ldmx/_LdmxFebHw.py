import pyrogue as pr

import surf.devices.micron
import surf.devices.microchip
import surf.xilinx

import ldmx

class LdmxFebHw(pr.Device):
    def __init__(self, numHybrids, febCore, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.xilinx.ClockManager(
            name = 'HybridClockPhaseA',
            offset = 0x0000,
            type = 'MMCME4'))

        self.add(surf.xilinx.ClockManager(
            name = 'HybridClockPhaseB',
            offset = 0x1000,
            type = 'MMCME4'))
        

        self.add(surf.xilinx.ClockManager(
            name = 'AdcClockPhase',
            offset = 0x2000,
            type = 'MMCME4'))

        # Loc I2C Bus
        self.add(surf.devices.microchip.Axi24LC64FT(
            enabled = False,
            offset = 0x10_0000))

        self.add(ldmx.Pcal6524(
            name = 'AmpPdA',
            expand = False,
            enabled = False,
            offset = 0x14_0000))

        self.add(ldmx.Pcal6524(
            name = 'AmpPdB',
            expand = False,
            enabled = False,
            offset = 0x18_0000))
        
        # SFP I2C Bus
        self.add(surf.devices.transceivers.Sfp(
            name = 'Sfp',
            enabled = False,
            expand = False,
            offset = 0x4000))

        self.add(surf.devices.transceivers.Qsfp(
            name = 'Qsfp',
            enabled = False,
            expand = False,
            offset = 0x5000))

        self.add(surf.xilinx.AxiSysMonUltraScale(
            enabled = True,
            offset = 0x1_0000))

        self.add(surf.devices.micron.AxiMicronN25Q(
            enabled = False,
            offset = 0x3000))

        self.add(ldmx.LdmxHybridPowerI2c(
            name = f'HybridPowerArray',
            offset = 0x2_0000,
            expand = True,
            numHybrids = numHybrids)) 

#         self.add(ldmx.DigPwrMon(
#             offset = 0x3_0000))

#         self.add(ldmx.AnaPwrMon(
#             offset = 0x4_0000))

        self.add(ldmx.AdcReadout(
            offset = 0x5_0000,
            numHybrids = 8))

        self.add(ldmx.AdcConfig(
            offset = 0x6_0000,
            numAdcs = 4))

        
        


#         for i in range(numHybrids):
#             self.add(ldmx.HybridPowerControl(
#                 numHybrids=i,
#                 febHw=self,
#                 febCore=febCore,
#                 name=f'HybridPowerControl[{i}]',
#                 expand=True))

#         self.add(ldmx.SoftPowerMonitor(
#             name='BoardPowerMonitor',
#             expand=False,
#             parent=self))
#         self.BoardPowerMonitor.setPollInterval(5)

#         self.add(ldmx.IntermediatePowerControl(
#             name = 'IntermediatePowerControl',
#             ad5144 = self.Ad5144[4],
#             pm = self.BoardPowerMonitor))



   

        @self.command()
        def ConfigureLtc2991():
            for dev in self.find(name="LdmxHybridPowerI2c"):
                dev.ConfigureLtc2991()
