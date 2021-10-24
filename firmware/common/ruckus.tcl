# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadSource -lib ldmx -dir "$::DIR_PATH/rtl/"
loadSource -dir "$::DIR_PATH/verilog/"
loadSource -dir "$::DIR_PATH/verilog/pflink"
loadSource -dir "$::DIR_PATH/verilog/pflink/core"
#loadSource -dir "$::DIR_PATH/verilog/pflink/core/pfclk"
#loadSource -dir "$::DIR_PATH/verilog/pflink/core/pflink"
loadSource -dir "$::DIR_PATH/verilog/pflink/utility"
loadSource -dir "$::DIR_PATH/verilog/ts"
loadSource -dir "$::DIR_PATH/verilog/ts/core/tslink"
