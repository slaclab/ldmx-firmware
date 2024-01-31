import pyrogue as pr

class Ad9252Config(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(description="AD9252 ADC object.",**kwargs)


#         self.add(pr.RemoteVariable(
#             name = "ConfigEn",
#             description='Set to ''True'' to enable register writes to ADC.',
#             offset=0x00,
#             bitSize=1,
#             bitOffset=0,
#             base =pr.Bool))

        self.add(pr.RemoteVariable(
            name = "ChipId",
            description='Read only chip ID value.',
            offset=0x04,
            bitSize=8,
            bitOffset=0,
            mode = "RO"))

        self.add(pr.RemoteVariable(
            name="ChipGrade",
            description='Read only chip grade value.',
            offset=0x08,
            bitSize=3,
            bitOffset=4,
            mode="RO"))


        self.add(pr.RemoteVariable(
            name="PowerDownMode",
            description='Set power mode of device.',
            offset=0x20,
            bitSize=2,
            bitOffset=0,
            base=pr.UInt,
            enum = {
                0: "Chip Run",
                1: "Full Power Down",
                2: "Standby",
                3: "Digital Reset"}))

        self.add(pr.RemoteVariable(
            name = "DutyCycleStabilizer",
            description='Turns on internal duty cycle stabilizer. (default=True).',
            offset=0x24,
            bitSize=1,
            bitOffset=0,
            base =pr.Bool))

        self.add(pr.RemoteVariable(
            name="DevIndexMaskHigh",
            offset=0x10,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            hidden=True,
            disp='{:#b}'))

        self.add(pr.RemoteVariable(
            name="DevIndexMaskLow",
            offset=0x14,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            hidden=True,
            disp='{:#b}'))

        self.add(pr.RemoteVariable(
            name="DevIndexMask_DCO_FCO",
            offset=0x14,
            bitSize=2,
            bitOffset=0x4,
            hidden=True,
            base=pr.UInt))        

        def _setDevIndexMask(value, write):
            self.DevIndexMaskLow.set(value & 0b1111, write=False)
            self.DevIndexMaskHigh.set((value>>4) & 0b1111, write=False)
            self.DevIndexMask_DCO_FCO.set((value>>8) & 0b11, write=False)
            self.writeBlocks()

        def _getDevIndexMask(read):
            low = self.DevIndexMaskLow.get(read=read)
            high = self.DevIndexMaskHigh.get(read=read)
            df = self.DevIndexMask_DCO_FCO.get(read=read)
            return (df << 8) | (high << 4) | low
        
        self.add(pr.LinkVariable(
            name = 'DevIndexMask',
            dependencies = [self.DevIndexMaskHigh, self.DevIndexMaskLow, self.DevIndexMask_DCO_FCO],
            disp = '{:#b}',
            linkedSet = _setDevIndexMask,
            linkedGet = _getDevIndexMask))



        self.add(pr.RemoteVariable(
            name="OutputTestMode",
            description='Set output test mode.',
            offset=0x34,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            enum={
                0: "Off",
                1: "Midscale Short",
                2: "Positive FS",
                3: "Negative FS",
                4: "Alternating checkerboard",
                5: "PN23",
                6: "PN9",
                7: "1/0-word toggle",
                8: "User Input",
                9: "1/0-bit Toggle",
                10: "1x sync",
                11: "One bit high",
                12: "mixed bit frequency"}))

        self.add(pr.RemoteVariable(
            name='ResetPNShort',
            description='Reset PN short gen test mode',
            offset=0x34,
            bitSize=1,
            bitOffset=4,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name='ResetPNLong',
            description='Reset PN long gen test mode',
            offset=0x34,
            bitSize=1,
            bitOffset=5,
            base=pr.Bool))


        self.add(pr.RemoteVariable(
            name='UserTestMode',
            description='Sets user test mode of all channels',
            offset=0x34,
            bitSize=3,
            bitOffset=6,
            base=pr.UInt,
            enum={
                0: 'Off',
                1: 'OnSingAlternate',
                2: 'OnSingleOnce',
                3: 'OnAlternateOnce'}))


        self.add(pr.RemoteVariable(
            name='OutputFormat',
            description='Set output format. binary or twos complement.',
            offset=0x50,
            bitSize=2,
            bitOffset=0,
            base=pr.UInt,
            enum={
                1: 'Twos Compliment',
                0: 'Offset Binary'}))

        self.add(pr.RemoteVariable(
            name='OutputInvert',
            description='Enable output inversion.',
            offset=0x50,
            bitSize=1,
            bitOffset=2,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name='OutputMode',
            description='Set output mode of device. Default=LVDS.',
            offset=0x50,
            bitSize=1,
            bitOffset=6,
            base=pr.UInt,
            enum={
                0:'LVDS ANSI-644',
                1:'LVDS Low Power'}))

        self.add(pr.RemoteVariable(
            name='DcoFcoDrive2x',
            description='Set DCO and DCO output drive strength.',
            offset=0x54,
            bitSize=1,
            bitOffset=0,
            base = pr.Bool))


        self.add(pr.RemoteVariable(
            name='OutputTermDrive',
            description='Set output driver termination.',
            offset=0x54,
            bitSize=2,
            bitOffset=4,
            base = pr.UInt,
            enum={
                0:'none',
                1:'200 Ohms',
                2:'100 Ohms',
                3:'100 Ohms'}))

        self.add(pr.RemoteVariable(
            name='OutputPhase',
            description='Set output phase adjustment.',
            offset=0x58,
            bitSize=4,
            bitOffset=0,
            base = pr.UInt,
            enum={
                0:'0 deg to edge',
                1:'60 deg to edge',
                2:'120 deg to edge',
                3:'180 deg to edge',
                4:'unused1',
                5:'300 deg to edge',
                6:'360 deg to edge',
                7:'unused2',
                8:'480 deg to edge',
                9:'540 deg to edge',
                10:'600 deg to edge',
                11:'660 deg to edge'}))

#          def convPattern(raw):
#             def convert():
#                 return raw.value()
#             return convert

        self.add(pr.RemoteVariable(
            name="UserPattern1Lsb",
            offset=0x64,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="UserPattern1Msb",
            offset=0x68,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="UserPattern2Lsb",
            offset=0x6C,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="UserPattern2Msb",
            offset=0x70,
            bitSize=8,
            bitOffset=0,
            base=pr.UInt))

    #     self.add(pr.LinkVariable(
#             name='UserPattern1',
#             description='Set user test pattern 1 data.',
#             linkedGet=convPattern(self.UserPattern1Raw),
#             dependencies=[self.UserPattern1Raw]))

#         self.add(pr.LinkVariable(
#             name='UserPattern2',
#             description='Set user test pattern 2 data.',
#             linkedGet=convPattern(self.UserPattern2Raw),
#             dependencies=[self.UserPattern2Raw]))

        self.add(pr.RemoteVariable(
            name='SerialBits',
            description='Set number of serial bits.',
            offset=0x84,
            bitSize=3,
            bitOffset=0,
            base = pr.UInt,
            enum={
                0:'14 bits',
                1:'8 bits',
                2:'10 bits',
                3:'12 bits',
                4:'14 bits'}))

        self.add(pr.RemoteVariable(
            name='LowEncodeRate',
            description='Set low rate less than 10mbs mode.',
            offset=0x84,
            bitSize=1,
            bitOffset=3,
            base = pr.Bool))

        self.add(pr.RemoteVariable(
            name='SerialLsbFirst',
            description='Set LSB first mode of device.',
            offset=0x84,
            bitSize=1,
            bitOffset=7,
            base = pr.Bool))


        self.add(pr.RemoteVariable(
            name='ChPowerDown',
            description='Set channel power down.',
            offset=0x88,
            bitSize=1,
            bitOffset=0,
            base = pr.Bool))

        self.add(pr.RemoteCommand(
            name='DeviceUpdate',
            offset=0x3FC,
            function=pr.BaseCommand.touchOne,
        ))

    def writeBlocks(self, **kwargs):
        pr.Device.writeBlocks(self, **kwargs)
        self.DeviceUpdate()



class Ad9252Readout(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="Power Monitor object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="FrameLocked",
            offset=0x30,
            bitSize=1,
            bitOffset=16,
            base=pr.Bool,
            mode='RO'))

        self.add(pr.RemoteVariable(
            name="LostLockCount",
            offset=0x30,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.addRemoteVariables(
            number=5,
            stride=4,
            name="ADCReadout",
            offset=0x80,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt,
            mode='RO',
            disp='{:#09_x}')

        self.add(pr.RemoteVariable(
            name="FrameDelayRaw",
            hidden=False,
            offset=0x20,
            bitSize=8,
            bitOffset=0,
            minimum=0,
            maximum=31,
            disp='{:d}',
            base=pr.UInt))

        self.addRemoteVariables(
            number=5,
            stride=4,
            name="DataDelayRaw",
            offset=0x00,
            bitSize=8,
            bitOffset=0,
            minimum=0,
            maximum=31,
            disp='{:d}',
            base=pr.UInt)

        def getRaw(rawVar):
            def convert():
                raw = rawVar.value()
                return raw*0.078
            return convert


        for i in range(5):
            self.add(pr.LinkVariable(
                name=f'DataDelay[{i}]',
                units='ns',
                mode='RO',
                disp='{:1.3f}',
                minimum=None,
                maximum=None,
                variable=self.DataDelayRaw[i],
                linkedGet=lambda r=self.DataDelayRaw[i]: r.value() * 0.078))


        self.add(pr.LinkVariable(
            name='FrameDelay',
            units='ns',
            mode='RO',
            disp='{:1.3f}',
            minimum=None,
            maximum=None,
            variable= self.FrameDelayRaw,
            linkedGet=lambda: self.FrameDelayRaw.value() * 0.078))
