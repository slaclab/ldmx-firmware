import pyrogue
import pyrogue.pydm
import rogue

#pyrogue.addLibraryPath(f'../python/')
pyrogue.addLibraryPath(f'../../firmware/common/tracker/python')
pyrogue.addLibraryPath(f'../../firmware/common/tdaq/python')
pyrogue.addLibraryPath(f'../../firmware/common/ts/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/surf/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/axi-pcie-core/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/lcls-timing-core/python')

import ldmx_ts

#rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)
#rogue.Logging.setFilter('pyrogue.stream.TcpCore', rogue.Logging.Debug)

rogue.Logging.setLevel(rogue.Logging.Debug)
 
# parser = ldmx_tracker.FcHubArgParser()
# args = parser.parse_args()

with ldmx_ts.S30xlAPxRoot(sim=True, pollEn=False) as root:
    pyrogue.pydm.runPyDM(
        serverList = root.zmqServer.address,
        title='S30XL')

