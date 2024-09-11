import pyrogue
import pyrogue.pydm
import rogue

pyrogue.addLibraryPath(f'../../firmware/common/tracker/python')
pyrogue.addLibraryPath(f'../../firmware/common/tdaq/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/surf/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/axi-pcie-core/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/lcls-timing-core/python')

import ldmx_tracker

rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)

parser = ldmx_tracker.TrackerPciePgpFcArgParser()
args = parser.parse_args()

with ldmx_tracker.TrackerPciePgpFcRoot(**vars(args)) as root:
    pyrogue.pydm.runPyDM(
        serverList = root.zmqServer.address,
        title='PgpFc')
