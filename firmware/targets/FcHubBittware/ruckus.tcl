# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/BittWareXupVv8
loadRuckusTcl $::env(TOP_DIR)/common/tdaq
loadRuckusTcl $::env(TOP_DIR)/common/tracker

# Load local source Code and constraints
loadSource           -lib ldmx -dir "$::DIR_PATH/hdl"
loadConstraints      -dir           "$::DIR_PATH/xdc"
#loadSource -sim_only -lib ldmx -dir "$masterSourceDir/tb"

#set_property top {BittWareXupVv8Pgp2fc} [get_filesets {sources_1}]
# set_property top {BittWareXupVv8Pgp2fcTb} [get_filesets {sim_1}]
#set_property top {BittWareXupVv8Pgp2fcMultiFpgaTb} [get_filesets {sim_1}]

set_property target_language VHDL [current_project]

set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
