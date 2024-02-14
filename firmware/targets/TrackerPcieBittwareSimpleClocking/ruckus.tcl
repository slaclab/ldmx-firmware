# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/BittWareXupVv8
loadRuckusTcl $::env(TOP_DIR)/common

set sourceDir "$::DIR_PATH/../TrackerPcieBittware"

# Load local source Code and constraints
loadSource           -lib ldmx -dir "$sourceDir/hdl"
loadConstraints      -dir "$sourceDir/xdc"
loadSource -sim_only -lib ldmx -dir "$sourceDir/tb"

set_property top {BittWareXupVv8Pgp2fc} [get_filesets {sources_1}]
# set_property top {BittWareXupVv8Pgp2fcTb} [get_filesets {sim_1}]
set_property top {BittWareXupVv8Pgp2fcMultiFpgaTb} [get_filesets {sim_1}]

set sysGeneric [get_property generic -object [current_fileset]]
set clkGeneric "${sysGeneric}, SIMPLE_CLOCKING_G=true"
set_property generic ${clkGeneric} -object [current_fileset]

set_property target_language VHDL [current_project]

set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
