'''
Script that periodically queries several PGP2FC registers on a per-link basis to determine the interface's health status.
The script can also perform PRBS checks on all lanes.
'''

import pyrogue
import rogue
import argparse
import sys
import time
from os import system

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


####################################################################################################
# Board handling class
####################################################################################################
class BoardHandler():
    def __init__(self, board, args):
        # arguments
        self.board = board
        self.args  = args

        # nodes and variables
        self.lanes            = []
        self.quads            = []

        self.alignChecker     = []
        self.lockFlag         = []
        self.rxClkFreq        = []
        self.retryCnt         = []

        self.pgpMon           = []
        self.rxLocalLinkReady = []
        self.rxRemLinkReady   = []
        self.rxCellErrorCnt   = []
        self.rxLinkDownCnt    = []
        self.rxLinkErrorCnt   = []

        # PRBS
        self.prbsRx       = []
        self.prbsTx       = []
        self.prbsRxErrors = []
        self.prbsRxCnts   = []

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

    def alignStatusParser(self):
        for quad in range(args.numLanes):
            for lane in range(4):
                # Quad/Lane Enumeration
                self.quads.append(quad)
                self.lanes.append(lane)

                # Align Checker
                self.alignCheckerAppend(quad=quad, lane=lane)

                # PgpMon
                self.pgpMonAppend(quad=quad, lane=lane)

    def prbsParser(self):
        for quad in range(args.numLanes):
            for lane in range(4):
                # Quad/Lane Enumeration
                self.quads.append(quad)
                self.lanes.append(lane)

                # PgpMon
                self.pgpMonAppend(quad=quad, lane=lane)

                # PRBS
                self.prbsAppend(quad=quad, lane=lane)

    def alignCheckerAppend(self, quad, lane):
        self.alignChecker.append(self.board.PgpFc.PgpLane[quad][lane].PgpFcGtyCoreWrapper.GtRxAlignCheck)

    def alignCheckerRead(self):
        for alignCheckerNode in range(len(self.alignChecker)):
            self.lockFlag.append(self.alignChecker[alignCheckerNode].Locked.get())
            self.rxClkFreq.append(round((self.alignChecker[alignCheckerNode].RxClkFreqRaw.get())*1.0e-6, 5))
            self.retryCnt.append(self.alignChecker[alignCheckerNode].RetryCnt.get())

    def pgpMonAppend(self, quad, lane):
        self.pgpMon.append(self.board.PgpFc.PgpLane[quad][lane].Pgp2fcAxi)

    def pgpMonRead(self):
        for pgpMonNode in range(len(self.pgpMon)):
            self.rxLocalLinkReady.append(self.pgpMon[pgpMonNode].RxLocalLinkReady.get())
            self.rxRemLinkReady.append(self.pgpMon[pgpMonNode].RxRemLinkReady.get())
            self.rxCellErrorCnt.append(self.pgpMon[pgpMonNode].RxCellErrorCount.get())
            self.rxLinkDownCnt.append(self.pgpMon[pgpMonNode].RxLinkDownCount.get())
            self.rxLinkErrorCnt.append(self.pgpMon[pgpMonNode].RxLinkErrorCount.get())

    def prbsAppend(self, quad, lane):
        self.prbsRx.append(self.board.prbsRx[quad][lane])
        self.prbsTx.append(self.board.prbsTx[quad][lane])

    def _prbsEnableTx(self):
        for prbsNode in range(len(self.prbsTx)):
            self.prbsTx[prbsNode].txEnable.set(1)

    def _prbsReadRx(self):
        for prbsNode in range(len(self.prbsRx)):
            self.prbsRxErrors.append(self.prbsRx[prbsNode].rxErrors.get())
            self.prbsRxCnts.append(self.prbsRx[prbsNode].rxCount.get())

    def _alignStatusFormatter(self):
        self._formatDigits = len(str(max(self.rxClkFreq + self.retryCnt + self.rxLinkErrorCnt)))
        self._format = 'Quad = {0:<%d} Lane = {1:<%d} RxClkFreq = {2:<%d} MHz AlignerRetryCnt = {3:<%d} AlignerLocked = {4:<%d} LocalLinkReady = {5:<%d} RemLinkReady = {6:<%d} RXLinkErrorCnt = {7:<%d}' % (1, 1, self._formatDigits, self._formatDigits, 1, 1, 1, self._formatDigits)

    def _prbsStatusFormatter(self):
        self._formatDigits = len(str(max(self.prbsRxErrors + self.prbsRxCnts)))
        self._format = 'Quad = {0:<%d} Lane = {1:<%d} AlignerLocked = {2:<%d} LocalLinkReady = {3:<%d} RemLinkReady = {4:<%d} PrbsRxCnts = {5:<%d} PrbsRxErrors = {6:<%d}' % (1, 1, 1, 1, 1, self._formatDigits, self._formatDigits)

    def _alignStatusPrinter(self):
        self._alignStatusFormatter()
        system('clear')
        for i in range(len(self.quads)):
            print(self._format.format(self.quads[i], self.lanes[i], '{0:.5f}'.format(self.rxClkFreq[i]), self.retryCnt[i], self.lockFlag[i], self.rxLocalLinkReady[i], self.rxRemLinkReady[i], self.rxLinkErrorCnt[i]))

    def _prbsStatusPrinter(self):
        self._prbsStatusFormatter()
        system('clear')
        for i in range(len(self.quads)):
            print(self._format.format(self.quads[i], self.lanes[i], self.lockFlag[i], self.rxLocalLinkReady[i], self.rxRemLinkReady[i], self.prbsRxCnts[i], self.prbsRxErrors[i]))

    def _clearAll(self):
        self.lanes.clear()
        self.quads.clear()
        self.alignChecker.clear()
        self.lockFlag.clear()
        self.rxClkFreq.clear()
        self.retryCnt.clear()
        self.pgpMon.clear()
        self.rxLocalLinkReady.clear()
        self.rxRemLinkReady.clear()
        self.rxCellErrorCnt.clear()
        self.rxLinkDownCnt.clear()
        self.rxLinkErrorCnt.clear()
        self.prbsRx.clear()
        self.prbsTx.clear()
        self.prbsRx.clear()
        self.prbsTx.clear()
        self.prbsRxErrors.clear()
        self.prbsRxCnts.clear()

    def _doAllChecks(self):
        self.alignStatusParser()
        self.alignCheckerRead()
        self.pgpMonRead()
        self._alignStatusPrinter()
        self.cntReset()
        self._clearAll()

    def _doAllPrbs(self):
        self.prbsParser()
        self._prbsEnableTx()
        self.pgpMonRead()
        self._prbsReadRx()
        self._prbsStatusPrinter()
        self._clearAll()

####################################################################################################

parser = PgpLaneHealthCheckerParser()
args = parser.parse_args()

with ldmx.TrackerPciePgpFcRoot(dev=args.dev, sim=args.sim, prbsEn=args.prbsEn, numLanes=args.numLanes) as root:
    handler = BoardHandler(board=root, args=args)

    if args.oneRead:
        handler._doAllChecks()
    else:
        while True:
            try:
                if args.prbsEn:
                    print("Performing PRBS checks...")
                    handler._doAllPrbs()
                else:
                    handler._doAllChecks()

                time.sleep(args.sleepTime)

            except KeyboardInterrupt:
                print("")
                print("Exited.")
                sys.exit()
