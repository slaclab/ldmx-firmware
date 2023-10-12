'''Script that periodically queries several PGP2FC registers on a per-link basis to determine the interface's health status.'''

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
class PgpLaneHealthCheckerParser(ldmx.TrackerPciePgpFcArgParser):
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
            "--rstCnt",
            action = 'store_true',
            default = False)


#######################
# Board handling class
#######################
class BoardHandler():
    def __init__(self, board, args):
        # arguments
        self.board = board
        self.args  = args

        # variables
        self.lanes            = []
        self.quads            = []
        self.lockFlags        = []
        self.rxClkFreqs       = []
        self.retryCnts        = []
        self.rxLocalLinkReady = []
        self.rxRemLinkReady   = []
        self.rxCellErrorCnts  = []
        self.rxLinkDownCnts   = []
        self.rxLinkErrorCnts  = []

        # internal stuff
        self._formatDigits = 0
        self._format       = None

    def cntReset(self):
        if self.args.rstCnt:
            print("Resetting...please make sure you wait long enough in-between readouts.")
            for quad in range(args.numLanes):
                for lane in range(4):
                    self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RstRetryCnt.set(1)
                    self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi.CountReset.set(1)

    def statusParser(self):
        for quad in range(args.numLanes):
            for lane in range(4):
                # Quad/Lane Enumeration
                self.quads.append(quad)
                self.lanes.append(lane)

                # Align Checker
                self.lockFlags.append(self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.Locked.get())
                self.rxClkFreqs.append(round((self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RxClkFreqRaw.get())*1.0e-6, 5))
                self.retryCnts.append(self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck.RetryCnt.get())

                # PgpMon
                self.rxLocalLinkReady.append(self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi.RxLocalLinkReady.get())
                self.rxRemLinkReady.append(self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi.RxRemLinkReady.get())
                self.rxCellErrorCnts.append(self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi.RxCellErrorCount.get())
                self.rxLinkDownCnts.append(self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi.RxLinkDownCount.get())
                self.rxLinkErrorCnts.append(self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi.RxLinkErrorCount.get())

    def _formatter(self):
        self._formatDigits = len(str(max(self.retryCnts + self.rxClkFreqs + self.rxCellErrorCnts + self.rxLinkDownCnts + self.rxLinkErrorCnts)))
        self._format = 'Quad = {0:<%d} Lane = {1:<%d} RxClkFreq = {2:<%d} MHz AlignerRetryCnt = {3:<%d} AlignerLocked = {4:<%d} LocalLinkReady = {5:<%d} RemLinkReady = {6:<%d} RXLinkErrorCnt = {7:<%d}' % (1, 1, self._formatDigits, self._formatDigits, 1, 1, 1, self._formatDigits)

    def statusPrinter(self):
        self._formatter()
        system('clear')
        for i in range(len(self.lockFlags)):
            print(self._format.format(self.quads[i], self.lanes[i], '{0:.5f}'.format(self.rxClkFreqs[i]), self.retryCnts[i], self.lockFlags[i], self.rxLocalLinkReady[i], self.rxRemLinkReady[i], self.rxLinkErrorCnts[i]))

    def _clearAll(self):
        self.lanes.clear()
        self.quads.clear()
        self.lockFlags.clear()
        self.rxClkFreqs.clear()
        self.retryCnts.clear()
        self.rxLocalLinkReady.clear()
        self.rxRemLinkReady.clear()
        self.rxCellErrorCnts.clear()
        self.rxLinkDownCnts.clear()
        self.rxLinkErrorCnts.clear()

    def _doAll(self):
        self.statusParser()
        self.statusPrinter()
        self.cntReset()
        self._clearAll()


parser = PgpLaneHealthCheckerParser()
args = parser.parse_args()

with ldmx.TrackerPciePgpFcRoot(dev=args.dev, sim=args.sim, numLanes=args.numLanes) as root:
    handler = BoardHandler(board=root, args=args)

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
