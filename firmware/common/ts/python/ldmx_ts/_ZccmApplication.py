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

class ZccmApplication(pr.Device):
    def __init__(self,**kwargs):
        super().__init__(**kwargs)

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
