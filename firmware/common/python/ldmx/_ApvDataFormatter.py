import pyrogue as pr
import surf.axi

class ApvDataFormatter(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(surf.axi.AxiStreamScatterGather(
            enabled=False,
            expand=False,
            offset = 0x100))

        self.add(pr.RemoteVariable(
            name='TxState',
            mode = 'RO',
            offset = 0x00,
            bitSize = 2,
            enum = {
                0b00: 'WAIT_TRIGGER_S',
                0b01: 'BLANK_HEAD_S',
                0b10: 'TAIL_S',
                0b11: 'DATA_S'}))

        self.add(pr.RemoteVariable(
            name = 'TriggersOut',
            mode = 'RO',
            offset = 0x04,
            bitSize = 16,
            bitOffset = 0,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'TriggersIn',
            mode = 'RO',
            offset = 0x04,
            bitSize = 16,
            bitOffset = 16,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'NormalHeads',
            mode = 'RO',
            offset = 0x08,
            bitSize = 16,
            bitOffset = 0,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'TotalTails',
            mode = 'RO',
            offset = 0x0C,
            bitSize = 16,
            bitOffset = 0,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'BlankHeads',
            mode = 'RO',
            offset = 0x0C,
            bitSize = 16,
            bitOffset = 16,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'SofIn',
            mode = 'RO',
            offset = 0x10,
            bitSize = 32,
            bitOffset = 0,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'EofIn',
            mode = 'RO',
            offset = 0x14,
            bitSize = 32,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'EofeIn',
            mode = 'RO',
            offset = 0x18,
            bitSize = 32,
            disp = '{:d}'))

        self.add(pr.RemoteVariable(
            name = 'RxState',
            mode = 'RO',
            offset = 0x1C,
            bitSize = 3,
            bitOffset = 0,
            enum = {
                0b000: 'RUN_S',
                0b001: 'INSERT_S',
                0b010: 'TAIL_S',
                0b011: 'RESUME_S',
                0b100: 'FREEZE'}))

#         for i in range(8):
#             self.add(pr.RemoteVariable(
#                 name = f'LastSofApvFrameRaw[{i}]',
#                 mode = 'RO',
#                 offset = 0x24 + i*2,
#                 bitSize = 16,
#                 bitOffset = 0,
#                 hidden = True,
#                 disp = '{:#08x}'))

#         def formatSof(var):
#             raw = var.dependencies[0].value() & 0xFFFF
#             return f'{(raw>>13)&0x7} {(raw>>9)&0xF}  {(raw>>1)&0xFF:#x} {(raw&0x1)^1}'

#         for i in range(8):
#             self.add(pr.LinkVariable(
#                 name = f'LastSofApvFrame[{i}]',
#                 description = 'Apv frame header: APVNUM FRAMECOUNT BUFADDR ERROR',
#                 mode = 'RO',
#                 dependencies = [self.LastSofApvFrameRaw[i]],
#                 linkedGet = formatSof))


#         for i in range(8):
#             self.add(pr.RemoteVariable(
#                 name = f'LastTxnCount[{i}]',
#                 mode = 'RO',
#                 offset = 0x34 + i*2,
#                 bitSize = 16,
#                 disp = '{:d}'))

#         for i in range(16):
#             self.add(pr.RemoteVariable(
#                 name = f'InsertedFrames[{i}]',
#                 mode = 'RO',
#                 offset = 0x44 + i*2,
#                 bitSize = 16,
#                 disp = '{:d}'))
