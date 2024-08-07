#Define target output
target: bit
#Define Firmware Version: V0.1.0.0
export PRJ_VERSION = 0x00010000

#Define target part
export PRJ_PART = xck26-sfvc784-2lv-c

#Define the TOP_DIR path (point to location of the firmware/ directory)
export TOP_DIR = $(abspath $(PWD)/../../)

export GEN_XSA_IMAGE = 1

#Using XVC Debug bridge
export USE_XVC_DEBUG = 0

#Setup for releases.yaml
export RELEASE = simple_ruckus

#Use top level makefile
include ../../submodules/ruckus/system_vivado.mk
