import pyrogue as pr


class StreamLogger(pr.Device):
    def __init__ (self,logsize=2048, **kwargs):
        super().__init__(description="StreamLogger Object.", **kwargs)

        self.add(pr.RemoteVariable(
            name="LogEn",
            offset=0x00,
            bitSize=1,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.RemoteVariable(
            name="FrameCount",
            offset=0x0C,
            bitSize=8,
            bitOffset=0,
            mode='RO',
            base=pr.UInt))

        self.add(pr.LocalVariable(
            name="ReadSize",
            value=logsize))

        def ReadLog():
            for i in range(self.ReadSize.value()):
                if i%30 == 0:
                    print('-------------')
                print(f'SOF: {i}')
                print(f'EOF: {self.Data.get()}')
                print(f'EOFE: {self.Data.get()}')
                print(f'Count: {self.Data.get()}')
                print(f'Header: {self.Data.get()}')
                print(f'Count: {self.Data.get()}')
                print(f'Addr: {self.Data.get()}')
                print('Error: ')

                #  Log" << setw(3) << setfill('0') << dec << i << hex <<
                # ", SOF: " << setw(1) << r->get(31, 0x1) <<
                # ", EOF: " << setw(1) << r->get(30, 0x1) <<
                # ", EOFE: " << setw(1) << r->get(29, 0x1) <<
                # ", Count: " << setw(4) << dec << r->get(16, 0x1FFF) <<
                # ", Header: Apv: " << setw(1) << hex << r->get(13, 0x7) <<
                # ", Count: " << setw(1) << hex << r->get(12, 0x1) << " " << r->get(9, 0x7) <<
                # ", Addr: " << setw(2) << hex << r->get(1, 0xFF) <<
                # ", Error: " << setw(1) << dec << (!r->get(0, 0x1)) << endl;

        self.add(pr.RemoteCommand(
            name="Data",
            offset=0x8,
            bitSize=32,
            function=ReadLog))
