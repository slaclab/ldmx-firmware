# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadSource -lib ldmx_tracker -dir "$::DIR_PATH/rtl/" 
loadSource -lib ldmx_tracker -sim_only -dir  "$::DIR_PATH/sim/"

