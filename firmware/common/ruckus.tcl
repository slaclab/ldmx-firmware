# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadSource -lib ldmx -dir "$::DIR_PATH/rtl/"
loadSource -dir "$::DIR_PATH/verilog/"
