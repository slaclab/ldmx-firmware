#-------------------------------------------------------------------------------
#-- Title         : HPS Front End Board Constraints
#-- File          : FrontEndBoard.xdc
#-- Author        : Ben Reese <bareese@slac.stanford.edu>
#-- Created       : 11/20/2013
#-------------------------------------------------------------------------------
#-- Description:
#-- Constrains for the HPS Front End Board
#-------------------------------------------------------------------------------
#-- Copyright (c) 2013 by Ben Reese. All rights reserved.
#-------------------------------------------------------------------------------
#-- Modification history:
#-- 11/20/2013: created.
#-------------------------------------------------------------------------------



#Clocks
create_clock -period 4.000 -name gtRefClk250 [get_ports gtRefClk250P]

create_generated_clock \
    -name pgpDataClk \
    [get_pins {U_DataClockManager7/MmcmGen.U_Mmcm/CLKOUT1}]

create_generated_clock \
    -name clk250 \
    [get_pins {U_DataClockManager7/MmcmGen.U_Mmcm/CLKOUT0}]
    
create_clock -period 8.000 -name gtRefClk125 [get_ports gtRefClk125P]

create_generated_clock -name axiClk \
    [get_pins {U_CtrlClockManager7/MmcmGen.U_Mmcm/CLKOUT0}]

create_generated_clock \
    -name clk200 \
     [get_pins {U_CtrlClockManager7/MmcmGen.U_Mmcm/CLKOUT1}]
    
create_generated_clock \
    -name semClk \
    [get_pins {U_CtrlClockManager7/MmcmGen.U_Mmcm/CLKOUT2}]


create_clock -period 3.429 -name adcDClk[0] [get_ports {adcDClkP[0]}]
set_input_jitter adcDClk[0] .35
create_generated_clock -name adcBitClkR[0] -source [get_ports {adcDClkP[0]}] -divide_by 7 [get_pins {FebCore_1/HYBRIDS_GEN[0].HybridIoCore_1/AdcReadout7_1/U_AdcBitClkR/O}]

create_clock -period 3.429 -name adcDClk[1] [get_ports {adcDClkP[1]}]
set_input_jitter adcDClk[1] .35
create_generated_clock -name adcBitClkR[1] -source [get_ports {adcDClkP[1]}] -divide_by 7 [get_pins {FebCore_1/HYBRIDS_GEN[1].HybridIoCore_1/AdcReadout7_1/U_AdcBitClkR/O}]

create_clock -period 3.429 -name adcDClk[2] [get_ports {adcDClkP[2]}]
set_input_jitter adcDClk[2] .35
create_generated_clock -name adcBitClkR[2] -source [get_ports {adcDClkP[2]}] -divide_by 7 [get_pins {FebCore_1/HYBRIDS_GEN[2].HybridIoCore_1/AdcReadout7_1/U_AdcBitClkR/O}]

create_clock -period 3.429 -name adcDClk[3] [get_ports {adcDClkP[3]}]
set_input_jitter adcDClk[3] .35
create_generated_clock -name adcBitClkR[3] -source [get_ports {adcDClkP[3]}] -divide_by 7 [get_pins {FebCore_1/HYBRIDS_GEN[3].HybridIoCore_1/AdcReadout7_1/U_AdcBitClkR/O}]


set rxRecClkPin [get_pins {FebPgp_1/GEN_PGP.Pgp2bGtp7FixedLat_1/Gtp7Core_1/gtpe2_i/RXOUTCLK}]
create_clock -name pgpRxRecClk -period 8 ${rxRecClkPin}

#set daqClk125Pin [get_nets FebPgp_1/ctrlRxRecClkLoc]   
#set daqClk125Pin [get_pins FebPgp_1/GEN_PGP.RxClkMmcmGen.ClockManager7_1/PllGen.U_Pll/CLKOUT0]
#create_generated_clock -name daqClk125 ${daqClk125Pin}


set daqClk41Pin [get_pins {FebCore_1/DaqTiming_1/r_reg[daqClk41]/Q}]
create_generated_clock -name daqClk41 -source ${rxRecClkPin} -edges {1 3 7} \
    ${daqClk41Pin}

create_generated_clock -name hybridClk0 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_Hybrid/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name hybridClk1 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_Hybrid/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name hybridClk2 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_Hybrid/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT2]
create_generated_clock -name hybridClk3 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_Hybrid/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT3]

create_generated_clock -name adcClk0 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_ADC/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT0]
create_generated_clock -name adcClk1 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_ADC/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT1]
create_generated_clock -name adcClk2 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_ADC/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT2]
create_generated_clock -name adcClk3 -source ${daqClk41Pin} -duty_cycle 50 -multiply_by 1 \
    [get_pins FebCore_1/ClockPhaseShifter_ADC/CLOCK_SHIFTER_MMCM/mmcm_adv_inst/CLKOUT3]

#create_clock -period 8.000 -name flPgpGtRefClk [get_pins PgpFrontEnd_1/Pgp2Gtp7Fixedlat_1/Gtp7Core_1/gtpe2_i/RXOUTCLKFABRIC]

create_clock -name daqRefClk -period 8 [get_ports daqRefClkP]

set_clock_groups  -asynchronous \ 
-group [get_clocks -include_generated_clocks gtRefClk125] \
-group [get_clocks -include_generated_clocks gtRefClk250] \ 
-group [get_clocks -include_generated_clocks daqRefClk] \ 
-group [get_clocks -include_generated_clocks {pgpRxRecClk}] \
-group [get_clocks -include_generated_clocks {adcDClk[0]}] \
-group [get_clocks -include_generated_clocks {adcDClk[1]}] \ 
-group [get_clocks -include_generated_clocks {adcDClk[2]}] \
-group [get_clocks -include_generated_clocks {adcDClk[3]}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks pgpDataClk] \
    -group [get_clocks -include_generated_clocks clk250]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks axiClk] \
    -group [get_clocks -include_generated_clocks clk200] \
    -group [get_clocks -include_generated_clocks semClk]

set_output_delay -clock {hybridClk0} 5 [get_ports {hyTrgP[0]}]
set_output_delay -clock {hybridClk1} 5 [get_ports {hyTrgP[1]}]
set_output_delay -clock {hybridClk2} 5 [get_ports {hyTrgP[2]}]
set_output_delay -clock {hybridClk3} 5 [get_ports {hyTrgP[3]}]

#set_property IOB TRUE [get_cells -hierarchical {*TrigControl_1/r_reg[shiftOut][5]}]

# create_pblock IO_FIFO_BLK_0
# add_cells_to_pblock IO_FIFO_BLK_0 [get_cells FebCore_1/HYBRIDS_IO_GEN[0].HybridIoCore_1/AdcReadout7_1/IN_FIFO_0]
# add_cells_to_pblock IO_FIFO_BLK_0 [get_cells FebCore_1/HYBRIDS_IO_GEN[0].HybridIoCore_1/AdcReadout7_1/IN_FIFO_1]
# add_cells_to_pblock IO_FIFO_BLK_0 [get_cells FebCore_1/HYBRIDS_IO_GEN[1].HybridIoCore_1/AdcReadout7_1/IN_FIFO_0]
# add_cells_to_pblock IO_FIFO_BLK_0 [get_cells FebCore_1/HYBRIDS_IO_GEN[1].HybridIoCore_1/AdcReadout7_1/IN_FIFO_1]
# resize_pblock [get_pblocks IO_FIFO_BLK_0] -add {CLOCKREGION_X0Y3:CLOCKREGION_X0Y3}

# create_pblock IO_FIFO_BLK_1
# add_cells_to_pblock IO_FIFO_BLK_1 [get_cells FebCore_1/HYBRIDS_IO_GEN[2].HybridIoCore_1/AdcReadout7_1/IN_FIFO_0]
# add_cells_to_pblock IO_FIFO_BLK_1 [get_cells FebCore_1/HYBRIDS_IO_GEN[2].HybridIoCore_1/AdcReadout7_1/IN_FIFO_1]
# add_cells_to_pblock IO_FIFO_BLK_1 [get_cells FebCore_1/HYBRIDS_IO_GEN[3].HybridIoCore_1/AdcReadout7_1/IN_FIFO_0]
# add_cells_to_pblock IO_FIFO_BLK_1 [get_cells FebCore_1/HYBRIDS_IO_GEN[3].HybridIoCore_1/AdcReadout7_1/IN_FIFO_1]
# resize_pblock [get_pblocks IO_FIFO_BLK_1] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y0}


#Assure that sychronization registers are placed in the same slice with no logic between each sync stage
#set_property ASYNC_REG TRUE [get_cells -hierarchical *crossDomainSyncReg_reg*]

set_property PACKAGE_PIN AA13 [get_ports gtRefClk125P]
set_property PACKAGE_PIN AB13 [get_ports gtRefClk125N]

#set_property PACKAGE_PIN AA11 [get_ports daqRefClkP]
#set_property PACKAGE_PIN AB11 [get_ports daqRefClkN]

set_property PACKAGE_PIN B20 [get_ports daqClk125P]
set_property PACKAGE_PIN A20 [get_ports daqClk125N]
set_property IOSTANDARD LVDS_25 [get_ports daqClk125P]
set_property IOSTANDARD LVDS_25 [get_ports daqClk125N]

set_property PACKAGE_PIN F11 [get_ports gtRefClk250P]
set_property PACKAGE_PIN E11 [get_ports gtRefClk250N]

set_property PACKAGE_PIN AD12 [get_ports sysGtRxN]
set_property PACKAGE_PIN AC12 [get_ports sysGtRxP]
set_property PACKAGE_PIN AD10 [get_ports sysGtTxN]
set_property PACKAGE_PIN AC10 [get_ports sysGtTxP]

set_property IOSTANDARD LVCMOS33 [get_ports {leds}]
set_property PACKAGE_PIN G20 [get_ports {leds[0]}]
set_property PACKAGE_PIN G21 [get_ports {leds[1]}]
set_property PACKAGE_PIN K21 [get_ports {leds[7]}]
set_property PACKAGE_PIN J21 [get_ports {leds[6]}]
set_property PACKAGE_PIN H21 [get_ports {leds[2]}]
set_property PACKAGE_PIN H22 [get_ports {leds[4]}]
set_property PACKAGE_PIN J23 [get_ports {leds[5]}]
set_property PACKAGE_PIN H23 [get_ports {leds[3]}]

set_property PACKAGE_PIN A11 [get_ports {dataGtRxN[0]}]
set_property PACKAGE_PIN B11 [get_ports {dataGtRxP[0]}]
set_property PACKAGE_PIN A7 [get_ports {dataGtTxN[0]}]
set_property PACKAGE_PIN B7 [get_ports {dataGtTxP[0]}]

set_property PACKAGE_PIN C14 [get_ports {dataGtRxN[1]}]
set_property PACKAGE_PIN D14 [get_ports {dataGtRxP[1]}]
set_property PACKAGE_PIN C8 [get_ports {dataGtTxN[1]}]
set_property PACKAGE_PIN D8 [get_ports {dataGtTxP[1]}]

set_property PACKAGE_PIN A13 [get_ports {dataGtRxN[2]}]
set_property PACKAGE_PIN B13 [get_ports {dataGtRxP[2]}]
set_property PACKAGE_PIN A9 [get_ports {dataGtTxN[2]}]
set_property PACKAGE_PIN B9 [get_ports {dataGtTxP[2]}]

set_property PACKAGE_PIN C12 [get_ports {dataGtRxN[3]}]
set_property PACKAGE_PIN D12 [get_ports {dataGtRxP[3]}]
set_property PACKAGE_PIN C10 [get_ports {dataGtTxN[3]}]
set_property PACKAGE_PIN D10 [get_ports {dataGtTxP[3]}]

set_property IOSTANDARD LVDS_25 [get_ports {adcClkP}]
set_property IOSTANDARD LVDS_25 [get_ports {adcClkN}]

set_property DIFF_TERM TRUE [get_ports {adcClkP}]
set_property DIFF_TERM TRUE [get_ports {adcClkN}]

set_property PACKAGE_PIN G17 [get_ports {adcClkP[0]}]
set_property PACKAGE_PIN F17 [get_ports {adcClkN[0]}]

set_property PACKAGE_PIN E17 [get_ports {adcFClkP[0]}]
set_property PACKAGE_PIN E18 [get_ports {adcFClkN[0]}]
set_property PACKAGE_PIN D18 [get_ports {adcDClkP[0]}]
set_property PACKAGE_PIN C18 [get_ports {adcDClkN[0]}]
set_property PACKAGE_PIN F18 [get_ports {adcDataP[0][0]}]
set_property PACKAGE_PIN F19 [get_ports {adcDataN[0][0]}]
set_property PACKAGE_PIN G15 [get_ports {adcDataP[0][1]}]
set_property PACKAGE_PIN F15 [get_ports {adcDataN[0][1]}]
set_property PACKAGE_PIN G19 [get_ports {adcDataP[0][2]}]
set_property PACKAGE_PIN F20 [get_ports {adcDataN[0][2]}]
set_property PACKAGE_PIN H16 [get_ports {adcDataP[0][3]}]
set_property PACKAGE_PIN G16 [get_ports {adcDataN[0][3]}]
set_property PACKAGE_PIN C17 [get_ports {adcDataP[0][4]}]
set_property PACKAGE_PIN B17 [get_ports {adcDataN[0][4]}]

set_property IOSTANDARD LVDS_25 [get_ports {adcFClkP}]
set_property IOSTANDARD LVDS_25 [get_ports {adcFClkN}]
set_property IOSTANDARD LVDS_25 [get_ports adcDataP*]
set_property IOSTANDARD LVDS_25 [get_ports adcDataN*]

set_property DIFF_TERM TRUE [get_ports {adcFClkP}]
set_property DIFF_TERM TRUE [get_ports {adcFClkN}]
set_property DIFF_TERM true [get_ports adcDataP*]
set_property DIFF_TERM true [get_ports adcDataN*]

set_property PACKAGE_PIN C24 [get_ports {adcClkP[1]}]
set_property PACKAGE_PIN B24 [get_ports {adcClkN[1]}]
set_property PACKAGE_PIN E20 [get_ports {adcFClkP[1]}]
set_property PACKAGE_PIN D20 [get_ports {adcFClkN[1]}]
set_property PACKAGE_PIN D19 [get_ports {adcDClkP[1]}]
set_property PACKAGE_PIN C19 [get_ports {adcDClkN[1]}]
set_property PACKAGE_PIN C26 [get_ports {adcDataP[1][0]}]
set_property PACKAGE_PIN B26 [get_ports {adcDataN[1][0]}]
set_property PACKAGE_PIN A23 [get_ports {adcDataP[1][1]}]
set_property PACKAGE_PIN A24 [get_ports {adcDataN[1][1]}]
set_property PACKAGE_PIN B25 [get_ports {adcDataP[1][2]}]
set_property PACKAGE_PIN A25 [get_ports {adcDataN[1][2]}]
set_property PACKAGE_PIN C22 [get_ports {adcDataP[1][3]}]
set_property PACKAGE_PIN C23 [get_ports {adcDataN[1][3]}]
set_property PACKAGE_PIN E21 [get_ports {adcDataP[1][4]}]
set_property PACKAGE_PIN D21 [get_ports {adcDataN[1][4]}]

set_property PACKAGE_PIN U14 [get_ports {adcClkP[2]}]
set_property PACKAGE_PIN V14 [get_ports {adcClkN[2]}]
set_property PACKAGE_PIN W21 [get_ports {adcFClkP[2]}]
set_property PACKAGE_PIN Y21 [get_ports {adcFClkN[2]}]
set_property PACKAGE_PIN U21 [get_ports {adcDClkP[2]}]
set_property PACKAGE_PIN V21 [get_ports {adcDClkN[2]}]
set_property PACKAGE_PIN U15 [get_ports {adcDataP[2][0]}]
set_property PACKAGE_PIN U16 [get_ports {adcDataN[2][0]}]
set_property PACKAGE_PIN T17 [get_ports {adcDataP[2][1]}]
set_property PACKAGE_PIN T18 [get_ports {adcDataN[2][1]}]
set_property PACKAGE_PIN T14 [get_ports {adcDataP[2][2]}]
set_property PACKAGE_PIN T15 [get_ports {adcDataN[2][2]}]
set_property PACKAGE_PIN V18 [get_ports {adcDataP[2][3]}]
set_property PACKAGE_PIN W18 [get_ports {adcDataN[2][3]}]
set_property PACKAGE_PIN V19 [get_ports {adcDataP[2][4]}]
set_property PACKAGE_PIN W19 [get_ports {adcDataN[2][4]}]

set_property PACKAGE_PIN V26 [get_ports {adcClkP[3]}]
set_property PACKAGE_PIN W26 [get_ports {adcClkN[3]}]
set_property PACKAGE_PIN Y22 [get_ports {adcFClkP[3]}]
set_property PACKAGE_PIN Y23 [get_ports {adcFClkN[3]}]
set_property PACKAGE_PIN U22 [get_ports {adcDClkP[3]}]
set_property PACKAGE_PIN V22 [get_ports {adcDClkN[3]}]
set_property PACKAGE_PIN AB26 [get_ports {adcDataP[3][0]}]
set_property PACKAGE_PIN AC26 [get_ports {adcDataN[3][0]}]
set_property PACKAGE_PIN W25 [get_ports {adcDataP[3][1]}]
set_property PACKAGE_PIN Y26 [get_ports {adcDataN[3][1]}]
set_property PACKAGE_PIN Y25 [get_ports {adcDataP[3][2]}]
set_property PACKAGE_PIN AA25 [get_ports {adcDataN[3][2]}]
set_property PACKAGE_PIN V24 [get_ports {adcDataP[3][3]}]
set_property PACKAGE_PIN W24 [get_ports {adcDataN[3][3]}]
set_property PACKAGE_PIN AA24 [get_ports {adcDataP[3][4]}]
set_property PACKAGE_PIN AB25 [get_ports {adcDataN[3][4]}]

set_property PACKAGE_PIN H17 [get_ports {adcCsb[0]}]
set_property PACKAGE_PIN H15 [get_ports {adcSclk[0]}]
set_property PACKAGE_PIN H14 [get_ports {adcSdio[0]}]

set_property PACKAGE_PIN E22 [get_ports {adcCsb[1]}]
set_property PACKAGE_PIN D23 [get_ports {adcSclk[1]}]
set_property PACKAGE_PIN D24 [get_ports {adcSdio[1]}]

set_property PACKAGE_PIN U17 [get_ports {adcCsb[2]}]
set_property PACKAGE_PIN V16 [get_ports {adcSclk[2]}]
set_property PACKAGE_PIN V17 [get_ports {adcSdio[2]}]

set_property PACKAGE_PIN U24 [get_ports {adcCsb[3]}]
set_property PACKAGE_PIN U26 [get_ports {adcSclk[3]}]
set_property PACKAGE_PIN U25 [get_ports {adcSdio[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports {adcCsb}]
set_property IOSTANDARD LVCMOS25 [get_ports {adcSclk}]
set_property IOSTANDARD LVCMOS25 [get_ports {adcSdio}]

set_property PACKAGE_PIN H1 [get_ports ampI2cScl]
set_property IOSTANDARD LVCMOS25 [get_ports ampI2cScl]

set_property PACKAGE_PIN H2 [get_ports ampI2cSda]
set_property IOSTANDARD LVCMOS25 [get_ports ampI2cSda]

set_property PACKAGE_PIN G1 [get_ports boardI2cScl]
set_property IOSTANDARD LVCMOS33 [get_ports boardI2cScl]

set_property PACKAGE_PIN G2 [get_ports boardI2cSda]
set_property IOSTANDARD LVCMOS33 [get_ports boardI2cSda]

set_property PACKAGE_PIN A3 [get_ports boardSpiSclk]
set_property IOSTANDARD LVCMOS33 [get_ports boardSpiSclk]

set_property PACKAGE_PIN A2 [get_ports boardSpiSdi]
set_property IOSTANDARD LVCMOS33 [get_ports boardSpiSdi]

set_property PACKAGE_PIN C1 [get_ports boardSpiSdo]
set_property IOSTANDARD LVCMOS33 [get_ports boardSpiSdo]

set_property PACKAGE_PIN B1 [get_ports {boardSpiCsL[0]}]
set_property PACKAGE_PIN F2 [get_ports {boardSpiCsL[1]}]
set_property PACKAGE_PIN E2 [get_ports {boardSpiCsL[2]}]
set_property PACKAGE_PIN E1 [get_ports {boardSpiCsL[3]}]
set_property PACKAGE_PIN D1 [get_ports {boardSpiCsL[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {boardSpiCsL}]

set_property PACKAGE_PIN U4 [get_ports {hyPwrEn[0]}]
set_property PACKAGE_PIN T5 [get_ports {hyPwrEn[1]}]
set_property PACKAGE_PIN N6 [get_ports {hyPwrEn[2]}]
set_property PACKAGE_PIN N8 [get_ports {hyPwrEn[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {hyPwrEn}]

set_property IOSTANDARD LVDS_25 [get_ports {hyClkP}]
set_property IOSTANDARD LVDS_25 [get_ports {hyClkN}]
set_property IOSTANDARD LVDS_25 [get_ports {hyTrgP}]
set_property IOSTANDARD LVDS_25 [get_ports {hyTrgN}]
set_property IOSTANDARD LVCMOS25 [get_ports {hyRstL}]
set_property IOSTANDARD LVCMOS25 [get_ports {hyI2cScl}]
set_property IOSTANDARD LVCMOS25 [get_ports {hyI2cSdaOut}]
set_property IOSTANDARD LVCMOS25 [get_ports {hyI2cSdaIn}]

set_property PACKAGE_PIN T8 [get_ports {hyClkP[0]}]
set_property PACKAGE_PIN T7 [get_ports {hyClkN[0]}]
set_property PACKAGE_PIN R7 [get_ports {hyTrgP[0]}]
set_property PACKAGE_PIN R6 [get_ports {hyTrgN[0]}]
set_property PACKAGE_PIN P8 [get_ports {hyRstL[0]}]
set_property PACKAGE_PIN R8 [get_ports {hyI2cScl[0]}]
set_property PACKAGE_PIN U6 [get_ports {hyI2cSdaOut[0]}]
set_property PACKAGE_PIN U5 [get_ports {hyI2cSdaIn[0]}]

set_property PACKAGE_PIN P6 [get_ports {hyClkP[1]}]
set_property PACKAGE_PIN P5 [get_ports {hyClkN[1]}]
set_property PACKAGE_PIN U2 [get_ports {hyTrgP[1]}]
set_property PACKAGE_PIN U1 [get_ports {hyTrgN[1]}]
set_property PACKAGE_PIN R2 [get_ports {hyRstL[1]}]
set_property PACKAGE_PIN T2 [get_ports {hyI2cScl[1]}]
set_property PACKAGE_PIN T4 [get_ports {hyI2cSdaOut[1]}]
set_property PACKAGE_PIN T3 [get_ports {hyI2cSdaIn[1]}]

set_property PACKAGE_PIN M6 [get_ports {hyClkP[2]}]
set_property PACKAGE_PIN M5 [get_ports {hyClkN[2]}]
set_property PACKAGE_PIN K1 [get_ports {hyTrgP[2]}]
set_property PACKAGE_PIN J1 [get_ports {hyTrgN[2]}]
set_property PACKAGE_PIN L3 [get_ports {hyRstL[2]}]
set_property PACKAGE_PIN K2 [get_ports {hyI2cScl[2]}]
set_property PACKAGE_PIN M1 [get_ports {hyI2cSdaOut[2]}]
set_property PACKAGE_PIN N1 [get_ports {hyI2cSdaIn[2]}]

set_property PACKAGE_PIN K3 [get_ports {hyClkP[3]}]
set_property PACKAGE_PIN J3 [get_ports {hyClkN[3]}]
set_property PACKAGE_PIN M7 [get_ports {hyTrgP[3]}]
set_property PACKAGE_PIN L7 [get_ports {hyTrgN[3]}]
set_property PACKAGE_PIN M4 [get_ports {hyRstL[3]}]
set_property PACKAGE_PIN L4 [get_ports {hyI2cScl[3]}]
set_property PACKAGE_PIN K5 [get_ports {hyI2cSdaOut[3]}]
set_property PACKAGE_PIN L5 [get_ports {hyI2cSdaIn[3]}]

#Vivado makes you define IO standard for analog inputs because it is stupid
set_property IOSTANDARD LVCMOS33 [get_ports {vPIn}]
set_property IOSTANDARD LVCMOS33 [get_ports {vNIn}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxP[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vAuxN[15]}]

set_property PACKAGE_PIN N12 [get_ports {vPIn}]
set_property PACKAGE_PIN P11 [get_ports {vNIn}]
set_property PACKAGE_PIN K15 [get_ports {vAuxP[0]}]
set_property PACKAGE_PIN J16 [get_ports {vAuxN[0]}]
set_property PACKAGE_PIN K16 [get_ports {vAuxP[1]}]
set_property PACKAGE_PIN K17 [get_ports {vAuxN[1]}]
set_property PACKAGE_PIN J19 [get_ports {vAuxP[2]}]
set_property PACKAGE_PIN H19 [get_ports {vAuxN[2]}]
set_property PACKAGE_PIN K20 [get_ports {vAuxP[3]}]
set_property PACKAGE_PIN J20 [get_ports {vAuxN[3]}]
set_property PACKAGE_PIN E6 [get_ports {vAuxP[4]}]
set_property PACKAGE_PIN D6 [get_ports {vAuxN[4]}]
set_property PACKAGE_PIN H7 [get_ports {vAuxP[5]}]
set_property PACKAGE_PIN G7 [get_ports {vAuxN[5]}]
set_property PACKAGE_PIN J6 [get_ports {vAuxP[6]}]
set_property PACKAGE_PIN J5 [get_ports {vAuxN[6]}]
set_property PACKAGE_PIN J4 [get_ports {vAuxP[7]}]
set_property PACKAGE_PIN H4 [get_ports {vAuxN[7]}]
set_property PACKAGE_PIN J14 [get_ports {vAuxP[8]}]
set_property PACKAGE_PIN J15 [get_ports {vAuxN[8]}]
set_property PACKAGE_PIN M15 [get_ports {vAuxP[9]}]
set_property PACKAGE_PIN L15 [get_ports {vAuxN[9]}]
set_property PACKAGE_PIN L17 [get_ports {vAuxP[10]}]
set_property PACKAGE_PIN L18 [get_ports {vAuxN[10]}]
set_property PACKAGE_PIN J18 [get_ports {vAuxP[11]}]
set_property PACKAGE_PIN H18 [get_ports {vAuxN[11]}]
set_property PACKAGE_PIN H8 [get_ports {vAuxP[12]}]
set_property PACKAGE_PIN G8 [get_ports {vAuxN[12]}]
set_property PACKAGE_PIN H6 [get_ports {vAuxP[13]}]
set_property PACKAGE_PIN G6 [get_ports {vAuxN[13]}]
set_property PACKAGE_PIN L8 [get_ports {vAuxP[14]}]
set_property PACKAGE_PIN K8 [get_ports {vAuxN[14]}]
set_property PACKAGE_PIN K7 [get_ports {vAuxP[15]}]
set_property PACKAGE_PIN K6 [get_ports {vAuxN[15]}]


set_property PACKAGE_PIN C3 [get_ports {powerGood[a22]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[a22]}]
set_property PACKAGE_PIN F3 [get_ports {powerGood[a18]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[a18]}]
set_property PACKAGE_PIN E3 [get_ports {powerGood[a16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[a16]}]
set_property PACKAGE_PIN C2 [get_ports {powerGood[a29D]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[a29D]}]
set_property PACKAGE_PIN B2 [get_ports {powerGood[a29A]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[a29A]}]
set_property PACKAGE_PIN D3 [get_ports {powerGood[hybrid][0][avdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][0][avdd]}]
set_property PACKAGE_PIN B5 [get_ports {powerGood[hybrid][0][dvdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][0][dvdd]}]
set_property PACKAGE_PIN E5 [get_ports {powerGood[hybrid][0][v125]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][0][v125]}]
set_property PACKAGE_PIN A4 [get_ports {powerGood[hybrid][1][avdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][1][avdd]}]
set_property PACKAGE_PIN C4 [get_ports {powerGood[hybrid][1][dvdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][1][dvdd]}]
set_property PACKAGE_PIN F5 [get_ports {powerGood[hybrid][1][v125]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][1][v125]}]
set_property PACKAGE_PIN B4 [get_ports {powerGood[hybrid][2][avdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][2][avdd]}]
set_property PACKAGE_PIN D4 [get_ports {powerGood[hybrid][2][dvdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][2][dvdd]}]
set_property PACKAGE_PIN G5 [get_ports {powerGood[hybrid][2][v125]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][2][v125]}]
set_property PACKAGE_PIN A5 [get_ports {powerGood[hybrid][3][avdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][3][avdd]}]
set_property PACKAGE_PIN D5 [get_ports {powerGood[hybrid][3][dvdd]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][3][dvdd]}]
set_property PACKAGE_PIN F4 [get_ports {powerGood[hybrid][3][v125]}]
set_property IOSTANDARD LVCMOS33 [get_ports {powerGood[hybrid][3][v125]}]

set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 } [get_ports { bootCsL }];
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { bootMosi }];
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports { bootMiso }];



set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
# set_property bitstream.seu.essentialbits yes [current_design]

set_property CFGBVS VCCO                     [current_design]
set_property CONFIG_VOLTAGE 3.3              [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 33  [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
