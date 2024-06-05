import pyrogue as pr

import surf.devices.analog_devices

class AdcConfig(pr.Device):
    def __init__(self, numAdcs, **kwargs):
        super().__init__(**kwargs)

        for i in range(numAdcs):
            self.add(surf.devices.analog_devices.Ad9249Config(
                name = f'Ad9249Config[{i}]',
                chips = 1,
                offset = i * 0x2000))
            
