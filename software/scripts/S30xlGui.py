import pyrogue
import pyrogue.pydm
import rogue

import argparse

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

#rogue.Logging.setLevel(rogue.Logging.Debug)
 
# parser = ldmx_tracker.FcHubArgParser()
# args = parser.parse_args()
parser = argparse.ArgumentParser()


parser.add_argument(
    "--sim",
    action = 'store_true',
    default = False)

parser.add_argument(
    "--host",
    type     = str,
    required = False,
    default = '192.168.10.10',
    help     = "IP address")

parser.add_argument(
    "--pollEn",
    type = bool,
    required = False,
    default = False,
    help = 'Enable or disable polling on startup')

parser.add_argument(
    "--initRead",
    type = bool,
    required = False,
    default = False,
    help = 'Enable or disable read of all register on startup')

args = parser.parse_known_args()[0]
print(args)

with ldmx_ts.S30xlAPxRoot(**vars(args)) as root:
    pyrogue.pydm.runPyDM(
        serverList = root.zmqServer.address,
        title='S30XL')

