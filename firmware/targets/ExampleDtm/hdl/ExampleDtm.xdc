
# IO Types
# Start of spill
set_property IOSTANDARD LVCMOS25  [get_ports dtmToRtmLsP[0]]
# Trigger in
set_property IOSTANDARD LVCMOS25  [get_ports dtmToRtmLsM[0]]

# Busy
set_property IOSTANDARD LVCMOS25  [get_ports dtmToRtmLsP[1]]
# Trig re-sync
set_property IOSTANDARD LVCMOS25  [get_ports dtmToRtmLsM[1]]

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

create_clock -name pgpRxRecClk -period 8 [get_pins U_LdmxDtmWrapper/U_LdmxDtmPgp_1/U_Pgp2bGtx7FixedLatWrapper_1/Pgp2bGtx7Fixedlat_Inst/Gtx7Core_1/gtxe2_i/RXOUTCLK]
create_generated_clock -name pgpRxRecClkMmcm [get_pins U_LdmxDtmWrapper/U_LdmxDtmPgp_1/U_Pgp2bGtx7FixedLatWrapper_1/RxClkMmcmGen.ClockManager7_1/PllGen.U_Pll/CLKOUT0]

create_generated_clock -name pgpTxClk [get_pins U_LdmxDtmWrapper/U_LdmxDtmPgp_1/U_Pgp2bGtx7FixedLatWrapper_1/BUFDS_GTE2_0_GEN.IBUFDS_GTE2_0/ODIV2]


create_generated_clock -name distClk [get_pins U_LdmxDtmWrapper/U_PLL/MmcmGen.U_Mmcm/CLKOUT0]
create_generated_clock -name distDivClk [get_pins U_LdmxDtmWrapper/U_PLL/MmcmGen.U_Mmcm/CLKOUT1]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks fclk0] \
    -group [get_clocks -include_generated_clocks locRefClk] \
    -group [get_clocks -include_generated_clocks ethRefClkP] \
    -group [get_clocks -include_generated_clocks pgpRxRecClk]

set_clock_groups -asynchronous \
    -group [get_clocks  distClk] \
    -group [get_clocks  pgpTxClk] \
    -group [get_clocks  pgpRxRecClk] \
    -group [get_clocks  clk125]

set_clock_groups -asynchronous \
    -group [get_clocks  distDivClk] \
    -group [get_clocks  pgpTxClk] \
    -group [get_clocks  pgpRxRecClk] \
    -group [get_clocks  clk125]

