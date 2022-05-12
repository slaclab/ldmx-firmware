import pyrogue as pr
import hps
import surf.xilinx as xil
import time

class DaqTiming(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name='DaqAligned',
            offset=0x0,
            bitOffset=0,
            bitSize=1,
            mode='RO',
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name='TriggerCount',
            offset=0x04,
            bitSize=16,
            mode='RO',
            disp='{:d}'))

        self.add(pr.RemoteVariable(
            name='AlignCount',
            offset=0x08,
            bitSize=16,
            mode='RO',
            disp='{:d}'))

        self.add(pr.RemoteVariable(
            name='HySoftRstCount',
            offset=0x0C,
            bitSize=16,
            mode='RO',
            disp='{:d}'))


class PhaseShifter(pr.Device):
    def __init__(self, clocks=4, **kwargs):
        super().__init__(**kwargs)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name="PhaseShiftRaw",
            offset=0x00,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=511)

        for i in range(clocks):
            self.add(pr.LinkVariable(
                name=f'PhaseShift[{i}]',
                description='Clock phase delday',
                mode='RO',
                units='ns',
                dependencies=[self.PhaseShiftRaw[i]],
                linkedGet=lambda raw=self.PhaseShiftRaw[i]: raw.value() * 0.125))

        self.add(pr.RemoteCommand(
            name='ApplyConfig',
            offset=0x10,
            bitSize=1,
            bitOffset=0,
            base=pr.UInt,
            hidden=True,
            function=pr.BaseCommand.touchOne))

    def writeBlocks(self, **kwargs):
        #Check if there are stale blocks
        #print(f'{self.path}.writeBlocks()')
        #stale = any(b.stale for b in self._blocks)
        pr.Device.writeBlocks(self, **kwargs)
        self.ApplyConfig()

class HybridVoltageControl(pr.Device):
    def __init__(self,
                 trim,
                 near,
                 sense,
                 senseMult,
                 far,
                 current,
                 pgood,
                 pgood_fall,
                 **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True

        self.add(pr.LinkVariable(
            name='Trim',
            value=150,
            variable=trim,
        ))

        self.add(pr.LinkVariable(
            name='VoltageNear',
            variable=near,
            mode='RO',
            units='V',
            typeStr = 'float',
            pollInterval=3,
        ))

        if sense is not None:
            self.add(pr.LinkVariable(
                name='VoltageSense',
                variable=sense,
                mode='RO',
                units='V',
                typeStr = 'float',
                pollInterval=3,
                linkedGet=lambda: sense.value() * senseMult,
            ))

        self.add(pr.LinkVariable(
            name='VoltageFar',
            variable=far,
            mode='RO',
            units='V',
            typeStr = 'float',
            pollInterval=3,
        ))

        self.add(pr.LinkVariable(
            name='Current',
            variable=current,
            mode='RO',
            units='A',
            disp='{:1.3f}',
            typeStr = 'float',
            linkedGet=lambda: current.value() / .02,
            pollInterval=3,
        ))

        self.add(pr.LinkVariable(
            name='PGood',
            variable=pgood,
            mode='RO',
            pollInterval=3,
        ))

        self.add(pr.LinkVariable(
            name='PGood_FallCnt',
            variable=pgood_fall,
            mode='RO',
            pollInterval=3))


#Control Power for 1 hybrid
class HybridPowerControl(pr.Device):
    def __init__(self, hybridNum, febCore, **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True

        # def setPowerEn(var, value, write):
        #     print(f'{self.path}.setPowerEn(value={value}, write={write})')
        #     febCore.FebConfig.HybridPwrEn[hybridNum].set(value, write=write)

        #     if value is True and self.parent.enable.value() is True:
        #         print(f'{self.path} sleeping')
        #         time.sleep(1)
        #     febCore.Hybrid[hybridNum].enable.set(value)
        #     febCore.Hybrid[hybridNum].Type.set(self.Type.value())

        # self.add(pr.LinkVariable(
        #     name='PowerEn',
        #     enum = {False: 'False', True: 'True'},
        #     mode = 'RW',
        #     linkedSet = setPowerEn,
        #     linkedGet = lambda read: febCore.FebConfig.HybridPwrEn[hybridNum].get(read=read)
        # ))


        # def setType(var, value, write):
        #     print(f'{self.path}.setType(value={value}, write={write})')
        #     febCore.FebConfig.HybridType[hybridNum].set(value, write=write)
        #     febCore.Hybrid[hybridNum].Type.set(value)

        # self.add(pr.LinkVariable(
        #     name="Type",
        #     description='Configures the type of hybrid that is attached',
        #     mode = 'RW',
        #     enum = hps.HYBRID_TYPE_ENUM,
        #     linkedSet = setType,
        #     linkedGet = lambda read: febCore.FebConfig.HybridType[hybridNum].get(read=read)))

#            variable=febCore.FebConfig.HybridPwrEn[hybridNum]))

        self.add(HybridVoltageControl(
            name = 'DVDD',
            trim = febCore.Ad5144[hybridNum].Rdac[2],
            near = febCore.Ltc2991[hybridNum].V1,
            sense = None,
            senseMult = None,
            pgood = febCore.FebConfig.node(f'Hybrid{hybridNum}_Dvdd_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{hybridNum}_Dvdd_FallCnt'),
            far = febCore.Hybrid[hybridNum].DVDD,
            current = febCore.Ltc2991[hybridNum].V2))

        self.add(HybridVoltageControl(
            name = 'AVDD',
            trim = febCore.Ad5144[hybridNum].Rdac[1],
            near = febCore.Ltc2991[hybridNum].V3,
            sense = None, #febCore.Ltc2991[hybridNum].V8,
            senseMult = None, # -9.09,
            pgood = febCore.FebConfig.node(f'Hybrid{hybridNum}_Avdd_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{hybridNum}_Avdd_FallCnt'),
            far = febCore.Hybrid[hybridNum].AVDD,
            current = febCore.Ltc2991[hybridNum].V4))

        self.add(HybridVoltageControl(
            name = 'V125',
            trim = febCore.Ad5144[hybridNum].Rdac[0],
            near = febCore.Ltc2991[hybridNum].V5,
            sense = None, #febCore.Ltc2991[4].node(f'V{hybridNum*2+2}'),
            senseMult = None, # 4.02,
            pgood = febCore.FebConfig.node(f'Hybrid{hybridNum}_V125_PGood'),
            pgood_fall = febCore.FebConfig.node(f'Hybrid{hybridNum}_V125_FallCnt'),
            far = febCore.Hybrid[hybridNum].V125,
            current = febCore.Ltc2991[hybridNum].V6))

        self.add(pr.LinkVariable(
            name = 'HybridOnStatus',
            dependencies = [self.DVDD.PGood, self.AVDD.PGood, self.V125.PGood],
            mode = ['RO'],
            linkedGet = lambda: 2.5 if (self.DVDD.PGood.value() and self.AVDD.PGood.value() and self.V125.PGood.value()) else 0.0))

class InterVoltageControl(pr.Device):
    def __init__(self, trim, voltage, **kwargs):
        super().__init__(**kwargs)

        self.enable.hidden = True

        self.add(pr.LinkVariable(
            name='Trim',
            value=175,
            variable=trim,
        ))

        self.add(pr.LinkVariable(
            name='Voltage',
            variable=voltage,
            mode='RO',
            units='V',
            typeStr = 'float',
            pollInterval=3,
        ))

class InterPowerControl(pr.Device):
    def __init__(self, ad5144, pm, **kwargs):
        super().__init__(**kwargs)

        self.add(InterVoltageControl(
            name = 'FebA16V',
            trim = ad5144.Rdac[0],
            voltage = pm.FebA16V))

        self.add(InterVoltageControl(
            name = 'FebA29VA',
            trim = ad5144.Rdac[1],
            voltage = pm.FebA29VA))

        self.add(InterVoltageControl(
            name = 'FebA29VD',
            trim = ad5144.Rdac[2],
            voltage = pm.FebA29VD))

        self.add(InterVoltageControl(
            name = 'FebA22V',
            trim = ad5144.Rdac[3],
            voltage = pm.FebA22V))



class FebCore(pr.Device):
    def __init__(self, number, hybridNum=1, **kwargs):
        super().__init__(description="Front End Board FPGA FPGA Object.", **kwargs)

        self.number = number

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
            nodeClass=hps.Ltc2991,
            number=5,
            description='Hybrid Voltage Monitor',
            stride=0x0400,
            offset=0x2000,
            expand=False,
            hidden=False,
            enabled=True,
            defaults= None,)#ltcConfig)

        self.addNodes(
            name='Ad5144',
            nodeClass=hps.Ad5144,
            number=5,
            stride=0x0400,
            offset=0x8000,
            expand=False,
            hidden=False,
            enabled=True)

        self.addNodes(
            nodeClass=hps.Ad9252Config,
            number=4,
            stride=0x10000,
            offset=0x100400,
            expand=False,
            hidden=False,
            enabled=False,
            name='Ad9252')

        self.add(xil.Xadc(
            offset=0x5000,
            name='Xadc',
            auxChannels=16,
            expand=False,
            hidden=True,
        ))

        self.add(hps.Tca6424a(
            offset=0xB000,
            enabled=False))

        self.add(hps.FebConfig(
            offset=0x0,
            tca = self.Tca6424a,
            defaults = {
                'FebAddress': str(number)}
        ))

        self.add(hps.DaqTiming(offset=0x6000))



        self.add(PhaseShifter(
            name='HybridClkPhaseShift',
            offset=0x100,
            clocks=4,
            expand=False,
        ))

        self.add(PhaseShifter(
            name='AdcClkPhaseShift',
            offset=0x200,
            clocks=4,
            expand=False,
        ))

        for i in range(hybridNum):
            self.add(hps.Hybrid(
                offset=0x108000 + (i*0x10000),
                typeVar = self.FebConfig.HybridType[i],
                enableDeps=[self.FebConfig.HybridPwrEn[i]],
                name=f'Hybrid[{i}]'))

        for i in range(hybridNum):
            self.add(HybridPowerControl(
                hybridNum=i,
                febCore=self,
                name=f'HybridPowerControl[{i}]',
                expand=True))


        for i in range(hybridNum):
            self.add(hps.HybridSyncStatus(
                name=f'HybridSyncStatus[{i}]',
                enabled = True,
                offset=0x7000+(0x100*i)))


        self.addNodes(
            nodeClass=hps.Ad9252Readout,
            number=hybridNum,
            stride=0x10000,
            offset=0x100000,
            expand=False,
            name='AdcReadout')


        self.add(hps.SoftPowerMonitor(
            name='BoardPowerMonitor',
            expand=False,
            parent=self))
        self.BoardPowerMonitor.setPollInterval(5)

        self.add(InterPowerControl(
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

    def writeBlockss(self, force=False, recurse=True, variable=None, checkEach=False):
        print(f'{self.path}.writeBlocks()')
        super().writeBlocks(force, recurse, variable, checkEach)
        return

        # Make a copy of the device dict
        d = self.devices.copy()

        # Remove all the Hybrids from the copy
        for k, v in self.Hybrid.items():
            print(k, v)
            d.pop(v.name)

        # Write everything except the Hybrids
        for k, v in d.items():
            v.writeBlocks(force, recurse, variable, checkEach)

        # Sleep for some time if any of the hybrids are one
        if any((v.value() for v in self.FebConfig.HybridPwrEn.values())) and self.enable.value() is True:
            print('Sleeping')
            time.sleep(1.5)

        print(f'{self.path}.writeBlocks check blocks start')
        self.checkBlocks(recurse, variable)
        print(f'{self.path}.writeBlocks check blocks done')

        # Write the hybrids (will do nothing if not powered/disabled)
        print('Configure hybrids')
        for k, v in self.FebConfig.HybridPwrEn.items():
            self.Hybrid[k].writeBlocks(force, recurse, variable,checkEach)
