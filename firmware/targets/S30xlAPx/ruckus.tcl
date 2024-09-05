# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load SURF ruckus.tcl file
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls-timing-core
loadRuckusTcl $::env(TOP_DIR)/common/tdaq
loadRuckusTcl $::env(TOP_DIR)/common/ts



# Load APx-FS ruckus.tcl file
#loadRuckusTcl $::env(TOP_DIR)/submodules/apx-fs

# Load local source Code and constraints
loadSource -lib ldmx_ts -path "$::DIR_PATH/rtl/S30xlAPx.vhd"
loadSource -sim_only -lib ldmx_ts -dir "$::DIR_PATH/sim/"

loadConstraints -dir "$::DIR_PATH/constraints/"
# loadIpCore -dir "$::DIR_PATH/ip/"

# set_property top "S30xlApx" [get_filesets {sources_1}]

# Area constraints used in the implementation  only
#set_property used_in_synthesis false [get_files  $::DIR_PATH/constraints/floorplan.tcl]
#set_msg_config -suppress -id {Vivado 12-1433};  # Expecting a non-empty list of cells to be added to the pblock.  
# Set top level sim
set_property top "S30xlAPxTb"     [get_filesets sim_1]
