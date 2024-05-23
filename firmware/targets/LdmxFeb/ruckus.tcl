############################
# DO NOT EDIT THE CODE BELOW
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/common/tdaq
loadRuckusTcl $::env(TOP_DIR)/common/tracker

# Load target's source code and constraints
#loadIpCore      -path "$::DIR_PATH/xil_cores/FebSem/FebSem.xci"
loadIpCore      -path "$::DIR_PATH/ip/LdmxFebSysmon/LdmxFebSysmon.xci"
#loadIpCore      -path "$::TOP_DIR/common/HpsDaq/xil_cores/AxiXadcCore/AxiXadcCore.xci"
loadSource -lib ldmx_tracker      -dir  "$::DIR_PATH/rtl/"
loadSource -lib ldmx_tracker      -sim_only -dir "$::DIR_PATH/sim/"
loadConstraints -dir  "$::DIR_PATH/xdc/"

