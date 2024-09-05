#load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadRuckusTcl $::env(TOP_DIR)/submodules/axi-soc-ultra-plus-core/hardware/XilinxKriaKv260/
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(TOP_DIR)/common/ts
loadRuckusTcl $::env(TOP_DIR)/common/tdaq

loadSource -lib ldmx_ts -dir "$::env(TOP_DIR)/common/ts/rtl/"

loadSource -path "$::DIR_PATH/rtl/zCCM_kria.vhd"
loadSource -sim_only -path "$::DIR_PATH/sim/zCCM_kria_tb.vhd"
#loadBlockDesign -path "$::DIR_PATH/bd/project_1/project_1.bd"
loadConstraints -path "$::DIR_PATH/xdc/default.xdc"


#set_property top "top"
