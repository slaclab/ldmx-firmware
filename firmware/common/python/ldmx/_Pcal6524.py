import pyrogue as pr

class Pcal6524(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        for i in range(3):
            self.add(pr.RemoteVariable(
                name = f'InputPort[{i}]',
                mode = 'RO',
                offset = (0x00 + i) << 2,
                bitSize = 8))

        for i in range(3):
            self.add(pr.RemoteVariable(
                name = f'OutputPort[{i}]',
                mode = 'RW',
                offset = (0x04 + i) << 2,
                bitSize = 8))

        for i in range(3):
            self.add(pr.RemoteVariable(
                name = f'ConfigPort[{i}]',
                mode = 'RW',
                offset = (0x0C + i) << 2,
                bitSize = 8))

        for i in range(3):
            self.add(pr.RemoteVariable(
                name = f'Polarity[{i}]',
                mode = 'RW',
                offset = (0x08 + i) << 2,
                bitSize = 8))
