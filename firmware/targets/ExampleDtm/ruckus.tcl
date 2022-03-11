############################
# DO NOT EDIT THE CODE BELOW
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/common/
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/rce-gen3-fw-lib/DtmCore

# Load target's source code and constraints
loadSource      -lib ldmx -dir "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"

loadSource       -lib ldmx -sim_only -dir "$::DIR_PATH/sim/"

set_property top {ExampleDtmTb} [get_filesets {sim_1}]
