
# DTM Clock
#create_clock -name dtmClk -period 8.0 [get_ports dtmRefClkP]

#create_generated_clock -name distClk \
#    [get_pins {GenDistClkPll.ClockManager7_1/PllGen.U_Pll/CLKOUT0}]
#    [get_nets distClk]
#-source [get_ports dtmRefClkP] \

# PGP Clocks
create_clock -name locRefClk .-period 4.0  [get_ports locRefClkP]
create_clock -name dtmRefClk  -period 2.68 [get_ports dtmRefClkP]
create_clock -name dtmDistClk -period 5.37 [get_ports dtmClkP[0]]

#create_generated_clock -name pgpClk \
#    [get_pins ClockManager7_PGP/MmcmGen.U_Mmcm/CLKOUT0]
#    -source [get_ports locRefClkP] \

#create_generated_clock -name dataClk \
#    [get_pins ClockManager7_PGP/MmcmGen.U_Mmcm/CLKOUT1]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks fclk0] \
    -group [get_clocks -include_generated_clocks locRefClk] \
    -group [get_clocks -include_generated_clocks ethRefClkP] \
    -group [get_clocks -include_generated_clocks dtmRefClk] \
    -group [get_clocks -include_generated_clocks dtmDistClk]

#set_clock_groups -asynchronous \
#    -group [get_clocks pgpClk] \
#    -group [get_clocks dataClk]

