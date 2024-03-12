##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

create_generated_clock -name axilClk [get_pins {U_axilClk/PllGen.U_Pll/CLKOUT0}]

# Fast Control Receiver RefClk
create_clock -name fcRefClk185 -period 5.384 [get_ports {fcRefClk185P}]


# Tracker FEB PGP Ref Clocks
create_clock -name febPgpFcRefClk0 -period 5.384 [get_ports {febPgpRcRefClkP[0]}]
create_clock -name febPgpFcRefClk1 -period 5.384 [get_ports {febPgpRcRefClkP[1]}]
create_clock -name febPgpFcRefClk2 -period 5.384 [get_ports {febPgpRcRefClkP[2]}]
create_clock -name febPgpFcRefClk3 -period 5.384 [get_ports {febPgpRcRefClkP[3]}]
create_clock -name febPgpFcRefClk4 -period 5.384 [get_ports {febPgpRcRefClkP[4]}]
create_clock -name febPgpFcRefClk5 -period 5.384 [get_ports {febPgpRcRefClkP[5]}]
create_clock -name febPgpFcRefClk6 -period 5.384 [get_ports {febPgpRcRefClkP[6]}]
create_clock -name febPgpFcRefClk7 -period 5.384 [get_ports {febPgpRcRefClkP[7]}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks axilClk] \
    -group [get_clocks -include_generated_clocks dmaClk]
#    -group [get_clocks -include_generated_clocks qsfpRefClk0]
#    -group [get_clocks -include_generated_clocks qsfpRefClk1] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk2] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk3] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk4] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk5]
#    -group [get_clocks -include_generated_clocks qsfpRefClk6] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk7]


set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_Pgp/*/RXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_Pgp/*/TXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_Pgp/*/TXOUTCLKPCS}]]  \
    -group [get_clocks axilClk] 
#    -group [get_clocks -include_generated_clocks qsfpRefClk0]
#    -group [get_clocks -include_generated_clocks qsfpRefClk1] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk2] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk3] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk4] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk5] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk6] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk7] \

#set_clock_groups -asynchronous \
#    -group [get_clocks axilClk] \
#    -group [get_clocks dmaClk]

# add_cells_to_pblock SLR1_GRP [get_cells {U_Core}]

# add_cells_to_pblock SLR0_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[0]*}]]
# add_cells_to_pblock SLR0_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[1]*}]]
# add_cells_to_pblock SLR0_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[2]*}]]
# add_cells_to_pblock SLR0_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[3]*}]]
# add_cells_to_pblock SLR1_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[4]*}]]
# add_cells_to_pblock SLR1_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[5]*}]]
# add_cells_to_pblock SLR1_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[6]*}]]
# add_cells_to_pblock SLR2_GRP  [get_cells -of_objects  [get_pins -hier * -filter {name=~U_PgpLaneWrapper/GEN_QUAD[7]*}]]

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_PgpLaneWrapper/GEN_QUAD[*].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks -of_objects [get_pins {U_PgpLaneWrapper/GEN_QUAD[*].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_PgpLaneWrapper/GEN_QUAD[*].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLKPCS}]] -group [get_clocks -of_objects [get_pins {U_PgpLaneWrapper/GEN_QUAD[*].U_Lane/U_Pgp/PgpGtyCoreWrapper_1/U_PgpGtyCore/inst/gen_gtwizard_gtye4_top.PgpGtyCore_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[0].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

