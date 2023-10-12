'''Script that periodically queries the GtRxAlignCheck module registers across the lanes.'''

import pyrogue
import rogue
import argparse
import sys
import time
from os import system

#pyrogue.addLibraryPath(f'../python/')
pyrogue.addLibraryPath(f'../../firmware/common/python/')
pyrogue.addLibraryPath(f'../../firmware/submodules/surf/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/axi-pcie-core/python')

import ldmx

rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)

# inherit everything from the original parser and add a couple more stuff
class PgpLaneAlignCheckerParser(ldmx.TrackerPciePgpFcArgParser):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # Add arguments
        self.add_argument(
            "--sleepTime",
            "-s",
            type     = int,
            required = False,
            default  = 2,
            help     = "How many seconds to sleep between polling intervals.",
        )

parser = PgpLaneAlignCheckerParser()
args = parser.parse_args()

with ldmx.TrackerPciePgpFcRoot(dev=args.dev, sim=args.sim, numLanes=args.numLanes) as root:
    pgpFc = root.PgpFc

    while True:
        try:
            system('clear')
            for quad in range(args.numLanes):
                for lane in range(4):
                    locked       = pgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.Locked.get()
                    rxClkFreqRaw = pgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RxClkFreqRaw.get()
                    # formatting into a string retains the trailing zeros thus resulting in a justified printout
                    rxClkFreq    = '{:.5f}'.format(round(rxClkFreqRaw * 1.0e-6, 5))

                    print(f"Quad = {quad} Lane = {lane}, RxClkFreq = {rxClkFreq} MHz, Locked = {locked}")
            time.sleep(args.sleepTime)
        except KeyboardInterrupt:
            print("")
            print("Exited.")
            sys.exit()
