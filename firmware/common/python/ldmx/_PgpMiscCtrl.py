
import pyrogue as pr
import ldmx

class PgpMiscCtrl(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name = 'GtDrpOverride',
            offset = 0x68,
            bitOffset = 0,
            bitSize = 1,
            base = pr.Bool))

        self.add(pr.RemoteVariable(
            name = 'TxDiffCtrl',
            offset = 0x6C,
            bitOffset = 0,
            bitSize = 4))

        self.add(pr.RemoteVariable(
            name = 'TxPreCursor',
            offset = 0x70,
            bitOffset = 0,
            bitSize = 5))

        self.add(pr.RemoteVariable(
            name = 'TxPostCursor',
            offset = 0x74,
            bitOffset = 0,
            bitSize = 5))

        self.add(pr.RemoteVariable(
            name = 'QPllRxSelect',
            offset = 0x78,
            bitOffset = 0,
            bitSize = 2))
        
        self.add(pr.RemoteVariable(
            name = 'QPllTxSelect',
            offset = 0x7C,
            bitOffset = 0,
            bitSize = 2))

        self.add(pr.RemoteCommand(
            name = 'TxUserReset',
            offset = 0x80,
            bitOffset = 0,
            bitSize = 1,
            function = pr.BaseCommand.toggle))

        self.add(pr.RemoteCommand(
            name = 'RxUserReset',
            offset = 0x84,
            bitOffset = 0,
            bitSize = 1,
            function = pr.BaseCommand.toggle))
