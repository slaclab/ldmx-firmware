import pyrogue as pr

class Ad9510(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="AD9510 PLL object.",**kwargs)

        self.add(pr.RemoteVariable(
            name="ChipPortconfig",
            offset=0x04,
            bitSize=2,
            bitOffset=0,
            base=pr.UInt,
            enum = {
                0:"Chip Run",
                1: "Full Power Down",
                2: "Standby",
                3: "Digital Reset"}))

        self.add(pr.RemoteVariable(
            name="PowerDown4",
            offset=0x40,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="OutputLvl4",
            offset=0x40,
            bitSize=2,
            bitOffset=1,
            base=pr.UInt,
            enum = {
                0:'1.75 mA',
                1:'3.5 mA' ,
                2:'5.25 mA' ,
                3:'7 mA' }))

        self.add(pr.RemoteVariable(
            name="Logic4",
            offset=0x40,
            bitSize=1,
            bitOffset=3,
            base=pr.UInt,
            enum = {
                0:'LVDS',
                1:'CMOS'}))

        self.add(pr.RemoteVariable(
            name="InvertCmos4",
            offset=0x40,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt,
            enum = {
                0:'disabled',
                1:'enabled'}))


        self.add(pr.RemoteVariable(
            name="PowerDown5",
            offset=0x41,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="OutputLvl5",
            offset=0x41,
            bitSize=2,
            bitOffset=1,
            base=pr.UInt,
            enum = {
                0:'1.75 mA',
                1:'3.5 mA' ,
                2:'5.25 mA' ,
                3:'7 mA' }))

        self.add(pr.RemoteVariable(
            name="Logic5",
            offset=0x41,
            bitSize=1,
            bitOffset=3,
            base=pr.UInt,
            enum = {
                0:'LVDS',
                1:'CMOS'}))

        self.add(pr.RemoteVariable(
            name="InvertCmos5",
            offset=0x41,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt,
            enum = {
                0:'disabled',
                1:'enabled'}))


        self.add(pr.RemoteVariable(
            name="PowerDown6",
            offset=0x42,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="OutputLvl6",
            offset=0x42,
            bitSize=2,
            bitOffset=1,
            base=pr.UInt,
            enum = {
                0:'1.75 mA',
                1:'3.5 mA' ,
                2:'5.25 mA' ,
                3:'7 mA' }))

        self.add(pr.RemoteVariable(
            name="Logic6",
            offset=0x42,
            bitSize=1,
            bitOffset=3,
            base=pr.UInt,
            enum = {
                0:'LVDS',
                1:'CMOS'}))

        self.add(pr.RemoteVariable(
            name="InvertCmos6",
            offset=0x42,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt,
            enum = {
                0:'disabled',
                1:'enabled'}))

        self.add(pr.RemoteVariable(
            name="ClockSel",
            offset=0x45,
            bitSize=1,
            bitOffset=0,
            base=pr.UInt,
            enum = {
                0:'CLK 2',
                1:'CLK 1'}))


        self.add(pr.RemoteVariable(
            name="Divider4HighCycles",
            offset=0x50,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            disp='range',
            max=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Divider4LowCycles",
            offset=0x50,
            bitSize=4,
            bitOffset=4,
            base=pr.UInt,
            disp='range',
            max=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Divider4Phase",
            offset=0x51,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            disp='range',
            max=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Divider4StartHigh",
            offset=0x51,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Div4Force",
            offset=0x51,
            bitSize=1,
            bitOffset=5,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Divider4NoSync",
            offset=0x51,
            bitSize=1,
            bitOffset=6,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Divider4Bypass",
            offset=0x51,
            bitSize=1,
            bitOffset=7,
            base=pr.UInt))


        self.add(pr.RemoteVariable(
            name="Divider5HighCycles",
            description='Divider 5 High Cycles.',
            offset=0x52,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            disp='range',
            maximim=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Divider5LowCycles",
            description='Divider 5 Low Cycles.',
            offset=0x52 ,
            bitSize=4,
            bitOffset=4,
            base=pr.UInt,
            disp='range',
            maximum=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Divider5Phase",
            description='Divider 5 Offset.',
            offset=0x53,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            disp='range',
            maximum=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Divider5HL",
            description='Divider 5 Low Cycles.',
            offset=0x53,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Divider5Force",
            offset=0x53,
            bitSize=1,
            bitOffset=5,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Divider5NoSync",
            offset=0x53,
            bitSize=1,
            bitOffset=6,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Divider5Bypass",
            offset=0x53,
            bitSize=1,
            bitOffset=7,
            base=pr.UInt))


        self.add(pr.RemoteVariable(
            name="Divider6HighCyc",
            offset=0x54,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            disp='range',
            maximum=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Div6LowCyc",
            offset=0x54,
            bitSize=4,
            bitOffset=4,
            base=pr.UInt,
            disp='range',
            maximum=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Div6Offset",
            offset=0x55,
            bitSize=4,
            bitOffset=0,
            base=pr.UInt,
            disp='range',
            maximum=15,
            minimum=0,
            mode ='RW'))

        self.add(pr.RemoteVariable(
            name="Div6HL",
            offset=0x55,
            bitSize=1,
            bitOffset=4,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Div6Force",
            offset=0x55,
            bitSize=1,
            bitOffset=5,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Div6Sync",
            offset=0x55,
            bitSize=1,
            bitOffset=6,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="Div6Bypass",
            offset=0x55,
            bitSize=1,
            bitOffset=7,
            base=pr.UInt))
