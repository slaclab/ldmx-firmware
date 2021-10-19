
# IO Types
set_property IOSTANDARD LVCMOS    [get_ports dtmToRtmLsP[0]] # Start of spill
set_property IOSTANDARD LVCMOS    [get_ports dtmToRtmLsM[0]] # Trigger In

set_property IOSTANDARD LVCMOS    [get_ports dtmToRtmLsP[1]] # Busy
set_property IOSTANDARD LVCMOS    [get_ports dtmToRtmLsM[1]] # Trig Re-sync

set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsP[2]]
set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsM[2]]

set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsP[3]]
set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsM[3]]

set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsP[4]]
set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsM[4]]

set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsP[5]]
set_property IOSTANDARD LVDS_25   [get_ports dtmToRtmLsM[5]]

#set_property PULLDOWN true        [get_ports dtmToRtmLsP[5]]
#set_property PULLUP   true        [get_ports dtmToRtmLsM[5]]

#set_property IOSTANDARD LVDS_25  [get_ports plSpareP]
#set_property IOSTANDARD LVDS_25  [get_ports plSpareM]

#set_property PULLDOWN true       [get_ports plSpareP]
#set_property PULLUP   true       [get_ports plSpareM]

# PLL Clocks
#create_clock -name tiRtmClk -period 4 [get_ports dtmToRtmLsP[1]]
create_clock -name locRefClk -period 4 [get_ports locRefClkP]
#set_clock_groups -physically_exclusive -group tiClk250 -group locRefClk

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks fclk0] \
    -group [get_clocks -include_generated_clocks locRefClk] \
    -group [get_clocks -include_generated_clocks ethRefClkP]

