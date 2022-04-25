import pyrogue as pr

class EventBuilder(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="EventBuilder Object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="State",
            offset=0x00,
            bitSize=2,
            bitOffset=0,
            mode = 'RO',
            base=pr.UInt,
            pollInterval=11,
            enum = {
                0:'WAIT_TRIGGER_S',
                1:'DO_DATA_S',
                2:'EOF_S',
                3:'FROZEN_S'}))

        self.add(pr.RemoteVariable(
            name="ApvNum",
            offset=0x04,
            bitSize=3,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="HybridNum",
            offset=0x04,
            bitSize=2,
            bitOffset=3,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AllValid",
            offset=0x04,
            bitSize=1,
            bitOffset=5,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AnyValid",
            offset=0x04,
            bitSize=1,
            bitOffset=6,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AllHead",
            offset=0x04,
            bitSize=1,
            bitOffset=7,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AnyHead",
            offset=0x04,
            bitSize=1,
            bitOffset=8,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AllTails",
            offset=0x04,
            bitSize=1,
            bitOffset=9,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="EventCount",
            offset=0x08,
            bitSize=32,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt,
            pollInterval=5))

        self.add(pr.RemoteVariable(
            name="SampleCount",
            offset=0xC,
            bitSize=12,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="GotTails",
            offset=0x10,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="SofCount",
            offset=0x14,
            bitSize=16,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="EofCount",
            offset=0x18,
            bitSize=16,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt))



        self.add(pr.RemoteVariable(
            name="MaxEventSize",
            offset=0x1C,
            bitSize=12,
            bitOffset=0,
            disp = '{:d}',
            base=pr.UInt,
            value=0xFFF))

        self.add(pr.RemoteVariable(
            name="DataPathEn",
            offset=0x1C,
            bitSize=4,
            bitOffset=12,
            base=pr.UInt,
            value=0xF))

        self.add(pr.RemoteVariable(
            name="HeaderMode",
            offset=0x1C,
            bitSize=3,
            bitOffset=16,
            base=pr.UInt,
            enum={
                0:'All headers',
                1:'First header',
                3:'No headers'},
            value=0))

        self.add(pr.RemoteVariable(
            name="BurnCount",
            offset=0x20,
            bitSize=16,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt,
            pollInterval=11))

        self.add(pr.RemoteVariable(
            name="SampleCountLast",
            offset=0x24,
            bitSize=12,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt,
            pollInterval=5))

        self.add(pr.RemoteVariable(
            name="SyncErrorCount",
            offset=0x34,
            bitSize=16,
            bitOffset=0,
            mode='RO',
            base=pr.UInt,
            pollInterval=11))

        self.add(pr.RemoteVariable(
            name="HeadErrorCount",
            offset=0x28,
            bitSize=16,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt,
            pollInterval=11))

        self.add(pr.RemoteVariable(
            name="EventErrorCount",
            offset=0x28,
            bitSize=16,
            bitOffset=16,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt,
            pollInterval=11))

#         self.add(pr.RemoteVariable(
#             name="TriggersOutstanding",
#             offset=0x2C,
#             bitSize=16,
#             bitOffset=0,
#             disp = '{:d}',
#             mode='RO',
#             base=pr.UInt))

#         self.add(pr.RemoteVariable(
#             name="TriggersOustandingMax",
#             offset=0x2C,
#             bitSize=16,
#             bitOffset=16,
#             disp = '{:d}',
#             mode='RO',
#             base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="PeakOccupancy",
            offset=0x30,
            bitSize=12,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt,
            pollInterval=11))
