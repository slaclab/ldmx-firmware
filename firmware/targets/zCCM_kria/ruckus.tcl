#load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load the common source code
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/common/ts
loadRuckusTcl $::env(TOP_DIR)/common/tdaq
loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/shared

# Load shared source code for axi-soc
loadSource -lib axi_soc_ultra_plus_core -dir "$::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxKriaKv260/rtl"

# Set the board part
set_property board_part xilinx.com:k26c:part0:1.4 [current_project]

# Load the block design
if  { $::env(VIVADO_VERSION) >= 2023.1 } {
   set bdVer "2023.1"
} else {
   set bdVer "2022.2"
}
loadBlockDesign -path $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxKriaKv260/bd/${bdVer}/AxiSocUltraPlusCpuCore.bd

loadSource -lib ldmx_ts -dir "$::env(TOP_DIR)/common/ts/rtl/"

loadSource -path "$::DIR_PATH/rtl/zCCM_kria.vhd"
loadSource -sim_only -path "$::DIR_PATH/sim/zCCM_kria_tb.vhd"
loadConstraints -path "$::DIR_PATH/xdc/zCCM_kria.xdc"


#set_property top "top"
