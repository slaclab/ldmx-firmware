import pyrogue as pr

#import surf.xilinx as xil

HYBRID_TYPE_ENUM = {
    0: 'Unknown',
    1: 'Old',
    2: 'New',
    3: 'Layer0'}

class FebConfig(pr.Device):
    def __init__(self, tca, **kwargs):
        super().__init__(description="Front End Board FPGA FPGA Object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="FebAddress",
            description='Each Front End Board should be assigned a unique address',
            offset=0x18,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name=f'HybridPwrEn[{i}]',
                offset=0x0,
                bitOffset=i,
                bitSize=1,
                base=pr.UInt,
                enum =  {0: 'Off', 1: 'On'}))

        def setAllHybridPwrSwitch(value, write):
            for hyPwr in self.HybridPwrEn.values():
                hyPwr.set(value, write=write)

        def getAllHybridPwrSwitch(read):
            for hyPwr in self.HybridPwrEn.values():
                r = hyPwr.get(read=read)
                if r == 0:
                    return 0
            return 1

        self.add(pr.LinkVariable(
            name = 'HybridPwrAll',
            enum = {0: 'Off', 1: 'On'},
            dependencies = [x for x in self.HybridPwrEn.values()],
            linkedGet = getAllHybridPwrSwitch,
            linkedSet = setAllHybridPwrSwitch))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name=f'HybridType[{i}]',
                offset=0x1C,
                bitSize=2,
                bitOffset=i*2,
                base=pr.UInt,
                enum = HYBRID_TYPE_ENUM))

        self.add(pr.RemoteVariable(
            name="HybridTrigEn",
            description='Enables triggers to go to hybrids',
            offset=0xC,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool,
            value=True,
            hidden=True))

        def ampPwrAllGet(index, read):
            print(f'ampPwrAllGet({index}, {read}')
            ports = [tca.OutputPort[i].get(read) for i in range(3)]
            print([hex(p) for p in ports])
            ports = [p & 0x3f for p in ports]
            print([hex(p) for p in ports])
            ret = ports[2] << 12 | ports[1] << 6 | ports[0]
            print(hex(ret))
            return ret

        def ampPwrAllSet(value, index, write):
            tca.ConfigPort[0].set(0, write=write)
            tca.ConfigPort[1].set(0, write=write)
            tca.ConfigPort[2].set(0, write=write)
            tca.OutputPort[0].set((value&0x3f), write=write)
            tca.OutputPort[1].set(((value>>6)&0x3f), write=write)
            tca.OutputPort[2].set(((value>>12)&0x3f), write=write)

        self.add(pr.LinkVariable(
            name = 'AmplifierPowerAll',
            dependencies = [tca.OutputPort[x] for x in range(3)],
            disp = '{:#x}',
            linkedGet = ampPwrAllGet,
            linkedSet = ampPwrAllSet))


        self.add(pr.RemoteVariable(
            name="CalDelay",
            description='Hybrid clock cycles between charge injection trigger and readout trigger',
            offset=0x28,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="CalEn",
            description='Enables Calibration triggers',
            offset=0x28,
            bitSize=1,
            bitOffset=8,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="ApvDataStreamEn",
            description='Enable the APV Frame stream for each hybrid',
            offset=0x2C,
            bitSize=20,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="HeaderHighThreshold",
            description='Adc values above this indicate an APV header 1 bit',
            offset=0x40,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="StatusFrameIntervalRaw",
            description='Time between each Feb status PGP frame',
            offset=0x44,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        def getRaw(dev,var,read):
            return var.dependencies[0].value() * 8.0e-9

        self.add(pr.LinkVariable(
            name="StatusFrameInterval",
            description='Time between each Feb status PGP frame',
            units='s',
            linkedGet=getRaw,
            dependencies=[self.StatusFrameIntervalRaw]))

        self.add(pr.RemoteVariable(
            name="AllowResync",
            description='Allow APV sync to be re-established',
            offset=0x48,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="LedEn",
            description='Enable debug leds',
            offset=0x4C,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        powerList = [
            'FebA22V',
            'FebA18V',
            'FebA16V',
            'FebA29VA',
            'FebA29VD',
            'Hybrid0_V125',
            'Hybrid0_Dvdd',
            'Hybrid0_Avdd',
            'Hybrid1_V125',
            'Hybrid1_Dvdd',
            'Hybrid1_Avdd',
            'Hybrid2_V125',
            'Hybrid2_Dvdd',
            'Hybrid2_Avdd',
            'Hybrid3_V125',
            'Hybrid3_Dvdd',
            'Hybrid3_Avdd']

        for i, name in enumerate(powerList):
            self.add(pr.RemoteVariable(
                name=f"{name}_PGood",
                description='Regulator PGood value',
                offset=0x80+(i*4),
                bitSize=1,
                bitOffset=31,
                mode='RO',
                pollInterval=10,
                hidden=True,
                base=pr.Bool))

        for i, name in enumerate(powerList):
            self.add(pr.RemoteVariable(
                name=f'{name}_FallCnt',
                offset=0x80+(i*4),
                bitSize=31,
                bitOffset=0,
                mode='RO',
                pollInterval=10,
                hidden=True,
                base=pr.UInt))


        self.add(pr.RemoteCommand(
            name='HybridHardReset',
            description='Assert reset line to APV25s.',
            offset=0x04,
            function=pr.BaseCommand.createTouch(0xF)))

        def toggleHybridPwr(hybrid):
            self.HybridPwrEn[hybrid].set(not self.HybridPwrEn[hybrid].get())
            return self.HybridPwrEn[hybrid].value()

        for i in range(4):
            @self.command(name=f'ToggleHybridPower{i}')
            def _():
                return toggleHybridPwr(i)


    def hardReset(self):
        self.HybridHardReset()
