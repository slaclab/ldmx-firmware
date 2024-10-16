#-----------------------------------------------------------------------------
# This file is part of the 'Camera link gateway'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Camera link gateway', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

class LTC4331(pr.Device):
    def __init__(self,
                 description = "Container for xxx",
                 pollInterval = 1,
            **kwargs):
        super().__init__(description=description, **kwargs)

        self.addRemoteVariables(
            name         = 'SCRATCH',
            description  = 'Scratch register',
            offset       = (0x05<<2),
            bitSize      = 8,
            mode         = 'RW',
            number       = 1,
            stride       = 0,
            pollInterval = pollInterval
        )

class Si5344(pr.Device):
    def __init__(self,
                 description = "Container for xxx",
                 pollInterval = 1,
            **kwargs):
        super().__init__(description=description, **kwargs)

        self.addRemoteVariables(
            name         = 'PAGE',
            description  = 'Selects one of 256 possible pages',
            offset       = 0x1,
            bitSize      = 8,
            mode         = 'RW',
            number       = 1,
            stride       = 0,
            pollInterval = pollInterval
        )

        self.addRemoteVariables(
            name         = 'PN_BASE_LOWER',
            description  = 'lower 2 digits of part number',
            offset       = 0x2,
            bitSize      = 8,
            mode         = 'RO',
            number       = 1,
            stride       = 0,
            pollInterval = pollInterval
        )

        self.addRemoteVariables(
            name         = 'PN_BASE_UPPER',
            description  = 'upper 2 digits of part number',
            offset       = 0x3,
            bitSize      = 8,
            mode         = 'RO',
            number       = 1,
            stride       = 0,
            pollInterval = pollInterval
        )

class ZccmApplication(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

        # RM0 I2C extender
        self.add(LTC4331(
            name         = 'RM0_I2C_EXT',
            offset       = 0x3_8000,
            pollInterval = 0,
            hidden       = False,
        ))
        
        # synthesizing clock chip 
        self.add(Si5344(
            name         = 'SYNTH_I2C',
            offset       = 0x3_0000,
            pollInterval = 0,
            hidden       = False,
        ))

        # jitter cleaner clock chip 
        self.add(Si5344(
            name         = 'JITTER_I2C',
            offset       = 0x4_0000,
            pollInterval = 0,
            hidden       = False,
        ))
        
        self.add(pr.RemoteVariable(
            name         = 'input_register',
            offset       = 0xE_0000,
            bitSize      = 32,
            mode         = 'RW',
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'output_registerA',
            offset       = 0xE_0100,
            bitSize      = 32,
            mode         = 'RW',
            pollInterval = 1,
        ))

        
        self.add(pr.RemoteVariable(
            name         = 'output_registerB',
            offset       = 0xE_0104,
            bitSize      = 32,
            mode         = 'RW',
            pollInterval = 1,
        ))
