import pyrogue as pr

import ldmx
import time

class FebCore(pr.Device):
    def __init__(self, number, numHybrids=1, **kwargs):
        super().__init__(description="Front End Board FPGA FPGA Object.", **kwargs)

        self.number = number

        # AXI Version
        self.add(axi.AxiVersion(
            expand=True,
            offset=0x0000))
        self.AxiVersion.UpTimeCnt.pollInterval = 3
        

        # Feb Config
        self.add(hps.FebConfig(
            offset=0x1000,
            defaults = {
                'FebAddress': str(number)}))

        # DAQ Timing
        self.add(ldmx.DaqTiming(
            offset=0x2000))

        # Event Builder
        self.add(ldmx.EventBuilder(
            offset = 0x3000))

        # Hybrids (I2C config)
        for i in range(numHybrids):
            self.add(hps.Hybrid(
                offset=0x00100000 + (i*0x10000),
                typeVar = self.FebConfig.HybridType[i],
                enableDeps=[self.FebConfig.HybridPwrEn[i]],
                name=f'Hybrid[{i}]'))



        for i in range(numHybrids):
            self.add(ldmx.HybridDataCore(
                name=f'HybridDataCore[{i}]',
                enabled = True,
                offset=0x01000000+(0x00100000*i)))





    def writeBlockss(self, force=False, recurse=True, variable=None, checkEach=False):
        print(f'{self.path}.writeBlocks()')
        super().writeBlocks(force, recurse, variable, checkEach)
        return

        # Make a copy of the device dict
        d = self.devices.copy()

        # Remove all the Hybrids from the copy
        for k, v in self.Hybrid.items():
            print(k, v)
            d.pop(v.name)

        # Write everything except the Hybrids
        for k, v in d.items():
            v.writeBlocks(force, recurse, variable, checkEach)

        # Sleep for some time if any of the hybrids are one
        if any((v.value() for v in self.FebConfig.HybridPwrEn.values())) and self.enable.value() is True:
            print('Sleeping')
            time.sleep(1.5)

        print(f'{self.path}.writeBlocks check blocks start')
        self.checkBlocks(recurse, variable)
        print(f'{self.path}.writeBlocks check blocks done')

        # Write the hybrids (will do nothing if not powered/disabled)
        print('Configure hybrids')
        for k, v in self.FebConfig.HybridPwrEn.items():
            self.Hybrid[k].writeBlocks(force, recurse, variable,checkEach)
