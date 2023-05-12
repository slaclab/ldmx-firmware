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

class FcEmu(pr.Device):
    def __init__( self,**kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name         = 'EnableTimingMsg',
            description  = 'If True, Timing Msg Period Counter increments and FC Timing Messages are being sent',
            offset       = 0x000,
            bitSize      = 1,
            mode         = 'RW',
            base         = pr.Bool,
        ))

        self.add(pr.RemoteVariable(
            name         = 'EnableRoR',
            description  = 'If True, RoR Period Counter increments every 5 cycles, and RoRs are being sent',
            offset       = 0x004,
            bitSize      = 1,
            mode         = 'RW',
            base         = pr.Bool,
        ))

        self.add(pr.RemoteVariable(
            name         = 'UsrRoR',
            description  = 'Sends a single RoR for every False-to-True transition',
            offset       = 0x008,
            bitSize      = 1,
            # Set to WO to avoid errors of read mismatch due to firmware forcing reg to zero to do a strobe
            mode         = 'WO',
            base         = pr.Bool,
        ))

        self.add(pr.RemoteVariable(
            name         = 'PulseIDinit',
            description  = 'Set pulseID initial value. Being registered when Timing Messages are disabled',
            offset       = 0x00C,
            bitSize      = 64,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'BunchCntInit',
            description  = 'Set Bunch Count initial value. Being registered when a RoR is TX\'d, or if RoRs are disabled',
            offset       = 0x014,
            bitSize      = 5,
            mode         = 'RW',
        ))

        # self.add(pr.RemoteVariable(
        #     name         = 'TimingMsgPeriodSet',
        #     description  = 'FC Timing Message period (in units of timing clk period). [WARNING]: Only registered if firmware generic is set to override firmware default value of 200.',
        #     offset       = 0x018,
        #     bitSize      = 32,
        #     mode         = 'RW',
        # ))

        # self.add(pr.RemoteVariable(
        #     name         = 'BunchCntPeriodSet',
        #     description  = 'Bunch Count period (in units of timing clk period). [WARNING]: Only registered if firmware generic is set to override firmware default value of 5.',
        #     offset       = 0x01C,
        #     bitSize      = 5,
        #     mode         = 'RW',
        # ))

        self.add(pr.RemoteVariable(
            name         = 'FCrunStateSet',
            description  = 'Next FC Message Run State set value (subsequent messages retain this state)',
            offset       = 0x020,
            bitSize      = 5,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'RoRperiod',
            description  = 'Read-Out-Req period (in units of BunchCntPeriod*timing clk period. default is 5*timing clk period)',
            offset       = 0x024,
            bitSize      = 32,
            mode         = 'RW',
        ))
