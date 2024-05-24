import pyrogue as pr

class DataReadout(pr.Device):

    def __init__ (self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name="TrigEnable",
            description='TriggerEnable',
            offset=0x00,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="EmuSamplesRaw",
            description='Data Size In 32-bit Words',
            hidden=True,
            offset=0x04,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        @self.linkedGet(dependencies=[self.EmuSamplesRaw])
        def EmuSamples():
            return self.dependencies[0].value() * 4 + 2

        self.add(pr.RemoteVariable(
            name="TrigCount",
            description='Trigger Counter',
            offset=0x0C,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="AckCount",
            description='Ack Counter',
            offset=0x10,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TiDataCount",
            description='Trigger Data Counter',
            offset=0x14,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BusyCount",
            description='Busy Counter',
            offset=0x18,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="PauseStatus",
            description='Pause Status',
            offset=0x1C,
            bitSize=1,
            bitOffset=0,
            base=pr.Bool))

        self.add(pr.RemoteVariable(
            name="EmulateEn",
            description='Enable Emulation',
            offset=0x20,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="TrigOverFlow",
            description='Trigger Over Flow',
            offset=0x24,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BlockCount",
            description='Data Path Block Count',
            offset=0x28,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="EventCount",
            description='Data path Event Count',
            offset=0x2C,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="EvenState",
            description='Event State',
            offset=0x30,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="RocId",
            description='ROC ID',
            offset=0x34,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="BlockLevel",
            description='Block Level',
            offset=0x38,
            bitSize=32,
            bitOffset=0,
            base=pr.UInt,
            disp='{:#d}'))
