import pyrogue as pr


class SampleExtractor(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="SampleExtractor Object.", **kwargs)


        self.add(pr.RemoteVariable(
            name="TxStates",
            offset=0x00,
            bitSize=2,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO',
            enum={
                0:'WAIT_TRIGGER_S',
                1:'BLANK_HEAD_S',
                2:'TAIL_S',
                3:'DATA_S'}))

        self.add(pr.RemoteVariable(
            name="TriggersOut",
            offset=0x04,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="TriggersIn",
            offset=0x04,
            bitSize=16,
            bitOffset=16,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="NormalHeads",
            offset=0x08,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="TotalTails",
            offset=0x0C,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="BlankHeads",
            offset=0x0C,
            bitSize=16,
            bitOffset=16,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SofIn",
            offset=0x10,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="EofIn",
            offset=0x14,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="EofeIn",
            offset=0x18,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="RxStates",
            offset=0x1C,
            bitSize=3,
            bitOffset=0,
            base=pr.UInt,
            enum={
                0:'RUN_S',
                1:'INSERT_S',
                2:'TAIL_S',
                3:'RESUME_S',
                4:'FREEZE_S'},
            mode = 'RO'))

        self.addRemoteVariables(
            number=8,
            stride=2,
            name="LastSofApvFrameRaw",
            hidden=True,
            offset=0x20,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO')

        def getSof(rawVar,bit=8,mask=1):
            def convert():
                raw = (rawVar.value()) >>bit & mask
                return f'{(raw>>13)&0x7} {(raw>>9)&0xF}  {(raw>>1)&0xFF:#x} {raw&0x1:#x}'
            return convert

        for i in range(8):
            self.add(pr.LinkVariable(
                name=f'LastSofApvFrame[{i}]',
                units='ns',
                linkedGet=getSof(self.LastSofApvFrameRaw[i]),
                dependencies=[self.LastSofApvFrameRaw[i]]))

        self.addRemoteVariables(
            number=16,
            stride=2,
            name="InsertedFrames",
            offset=0x30,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO')

        self.add(pr.RemoteVariable(
            name="SgRxRamWrAddr",
            offset=0x50,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgRxSofAddr",
            offset=0x54,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgRxWordCount",
            offset=0x58,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgRxFrameNumber",
            offset=0x5C,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgRxError",
            offset=0x5C,
            bitSize=1,
            bitOffset=31,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgTxRamRdAddr",
            offset=0x60,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgTxWordCount",
            offset=0x64,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgTxFrameNumber",
            offset=0x68,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgLongWords",
            offset=0x6C,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgLongWordCount",
            offset=0x70,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgBadWords",
            offset=0x74,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))

        self.add(pr.RemoteVariable(
            name="SgBadWordCount",
            offset=0x78,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            mode = 'RO'))
