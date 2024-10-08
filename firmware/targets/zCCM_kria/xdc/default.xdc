# Copyright (C) 2022, Xilinx, Inc.
# Copyright (C) 2022, Advanced Micro Devices, Inc.
# SPDX-License-Identifier: Apache-2.0

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

create_generated_clock -name dmaClk [get_pins {U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT0}]
create_generated_clock -name axilClk [get_pins {U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT1}]

create_clock -name appFcRefClk -period 5.384 [get_ports CLKGEN_MGTCLK_AC_P]
create_generated_clock -name appFcRefClkDiv2 [get_pins U_App/U_FcReceiver_1/U_mgtUserRefClkDiv2/O]

create_clock -name appFcRxOutClk -period 5.384 [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/RXOUTCLK}]
create_generated_clock -name appFcRxOutClkMmcm [get_pins  U_App/U_FcReceiver_1/U_LdmxPgpFcLane_1/RX_CLK_MMCM_GEN.U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0 ]

create_generated_clock -name appFcTxOutClkPcs [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/TXOUTCLKPCS}]
create_generated_clock -name appFcTxOutClk [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/TXOUTCLK}]


set_clock_groups -asynchronous \
    -group [get_clocks dmaClk] \
    -group [get_clocks axilClk] \
    -group [get_clocks appFcRefClkDiv2]

set_clock_groups -asynchronous \
    -group [get_clocks appFcRxOutClkMmcm] \
    -group [get_clocks appFcRefClk -include_generated_clocks] \
    -Group [get_clocks axilClk] \
    -group [get_clocks appFcRefClkDiv2]
