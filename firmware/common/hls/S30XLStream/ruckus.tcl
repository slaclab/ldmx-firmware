# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
#loadSource    -path "$::DIR_PATH/rtl/AxiStreamExampleWrapper.vhd"
# loadZipIpCore -path "$::DIR_PATH/ip/S30XLStream-v1.0-20240516132713-bareese-dirty.zip" -repo_path $::env(IP_REPO)
# if { [get_ips AxiStreamExample_0] eq ""  } {
#    create_ip -name S30XLStream -vendor SLAC -library hls -version 1.0 -module_name hitproducerStream_hw_0
# }
loadSource -lib hls -path "$::DIR_PATH/ip/verilog"
