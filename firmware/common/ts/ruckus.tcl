# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadSource -lib ldmx_ts -dir "$::DIR_PATH/rtl/"
# loadSource -lib ldmx_ts -sim_only -dir  "$::DIR_PATH/sim/"

#loadRuckusTcl "$::DIR_PATH/hls/ts_s30xl_threshold_trigger"

#loadIpCore -path "$::DIR_PATH/ip/TsGtyIpCore/TsGtyIpCore.xci"
loadSource -path "$::DIR_PATH/ip/TsGtyIpCore/TsGtyIpCore.dcp"
