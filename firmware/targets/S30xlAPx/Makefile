
# Define target output
target: bit

# Define Firmware Version Number
export PRJ_VERSION = 0x00000001

export RUCKUS_DIR = $(abspath $(PWD)/../../submodules/ruckus)

#export PROJECT = apd1_top
#export BOARD = APd1

#Define target part
export PRJ_PART = xcvu9p-flgc2104-1-e

export PARALLEL_SYNTH = 24
export GZIP_BUILD_IMAGE = 1


# Use top level makefile
include $(RUCKUS_DIR)/system_vivado.mk


vcs: export PGP2FC_XCI=1
vcs: export LCLS_TIMING_XCI=1
vcs: export LDMX_TS_XCI=1

