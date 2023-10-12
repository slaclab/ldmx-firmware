##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS Laserlocker Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
## User Debug Script

# Bypass the debug chipscope generation
# return

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
# open_run synth_1

# create_debug_core u_ila_0 ila
# set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
# set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
# set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
# set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
# set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
# set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
# set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
# set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
# create_debug_core u_ila_1 ila
# set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
# set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
# set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
# set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
# set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_1]
# set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
# set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
# set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
# create_debug_core u_ila_2 ila
# set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_2]
# set_property C_TRIGIN_EN false [get_debug_cores u_ila_2]
# set_property C_TRIGOUT_EN false [get_debug_cores u_ila_2]
# set_property C_ADV_TRIGGER false [get_debug_cores u_ila_2]
# set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_2]
# set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_2]
# set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_2]
# set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_2]
# connect_debug_port u_ila_0/clk [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/pgpTxClk} ]]
# connect_debug_port u_ila_1/clk [get_nets [list {U_axilClk/clkOut[0]} ]]
# connect_debug_port u_ila_2/clk [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/pgpRxClk} ]]
# set_property port_width 16 [get_debug_ports u_ila_0/probe0]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
# connect_debug_port u_ila_0/probe0 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[0]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[1]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[2]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[3]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[4]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[5]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[6]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[7]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[8]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[9]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[10]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[11]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[12]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[13]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[14]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtwiz_userdata_tx_in[15]} ]]
# set_property port_width 1 [get_debug_ports u_ila_1/probe0]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
# connect_debug_port u_ila_1/probe0 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/rxbufreset_in[0]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe1]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
# connect_debug_port u_ila_1/probe1 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxresetdone_out[0]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 3 [get_debug_ports u_ila_1/probe2]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
# connect_debug_port u_ila_1/probe2 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/loopback_in[0]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/loopback_in[1]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/loopback_in[2]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe3]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
# connect_debug_port u_ila_1/probe3 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/txresetdone_out[0]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe4]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
# connect_debug_port u_ila_1/probe4 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/rxresetdone_out[0]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe5]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
# connect_debug_port u_ila_1/probe5 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txresetdone_out[0]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 3 [get_debug_ports u_ila_1/probe6]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
# connect_debug_port u_ila_1/probe6 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST_3[0]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST_3[1]} {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST_3[2]} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe7]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
# connect_debug_port u_ila_1/probe7 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gen_gtwizard_gtye4.gtrxreset_int} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe8]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
# connect_debug_port u_ila_1/probe8 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gen_gtwizard_gtye4.rxprogdivreset_int} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe9]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
# connect_debug_port u_ila_1/probe9 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gen_gtwizard_gtye4.rxuserrdy_int} ]]
# create_debug_port u_ila_1 probe
# set_property port_width 1 [get_debug_ports u_ila_1/probe10]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
# connect_debug_port u_ila_1/probe10 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/GTYE4_TXPROGDIVRESET_OUT} ]]
# set_property port_width 1 [get_debug_ports u_ila_2/probe0]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe0]
# connect_debug_port u_ila_2/probe0 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxpmaresetdone_out[0]} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe1]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe1]
# connect_debug_port u_ila_2/probe1 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/TXRATE[0]} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe2]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe2]
# connect_debug_port u_ila_2/probe2 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/rxcommadet_out[0]} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe3]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe3]
# connect_debug_port u_ila_2/probe3 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/rxpmaresetdone_out[0]} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe4]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe4]
# connect_debug_port u_ila_2/probe4 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/txpmaresetdone_out[0]} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe5]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe5]
# connect_debug_port u_ila_2/probe5 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txpmaresetdone_out[0]} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe6]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe6]
# connect_debug_port u_ila_2/probe6 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gen_gtwizard_gtye4.gtpowergood_int} ]]
# create_debug_port u_ila_2 probe
# set_property port_width 1 [get_debug_ports u_ila_2/probe7]
# set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_2/probe7]
# connect_debug_port u_ila_2/probe7 [get_nets [list {U_PgpLaneWrapper/GEN_QUAD[0].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gen_gtwizard_gtye4.gttxreset_ch_int} ]]



###############################
## Set the name of the ILA core
###############################
# set ilaCore u_ila_0

# ##################
# ## Create the core
# ##################
# CreateDebugCore ${ilaCore}

# #######################
# ## Set the record depth
# #######################
# set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaCore}]

# #################################
# ## Set the clock for the ILA core
# #################################
# SetDebugCoreClk ${ilaCore} {dmaClk}


# #######################
# ## Set the debug Probes
# #######################
# ConfigProbe ${ilaCore} {dmaRst}


# ##########################
# ## Write the port map file
# ##########################
# WriteDebugProbes ${ilaCore}
