import pyrogue
import pyrogue.pydm
import rogue

#pyrogue.addLibraryPath(f'../python/')
pyrogue.addLibraryPath(f'../../firmware/common/python/')
pyrogue.addLibraryPath(f'../../firmware/submodules/surf/python')
pyrogue.addLibraryPath(f'../../firmware/submodules/axi-pcie-core/python')

import ldmx

rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)

parser = ldmx.TrackerPcieAlveoArgParser()
args = parser.parse_args()

with ldmx.PgpLaneTb(pollEn=False) as root:
    pyrogue.pydm.runPyDM(root=root, title='Alveo', )

