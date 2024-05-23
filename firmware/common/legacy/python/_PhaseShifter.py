import pyrogue as pr



class PhaseShifter(pr.Device):
    def __init__(self, clocks=4, **kwargs):
        super().__init__(**kwargs)

        self.addRemoteVariables(
            number=4,
            stride=4,
            name="PhaseShiftRaw",
            offset=0x00,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            minimum=0,
            maximum=511)

        for i in range(clocks):
            self.add(pr.LinkVariable(
                name=f'PhaseShift[{i}]',
                description='Clock phase delday',
                mode='RO',
                units='ns',
                dependencies=[self.PhaseShiftRaw[i]],
                linkedGet=lambda raw=self.PhaseShiftRaw[i]: raw.value() * 0.125))

        self.add(pr.RemoteCommand(
            name='ApplyConfig',
            offset=0x10,
            bitSize=1,
            bitOffset=0,
            base=pr.UInt,
            hidden=True,
            function=pr.BaseCommand.touchOne))

    def writeBlocks(self, **kwargs):
        #Check if there are stale blocks
        #print(f'{self.path}.writeBlocks()')
        #stale = any(b.stale for b in self._blocks)
        pr.Device.writeBlocks(self, **kwargs)
        self.ApplyConfig()
