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

##########################################################################
# inherit everything from the original parser and add a couple more stuff
##########################################################################
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
            help     = "How many seconds to sleep between polling intervals. Important to set this \
                        value to at least 8 if resetting the retry counter in-between multiple \
                        readouts. Value is irrelevant if oneRead flag is set to True.",
        )

        self.add_argument(
            "--oneRead",
            action = 'store_true',
            default = False)

        self.add_argument(
            "--rstRetryCnt",
            action = 'store_true',
            default = False)


#########################
# Bittware handling class
#########################
class BittwareHandler():
    def __init__(self, board, args):
        # arguments
        self.board         = board
        self.args          = args

        # variables
        self.lanes         = []
        self.quads         = []
        self.lockFlags     = []
        self.rxClkFreqs    = []
        self.retryCnts     = []
        self._formatDigits = 0
        self._format       = None

    def cntReset(self):
        if self.args.rstRetryCnt:
            print("Resetting...please make sure you wait long enough in-between readouts.")
            for quad in range(args.numLanes):
                for lane in range(4):
                    self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RstRetryCnt.set(1)

    def statusParser(self):
        for quad in range(args.numLanes):
            for lane in range(4):
                self.quads.append(quad)
                self.lanes.append(lane)

                self.lockFlags.append(self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.Locked.get())

                self.rxClkFreqs.append(round((self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RxClkFreqRaw.get())*1.0e-6, 5))

                self.retryCnts.append(self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RetryCnt.get())

    def _formatter(self):
        self._formatDigits = len(str(max(self.retryCnts + self.rxClkFreqs)))
        self._format = 'Quad = {0:<%d}, Lane = {1:<%d}, RxClkFreq = {2:<%d} MHz, RetryCnt = {3:<%d}, Locked = {4:<%d}' % (1, 1, self._formatDigits, self._formatDigits, 1)

    def statusPrinter(self):
        self._formatter()
        system('clear')
        for i in range(len(self.lockFlags)):
            print(self._format.format(self.quads[i], self.lanes[i], '{0:.5f}'.format(self.rxClkFreqs[i]), self.retryCnts[i], self.lockFlags[i]))

    def _clearAll(self):
        self.lanes.clear()
        self.quads.clear()
        self.lockFlags.clear()
        self.rxClkFreqs.clear()
        self.retryCnts.clear()

    def _doAll(self):
        self.statusParser()
        self.statusPrinter()
        self.cntReset()
        self._clearAll()


parser = PgpLaneAlignCheckerParser()
args = parser.parse_args()

with ldmx.TrackerPciePgpFcRoot(dev=args.dev, sim=args.sim, numLanes=args.numLanes) as root:
    handler = BittwareHandler(board=root, args=args)

    if args.oneRead is True:
        handler._doAll()
    else:
        while True:
            try:
                handler._doAll()
                time.sleep(args.sleepTime)
            except KeyboardInterrupt:
                print("")
                print("Exited.")
                sys.exit()
