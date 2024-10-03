export REMOVE_UNUSED_CODE = 0

# Firmware Version
export PRJ_VERSION = 0x00000001

# Define target output
target: vcs

# Define target part
export PRJ_PART = xcvu9p-fsgd2104-2-e
#export PRJ_PART = XC7Z045FFG900-2

#export REMOVE_UNUSED_CODE = 1

# Use top level makefile
include ../../submodules/ruckus/system_vivado.mk

vcs: export PGP2FC_XCI=1
vcs: export LCLS_TIMING_GTY_XCI=1
