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
# create_generated_clock -name xvcClk [get_pins {U_axilClk/PllGen.U_Pll/CLKOUT1}]

create_clock -name qsfpRefClk0 -period 5.384 [get_ports {qsfpRefClkP[0]}]
create_clock -name qsfpRefClk1 -period 5.384 [get_ports {qsfpRefClkP[1]}]
create_clock -name qsfpRefClk2 -period 5.384 [get_ports {qsfpRefClkP[2]}]
create_clock -name qsfpRefClk3 -period 5.384 [get_ports {qsfpRefClkP[3]}]
create_clock -name qsfpRefClk4 -period 5.384 [get_ports {qsfpRefClkP[4]}]
create_clock -name qsfpRefClk5 -period 5.384 [get_ports {qsfpRefClkP[5]}]
create_clock -name qsfpRefClk6 -period 5.384 [get_ports {qsfpRefClkP[6]}]
create_clock -name qsfpRefClk7 -period 5.384 [get_ports {qsfpRefClkP[7]}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks axilClk] \
    -group [get_clocks -include_generated_clocks dmaClk] \
    -group [get_clocks -include_generated_clocks qsfpRefClk0]
#    -group [get_clocks -include_generated_clocks qsfpRefClk1] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk2] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk3] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk4] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk5]
#    -group [get_clocks -include_generated_clocks qsfpRefClk6] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk7]


set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_PgpLaneWrapper/*/RXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_PgpLaneWrapper/*/TXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_PgpLaneWrapper/*/TXOUTCLKPCS}]]  \
    -group [get_clocks axilClk] \
    -group [get_clocks -include_generated_clocks qsfpRefClk0]
#    -group [get_clocks -include_generated_clocks qsfpRefClk1] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk2] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk3] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk4] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk5] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk6] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk7] \

set_clock_groups -asynchronous \
    -group [get_clocks axilClk] \
    -group [get_clocks dmaClk]

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
