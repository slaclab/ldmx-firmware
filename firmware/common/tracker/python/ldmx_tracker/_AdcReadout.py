import pyrogue as pr

import surf.devices.analog_devices

class AdcReadout(pr.Device):
    def __init__(self, numHybrids, **kwargs):
        super().__init__(**kwargs)

        for i in range(numHybrids):
            self.add(surf.devices.analog_devices.Ad9249ReadoutGroup2(
                name = f'Ad9249Readout[{i}]',
                offset = i * 0x100))
            
