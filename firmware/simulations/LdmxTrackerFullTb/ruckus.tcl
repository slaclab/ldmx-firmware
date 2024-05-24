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

# Target tops
loadSource           -lib ldmx -dir "$::env(TOP_DIR)/targets/LdmxFeb/rtl"
loadSource -sim_only -lib ldmx -dir "$::env(TOP_DIR)/targets/LdmxFeb/sim"

#loadIpCore      -path "$::env(TOP_DIR)/targets/LdmxFeb/ip/LdmxFebSysmon/LdmxFebSysmon.xci"

#loadConstraints      -dir "$::DIR_PATH/xdc"
#loadSource -sim_only -lib ldmx -dir "$::DIR_PATH/tb"

loadSource           -lib ldmx -dir "$::env(TOP_DIR)/targets/TrackerBittware/hdl"
loadSource -sim_only -lib ldmx -dir "$::env(TOP_DIR)/targets/TrackerBittware/tb"


# Load target's source code and constraints
loadSource -lib ldmx -sim_only -dir "$::env(PROJ_DIR)/tb"

# Set the top level synth_1 and sim_1
set_property top {LdmxFeb}       [get_filesets {sources_1}]
set_property top "LdmxTrackerFullTb"     [get_filesets sim_1]
