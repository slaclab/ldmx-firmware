import pyrogue
import pyrogue.pydm
import rogue

#pyrogue.addLibraryPath(f'../python/')
pyrogue.addLibraryPath(f'../../firmware/common/python/')
pyrogue.addLibraryPath(f'../../firmware/submodules/surf/python')

import ldmx

rogue.Logging.setFilter('pyrogue.SrpV3', rogue.Logging.Debug)

with ldmx.HpsFebRoot() as root:
    pyrogue.pydm.runPyDM(root=root, title='HpsFeb')
    pyrogue.waitCntrlC()
