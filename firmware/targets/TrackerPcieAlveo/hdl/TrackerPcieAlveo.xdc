##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################



set_property -dict {PACKAGE_PIN AY38 IOSTANDARD DIFF_POD12_DCI } [get_ports ddrClkN ]; # Bank 42 VCCO - VCC1V2 Net "SYSCLK0_300_N" - IO_L13N_T2L_N1_GC_QBC_42
set_property -dict {PACKAGE_PIN AY37 IOSTANDARD DIFF_POD12_DCI } [get_ports ddrClkP]; # Bank 42 VCCO - VCC1V2 Net "SYSCLK0_300_P" - IO_L13P_T2L_N0_GC_QBC_42

create_clock -period 3.332 -name ddrClk [get_ports ddrClkP]

create_generated_clock -name appAxilClk [get_pins {U_axilClk/PllGen.U_Pll/CLKOUT0}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks dmaClk] \
    -group [get_clocks -include_generated_clocks ddrClk]


create_clock -period 5.385 -name qsfp0RefClkP0 [get_ports {qsfp0RefClkP[0]}]
create_clock -period 5.385 -name qsfp1RefClkP0 [get_ports {qsfp1RefClkP[0]}]
create_clock -period 5.385 -name qsfp0RefClkP1 [get_ports {qsfp0RefClkP[1]}]
create_clock -period 5.385 -name qsfp1RefClkP1 [get_ports {qsfp1RefClkP[1]}]
create_clock -period 5.385 -name userClkP   [get_ports {userClkP}]

set_clock_groups -asynchronous \
    -group [get_clocks appAxilClk] \
    -group [get_clocks dnaClk] \
    -group [get_clocks iprogClk]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {qsfp0RefClkP1}] \
    -group [get_clocks {appAxilClk}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {qsfp1RefClkP1}] \
    -group [get_clocks {appAxilClk}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}] \
    -group [get_clocks {appAxilClk}]
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}] \
    -group [get_clocks {appAxilClk}]
	    

set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_AlveoPGP/U_Pgp/*/RXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_AlveoPGP/U_Pgp/*/TXOUTCLK}]] \
    -group [get_clocks -of_objects [get_pins -hier * -filter {name=~U_AlveoPGP/U_Pgp/*/TXOUTCLKPCS}]]  \
    -group [get_clocks appAxilClk]

set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets U_AlveoPGP/U_Pgp/userRefClk[0]]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets U_AlveoPGP/U_Pgp/userRefClk[1]]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets U_AlveoPGP/U_Pgp/userRefClk[2]]
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets U_AlveoPGP/U_Pgp/userRefClk[3]]
	    


# set_clock_groups -asynchronous \
#     -group [get_clocks appAxilClk] \
#     -group [get_clocks dmaClk] \    
#     -group [get_clocks pgpRxClk0] \
#     -group [get_clocks pgpRxClk1] \
#     -group [get_clocks pgpRxClk2] \
#     -group [get_clocks pgpRxClk3] \
#     -group [get_clocks pgpRxClk4] \
#     -group [get_clocks pgpRxClk5] \
#     -group [get_clocks pgpRxClk6] \
#     -group [get_clocks pgpRxClk7] \
#     -group [get_clocks pgpTxClk0] \
#     -group [get_clocks pgpTxClk1] \
#     -group [get_clocks pgpTxClk2] \
#     -group [get_clocks pgpTxClk3] \
#     -group [get_clocks pgpTxClk4] \
#     -group [get_clocks pgpTxClk5] \
#     -group [get_clocks pgpTxClk6] \
#     -group [get_clocks pgpTxClk7] 
