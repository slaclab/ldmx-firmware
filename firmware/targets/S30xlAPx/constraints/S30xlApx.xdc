# Input Clocks
create_clock -name clk125In -period 8.0 [get_ports clk125InP];
create_clock -name lclsTimingRefClk -period 5.384 [get_ports lclsTimingRefClk185P]
create_clock -name fcHubRefClk0 -period 5.384 [get_ports fcHubRefClkP[0]]
create_clock -name fcHubRefClk1 -period 5.384 [get_ports fcHubRefClkP[1]]
create_clock -name appFcRefClk -period 5.384 [get_ports appFcRefClkP]
create_clock -name tsRefClk250 -period 4.0 [get_ports tsRefClk250P]
create_clock -name ethRefClk156 -period 6.4 [get_ports ethRefClk156P]

# LCLS Timing
# create_generated_clock -name lclsTimingTxUsrClk [get_pins U_FcHub_1/U_Lcls2TimingRx_1/U_BUFG_GT_DIV2/O]
create_generated_clock -name lclsTimingTxOutClkPcs [get_pins -hier * -filter {name=~U_FcHub_1/U_Lcls2TimingRx_1/*/TXOUTCLKPCS}]
create_generated_clock -name lclsTimingTxOutClk [get_pins -hier * -filter {name=~U_FcHub_1/U_Lcls2TimingRx_1/*/TXOUTCLK}]
create_clock -name lclsTimingRxOutClk -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/U_Lcls2TimingRx_1/*/RXOUTCLK}]
create_generated_clock -name lclsTimingRxOutClkMmcm [get_pins U_FcHub_1/U_Lcls2TimingRx_1/RX_CLK_MMCM_GEN.U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]

# FC Hub Rec Clocks
create_clock -name fcHubRxOutClk0  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[0].GEN_CHANNELS[0]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk1  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[0].GEN_CHANNELS[1]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk2  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[0].GEN_CHANNELS[2]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk3  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[0].GEN_CHANNELS[3]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk4  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[1].GEN_CHANNELS[0]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk5  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[1].GEN_CHANNELS[1]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk6  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[1].GEN_CHANNELS[2]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk7  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[1].GEN_CHANNELS[3]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk8  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[2].GEN_CHANNELS[0]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk9  -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[2].GEN_CHANNELS[1]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk10 -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[2].GEN_CHANNELS[2]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk11 -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[2].GEN_CHANNELS[3]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk12 -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[3].GEN_CHANNELS[0]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk13 -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[3].GEN_CHANNELS[1]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk14 -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[3].GEN_CHANNELS[2]*/*/RXOUTCLK}]
create_clock -name fcHubRxOutClk15 -period 5.384 [get_pins -hier * -filter {name=~U_FcHub_1/*/GEN_QUADS[3].GEN_CHANNELS[3]*/*/RXOUTCLK}]

# App FC Clocks
create_clock -name appFcRxOutClk -period 5.384 [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/RXOUTCLK}]
create_generated_clock -name appFcRxOutClkMmcm [get_pins U_S30xlAppCore_1/U_FcReceiver_1/U_LdmxPgpFcLane_1/RX_CLK_MMCM_GEN.U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]
create_clock -name appFcTxOutClkPcs -period 5.384 [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/TXOUTCLKPCS}]


# TS Rec Clocks
create_clock -name tsRxOutClk0 -period 4.0 [get_pins -hier * -filter {name=~*U_TsDataRx_1/*/GEN_LANES[0]*/RXOUTCLK}]
create_clock -name tsRxOutClk1 -period 4.0 [get_pins -hier * -filter {name=~*U_TsDataRx_1/*/GEN_LANES[1]*/RXOUTCLK}]

create_generated_clock -name tsTxOutClk0 [get_pins -hier * -filter {name=~*U_TsDataRx_1/*/GEN_LANES[0]*/TXOUTCLK}]
create_generated_clock -name tsTxOutClk1 [get_pins -hier * -filter {name=~*U_TsDataRx_1/*/GEN_LANES[1]*/TXOUTCLK}]

# Eth GT Clocks
create_generated_clock -name ethTxOutClk [get_pins -hier * -filter {name=~U_TenGigEthGtyCore_1/*/TXOUTCLK}]
create_generated_clock -name ethTxOutClkPcs [get_pins -hier * -filter {name=~U_TenGigEthGtyCore_1/*/TXOUTCLKPCS}]
create_generated_clock -name ethRxOutClk [get_pins -hier * -filter {name=~U_TenGigEthGtyCore_1/*/RXOUTCLK}]


########################################################
# Clock Groups
########################################################
# set_clock_groups -asynchronous \
#     -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/RXOUTCLK}]] \
#     -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/TXOUTCLK}]] \
#     -group [get_clocks -of_objects [get_pins -hier * -filter {name=~*/TXOUTCLKPCS}]]

# Primary clocks and recovered clocks
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks clk125In] \
    -group [get_clocks -include_generated_clocks lclsTimingRefClk] \
    -group [get_clocks -include_generated_clocks fcHubRefClk0] \
    -group [get_clocks -include_generated_clocks appFcRefClk] \
    -group [get_clocks -include_generated_clocks tsRefClk250] \
    -group [get_clocks -include_generated_clocks ethRefClk156] \
    -group [get_clocks -include_generated_clocks lclsTimingRxOutClk] \
    -group [get_clocks -include_generated_clocks apFcRxOutClk]

set_clock_groups -asynchronous \
    -group [get_clocks appFcTxOutClkPcs] \
    -group [get_clocks -include_generated_clocks appFcRxOutClk] \
    -group [get_clocks appFcRefClk]

#Ethernet Clocks
set_clock_groups -asynchronous \
    -group [get_clocks ethRefClk156]    
    -group [get_clocks ethTxOutClkPcs] \
    -group [get_clocks ethRxOutClk] \
    -group [get_clocks ethTxOutClk]

set_clock_groups -asynchronous \
    -group [get_clocks ethRxOutClk] \
    -group [get_clocks ethTxOutClk]
    
set_clock_groups -asynchronous \
    -group [get_clocks ethTxOutClkPcs] \
    -group [get_clocks ethTxOutClk] 


set_clock_groups -asynchronous \
    -group [get_clocks ethRefClk156] \
    -group [get_clocks -include_generated_clocks appFcRxOutClk]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks lclsTimingRxOutClk]
    -group [get_clocks ethRefClk156] \
    -group [get_clocks tsRxOutClk0] \
    -group [get_clocks tsRxOutClk1] \    
    -group [get_clocks fcHubRxOutClk0] \
    -group [get_clocks fcHubRxOutClk1] \
    -group [get_clocks fcHubRxOutClk2] \
    -group [get_clocks fcHubRxOutClk3] 

set_clock_groups -asynchronous \
    -group [get_clocks tsRefClk250] \
    -group [get_clocks tsRxOutClk0] \
    -group [get_clocks tsRxOutClk1]

set_clock_groups -asynchronous \
    -group [get_clocks lclsTimingTxOutClkPcs] \
    -group [get_clocks lclsTimingRefClk]

# 125 MHz OSC Clock In
set_property -dict {PACKAGE_PIN H28 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports clk125InP]
set_property -dict {PACKAGE_PIN H29 IOSTANDARD LVDS DIFF_TERM TRUE} [get_ports clk125InN]

# 125 MHz Clock Out
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVDS} [get_ports clk125OutP[0]]; # TOPA_IN1
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVDS} [get_ports clk125OutN[0]];
set_property -dict {PACKAGE_PIN M30 IOSTANDARD LVDS} [get_ports clk125OutP[1]]; # BOTA_IN1
set_property -dict {PACKAGE_PIN L30 IOSTANDARD LVDS} [get_ports clk125OutN[1]];

# Recovered LCLS Timing clock out to synchronous clocks
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVDS} [get_ports lclsTimingRecClkOutP[0]]; # TOPS_IN1
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVDS} [get_ports lclsTimingRecClkOutN[0]];
set_property -dict {PACKAGE_PIN N27 IOSTANDARD LVDS} [get_ports lclsTimingRecClkOutP[1]]; # BOTS_IN1
set_property -dict {PACKAGE_PIN M27 IOSTANDARD LVDS} [get_ports lclsTimingRecClkOutN[1]];


# Bank 120 - FFLY L0 - FF8 - P5-far
# BOT_0 Refclk
# set_property PACKAGE_PIN AN36 [get_ports ]; # BOTS_0P
# set_property PACKAGE_PIN AN37 [get_ports ]; # BOTS_0N
# set_property PACKAGE_PIN AM34 [get_ports ]; # BOTA_0P
# set_property PACKAGE_PIN AM35 [get_ports ]; # BOTA_0N

# set_property PACKAGE_PIN BF38 [get_ports ]; # TX0P - FFLY_TX4P
# set_property PACKAGE_PIN BF39 [get_ports ]; # TX0N - FFLY_TX4N
# set_property PACKAGE_PIN BF33 [get_ports ]; # RX0P - FFLY_RX2N - Pin Swap
# set_property PACKAGE_PIN BF34 [get_ports ]; # RX0N - FFLY_RX2P - Pin Swap
# set_property PACKAGE_PIN BE36 [get_ports ]; # TX1P - FFLY_TX3P
# set_property PACKAGE_PIN BE37 [get_ports ]; # TX1N - FFLY_TX3N
# set_property PACKAGE_PIN BD33 [get_ports ]; # RX1P - FFLY_RX1N - Pin Swap
# set_property PACKAGE_PIN BD34 [get_ports ]; # RX1N - FFLY_RX1P - Pin Swap
# set_property PACKAGE_PIN BE40 [get_ports ]; # TX2P - FFLY_TX2P
# set_property PACKAGE_PIN BE41 [get_ports ]; # TX2N - FFLY_TX2N 
# set_property PACKAGE_PIN BF43 [get_ports ]; # RX2P - FFLY_RX4N - Pin Swap
# set_property PACKAGE_PIN BF44 [get_ports ]; # RX2N - FFLY_RX4P - Pin Swap
# set_property PACKAGE_PIN BD38 [get_ports ]; # TX3P - FFLY_TX1P
# set_property PACKAGE_PIN BD39 [get_ports ]; # TX3N - FFLY_TX1N
# set_property PACKAGE_PIN BD43 [get_ports ]; # RX3P - FFLY_RX3N - Pin Swap
# set_property PACKAGE_PIN BD44 [get_ports ]; # RX3N - FFLY_RX3P - Pin Swap

# # Bank 121 - FFLY L1 - FF12 - P5-near
# set_property PACKAGE_PIN BC40 [get_ports ]; # TX0P - FFLY_TX3P
# set_property PACKAGE_PIN BC41 [get_ports ]; # TX0N - FFLY_TX3N
# set_property PACKAGE_PIN BC45 [get_ports ]; # RX0P - FFLY_RX1P
# set_property PACKAGE_PIN BC46 [get_ports ]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN BB38 [get_ports ]; # TX1P - FFLY_TX4P
# set_property PACKAGE_PIN BB39 [get_ports ]; # TX1N - FFLY_TX4N
# set_property PACKAGE_PIN BB43 [get_ports ]; # RX1P - FFLY_RX2P
# set_property PACKAGE_PIN BB44 [get_ports ]; # RX1N - FFLY_RX2N
# set_property PACKAGE_PIN BA40 [get_ports ]; # TX2P - FFLY_TX1P
# set_property PACKAGE_PIN BA41 [get_ports ]; # TX2N - FFLY_TX1N 
# set_property PACKAGE_PIN BA45 [get_ports ]; # RX2P - FFLY_RX3P
# set_property PACKAGE_PIN BA45 [get_ports ]; # RX2N - FFLY_RX3N
# set_property PACKAGE_PIN AY38 [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN AY39 [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN AY43 [get_ports ]; # RX3P - FFLY_RX4P
# set_property PACKAGE_PIN AY44 [get_ports ]; # RX3N - FFLY_RX4N

# # Bank 122 - FFLY L2 - FF16 - P6-near
# # BOT_1 Refclk
# set_property PACKAGE_PIN AJ36 [get_ports ]; # BOTS_1P
# set_property PACKAGE_PIN AJ37 [get_ports ]; # BOTS_1N
# set_property PACKAGE_PIN AH34 [get_ports ]; # BOTA_1P
# set_property PACKAGE_PIN AH35 [get_ports ]; # BOTA_1N

# set_property PACKAGE_PIN AW40 [get_ports ]; # TX0P - FFLY_TX3P
# set_property PACKAGE_PIN AW41 [get_ports ]; # TX0N - FFLY_TX3N
# set_property PACKAGE_PIN AW45 [get_ports ]; # RX0P - FFLY_RX1P
# set_property PACKAGE_PIN AW46 [get_ports ]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN AV38 [get_ports ]; # TX1P - FFLY_TX4P
# set_property PACKAGE_PIN AV39 [get_ports ]; # TX1N - FFLY_TX4N
# set_property PACKAGE_PIN AV43 [get_ports ]; # RX1P - FFLY_RX2P
# set_property PACKAGE_PIN AV44 [get_ports ]; # RX1N - FFLY_RX2N
# set_property PACKAGE_PIN AU40 [get_ports ]; # TX2P - FFLY_TX1P
# set_property PACKAGE_PIN AU41 [get_ports ]; # TX2N - FFLY_TX1N 
# set_property PACKAGE_PIN AU45 [get_ports ]; # RX2P - FFLY_RX3P
# set_property PACKAGE_PIN AU46 [get_ports ]; # RX2N - FFLY_RX3N
# set_property PACKAGE_PIN AT38 [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN AT39 [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN AT43 [get_ports ]; # RX3P - FFLY_RX4P
# set_property PACKAGE_PIN AT44 [get_ports ]; # RX3N - FFLY_RX4N

# # Bank 124 - FFLY L3 - FF10 - P7-near
# set_property PACKAGE_PIN AR40 [get_ports ]; # TX0P - FFLY_TX3P
# set_property PACKAGE_PIN AR41 [get_ports ]; # TX0N - FFLY_TX3N
# set_property PACKAGE_PIN AR45 [get_ports ]; # RX0P - FFLY_RX1P
# set_property PACKAGE_PIN AR45 [get_ports ]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN AR38 [get_ports ]; # TX1P - FFLY_TX4P
# set_property PACKAGE_PIN AR39 [get_ports ]; # TX1N - FFLY_TX4N
# set_property PACKAGE_PIN AP43 [get_ports ]; # RX1P - FFLY_RX2P
# set_property PACKAGE_PIN AP44 [get_ports ]; # RX1N - FFLY_RX2N
# set_property PACKAGE_PIN AN40 [get_ports ]; # TX2P - FFLY_TX1P
# set_property PACKAGE_PIN AN41 [get_ports ]; # TX2N - FFLY_TX1N 
# set_property PACKAGE_PIN AN45 [get_ports ]; # RX2P - FFLY_RX3P
# set_property PACKAGE_PIN AN46 [get_ports ]; # RX2N - FFLY_RX3N
# set_property PACKAGE_PIN AM38 [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN AM39 [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN AM43 [get_ports ]; # RX3P - FFLY_RX4P
# set_property PACKAGE_PIN AM44 [get_ports ]; # RX3N - FFLY_RX4N

# Bank 125 - FFLY L4 - FF14 - P7-far
# BOT_2 Refclk
# set_property PACKAGE_PIN AE36 [get_ports ]; # BOTS_2P
# set_property PACKAGE_PIN AE37 [get_ports ]; # BOTS_2N
set_property PACKAGE_PIN AD34 [get_ports appFcRefClkP]; # BOTA_2P
set_property PACKAGE_PIN AD35 [get_ports appFcRefClkN]; # BOTA_2N

set_property PACKAGE_PIN AL40 [get_ports appFcTxP]; # TX0P - FFLY_TX3P
set_property PACKAGE_PIN AL41 [get_ports appFcTxN]; # TX0N - FFLY_TX3N
set_property PACKAGE_PIN AL45 [get_ports appFcRxP]; # RX0P - FFLY_RX1P
set_property PACKAGE_PIN AL46 [get_ports appFcRxN]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN AK38 [get_ports ]; # TX1P - FFLY_TX4P
# set_property PACKAGE_PIN AK39 [get_ports ]; # TX1N - FFLY_TX4N
# set_property PACKAGE_PIN AK43 [get_ports ]; # RX1P - FFLY_RX2P
# set_property PACKAGE_PIN AK44 [get_ports ]; # RX1N - FFLY_RX2N
# set_property PACKAGE_PIN AJ40 [get_ports ]; # TX2P - FFLY_TX1P
# set_property PACKAGE_PIN AJ41 [get_ports ]; # TX2N - FFLY_TX1N 
# set_property PACKAGE_PIN AJ45 [get_ports ]; # RX2P - FFLY_RX3P
# set_property PACKAGE_PIN AJ46 [get_ports ]; # RX2N - FFLY_RX3N
# set_property PACKAGE_PIN AH38 [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN AH39 [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN AH43 [get_ports ]; # RX3P - FFLY_RX4P
# set_property PACKAGE_PIN AH44 [get_ports ]; # RX3N - FFLY_RX4N

# Bank 126 - AXILINK
# set_property PACKAGE_PIN  [get_ports ]; # TX0P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX0N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX0P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX0N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX1P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX1N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX1P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX1N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX2P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX2N - FFLY_TXN 
# set_property PACKAGE_PIN  [get_ports ]; # RX2P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX2N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX3P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX3N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX3P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX3N - FFLY_RXN

# Bank 127 - FFLY L5 - FF19 - P8-near
# set_property PACKAGE_PIN AA36 [get_ports ]; # BOTS_4P
# set_property PACKAGE_PIN AA37 [get_ports ]; # BOTS_4N
# set_property PACKAGE_PIN Y34  [get_ports ]; # BOTA_4P
# set_property PACKAGE_PIN Y35  [get_ports ]; # BOTA_4N
# set_property PACKAGE_PIN AC40 [get_ports ]; # TX0P - FFLY_TX3P
# set_property PACKAGE_PIN AC41 [get_ports ]; # TX0N - FFLY_TX3N
# set_property PACKAGE_PIN AC45 [get_ports ]; # RX0P - FFLY_RX1P
# set_property PACKAGE_PIN AC46 [get_ports ]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN AB38 [get_ports ]; # TX1P - FFLY_TX4P
# set_property PACKAGE_PIN AB39 [get_ports ]; # TX1N - FFLY_TX4N
# set_property PACKAGE_PIN AB43 [get_ports ]; # RX1P - FFLY_RX2P
# set_property PACKAGE_PIN AB44 [get_ports ]; # RX1N - FFLY_RX2N
# set_property PACKAGE_PIN AA40 [get_ports ]; # TX2P - FFLY_TX1P
# set_property PACKAGE_PIN AA41 [get_ports ]; # TX2N - FFLY_TX1N 
# set_property PACKAGE_PIN AA45 [get_ports ]; # RX2P - FFLY_RX3P
# set_property PACKAGE_PIN AA46 [get_ports ]; # RX2N - FFLY_RX3N
# set_property PACKAGE_PIN Y38  [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN Y39  [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN Y43  [get_ports ]; # RX3P - FFLY_RX4P
# set_property PACKAGE_PIN Y44  [get_ports ]; # RX3N - FFLY_RX4N

# Bank 128 - FFLY L6 - FF18 - P8-far
# set_property PACKAGE_PIN W40 [get_ports ]; # TX0P - FFLY_TX3P
# set_property PACKAGE_PIN W41 [get_ports ]; # TX0N - FFLY_TX3N
# set_property PACKAGE_PIN W45 [get_ports ]; # RX0P - FFLY_RX1P
# set_property PACKAGE_PIN W46 [get_ports ]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN V38 [get_ports ]; # TX1P - FFLY_TX4P
# set_property PACKAGE_PIN V39 [get_ports ]; # TX1N - FFLY_TX4N
# set_property PACKAGE_PIN V43 [get_ports ]; # RX1P - FFLY_RX2P
# set_property PACKAGE_PIN V44 [get_ports ]; # RX1N - FFLY_RX2N
# set_property PACKAGE_PIN U40 [get_ports ]; # TX2P - FFLY_TX1P
# set_property PACKAGE_PIN U41 [get_ports ]; # TX2N - FFLY_TX1N 
# set_property PACKAGE_PIN U45 [get_ports ]; # RX2P - FFLY_RX3P
# set_property PACKAGE_PIN U46 [get_ports ]; # RX2N - FFLY_RX3N
# set_property PACKAGE_PIN T38 [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN T39 [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN T43 [get_ports ]; # RX3P - FFLY_RX4P
# set_property PACKAGE_PIN T44 [get_ports ]; # RX3N - FFLY_RX4N

# Bank 129 - FFLY L7 - FF15 - P9-near
set_property PACKAGE_PIN R40 [get_ports fcHubTxP[0]]; # TX0P - FFLY_TX3P
set_property PACKAGE_PIN R41 [get_ports fcHubTxN[0]]; # TX0N - FFLY_TX3N
set_property PACKAGE_PIN R45 [get_ports fcHubRxP[0]]; # RX0P - FFLY_RX1P
set_property PACKAGE_PIN R46 [get_ports fcHubRxN[0]]; # RX0N - FFLY_RX1N
set_property PACKAGE_PIN P38 [get_ports fcHubTxP[1]]; # TX1P - FFLY_TX4P
set_property PACKAGE_PIN P39 [get_ports fcHubTxN[1]]; # TX1N - FFLY_TX4N
set_property PACKAGE_PIN P43 [get_ports fcHubRxP[1]]; # RX1P - FFLY_RX2P
set_property PACKAGE_PIN P44 [get_ports fcHubRxN[1]]; # RX1N - FFLY_RX2N
set_property PACKAGE_PIN N40 [get_ports fcHubTxP[2]]; # TX2P - FFLY_TX1P
set_property PACKAGE_PIN N41 [get_ports fcHubTxN[2]]; # TX2N - FFLY_TX1N 
set_property PACKAGE_PIN N45 [get_ports fcHubRxP[2]]; # RX2P - FFLY_RX3P
set_property PACKAGE_PIN N46 [get_ports fcHubRxN[2]]; # RX2N - FFLY_RX3N
set_property PACKAGE_PIN M38 [get_ports fcHubTxP[3]]; # TX3P - FFLY_TX2P
set_property PACKAGE_PIN M39 [get_ports fcHubTxN[3]]; # TX3N - FFLY_TX2N
set_property PACKAGE_PIN M43 [get_ports fcHubRxP[3]]; # RX3P - FFLY_RX4P
set_property PACKAGE_PIN M44 [get_ports fcHubRxN[3]]; # RX3N - FFLY_RX4N

# Bank 130 - FFLY L8 - FF11 - P9-far
set_property PACKAGE_PIN R36 [get_ports fcHubRefClkP[0]]; # BOTS_5P
set_property PACKAGE_PIN R37 [get_ports fcHubRefClkN[0]]; # BOTS_5N
# set_property PACKAGE_PIN P34 [get_ports ]; # BOTA_5P
# set_property PACKAGE_PIN P35 [get_ports ]; # BOTA_5N
set_property PACKAGE_PIN L40 [get_ports fcHubTxP[4]]; # TX0P - FFLY_TX3P
set_property PACKAGE_PIN L41 [get_ports fcHubTxN[4]]; # TX0N - FFLY_TX3N
set_property PACKAGE_PIN L45 [get_ports fcHubRxP[4]]; # RX0P - FFLY_RX1P
set_property PACKAGE_PIN L46 [get_ports fcHubRxN[4]]; # RX0N - FFLY_RX1N
set_property PACKAGE_PIN K38 [get_ports fcHubTxP[5]]; # TX1P - FFLY_TX4P
set_property PACKAGE_PIN K39 [get_ports fcHubTxN[5]]; # TX1N - FFLY_TX4N
set_property PACKAGE_PIN K43 [get_ports fcHubRxP[5]]; # RX1P - FFLY_RX2P
set_property PACKAGE_PIN K44 [get_ports fcHubRxN[5]]; # RX1N - FFLY_RX2N
set_property PACKAGE_PIN J40 [get_ports fcHubTxP[6]]; # TX2P - FFLY_TX1P
set_property PACKAGE_PIN J41 [get_ports fcHubTxN[6]]; # TX2N - FFLY_TX1N 
set_property PACKAGE_PIN J45 [get_ports fcHubRxP[6]]; # RX2P - FFLY_RX3P
set_property PACKAGE_PIN J46 [get_ports fcHubRxN[6]]; # RX2N - FFLY_RX3N
set_property PACKAGE_PIN H38 [get_ports fcHubTxP[7]]; # TX3P - FFLY_TX2P
set_property PACKAGE_PIN H39 [get_ports fcHubTxN[7]]; # TX3N - FFLY_TX2N
set_property PACKAGE_PIN H43 [get_ports fcHubRxP[7]]; # RX3P - FFLY_RX4P
set_property PACKAGE_PIN H44 [get_ports fcHubRxN[7]]; # RX3N - FFLY_RX4N

# Bank 131 - FFLY L9 - FF17 - P6-far
# set_property PACKAGE_PIN N36 [get_ports ]; # BOTS_6P
# set_property PACKAGE_PIN N37 [get_ports ]; # BOTS_6N
set_property PACKAGE_PIN M34 [get_ports lclsTimingRefClk185P]; # BOTA_6P
set_property PACKAGE_PIN M35 [get_ports lclsTimingRefClk185N]; # BOTA_6N
set_property PACKAGE_PIN G40 [get_ports lclsTimingTxP]; # TX0P - FFLY_TX3P
set_property PACKAGE_PIN G41 [get_ports lclsTimingTxN]; # TX0N - FFLY_TX3N
set_property PACKAGE_PIN G45 [get_ports lclsTimingRxP]; # RX0P - FFLY_RX1P
set_property PACKAGE_PIN G46 [get_ports lclsTimingRxN]; # RX0N - FFLY_RX1N
# set_property PACKAGE_PIN F38 [get_ports ]; # TX1P - FFLY_TX1P
# set_property PACKAGE_PIN F39 [get_ports ]; # TX1N - FFLY_TX1N
# set_property PACKAGE_PIN F43 [get_ports ]; # RX1P - FFLY_RX3P
# set_property PACKAGE_PIN F44 [get_ports ]; # RX1N - FFLY_RX3N
# set_property PACKAGE_PIN G36 [get_ports ]; # TX2P - FFLY_TX4P
# set_property PACKAGE_PIN G37 [get_ports ]; # TX2N - FFLY_TX4N 
# set_property PACKAGE_PIN G31 [get_ports ]; # RX2P - FFLY_RX4N - Pin swap
# set_property PACKAGE_PIN G32 [get_ports ]; # RX2N - FFLY_RX4P - Pin swap
# set_property PACKAGE_PIN F34 [get_ports ]; # TX3P - FFLY_TX2P
# set_property PACKAGE_PIN F35 [get_ports ]; # TX3N - FFLY_TX2N
# set_property PACKAGE_PIN E31 [get_ports ]; # RX3P - FFLY_RX2N - Pin swap
# set_property PACKAGE_PIN E32 [get_ports ]; # RX3N - FFLY_RX2P - Pin swap

# Bank 132 - FFLY L10 - FF13 - P4-far
set_property PACKAGE_PIN L36 [get_ports fcHubRefClkP[1]]; # BOTS_7P
set_property PACKAGE_PIN L37 [get_ports fcHubRefClkN[1]]; # BOTS_7N
# set_property PACKAGE_PIN K34 [get_ports ]; # BOTA_7P
# set_property PACKAGE_PIN K35 [get_ports ]; # BOTA_7N
set_property PACKAGE_PIN E40 [get_ports fcHubTxP[8]]; # TX0P - FFLY_TX4N - Pin swap
set_property PACKAGE_PIN E41 [get_ports fcHubTxN[8]]; # TX0N - FFLY_TX4P - Pin swap
set_property PACKAGE_PIN E45 [get_ports fcHubRxP[8]]; # RX0P - FFLY_RX1P
set_property PACKAGE_PIN E46 [get_ports fcHubRxN[8]]; # RX0N - FFLY_RX1N
set_property PACKAGE_PIN E36 [get_ports fcHubTxP[9]]; # TX1P - FFLY_TX2N - Pin swap
set_property PACKAGE_PIN E37 [get_ports fcHubTxN[9]]; # TX1N - FFLY_TX2P - Pin swap
set_property PACKAGE_PIN D43 [get_ports fcHubRxP[9]]; # RX1P - FFLY_RX3P
set_property PACKAGE_PIN D44 [get_ports fcHubRxN[9]]; # RX1N - FFLY_RX3N
set_property PACKAGE_PIN C40 [get_ports fcHubTxP[10]]; # TX2P - FFLY_TX3N - Pin swap
set_property PACKAGE_PIN C41 [get_ports fcHubTxN[10]]; # TX2N - FFLY_TX3P  - Pin swap
set_property PACKAGE_PIN C45 [get_ports fcHubRxP[10]]; # RX2P - FFLY_RX2P
set_property PACKAGE_PIN C46 [get_ports fcHubRxN[10]]; # RX2N - FFLY_RX2N
set_property PACKAGE_PIN A40 [get_ports fcHubTxP[11]]; # TX3P - FFLY_TX1N - Pin swap
set_property PACKAGE_PIN A41 [get_ports fcHubTxN[11]]; # TX3N - FFLY_TX1P - Pin swap
set_property PACKAGE_PIN B43 [get_ports fcHubRxP[11]]; # RX3P - FFLY_RX4P
set_property PACKAGE_PIN B44 [get_ports fcHubRxN[11]]; # RX3N - FFLY_RX4N

# Bank 133 - FFLY11 - FF9 - P4-near
set_property PACKAGE_PIN D38 [get_ports fcHubTxP[12]]; # TX0P - FFLY_TX3N - Pin swap
set_property PACKAGE_PIN D39 [get_ports fcHubTxN[12]]; # TX0N - FFLY_TX3P - Pin swap
set_property PACKAGE_PIN D33 [get_ports fcHubRxP[12]]; # RX0P - FFLY_RX1P
set_property PACKAGE_PIN D34 [get_ports fcHubRxN[12]]; # RX0N - FFLY_RX1N
set_property PACKAGE_PIN C36 [get_ports fcHubTxP[13]]; # TX1P - FFLY_TX2N - Pin swap
set_property PACKAGE_PIN C37 [get_ports fcHubTxN[13]]; # TX1N - FFLY_TX2P - Pin swap
set_property PACKAGE_PIN C31 [get_ports fcHubRxP[13]]; # RX1P - FFLY_RX3P
set_property PACKAGE_PIN C32 [get_ports fcHubRxN[13]]; # RX1N - FFLY_RX3N
set_property PACKAGE_PIN B38 [get_ports fcHubTxP[14]]; # TX2P - FFLY_TX4N - Pin swap
set_property PACKAGE_PIN B39 [get_ports fcHubTxN[14]]; # TX2N - FFLY_TX4P  - Pin swap
set_property PACKAGE_PIN B33 [get_ports fcHubRxP[14]]; # RX2P - FFLY_RX2P
set_property PACKAGE_PIN B34 [get_ports fcHubRxN[14]]; # RX2N - FFLY_RX2N
set_property PACKAGE_PIN A36 [get_ports fcHubTxP[15]]; # TX3P - FFLY_TX1N - Pin swap
set_property PACKAGE_PIN A37 [get_ports fcHubTxN[15]]; # TX3N - FFLY_TX1P - Pin swap
set_property PACKAGE_PIN A31 [get_ports fcHubRxP[15]]; # RX3P - FFLY_RX4P
set_property PACKAGE_PIN A32 [get_ports fcHubRxN[15]]; # RX3N - FFLY_RX4N



# Bank 220 - FFLY U0 - FF7 - S1
# set_property PACKAGE_PIN AN11 [get_ports ]; # TOPS_7P
# set_property PACKAGE_PIN AN10 [get_ports ]; # TOPS_7N
# set_property PACKAGE_PIN AM13 [get_ports ]; # TOPA_7P
# set_property PACKAGE_PIN AM12 [get_ports ]; # TOPA_7N
# set_property PACKAGE_PIN BF9  [get_ports ]; # TX0P - FFLY_TX3N - Pin swap
# set_property PACKAGE_PIN BF8  [get_ports ]; # TX0N - FFLY_TX3P - Pin swap
# set_property PACKAGE_PIN BF14 [get_ports ]; # RX0P - FFLY_RX4P
# set_property PACKAGE_PIN BF13 [get_ports ]; # RX0N - FFLY_RX4N
# set_property PACKAGE_PIN BE11 [get_ports ]; # TX1P - FFLY_TX1N - Pin swap
# set_property PACKAGE_PIN BE10 [get_ports ]; # TX1N - FFLY_TX1P - Pin swap
# set_property PACKAGE_PIN BD14 [get_ports ]; # RX1P - FFLY_RX3P
# set_property PACKAGE_PIN BD13 [get_ports ]; # RX1N - FFLY_RX3N
# set_property PACKAGE_PIN BE7  [get_ports ]; # TX2P - FFLY_TX4N - Pin swap
# set_property PACKAGE_PIN BE6  [get_ports ]; # TX2N - FFLY_TX4P  - Pin swap
# set_property PACKAGE_PIN BF4  [get_ports ]; # RX2P - FFLY_RX2P
# set_property PACKAGE_PIN BF3  [get_ports ]; # RX2N - FFLY_RX2N
# set_property PACKAGE_PIN BD9  [get_ports ]; # TX3P - FFLY_TX2N - Pin swap
# set_property PACKAGE_PIN BD8  [get_ports ]; # TX3N - FFLY_TX2P - Pin swap
# set_property PACKAGE_PIN BD4  [get_ports ]; # RX3P - FFLY_RX1P
# set_property PACKAGE_PIN BD3  [get_ports ]; # RX3N - FFLY_RX1N

# Bank 221 - FFLY U1 - FF5 - P1-far
# set_property PACKAGE_PIN  [get_ports ]; # TX0P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX0N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX0P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX0N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX1P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX1N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX1P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX1N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX2P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX2N - FFLY_TXN 
# set_property PACKAGE_PIN  [get_ports ]; # RX2P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX2N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX3P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX3N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX3P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX3N - FFLY_RXN

# # Bank 222 - FFLY U2 - FF2 - P1-near
# set_property PACKAGE_PIN  [get_ports ]; # TX0P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX0N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX0P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX0N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX1P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX1N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX1P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX1N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX2P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX2N - FFLY_TXN 
# set_property PACKAGE_PIN  [get_ports ]; # RX2P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX2N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX3P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX3N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX3P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX3N - FFLY_RXN

# # Bank 224 - FFLY U3 - FF6 - P3-far
# set_property PACKAGE_PIN  [get_ports ]; # TX0P - FFLY_TX2P
# set_property PACKAGE_PIN  [get_ports ]; # TX0N - FFLY_TX2N
# set_property PACKAGE_PIN  [get_ports ]; # RX0P - FFLY_RX4P
# set_property PACKAGE_PIN  [get_ports ]; # RX0N - FFLY_RX4N
# set_property PACKAGE_PIN  [get_ports ]; # TX1P - FFLY_TX1P
# set_property PACKAGE_PIN  [get_ports ]; # TX1N - FFLY_TX1N
# set_property PACKAGE_PIN  [get_ports ]; # RX1P - FFLY_RX3P
# set_property PACKAGE_PIN  [get_ports ]; # RX1N - FFLY_RX3N
# set_property PACKAGE_PIN  [get_ports ]; # TX2P - FFLY_TX4P
# set_property PACKAGE_PIN  [get_ports ]; # TX2N - FFLY_TX4N 
# set_property PACKAGE_PIN  [get_ports ]; # RX2P - FFLY_RX2P
# set_property PACKAGE_PIN  [get_ports ]; # RX2N - FFLY_RX2N
# set_property PACKAGE_PIN  [get_ports ]; # TX3P - FFLY_TX3P
# set_property PACKAGE_PIN  [get_ports ]; # TX3N - FFLY_TX3N
# set_property PACKAGE_PIN  [get_ports ]; # RX3P - FFLY_RX1P
# set_property PACKAGE_PIN  [get_ports ]; # RX3N - FFLY_RX1N

# # Bank 225 - FFLY U4 - FF4 - P3-near
# set_property PACKAGE_PIN AE11 [get_ports ]; # TOPS_5
# set_property PACKAGE_PIN AE10 [get_ports ]; # TOPS_5
set_property PACKAGE_PIN AD13 [get_ports tsRefClk250P[0]]; # TOPA_5
set_property PACKAGE_PIN AD12 [get_ports tsRefClk250N[0]]; # TOPA_5
# set_property PACKAGE_PIN AL7 [get_ports ]; # TX0P - FFLY_TX2P
# set_property PACKAGE_PIN AL6 [get_ports ]; # TX0N - FFLY_TX2N
set_property PACKAGE_PIN AL2 [get_ports tsDataRxP[0]]; # RX0P - FFLY_RX4P
set_property PACKAGE_PIN AL1 [get_ports tsDataRxN[0]]; # RX0N - FFLY_RX4N
# set_property PACKAGE_PIN AK9 [get_ports ]; # TX1P - FFLY_TX1P
# set_property PACKAGE_PIN AK8 [get_ports ]; # TX1N - FFLY_TX1N
set_property PACKAGE_PIN AK4 [get_ports tsDataRxP[1]]; # RX1P - FFLY_RX3P
set_property PACKAGE_PIN AK3 [get_ports tsDataRxN[1]]; # RX1N - FFLY_RX3N
# set_property PACKAGE_PIN AJ7 [get_ports ]; # TX2P - FFLY_TX4P
# set_property PACKAGE_PIN AJ6 [get_ports ]; # TX2N - FFLY_TX4N 
# set_property PACKAGE_PIN AJ2 [get_ports ]; # RX2P - FFLY_RX2P
# set_property PACKAGE_PIN AJ1 [get_ports ]; # RX2N - FFLY_RX2N
# set_property PACKAGE_PIN AH9 [get_ports ]; # TX3P - FFLY_TX3P
# set_property PACKAGE_PIN AH8 [get_ports ]; # TX3N - FFLY_TX3N
# set_property PACKAGE_PIN AH4 [get_ports ]; # RX3P - FFLY_RX1P
# set_property PACKAGE_PIN AH3 [get_ports ]; # RX3N - FFLY_RX1N

# Bank 226 - FFLY U5 - FF1 - P2-near
# set_property PACKAGE_PIN  [get_ports ]; # TX0P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX0N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX0P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX0N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX1P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX1N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX1P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX1N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX2P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX2N - FFLY_TXN 
# set_property PACKAGE_PIN  [get_ports ]; # RX2P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX2N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX3P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX3N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX3P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX3N - FFLY_RXN

# # Bank 227 - FFLY U6 - FF3 - P2-far
# set_property PACKAGE_PIN AA11 [get_ports ]; # TOPS_3
# set_property PACKAGE_PIN AA10 [get_ports ]; # TOPS_3
set_property PACKAGE_PIN Y13 [get_ports ethRefClk156P]; # TOPA_3
set_property PACKAGE_PIN Y12 [get_ports ethRefClk156N]; # TOPA_3
set_property PACKAGE_PIN AC7 [get_ports ethTxP]; # TX0P - FFLY_TX2P
set_property PACKAGE_PIN AC6 [get_ports ethTxN]; # TX0N - FFLY_TX2N
set_property PACKAGE_PIN AC2 [get_ports ethRxP]; # RX0P - FFLY_RX4P
set_property PACKAGE_PIN AC1 [get_ports ethRxN]; # RX0N - FFLY_RX4N
# set_property PACKAGE_PIN AB9 [get_ports ]; # TX1P - FFLY_TX1P
# set_property PACKAGE_PIN AB8 [get_ports ]; # TX1N - FFLY_TX1N
# set_property PACKAGE_PIN AB4 [get_ports ]; # RX1P - FFLY_RX3P
# set_property PACKAGE_PIN AB3 [get_ports ]; # RX1N - FFLY_RX3N
# set_property PACKAGE_PIN AA7 [get_ports ]; # TX2P - FFLY_TX4P
# set_property PACKAGE_PIN AA6 [get_ports ]; # TX2N - FFLY_TX4N 
# set_property PACKAGE_PIN AA2 [get_ports ]; # RX2P - FFLY_RX2P
# set_property PACKAGE_PIN AA1 [get_ports ]; # RX2N - FFLY_RX2N
# set_property PACKAGE_PIN Y9 [get_ports ]; # TX3P - FFLY_TX3P
# set_property PACKAGE_PIN Y8 [get_ports ]; # TX3N - FFLY_TX3N
# set_property PACKAGE_PIN Y4 [get_ports ]; # RX3P - FFLY_RX1P
# set_property PACKAGE_PIN Y3 [get_ports ]; # RX3N - FFLY_RX1N


# set_property PACKAGE_PIN  [get_ports ]; # TX0P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX0N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX0P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX0N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX1P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX1N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX1P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX1N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX2P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX2N - FFLY_TXN 
# set_property PACKAGE_PIN  [get_ports ]; # RX2P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX2N - FFLY_RXN
# set_property PACKAGE_PIN  [get_ports ]; # TX3P - FFLY_TXP
# set_property PACKAGE_PIN  [get_ports ]; # TX3N - FFLY_TXN
# set_property PACKAGE_PIN  [get_ports ]; # RX3P - FFLY_RXP
# set_property PACKAGE_PIN  [get_ports ]; # RX3N - FFLY_RXN

