# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load SURF ruckus.tcl file
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/base
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/axi/axi-lite
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/axi/axi-stream
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/axi/bridge
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/xilinx
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/protocols/i2c
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf/protocols/pgp/pgp3/core


# Load APx-FS ruckus.tcl file
loadRuckusTcl $::env(TOP_DIR)/submodules/apx-fs

# Load local source Code and constraints
loadSource -path "$::DIR_PATH/rtl/apd1_top.vhd"
loadSource -path "$::DIR_PATH/rtl/algoTopWrapper.vhd"
loadSource -lib apx_fs -dir "$::DIR_PATH/cfg/"
loadConstraints -dir "$::DIR_PATH/constraints/"
loadIpCore -dir "$::DIR_PATH/ip/" 

# Area constraints used in the implementation  only
set_property used_in_synthesis false [get_files  $::DIR_PATH/constraints/floorplan.tcl]
set_msg_config -suppress -id {Vivado 12-1433};  # Expecting a non-empty list of cells to be added to the pblock.  
