import pyrogue as pr

class Ads7924(pr.Device):
    def __init__ (self,avdd=2.5,**kwargs):
        super().__init__(description="ADS7924 AtoD Converter.", **kwargs)

        # All addresses have bit 7 set so that 2 byte accesses work
        # All registers return data flipped, with the low byte at offset 8
        MODECNTRL = 0x80*4
        DATA = [0x82*4, 0x84*4, 0x86*4, 0x88*4]
        LIMIT = [0x8A*4, 0x8C*4, 0x8E*4, 0x90*4]
        INTSLPCONFIG = 0x92*4
        ACQPWRCONFIG = 0x94*4
        RESET = 0x96*4

        self.add(pr.LocalVariable(
            name="Avdd",
            description='AVDD that the chip is running at',
            mode='RO',
            units='V',
            value=avdd))


        self.add(pr.RemoteVariable(
            name="ChannelSel",
            offset=MODECNTRL,
            bitSize=2,
            bitOffset=8,
            base=pr.UInt,
            verify=False,
            enum = {
                0: "Channel 0",
                1: "Channel 1",
                2: "Channel 2",
                3: "Channel 3"}))

        self.add(pr.RemoteVariable(
            name="Mode",
            description='ADC sampling mode',
            offset=MODECNTRL,
            bitSize=6,
            bitOffset=10,
            base=pr.UInt,
            enum = {
                0x00: "Idle",
                0x20: "Awake",
                0x30: "Manual-Single",
                0x32: "Manual-Scan",
                0x31: "Auto-Single",
                0x33: "Auto-Scan",
                0x39: "Auto-Single Sleep",
                0x3B: "Auto-Scan Sleep",
                0x3F: "Auto-BurstScan Sleep"}))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name=f"AlarmEn[{i}]",
                description='Enabled the alarm',
                offset=MODECNTRL,
                bitSize=1,
                bitOffset=i,
                base=pr.Bool))

        for i in range(4):
            self.add(pr.RemoteVariable(
                name=f"AlarmSt[{i}]",
                description='Status of the alarm',
                offset=MODECNTRL,
                bitSize=1,
                bitOffset=4+i,
                base=pr.Bool,
                mode='RO'))

        for i, addr in enumerate(DATA):
            self.add(pr.RemoteVariable(
                name=f"Data[{i}]",
                description='Channel ADC value',
                offset=addr,
                bitSize=16,
                bitOffset=0,
                base=pr.UInt,
                mode='RO'))


            self.add(pr.LinkVariable(
                name=f'Voltage[{i}]',
                disp='{:1.3f}',
                dependencies = [self.Data[i]],
                linkedGet = lambda tmp=self.Data[i]: tmp.value() * (avdd/65536)))

        for i, addr in enumerate(LIMIT):
            self.add(pr.RemoteVariable(
                name=f"LowerLimitThreshRaw[{i}]",
                description='Lower Limit Threshold for Channel Comparator.',
                hidden=True,
                offset=addr,
                bitSize=8,
                bitOffset=0,
                base=pr.UInt,
                disp='{:d}'))

            self.add(pr.RemoteVariable(
                name=f"UpperLimitThreshRaw[{i}]",
                description='Upper Limit Threshold for Channel Comparator.',
                hidden=True,
                offset=addr,
                bitSize=8,
                bitOffset=8,
                base=pr.UInt,
                disp='{:d}'))

    #     def getLimit(rawVar):
#             def conVert(read):
#                 raw = rawVar.get(read=read)
#                 return raw*avdd/256
#             return conVert

#         for i in range(4):
#             self.add(pr.LinkVariable(
#                 name=f'LowerLimitThreshold{i}',
#                 description='Lower Limit Threshold for Channel Comparator.',
#                 units='V',
#                 mode='RO',
#                 linkedGet=getLimit(self.LowerLimitThreshRaw[i]),
#                 dependencies=[self.LowerLimitThreshRaw[i]]))

#             self.add(pr.LinkVariable(
#                 name=f'UpperLimitThreshold{i}',
#                 description='Upper Limit Threshold for Channel Comparator.',
#                 units='V',
#                 linkedGet=getLimit(self.UpperLimitThreshRaw[i]),
#                 dependencies=[self.UpperLimitThreshRaw[i]]))

        self.add(pr.RemoteVariable(
            name="IntTrig",
            description='INT pin signaling',
            offset=INTSLPCONFIG,
            bitSize=1,
            bitOffset=8,
            base=pr.UInt,
            enum={0:'Level', 1:'Edge'}))

        self.add(pr.RemoteVariable(
            name="IntPol",
            description='INT pin polarity.',
            offset=INTSLPCONFIG,
            bitSize=1,
            bitOffset=9,
            base=pr.UInt,
            enum={0:'Low', 1:'High'}))

        self.add(pr.RemoteVariable(
            name="IntConfig",
            description='Determines which signals is output on INT and conversion control event',
            offset=INTSLPCONFIG,
            bitSize=3,
            bitOffset=10,
            base=pr.UInt,
            enum={
                0:'Alarm, Alarm',
                1:'Busy, Alarm',
                2:'Data Ready 1, Data Ready 1',
                3:'Busy, Data Ready 1',
                4:'Do Not Use',
                5:'Do Not Use',
                6:'Data Ready 4, Data Ready 4',
                7:'Busy, Data Ready 4'}))

        self.add(pr.RemoteVariable(
            name="AlarmCount",
            description='Number of times threshold limit must be exceeded to generate an alarm.',
            offset=INTSLPCONFIG,
            bitSize=3,
            bitOffset=13,
            base=pr.UInt,
            disp='{:d}',
            minimum=0,
            maximum=7))


        self.add(pr.RemoteVariable(
            name="SleepTime",
            description='Sleep time',
            offset=INTSLPCONFIG,
            bitSize=3,
            bitOffset=0,
            base=pr.UInt,
            enum={
                0:'2.5 ms',
                1:'5 ms',
                2:'10 ms',
                3:'20 ms',
                4:'40 ms',
                5:'80 ms',
                6:'160 ms',
                7:'5320 ms'}))

        self.add(pr.RemoteVariable(
            name="SleepMult8",
            description='Sets speed of sleep clock',
            offset=INTSLPCONFIG,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt,
            enum={
                0:'1',
                1:'8'}))

        self.add(pr.RemoteVariable(
            name="SleepDiv4",
            description='Sets speed of sleep clock',
            offset=INTSLPCONFIG,
            bitSize=1,
            bitOffset=5,
            base=pr.UInt,
            enum={
                0:'1',
                1:'4'}))

        self.add(pr.RemoteVariable(
            name="ConvCtrl",
            description='Determines conversion status after a conversion control event.',
            offset=INTSLPCONFIG,
            bitSize=1,
            bitOffset=6,
            base=pr.UInt,
            enum={
                0:'Continue',
                1:'Stop'}))

        self.add(pr.RemoteVariable(
            name="AcqTime",
            description='Signal acuqisition time',
            offset=ACQPWRCONFIG,
            bitSize=5,
            bitOffset=8,
            disp='{:d}',
            base=pr.UInt))

#         def getTime(rawVar,type):
#             def conVert(read):
#                 raw = rawVar.get(read=read)
#                 if type is 0:
#                     return (raw*2)+6
#                 return raw*2
#             return conVert

#         self.add(pr.LinkVariable(
#             name='AcqTime',
#             description='Signal acuqisition time',
#             units='us',
#             linkedGet=getTime(self.AcqTimeRaw,0),
#             dependencies=[self.AcqTimeRaw]))

        self.add(pr.RemoteVariable(
            name="PwrUpTime",
            description='Power-up time setting',
            offset=ACQPWRCONFIG,
            bitSize=5,
            bitOffset=0,
            base=pr.UInt,
            disp='{:d}'))

#         self.add(pr.LinkVariable(
#             name='PwrUpTime',
#             description='Power-up time setting',
#             units='us',
#             linkedGet=getTime(self.PwrUpTimeRaw,1),
#             dependencies=[self.PwrUpTimeRaw]))

        self.add(pr.RemoteVariable(
            name="PwrConEn",
            description='PWRCON enable',
            offset=ACQPWRCONFIG,
            bitSize=1,
            bitOffset=5,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="PwrConPol",
            description='PWRCON pin polarity',
            offset=ACQPWRCONFIG,
            bitSize=1,
            bitOffset=6,
            base=pr.UInt,
            enum={
                0:'Active Low',
                1:'Active High'}))

        self.add(pr.RemoteVariable(
            name="CalCntl",
            description='Calibration Control',
            offset=ACQPWRCONFIG,
            bitSize=1,
            bitOffset=7,
            base=pr.UInt,
            enum={
                0:'CH3',
                1:'AGND'}))

        self.add(pr.RemoteVariable(
            name="ID",
            description='Device ID',
            overlapEn = True,
            offset=RESET,
            bitSize=8,
            bitOffset=8,
            base=pr.UInt,
            mode='RO'))


        self.add(pr.RemoteCommand(
            name="Reset",
            overlapEn = True,
            offset=RESET,
            bitSize=8,
            bitOffset=8,
            base=pr.UInt,
            function=pr.BaseCommand.createTouch(0xAA)))


    def convAdc(self, adc):
        value = adc * (self.Avdd.get() / 65536)
        return value
