import pyrogue as pr

import surf.xilinx
import pyrogue.interfaces.simulation
import rogue.interfaces.memory as rim

class PhaseShift(pr.Device):
    def __init__(self, *, rx, offset, **kwargs):
        super().__init__(**kwargs)

        VCO_PERIOD = 26.923e-9 / 32

        self.delays = [0 for x in range(4)]

        self.rx = rx

        self.add(surf.xilinx.ClockManager(
            name = 'CM',
            offset = offset,
            hidden = False,
            type = 'MMCME4'))        


        for i in range(4):
            self.add(pr.LinkVariable(
                name = f'PhaseShiftRaw[{i}]',
                variable = self.CM.DELAY_TIME[i],
                dependencies = [self.CM.DELAY_TIME[i]],
                disp = '{:d}'))

        for i in range(4):
            self.add(pr.LinkVariable(
                name = f'PhaseShift[{i}]',
                units = 'nS',
                dependencies = [self.PhaseShiftRaw[i]],
                linkedGet = lambda read, x=i: self.PhaseShiftRaw[x].get(read=read) * VCO_PERIOD * 1e9,
                linkedSet = lambda value, write, x=i: self.PhaseShiftRaw[x].set(int(value / 1e9 / VCO_PERIOD), write=write)))

        # Monkey patch a new writeBlocks into CM Device
        self.CM.writeBlocks = self._writeBlocks

    def _writeBlocks(self, variable, **kwargs):
        # Handle POWER with normal writeBlocks to avoid infinite recursion
        if variable is not None and variable.name == 'POWER':
            super().writeBlocks(variable=variable)
        else:
            # Pull CM reset high
            self.rx.FcClkRst.set(1)

            # Set POWER register for reprogramming
            self.CM.POWER.set(0xFFFF)

            # Write the blocks in hardware (other than POWER)
            if variable is not None:
                pr.startTransaction(variable._block, type=rim.Write, variable=variable, **kwargs)
            else:
                for block in self.CM._blocks:
                    if block.bulkOpEn:
                        pr.startTransaction(block, type=rim.Write, **kwargs)

            # Bring CM reset back low
            self.rx.FcClkRst.set(0)

