############################
# DO NOT EDIT THE CODE BELOW
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/common

# Load target's source code and constraints
loadIpCore      -path "$::DIR_PATH/xil_cores/FebSem/FebSem.xci"
#loadIpCore      -path "$::TOP_DIR/common/HpsDaq/xil_cores/AxiXadcCore/AxiXadcCore.xci"
loadSource -lib ldmx      -dir  "$::DIR_PATH/rtl/"
loadSource -lib ldmx      -sim_only -dir "$::DIR_PATH/sim/"
loadConstraints -dir  "$::DIR_PATH/rtl/"

