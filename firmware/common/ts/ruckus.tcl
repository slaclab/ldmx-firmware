# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load ruckus files
loadSource -lib ldmx_ts -dir "$::DIR_PATH/rtl/"
# loadSource -lib ldmx_ts -sim_only -dir  "$::DIR_PATH/sim/"

loadRuckusTcl "$::DIR_PATH/hls/ts_s30xl_threshold_trigger"

if { [info exists ::env(LDMX_TS_XCI)] == 1 && $::env(LDMX_TS_XCI) == 1 } {
    loadIpCore -path "$::DIR_PATH/ip/TsGtyIpCore/TsGtyIpCore.xci"
    puts "Loading XCI file for LDMX TS"
} else {
    loadSource -path "$::DIR_PATH/ip/TsGtyIpCore/TsGtyIpCore.dcp"
}   






