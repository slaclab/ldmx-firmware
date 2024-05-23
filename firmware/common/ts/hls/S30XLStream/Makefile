
# Define target output
target: build

# Set ARGV, CFLAGs, LDFLAGs
export ARGV    = 
export CFLAGS  = 
export LDFLAGS = 

# Set TOP_DIR to be the base directory for which the build directory resides
export TOP_DIR  = $(abspath $(PWD)/../../..)

export SKIP_COSIM = 1

# Need to modify the component.xml
export ALL_XIL_FAMILY = 1

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vitis_hls.mk
