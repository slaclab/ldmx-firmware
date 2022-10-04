# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/XilinxAlveoU200
loadRuckusTcl $::env(TOP_DIR)/common
#loadRuckusTcl $::env(PROJ_DIR)/../../../common/pgp2b/hardware/XilinxAlveoU200

# Load local source Code and constraints
loadSource      -lib ldmx -dir "$::DIR_PATH/hdl"
loadSource      -lib ldmx -sim_only -dir "$::DIR_PATH/sim"
loadConstraints -dir "$::DIR_PATH/hdl"

set_property top "TrackerPcieAlveoTb"     [get_filesets sim_1]
