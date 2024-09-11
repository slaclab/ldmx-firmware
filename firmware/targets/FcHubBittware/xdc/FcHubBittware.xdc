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
#create_clock -name fcRefClk185 -period 5.384 [get_ports {fcRefClk185P}]



# Tracker FEB PGP Ref Clocks
# The fcRefClk period is subject to change, depending on the GT used:
# EXTREF -> 5.384 (185.x MHz)
# FIXEDLAT -> 2.691 (371.x MHz)
create_clock -name fcRefClk -period 5.384 [get_ports {qsfpRefClkP[0]}]
create_clock -name febPgpFcRefClk0 -period 5.384 [get_ports {qsfpRefClkP[4]}]
create_clock -name febPgpFcRefClk1 -period 5.384 [get_ports {qsfpRefClkP[5]}]
# create_clock -name febPgpFcRefClk3 -period 5.384 [get_ports {febPgpRcRefClkP[3]}]
# create_clock -name febPgpFcRefClk4 -period 5.384 [get_ports {febPgpRcRefClkP[4]}]
# create_clock -name febPgpFcRefClk5 -period 5.384 [get_ports {febPgpRcRefClkP[5]}]
# create_clock -name febPgpFcRefClk6 -period 5.384 [get_ports {febPgpRcRefClkP[6]}]
# create_clock -name febPgpFcRefClk7 -period 5.384 [get_ports {febPgpRcRefClkP[7]}]

# Recovered FC clock after MMCM
create_generated_clock -name fcRecClk [get_pins U_FcHub_1/U_Lcls2TimingRx_1/RX_CLK_MMCM_GEN.U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]

# set_clock_groups -asynchronous \
#     -group [get_clocks -include_generated_clocks axilClk] \
#     -group [get_clocks -include_generated_clocks dmaClk]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks axilClk] \
    -group [get_clocks -include_generated_clocks dmaClk] \
    -group [get_clocks -include_generated_clocks fcRefClk] \
    -group [get_clocks -include_generated_clocks febPgpFcRefClk0] \
    -group [get_clocks -include_generated_clocks febPgpFcRefClk1] \
    -group [get_clocks fcRecClk] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Lcls2TimingRx_1/*/RXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Lcls2TimingRx_1/*/TXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Lcls2TimingRx_1/*/TXOUTCLKPCS}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Pgp2fcGt*Core/*/RXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Pgp2fcGt*Core/*/TXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Pgp2fcGt*Core/*/TXOUTCLKPCS}]]


#    -group [get_clocks -include_generated_clocks qsfpRefClk0]
#    -group [get_clocks -include_generated_clocks qsfpRefClk1] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk2] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk3] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk4] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk5]
#    -group [get_clocks -include_generated_clocks qsfpRefClk6] \
#    -group [get_clocks -include_generated_clocks qsfpRefClk7]


# set_clock_groups -asynchronous \
#     -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Pgp2fcGt*Core/*/RXOUTCLK}]] \
#     -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Pgp2fcGt*Core/*/TXOUTCLK}]] \
#     -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/U_Pgp2fcGt*Core/*/TXOUTCLKPCS}]]  \
#     -group [get_clocks axilClk] \
#     -group [get_clocks dmaClk]
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
