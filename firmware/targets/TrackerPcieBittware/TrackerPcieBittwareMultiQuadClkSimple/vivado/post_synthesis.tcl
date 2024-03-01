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

##############################
# Get variables and procedures
##############################
# source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
# source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

############################
## Open the synthesis design
############################
# open_run synth_1

###############################
## Set the name of the ILA core
###############################
# set ilaRxClk u_ila_rxClk
# set ilaTxClk u_ila_txClk

##################
## Create the core
##################
# CreateDebugCore ${ilaRxClk}
# CreateDebugCore ${ilaTxClk}

#######################
## Set the record depth
#######################
# set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaRxClk}]
# set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaTxClk}]

#################################
## Set the clock for the ILA core
#################################
# SetDebugCoreClk ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/rxOutClk}
# SetDebugCoreClk ${ilaTxClk} {U_PgpLaneWrapper/U_MgtRefClkMux/userRefClk[4]}

#######################
## Set the debug Probes
#######################
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxresetdone_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxsyncdone_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxdlysresetdone_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxctrl0_out[*]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxctrl1_out[*]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxctrl2_out[*]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxctrl3_out[*]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxcommadet_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxcdrlock_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxbyterealign_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxbyteisaligned_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/cpllrefclklost_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/cpllfbclklost_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxphaligndone_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxsyncdone_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/rxpmaresetdone_out[0]}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.gtrxreset_int}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.rxdlysreset_int}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.rxuserrdy_int}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.gtrxreset_int}
# ConfigProbe ${ilaRxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.rxprogdivreset_int}
#######################
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txresetdone_out[0]}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.txdlysreset_int}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.txpmareset_ch_int}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/gen_gtwizard_gtye4.txuserrdy_int}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txresetdone_out[0]}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txsyncdone_out[0]}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txpmaresetdone_out[0]}
# ConfigProbe ${ilaTxClk} {U_PgpLaneWrapper/GEN_QUAD[4].GEN_LANE[0].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/txphaligndone_out[0]}

##########################
## Write the port map file
##########################
# WriteDebugProbes ${ilaRxClk}
# WriteDebugProbes ${ilaTxClk}