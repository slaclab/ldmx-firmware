#-----------------------------------------------------------------------------
# This file is part of the 'LDMX'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'LDMX', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

class SyntheticTrigger(pr.Device):
    def __init__( self,**kwargs):
        super().__init__(**kwargs)


        self.add(pr.RemoteVariable(
            name         = 'EnableRoR',
            description  = 'If True, RoR Period Counter increments every 5 cycles, and RoRs are being sent',
            offset       = 0x04,
            bitSize      = 1,
            mode         = 'RW',
            base         = pr.Bool,
        ))

        self.add(pr.RemoteCommand(
            name         = 'UsrRoR',
            description  = 'Sends a single RoR for every False-to-True transition',
            offset       = 0x00,
            bitSize      = 1,
            # Set to WO to avoid errors of read mismatch due to firmware forcing reg to zero to do a strobe
            function = pr.Command.touchOne
        ))


        self.add(pr.RemoteVariable(
            name         = 'RoRperiod',
            description  = 'Read-Out-Req period (in units of BunchCntPeriod period',
            offset       = 0x08,
            bitSize      = 32,
            mode         = 'RW',
        ))
