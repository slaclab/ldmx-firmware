import pyrogue as pr

class Ad5144(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="AD5144 Digital Potentiometer Object.",**kwargs)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name='RdacRaw',
            #hidden = True,
            offset=0b0001000000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}',
            mode = 'WO',
            minimum= 0,
            maximum=255)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name='EepromRaw',
            #hidden = True,
            offset=0b1000000000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}',
            mode = 'WO',
            minimum= 0,
            maximum=255,)
            

        self.addRemoteVariables(
            number=4,
            stride=4,
            name='Readback',
            hidden = True,
            offset=0b0011000000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}',
            mode = 'RO')
            

        def make_readback(reg, typ, index):
            def _linkedGet(read):
                print(f'{reg.path}._linkedGet({read=}, {typ=}, {index=}')
                if read is not True:
                    return reg.value()
                self.Readback[index].set(value=typ, write=True)
                return self.Readback[index].get(read=read)
            return _linkedGet

        def make_write(reg, index):
            def _linkedSet(value, write):
                print(f'{reg.path}._linkedSet({write=}, {index=})')
                reg.set(value=value, write=write)
            return _linkedSet

                
        for i in range(4):
            self.add(pr.LinkVariable(
                name = f'Rdac[{i}]',
                disp = '{:d}',
                mode = 'RW',
                dependencies = [self.RdacRaw[i], self.Readback[i]],
                linkedGet = make_readback(self.RdacRaw[i], 3, i), #lambda read, i=x: self.Readback[x].get(read=read),
                linkedSet = make_write(self.RdacRaw[i], i))) # lambda value, write, x=i: self.RdacRaw[x].set(value=value, write=write)))

        for i in range(4):
            self.add(pr.LinkVariable(
                name = f'Eeprom[{i}]',
                disp = '{:d}',
                mode = 'RW',                
                dependencies = [self.EepromRaw[i], self.Readback[i]],                
                linkedGet = make_readback(self.EepromRaw[i], 1, i), # lambda read, i=x: self.Readback[x].get(read=read),
                linkedSet = make_write(self.EepromRaw[i], i))) # lambda value, write, x=i: self.RdacRaw[x].set(value=value, write=write)))
            

        self.addRemoteCommands(
            number=4,
            stride=4,
            name="Copy",
            offset=0b0111000000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            #mode='WO'
            hidden=True,
            function=pr.BaseCommand.touch)


        self.add(pr.RemoteCommand(
            name='Lrdac',
            description='Copy Input registers to RDACs',
            offset=0b0110000000,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            function=pr.BaseCommand.createTouch(0x8)))

        # Not used so comment out for now
        #self.add(pr.RemoteVariable(name='CtrlReg', offset=0x44, bitSize=4, bitOffset=0, base=pr.UInt))

        self.add(pr.RemoteCommand(
            name='SoftReset',
            offset=0b1011000000,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            function=pr.BaseCommand.touchZero))


        @self.command(description='Save current RDAC values to EEPROM')
        def SaveToEeprom():
            for cmd in self.Copy.values():
                cmd(1)

        @self.command(description='Copy Input registers to RDACs')
        def LoadFromEeprom():
            for cmd in self.Copy.values():
                cmd(0)
