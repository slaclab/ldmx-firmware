import pyrogue as pr

class ControlData(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name="TrigEnable",
            description='Trigger Enable',
            offset=0x00,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="TrigCount",
            description='Trigger Counter',
            offset=0x0C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AckCount",
            description='Ack Count',
            offset=0x10,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="DataCount",
            description='Data Counter',
            offset=0x14,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BusyCount",
            description='Busy Counter',
            offset=0x18,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="PauseStatus",
            description='Pause Counter',
            offset=0x1C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrigOverFlow",
            description='Trigger Buffer Over Flow',
            offset=0x20,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="RocId",
            description='ROC ID',
            offset=0x24,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BlockCount",
            description='Block Counter',
            offset=0x28,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="EventCount",
            description='Event Counter',
            offset=0x2C,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="EventState",
            description='Event State',
            offset=0x30,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BlockLevel",
            description='Block Level',
            offset=0x34,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AlignCount",
            offset=0x38,
            bitSize=32,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))
