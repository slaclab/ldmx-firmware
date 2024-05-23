import pyrogue as pr

class Ad5144(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="AD5144 Digital Potentiometer Object.",**kwargs)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name='Rdac',
            #hidden = True,
            offset=0b000_0000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}',
            minimum= 0,
            maximum=255)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name='Eeprom',
            #hidden = True,
            offset=0b001_0000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}',
            minimum= 0,
            maximum=255,)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name='Inp',
            #hidden = True,
            offset=0b010_0000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}',
            minimum= 0,
            maximum=255,)
        

        self.addRemoteCommands(
            number=4,
            stride=4,
            name="Copy",
            offset=0b011_0000,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt,
            #mode='WO'
            hidden=True,
            function=pr.BaseCommand.touch)

        self.add(pr.RemoteCommand(
            name='Lrdac',
            description='Copy Input registers to RDACs',
            offset=0b100_0000,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            function=pr.BaseCommand.createTouch(0x8)))

        # Not used so comment out for now
        #self.add(pr.RemoteVariable(name='CtrlReg', offset=0x44, bitSize=4, bitOffset=0, base=pr.UInt))

        self.add(pr.RemoteCommand(
            name='SoftReset',
            offset=0b110_0000,
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
