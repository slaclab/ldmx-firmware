##############################################################################
## This file is part of 'LDMX'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'LDMX', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

create_clock -name gtRefClk185 -period 5.385 [get_ports {gtRefClk185P}] 
create_clock -name gtRefClk250 -period 4.0  [get_ports {gtRefClk250P}]


create_clock -name adcDClk0 -period 3.846 [get_ports {adcDClkP[0]}]
create_clock -name adcDClk1 -period 3.846 [get_ports {adcDClkP[1]}]
create_clock -name adcDClk2 -period 3.846 [get_ports {adcDClkP[2]}]
create_clock -name adcDClk3 -period 3.846 [get_ports {adcDClkP[3]}]
create_clock -name adcDClk4 -period 3.846 [get_ports {adcDClkP[4]}]
create_clock -name adcDClk5 -period 3.846 [get_ports {adcDClkP[5]}]
create_clock -name adcDClk6 -period 3.846 [get_ports {adcDClkP[6]}]
create_clock -name adcDClk7 -period 3.846 [get_ports {adcDClkP[7]}]

set_input_jitter adcDClk0 .35
set_input_jitter adcDClk1 .35
set_input_jitter adcDClk2 .35
set_input_jitter adcDClk3 .35
set_input_jitter adcDClk4 .35
set_input_jitter adcDClk5 .35
set_input_jitter adcDClk6 .35
set_input_jitter adcDClk7 .35

create_generated_clock -name axilClk [get_pins {U_LdmxFebPgp_1/U_BUFG/O}]

create_generated_clock -name rxOutClk [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[0].U_LdmxFebPgp_1/*/RXOUTCLK}]
create_generated_clock -name txOutClk [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[0].U_LdmxFebPgp_1/*/TXOUTCLK}]
create_generated_clock -name txOutClkPcs [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[0].U_LdmxFebPgp_1/*/TXOUTCLKPCS}]

create_generated_clock -name rxOutClk_unused [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[1].U_LdmxFebPgp_1/*/RXOUTCLK}]
create_generated_clock -name txOutClk_unused [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[1].U_LdmxFebPgp_1/*/TXOUTCLK}]
create_generated_clock -name txOutClkPcs_unused [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[1].U_LdmxFebPgp_1/*/TXOUTCLKPCS}]

create_generated_clock -name rxOutClk_unused2 [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[2].U_LdmxFebPgp_1/*/RXOUTCLK}]
create_generated_clock -name txOutClk_unused2 [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[2].U_LdmxFebPgp_1/*/TXOUTCLK}]
create_generated_clock -name txOutClkPcs_unused2 [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[2].U_LdmxFebPgp_1/*/TXOUTCLKPCS}]


set daqClk37Pin [get_pins { U_FebCore_1/U_FebFcRx_1/r_reg[fcClk37]/Q }]

create_generated_clock \
    -name daqClk37 \
    -source [get_pins -hier * -filter {name=~*/NO_SIM.PGP_GEN[0].U_LdmxFebPgp_1/*/RXOUTCLK}] \
    -edges {1 7 11} \
    ${daqClk37Pin}

create_generated_clock -name hybridClk0 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_A/MmcmGen.U_Mmcm/CLKOUT0]
create_generated_clock -name hybridClk1 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_A/MmcmGen.U_Mmcm/CLKOUT1]
create_generated_clock -name hybridClk2 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_A/MmcmGen.U_Mmcm/CLKOUT2]
create_generated_clock -name hybridClk3 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_A/MmcmGen.U_Mmcm/CLKOUT3]

create_generated_clock -name hybridClk4 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_B/MmcmGen.U_Mmcm/CLKOUT0]
create_generated_clock -name hybridClk5 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_B/MmcmGen.U_Mmcm/CLKOUT1]
create_generated_clock -name hybridClk6 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_B/MmcmGen.U_Mmcm/CLKOUT2]
create_generated_clock -name hybridClk7 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_HY_B/MmcmGen.U_Mmcm/CLKOUT3]

create_generated_clock -name adcClk0 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_ADC/MmcmGen.U_Mmcm/CLKOUT0]
create_generated_clock -name adcClk1 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_ADC/MmcmGen.U_Mmcm/CLKOUT1]
create_generated_clock -name adcClk3 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_ADC/MmcmGen.U_Mmcm/CLKOUT2]
create_generated_clock -name adcClk4 -source ${daqClk37Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins U_LdmxFebHw_1/U_ClockManagerUltraScale_ADC/MmcmGen.U_Mmcm/CLKOUT3]

#U_LdmxFebPgp_1/NO_SIM.PGP_GEN[0].U_LdmxFebPgp_1/U_Pgp2fcGtyUltra_1/PgpGtyCoreWrapper_1/U_Pgp2fcGtyCore/inst/gen_gtwizard_gtye4_top.Pgp2fcGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[35].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK
create_generated_clock -name dnaClk [get_pins U_LdmxFebHw_1/AxiVersion_1/GEN_DEVICE_DNA.DeviceDna_1/GEN_ULTRA_SCALE.DeviceDnaUltraScale_Inst/BUFGCE_DIV_Inst/O]
create_generated_clock -name icapClk [get_pins U_LdmxFebHw_1/AxiVersion_1/GEN_ICAP.Iprog_1/GEN_ULTRA_SCALE.IprogUltraScale_Inst/BUFGCE_DIV_Inst/O]


set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks gtRefClk185] \
    -group [get_clocks -include_generated_clocks gtRefClk250] \    
    -group [get_clocks -include_generated_clocks adcDClk0] \
    -group [get_clocks -include_generated_clocks adcDClk1] \
    -group [get_clocks -include_generated_clocks adcDClk2] \
    -group [get_clocks -include_generated_clocks adcDClk3] \
    -group [get_clocks -include_generated_clocks adcDClk4] \
    -group [get_clocks -include_generated_clocks adcDClk5] \
    -group [get_clocks -include_generated_clocks adcDClk6] \
    -group [get_clocks -include_generated_clocks adcDClk7] \
    -group [get_clocks -include_generated_clocks axilClk] \
    -group [get_clocks -include_generated_clocks rxOutClk] \
    -group [get_clocks -include_generated_clocks txOutClk] \
    -group [get_clocks -include_generated_clocks txOutClkPcs] \    
    -group [get_clocks -include_generated_clocks rxOutClk_unused] \
    -group [get_clocks -include_generated_clocks txOutClk_unused] \
    -group [get_clocks -include_generated_clocks txOutClkPcs_unused] \
    -group [get_clocks -include_generated_clocks rxOutClk_unused2] \
    -group [get_clocks -include_generated_clocks txOutClk_unused2] \
    -group [get_clocks -include_generated_clocks txOutClkPcs_unused2]
    

set_clock_groups -asynchronous \
    -group [get_clocks axilClk] \
    -group [get_clocks dnaClk] \
    -group [get_clocks icapClk]

set_clock_groups -asynchronous \
    -group [get_clocks rxOutClk] \
    -group [get_clocks daqClk37] \
    -group [get_clocks hybridClk0] \
    -group [get_clocks hybridClk1] \
    -group [get_clocks hybridClk2] \
    -group [get_clocks hybridClk3] \
    -group [get_clocks hybridClk4] \
    -group [get_clocks hybridClk5] \
    -group [get_clocks hybridClk6] \
    -group [get_clocks hybridClk7] 
    


# MGT Mapping
# Clocks
set_property PACKAGE_PIN T7 [get_ports {gtRefClk185P}]
set_property PACKAGE_PIN T6 [get_ports {gtRefClk185N}]
set_property PACKAGE_PIN P7 [get_ports {gtRefClk250P}]
set_property PACKAGE_PIN P6 [get_ports {gtRefClk250N}]

# QSFP
set_property PACKAGE_PIN W5  [get_ports {qsfpGtTxP[0]}]
set_property PACKAGE_PIN W4  [get_ports {qsfpGtTxN[0]}]
set_property PACKAGE_PIN AB2 [get_ports {qsfpGtRxP[0]}]
set_property PACKAGE_PIN AB1 [get_ports {qsfpGtRxN[0]}]
set_property PACKAGE_PIN U5  [get_ports {qsfpGtTxP[1]}]
set_property PACKAGE_PIN U4  [get_ports {qsfpGtTxN[1]}]
set_property PACKAGE_PIN Y2  [get_ports {qsfpGtRxP[1]}]
set_property PACKAGE_PIN Y1  [get_ports {qsfpGtRxN[1]}]
set_property PACKAGE_PIN AA5 [get_ports {qsfpGtTxP[2]}]
set_property PACKAGE_PIN AA4 [get_ports {qsfpGtTxN[2]}]
set_property PACKAGE_PIN V2  [get_ports {qsfpGtRxP[2]}]
set_property PACKAGE_PIN V1  [get_ports {qsfpGtRxN[2]}]
set_property PACKAGE_PIN R5  [get_ports {qsfpGtTxP[3]}]
set_property PACKAGE_PIN R4  [get_ports {qsfpGtTxN[3]}]
set_property PACKAGE_PIN T1  [get_ports {qsfpGtRxP[3]}]
set_property PACKAGE_PIN T2  [get_ports {qsfpGtRxN[3]}]


# SAS
set_property PACKAGE_PIN AH7 [get_ports {sasGtTxP[0]}]
set_property PACKAGE_PIN AH6 [get_ports {sasGtTxN[0]}]
set_property PACKAGE_PIN AH2 [get_ports {sasGtRxP[0]}]
set_property PACKAGE_PIN AH1 [get_ports {sasGtRxN[0]}]
set_property PACKAGE_PIN AF7 [get_ports {sasGtTxP[1]}]
set_property PACKAGE_PIN AF6 [get_ports {sasGtTxN[1]}]
set_property PACKAGE_PIN AD2 [get_ports {sasGtRxP[1]}]
set_property PACKAGE_PIN AD1 [get_ports {sasGtRxN[1]}]
set_property PACKAGE_PIN AD7 [get_ports {sasGtTxP[2]}]
set_property PACKAGE_PIN AD6 [get_ports {sasGtTxN[2]}]
set_property PACKAGE_PIN AF2 [get_ports {sasGtRxP[2]}]
set_property PACKAGE_PIN AF1 [get_ports {sasGtRxN[2]}]
set_property PACKAGE_PIN AB7 [get_ports {sasGtTxP[3]}]
set_property PACKAGE_PIN AB6 [get_ports {sasGtTxN[3]}]
set_property PACKAGE_PIN AG4 [get_ports {sasGtRxP[3]}]
set_property PACKAGE_PIN AG3 [get_ports {sasGtRxN[3]}]

# SFP
set_property PACKAGE_PIN G5 [get_ports {sfpGtTxP}]
set_property PACKAGE_PIN G4 [get_ports {sfpGtTxN}]
set_property PACKAGE_PIN P2 [get_ports {sfpGtRxP}]
set_property PACKAGE_PIN P1 [get_ports {sfpGtRxN}]




# IO Timing

# ADC Interface
set_property -dict { PACKAGE_PIN A17  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[0] }];
set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[0] }];
set_property -dict { PACKAGE_PIN D21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[0] }];
set_property -dict { PACKAGE_PIN C21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[0] }];
set_property -dict { PACKAGE_PIN F20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[0][0] }];
set_property -dict { PACKAGE_PIN F21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[0][0] }];
set_property -dict { PACKAGE_PIN G19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[0][1] }];
set_property -dict { PACKAGE_PIN G20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[0][1] }];
set_property -dict { PACKAGE_PIN E20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[0][2] }];
set_property -dict { PACKAGE_PIN E21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[0][2] }];
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[0][3] }];
set_property -dict { PACKAGE_PIN D19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[0][3] }];
set_property -dict { PACKAGE_PIN C17  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[0][4] }];
set_property -dict { PACKAGE_PIN B17  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[0][4] }];
set_property -dict { PACKAGE_PIN B19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[0][5] }];
set_property -dict { PACKAGE_PIN B20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[0][5] }];

set_property -dict { PACKAGE_PIN C24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[1] }];
set_property -dict { PACKAGE_PIN C25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[1] }];
set_property -dict { PACKAGE_PIN F22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[1] }];
set_property -dict { PACKAGE_PIN E23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[1] }];
set_property -dict { PACKAGE_PIN H22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[1][0] }];
set_property -dict { PACKAGE_PIN G22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[1][0] }];
set_property -dict { PACKAGE_PIN H24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[1][1] }];
set_property -dict { PACKAGE_PIN G24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[1][1] }];
set_property -dict { PACKAGE_PIN G23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[1][2] }];
set_property -dict { PACKAGE_PIN F23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[1][2] }];
set_property -dict { PACKAGE_PIN E24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[1][3] }];
set_property -dict { PACKAGE_PIN E25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[1][3] }];
set_property -dict { PACKAGE_PIN B23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[1][4] }];
set_property -dict { PACKAGE_PIN B24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[1][4] }];
set_property -dict { PACKAGE_PIN C22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[1][5] }];
set_property -dict { PACKAGE_PIN B22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[1][5] }];

set_property -dict { PACKAGE_PIN P26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[2] }];
set_property -dict { PACKAGE_PIN N26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[2] }];
set_property -dict { PACKAGE_PIN K25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[2] }];
set_property -dict { PACKAGE_PIN K26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[2] }];
set_property -dict { PACKAGE_PIN P24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[2][0] }];
set_property -dict { PACKAGE_PIN N24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[2][0] }];
set_property -dict { PACKAGE_PIN K24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[2][1] }];
set_property -dict { PACKAGE_PIN J24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[2][1] }];
set_property -dict { PACKAGE_PIN M23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[2][2] }];
set_property -dict { PACKAGE_PIN M24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[2][2] }];
set_property -dict { PACKAGE_PIN M28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[2][3] }];
set_property -dict { PACKAGE_PIN L28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[2][3] }];
set_property -dict { PACKAGE_PIN P27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[2][4] }];
set_property -dict { PACKAGE_PIN P28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[2][4] }];
set_property -dict { PACKAGE_PIN N27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[2][5] }];
set_property -dict { PACKAGE_PIN M27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[2][5] }];

set_property -dict { PACKAGE_PIN B27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[3] }];
set_property -dict { PACKAGE_PIN B28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[3] }];
set_property -dict { PACKAGE_PIN H25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[3] }];
set_property -dict { PACKAGE_PIN G25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[3] }];
set_property -dict { PACKAGE_PIN L27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[3][0] }];
set_property -dict { PACKAGE_PIN K28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[3][0] }];
set_property -dict { PACKAGE_PIN H27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[3][1] }];
set_property -dict { PACKAGE_PIN G28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[3][1] }];
set_property -dict { PACKAGE_PIN J27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[3][2] }];
set_property -dict { PACKAGE_PIN J28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[3][2] }];
set_property -dict { PACKAGE_PIN F25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[3][3] }];
set_property -dict { PACKAGE_PIN F26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[3][3] }];
set_property -dict { PACKAGE_PIN E26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[3][4] }];
set_property -dict { PACKAGE_PIN D26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[3][4] }];
set_property -dict { PACKAGE_PIN F28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[3][5] }];
set_property -dict { PACKAGE_PIN E28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[3][5] }];

set_property -dict { PACKAGE_PIN AA26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[4] }];
set_property -dict { PACKAGE_PIN AA27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[4] }];
set_property -dict { PACKAGE_PIN W26   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[4] }];
set_property -dict { PACKAGE_PIN Y26   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[4] }];
set_property -dict { PACKAGE_PIN AC24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[4][0] }];
set_property -dict { PACKAGE_PIN AD24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[4][0] }];
set_property -dict { PACKAGE_PIN AB27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[4][1] }];
set_property -dict { PACKAGE_PIN AB28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[4][1] }];
set_property -dict { PACKAGE_PIN AB25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[4][2] }];
set_property -dict { PACKAGE_PIN AC25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[4][2] }];
set_property -dict { PACKAGE_PIN Y28   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[4][3] }];
set_property -dict { PACKAGE_PIN AA28  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[4][3] }];
set_property -dict { PACKAGE_PIN Y25   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[4][4] }];
set_property -dict { PACKAGE_PIN AA25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[4][4] }];
set_property -dict { PACKAGE_PIN W27   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[4][5] }];
set_property -dict { PACKAGE_PIN W28   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[4][5] }];

set_property -dict { PACKAGE_PIN T27   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[5] }];
set_property -dict { PACKAGE_PIN U28   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[5] }];
set_property -dict { PACKAGE_PIN U24   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[5] }];
set_property -dict { PACKAGE_PIN V24   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[5] }];
set_property -dict { PACKAGE_PIN W23   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[5][0] }];
set_property -dict { PACKAGE_PIN Y23   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[5][0] }];
set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[5][1] }];
set_property -dict { PACKAGE_PIN V22   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[5][1] }];
set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[5][2] }];
set_property -dict { PACKAGE_PIN AA22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[5][2] }];
set_property -dict { PACKAGE_PIN T22   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[5][3] }];
set_property -dict { PACKAGE_PIN T23   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[5][3] }];
set_property -dict { PACKAGE_PIN U27   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[5][4] }];
set_property -dict { PACKAGE_PIN V27   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[5][4] }];
set_property -dict { PACKAGE_PIN T25   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[5][5] }];
set_property -dict { PACKAGE_PIN U25   IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[5][5] }];

set_property -dict { PACKAGE_PIN AF21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[6] }];
set_property -dict { PACKAGE_PIN AF22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[6] }];
set_property -dict { PACKAGE_PIN AE23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[6] }];
set_property -dict { PACKAGE_PIN AE24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[6] }];
set_property -dict { PACKAGE_PIN AG27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[6][0] }];
set_property -dict { PACKAGE_PIN AH27  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[6][0] }];
set_property -dict { PACKAGE_PIN AF25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[6][1] }];
set_property -dict { PACKAGE_PIN AF26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[6][1] }];
set_property -dict { PACKAGE_PIN AH25  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[6][2] }];
set_property -dict { PACKAGE_PIN AH26  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[6][2] }];
set_property -dict { PACKAGE_PIN AG24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[6][3] }];
set_property -dict { PACKAGE_PIN AH24  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[6][3] }];
set_property -dict { PACKAGE_PIN AH21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[6][4] }];
set_property -dict { PACKAGE_PIN AH22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[6][4] }];
set_property -dict { PACKAGE_PIN AF23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[6][5] }];
set_property -dict { PACKAGE_PIN AG23  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[6][5] }];

set_property -dict { PACKAGE_PIN AC21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkP[7] }];
set_property -dict { PACKAGE_PIN AD21  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcFClkN[7] }];
set_property -dict { PACKAGE_PIN AE19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkP[7] }];
set_property -dict { PACKAGE_PIN AF20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDClkN[7] }];
set_property -dict { PACKAGE_PIN AG20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[7][0] }];
set_property -dict { PACKAGE_PIN AH20  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[7][0] }];
set_property -dict { PACKAGE_PIN AF18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[7][1] }];
set_property -dict { PACKAGE_PIN AG18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[7][1] }];
set_property -dict { PACKAGE_PIN AG19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[7][2] }];
set_property -dict { PACKAGE_PIN AH19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[7][2] }];
set_property -dict { PACKAGE_PIN AF17  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[7][3] }];
set_property -dict { PACKAGE_PIN AG17  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[7][3] }];
set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[7][4] }];
set_property -dict { PACKAGE_PIN AC22  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[7][4] }];
set_property -dict { PACKAGE_PIN AD18  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataP[7][5] }];
set_property -dict { PACKAGE_PIN AD19  IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 } [get_ports { adcDataN[7][5] }];

set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVDS  } [get_ports { adcClkP[0] }];
set_property -dict { PACKAGE_PIN F18  IOSTANDARD LVDS  } [get_ports { adcClkN[0] }];
set_property -dict { PACKAGE_PIN M22  IOSTANDARD LVDS  } [get_ports { adcClkP[1] }];
set_property -dict { PACKAGE_PIN L22  IOSTANDARD LVDS  } [get_ports { adcClkN[1] }];
set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVDS  } [get_ports { adcClkP[2] }];
set_property -dict { PACKAGE_PIN AD27 IOSTANDARD LVDS  } [get_ports { adcClkN[2] }];
set_property -dict { PACKAGE_PIN AE28 IOSTANDARD LVDS  } [get_ports { adcClkP[3] }];
set_property -dict { PACKAGE_PIN AF28 IOSTANDARD LVDS  } [get_ports { adcClkN[3] }];


set_property -dict { PACKAGE_PIN D24  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[0] }];
set_property -dict { PACKAGE_PIN J23  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[1] }];
set_property -dict { PACKAGE_PIN A22  IOSTANDARD LVCMOS18 } [get_ports { adcSclk[0] }];
set_property -dict { PACKAGE_PIN A23  IOSTANDARD LVCMOS18 } [get_ports { adcSdio[0] }];
set_property -dict { PACKAGE_PIN B18  IOSTANDARD LVCMOS18 } [get_ports { adcPdwn[0] }];

set_property -dict { PACKAGE_PIN F27  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[2] }];
set_property -dict { PACKAGE_PIN G27  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[3] }];
set_property -dict { PACKAGE_PIN C26  IOSTANDARD LVCMOS18 } [get_ports { adcSclk[1] }];
set_property -dict { PACKAGE_PIN C27  IOSTANDARD LVCMOS18 } [get_ports { adcSdio[1] }];
set_property -dict { PACKAGE_PIN M25  IOSTANDARD LVCMOS18 } [get_ports { adcPdwn[1] }];

set_property -dict { PACKAGE_PIN T26  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[4] }];
set_property -dict { PACKAGE_PIN W22  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[5] }];
set_property -dict { PACKAGE_PIN R23  IOSTANDARD LVCMOS18 } [get_ports { adcSclk[2] }];
set_property -dict { PACKAGE_PIN R24  IOSTANDARD LVCMOS18 } [get_ports { adcSdio[2] }];
set_property -dict { PACKAGE_PIN AA23 IOSTANDARD LVCMOS18 } [get_ports { adcPdwn[2] }];

set_property -dict { PACKAGE_PIN AD17  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[6] }];
set_property -dict { PACKAGE_PIN AE18  IOSTANDARD LVCMOS18 } [get_ports { adcCsb[7] }];
set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS18 } [get_ports { adcSclk[3] }];
set_property -dict { PACKAGE_PIN AB19  IOSTANDARD LVCMOS18 } [get_ports { adcSdio[3] }];
set_property -dict { PACKAGE_PIN AG22  IOSTANDARD LVCMOS18 } [get_ports { adcPdwn[3] }];

# I2C Interfaces

set_property -dict { PACKAGE_PIN AH16  IOSTANDARD LVCMOS33 } [get_ports { locI2cScl }];
set_property -dict { PACKAGE_PIN AH17  IOSTANDARD LVCMOS33 } [get_ports { locI2cSda }];

set_property -dict { PACKAGE_PIN AG15  IOSTANDARD LVCMOS33 } [get_ports { qsfpI2cScl }];
set_property -dict { PACKAGE_PIN AH15  IOSTANDARD LVCMOS33 } [get_ports { qsfpI2cSda }];
set_property -dict { PACKAGE_PIN AG14  IOSTANDARD LVCMOS33 } [get_ports { qsfpI2cResetL }];

set_property -dict { PACKAGE_PIN AH14  IOSTANDARD LVCMOS33 } [get_ports { sfpI2cScl }];
set_property -dict { PACKAGE_PIN AF13  IOSTANDARD LVCMOS33 } [get_ports { sfpI2cSda }];

set_property -dict { PACKAGE_PIN AG13  IOSTANDARD LVCMOS33 } [get_ports { anaPmBusScl }];
set_property -dict { PACKAGE_PIN AE16  IOSTANDARD LVCMOS33 } [get_ports { anaPmBusSda }];
set_property -dict { PACKAGE_PIN AF16  IOSTANDARD LVCMOS33 } [get_ports { anaPmBusAlertL }];

set_property -dict { PACKAGE_PIN AE15  IOSTANDARD LVCMOS33 } [get_ports { digPmBusScl }];
set_property -dict { PACKAGE_PIN AF15  IOSTANDARD LVCMOS33 } [get_ports { digPmBusSda }];
set_property -dict { PACKAGE_PIN AE13  IOSTANDARD LVCMOS33 } [get_ports { digPmBusAlertL }];

set_property -dict { PACKAGE_PIN C15  IOSTANDARD LVCMOS33 } [get_ports { leds[0] }];
set_property -dict { PACKAGE_PIN C16  IOSTANDARD LVCMOS33 } [get_ports { leds[1] }];
set_property -dict { PACKAGE_PIN C14  IOSTANDARD LVCMOS33 } [get_ports { leds[2] }];
set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS33 } [get_ports { leds[3] }];
set_property -dict { PACKAGE_PIN B13  IOSTANDARD LVCMOS33 } [get_ports { leds[4] }];
set_property -dict { PACKAGE_PIN B14  IOSTANDARD LVCMOS33 } [get_ports { leds[5] }];
set_property -dict { PACKAGE_PIN A15  IOSTANDARD LVCMOS33 } [get_ports { leds[6] }];
set_property -dict { PACKAGE_PIN A16  IOSTANDARD LVCMOS33 } [get_ports { leds[7] }];

# Thermistors (SYSMON)
set_property -dict { PACKAGE_PIN AB13  IOSTANDARD ANALOG } [get_ports { thermistorP[0] }]
set_property -dict { PACKAGE_PIN AB14  IOSTANDARD ANALOG } [get_ports { thermistorN[0] }]
set_property -dict { PACKAGE_PIN AC14  IOSTANDARD ANALOG } [get_ports { thermistorP[1] }]
set_property -dict { PACKAGE_PIN AC15  IOSTANDARD ANALOG } [get_ports { thermistorN[1] }]
set_property -dict { PACKAGE_PIN AB15  IOSTANDARD ANALOG } [get_ports { thermistorP[2] }]
set_property -dict { PACKAGE_PIN AB16  IOSTANDARD ANALOG } [get_ports { thermistorN[2] }]
set_property -dict { PACKAGE_PIN AC16  IOSTANDARD ANALOG } [get_ports { thermistorP[3] }]
set_property -dict { PACKAGE_PIN AD16  IOSTANDARD ANALOG } [get_ports { thermistorN[3] }]

# Enable analog and hybrid voltage regulators
set_property -dict { PACKAGE_PIN AE14  IOSTANDARD LVCMOS33 } [get_ports { anaVREn }];
set_property -dict { PACKAGE_PIN AD13  IOSTANDARD LVCMOS33 } [get_ports { hyVREn }];


# Hybrid Power Monitor
set_property -dict { PACKAGE_PIN G13  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[0] }];
set_property -dict { PACKAGE_PIN F13  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[0] }];
set_property -dict { PACKAGE_PIN G14  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[1] }];
set_property -dict { PACKAGE_PIN G15  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[1] }];
set_property -dict { PACKAGE_PIN F15  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[2] }];
set_property -dict { PACKAGE_PIN F16  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[2] }];
set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[3] }];
set_property -dict { PACKAGE_PIN F17  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[3] }];
set_property -dict { PACKAGE_PIN E13  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[4] }];
set_property -dict { PACKAGE_PIN E14  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[4] }];
set_property -dict { PACKAGE_PIN E15  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[5] }];
set_property -dict { PACKAGE_PIN E16  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[5] }];
set_property -dict { PACKAGE_PIN D13  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[6] }];
set_property -dict { PACKAGE_PIN D14  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[6] }];
set_property -dict { PACKAGE_PIN D16  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cScl[7] }];
set_property -dict { PACKAGE_PIN D17  IOSTANDARD LVCMOS33 } [get_ports { hyPwrI2cSda[7] }];


# Hybrid Power Enables
set_property -dict { PACKAGE_PIN B10  IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[0] }];
set_property -dict { PACKAGE_PIN B9   IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[1] }];
set_property -dict { PACKAGE_PIN C12  IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[2] }];
set_property -dict { PACKAGE_PIN B12  IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[3] }];
set_property -dict { PACKAGE_PIN AD11 IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[4] }];
set_property -dict { PACKAGE_PIN AE10 IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[5] }];
set_property -dict { PACKAGE_PIN AD9  IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[6] }];
set_property -dict { PACKAGE_PIN AE9  IOSTANDARD LVCMOS25 } [get_ports { hyPwrEnOut[7] }];

# Hybrid IO
set_property -dict { PACKAGE_PIN H20   IOSTANDARD LVDS  } [get_ports { hyClkP[0] }];
set_property -dict { PACKAGE_PIN H21   IOSTANDARD LVDS  } [get_ports { hyClkN[0] }];
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVDS  } [get_ports { hyClkP[1] }];
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVDS  } [get_ports { hyClkN[1] }];
set_property -dict { PACKAGE_PIN P22   IOSTANDARD LVDS  } [get_ports { hyClkP[2] }];
set_property -dict { PACKAGE_PIN N22   IOSTANDARD LVDS  } [get_ports { hyClkN[2] }];
set_property -dict { PACKAGE_PIN L23   IOSTANDARD LVDS  } [get_ports { hyClkP[3] }];
set_property -dict { PACKAGE_PIN K23   IOSTANDARD LVDS  } [get_ports { hyClkN[3] }];
set_property -dict { PACKAGE_PIN AB23  IOSTANDARD LVDS  } [get_ports { hyClkP[4] }];
set_property -dict { PACKAGE_PIN AB24  IOSTANDARD LVDS  } [get_ports { hyClkN[4] }];
set_property -dict { PACKAGE_PIN AC27  IOSTANDARD LVDS  } [get_ports { hyClkP[5] }];
set_property -dict { PACKAGE_PIN AD28  IOSTANDARD LVDS  } [get_ports { hyClkN[5] }];
set_property -dict { PACKAGE_PIN AF27  IOSTANDARD LVDS  } [get_ports { hyClkP[6] }];
set_property -dict { PACKAGE_PIN AG28  IOSTANDARD LVDS  } [get_ports { hyClkN[6] }];
set_property -dict { PACKAGE_PIN AE25  IOSTANDARD LVDS  } [get_ports { hyClkP[7] }];
set_property -dict { PACKAGE_PIN AE26  IOSTANDARD LVDS  } [get_ports { hyClkN[7] }];


set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVDS  } [get_ports { hyTrgP[0] }];
set_property -dict { PACKAGE_PIN A21   IOSTANDARD LVDS  } [get_ports { hyTrgN[0] }];
set_property -dict { PACKAGE_PIN B25   IOSTANDARD LVDS  } [get_ports { hyTrgP[1] }];
set_property -dict { PACKAGE_PIN A25   IOSTANDARD LVDS  } [get_ports { hyTrgN[1] }];
set_property -dict { PACKAGE_PIN D27   IOSTANDARD LVDS  } [get_ports { hyTrgP[2] }];
set_property -dict { PACKAGE_PIN D28   IOSTANDARD LVDS  } [get_ports { hyTrgN[2] }];
set_property -dict { PACKAGE_PIN A26   IOSTANDARD LVDS  } [get_ports { hyTrgP[3] }];
set_property -dict { PACKAGE_PIN A27   IOSTANDARD LVDS  } [get_ports { hyTrgN[3] }];
set_property -dict { PACKAGE_PIN R25   IOSTANDARD LVDS  } [get_ports { hyTrgP[4] }];
set_property -dict { PACKAGE_PIN R26   IOSTANDARD LVDS  } [get_ports { hyTrgN[4] }];
set_property -dict { PACKAGE_PIN R28   IOSTANDARD LVDS  } [get_ports { hyTrgP[5] }];
set_property -dict { PACKAGE_PIN T28   IOSTANDARD LVDS  } [get_ports { hyTrgN[5] }];
set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVDS  } [get_ports { hyTrgP[6] }];
set_property -dict { PACKAGE_PIN AC17  IOSTANDARD LVDS  } [get_ports { hyTrgN[6] }];
set_property -dict { PACKAGE_PIN AC19  IOSTANDARD LVDS  } [get_ports { hyTrgP[7] }];
set_property -dict { PACKAGE_PIN AC20  IOSTANDARD LVDS  } [get_ports { hyTrgN[7] }];


set_property -dict { PACKAGE_PIN A11  IOSTANDARD LVCMOS25  } [get_ports { hyRstL[0] }];
set_property -dict { PACKAGE_PIN A10  IOSTANDARD LVCMOS25  } [get_ports { hyRstL[1] }];
set_property -dict { PACKAGE_PIN A13  IOSTANDARD LVCMOS25  } [get_ports { hyRstL[2] }];
set_property -dict { PACKAGE_PIN A12  IOSTANDARD LVCMOS25  } [get_ports { hyRstL[3] }];
set_property -dict { PACKAGE_PIN AB12 IOSTANDARD LVCMOS25  } [get_ports { hyRstL[4] }];
set_property -dict { PACKAGE_PIN AC12 IOSTANDARD LVCMOS25  } [get_ports { hyRstL[5] }];
set_property -dict { PACKAGE_PIN AC11 IOSTANDARD LVCMOS25  } [get_ports { hyRstL[6] }];
set_property -dict { PACKAGE_PIN AC10 IOSTANDARD LVCMOS25  } [get_ports { hyRstL[7] }];

set_property -dict { PACKAGE_PIN G12  IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[0] }];
set_property -dict { PACKAGE_PIN E9   IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[1] }];
set_property -dict { PACKAGE_PIN D11  IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[2] }];
set_property -dict { PACKAGE_PIN C11  IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[3] }];
set_property -dict { PACKAGE_PIN AF12 IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[4] }];
set_property -dict { PACKAGE_PIN AH9  IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[5] }];
set_property -dict { PACKAGE_PIN AF11 IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[6] }];
set_property -dict { PACKAGE_PIN AE11 IOSTANDARD LVCMOS25  } [get_ports { hyI2cScl[7] }];

set_property -dict { PACKAGE_PIN E11  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[0] }];
set_property -dict { PACKAGE_PIN E10  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[1] }];
set_property -dict { PACKAGE_PIN C9   IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[2] }];
set_property -dict { PACKAGE_PIN D12  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[3] }];
set_property -dict { PACKAGE_PIN AH11 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[4] }];
set_property -dict { PACKAGE_PIN AH10 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[5] }];
set_property -dict { PACKAGE_PIN AG9  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[6] }];
set_property -dict { PACKAGE_PIN AD12 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaOut[7] }];

set_property -dict { PACKAGE_PIN F11  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[0] }];
set_property -dict { PACKAGE_PIN F12  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[1] }];
set_property -dict { PACKAGE_PIN D9   IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[2] }];
set_property -dict { PACKAGE_PIN C10  IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[3] }];
set_property -dict { PACKAGE_PIN AH12 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[4] }];
set_property -dict { PACKAGE_PIN AG12 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[5] }];
set_property -dict { PACKAGE_PIN AG10 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[6] }];
set_property -dict { PACKAGE_PIN AF10 IOSTANDARD LVCMOS25  } [get_ports { hyI2cSdaIn[7] }];

set_property BITSTREAM.CONFIG.CONFIGRATE 85.0  [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
