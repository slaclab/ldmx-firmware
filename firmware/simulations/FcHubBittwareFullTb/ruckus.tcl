# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# SURF
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/surf/protocols/pgp/pgp2fc/gtyUltraScale+/

# AXI PCIE
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core/hardware/BittWareXupVv8

# LDMX Common
loadRuckusTcl $::env(TOP_DIR)/common/tdaq
loadRuckusTcl $::env(TOP_DIR)/common/tracker

# Timing
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls-timing-core

# Target tops
loadSource           -lib ldmx_tracker -dir "$::env(TOP_DIR)/targets/FcHubBittware/hdl"
loadSource -sim_only -lib ldmx_tracker -dir "$::env(TOP_DIR)/targets/FcHubBittware/tb"

loadSource           -lib ldmx_tracker -dir "$::env(TOP_DIR)/targets/TrackerBittware/hdl"
loadSource -sim_only -lib ldmx_tracker -dir "$::env(TOP_DIR)/targets/TrackerBittware/tb"

# Load target's source code and constraints
loadSource -lib ldmx -sim_only -dir "$::env(PROJ_DIR)/tb"

# Set the top level for sim_1
set_property top "FcHubBittware"           [get_filesets {sources_1}]
set_property top "FcHubBittwareFullTb"     [get_filesets sim_1]
