export BUILD_SCRIPT = $(PWD)/../../submodules/ruckus/system_vivado.mk

# Define target output
target: bit

# Define Firmware Version Number
export PRJ_VERSION = 0x00000001

#export PROJECT = apd1_top
#export BOARD = APd1

#Define target part
export PRJ_PART = xcvu9p-flgc2104-1-e

export PARALLEL_SYNTH = 24
export GZIP_BUILD_IMAGE = 1

export TOP_DIR = $(abspath $(PWD)/../..)

# !Caution! Timing failuire IGnore flag. Allows bitfile generation even if timing not met. 
#export TIG = true

# Use top level makefile
include $(BUILD_SCRIPT)
