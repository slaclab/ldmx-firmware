import pyrogue as pr


class HybridSyncStatus(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(description="Synchronziation status for 1 Hybrid.", **kwargs)

        self.add(pr.RemoteVariable(
            name="SyncDetected",
            offset=0x00,
            bitSize=5,
            bitOffset=0,
            mode='RO',
            pollInterval=3,
            base=pr.UInt))

        def onesCount(rawVar):
            def convert():
                tmp = rawVar.value()
                ones = 0
                while tmp:
                    ones+=1
                    tmp=tmp & (tmp-1)
                return ones
            return convert

        self.add(pr.LinkVariable(
            name="SyncedCount",
            value = 0,
            description='Indicates how many APVs have established sync',
            linkedGet= lambda: (f'{self.SyncDetected.value():b}').count('1'),
            dependencies=[self.SyncDetected]))

        for i in range(5):
            self.add(pr.RemoteVariable(
                name=f"Base[{i}]",
                offset=0x10+ i*4,
                bitSize=16,
                bitOffset=0,
                mode='RO',
                pollInterval=5,
                base=pr.UInt))

        for i in range(5):
            self.add(pr.RemoteVariable(
                name=f"Peak[{i}]",
                offset=0x10+ i*4,
                bitSize=16,
                bitOffset=16,
                mode='RO',
                pollInterval=5,
                base=pr.UInt))


        self.addRemoteVariables(
            number=5,
            stride=4,
            name="FrameCount",
            offset=0x30,
            bitSize=16,
            bitOffset=0,
            disp = '{:d}',
            mode='RO',
            base=pr.UInt)

        self.add(pr.RemoteVariable(
            name='LatchPulseStream',
            description = 'Reading this variable latches all off the pulse streams',
            offset = 0x50,
            mode='RO',
            hidden='True'))

        self.addRemoteVariables(
            number=5,
            stride=8,
            name="PulseStream",
            offset=0x60,
            bitSize=64,
            bitOffset=0,
            mode='RO',
            disp='{:064b}',
            pollInterval=0,
            base=pr.UInt)

        self.addRemoteVariables(
            number=5,
            stride=4,
            name = 'LostSyncCount',
            offset = 0x90,
            disp = '{:d}')

        for i in range(5):
            self.add(pr.RemoteVariable(
                name=f"MinSample[{i}]",
                offset=0xB0+ i*4,
                bitSize=16,
                bitOffset=0,
                mode='RO',
                pollInterval=0,
                base=pr.UInt))

        for i in range(5):
            self.add(pr.RemoteVariable(
                name=f"MaxSample[{i}]",
                offset=0xB0+ i*4,
                bitSize=16,
                bitOffset=16,
                mode='RO',
                pollInterval=0,
                base=pr.UInt))

        self.add(pr.RemoteCommand(
            name = 'CountReset',
            offset = 0xD0,
            bitOffset = 0,
            bitSize = 1,
            function = pr.RemoteCommand.touchOne))

    def countReset(self):
        self.CountReset()
