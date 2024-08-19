# Xilinx design constraints [XDC) file for Kria K26 SOM - Rev 1

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

##########################
## SFP data/control/monitor
##########################

#set_property PACKAGE_PIN Y2 [get_ports {SFP_MGT_RX_P[0]}]
#set_property PACKAGE_PIN Y1 [get_ports {SFP_MGT_RX_N[0]}]
#set_property PACKAGE_PIN W4 [get_ports {SFP_MGT_TX_P[0]}]
#set_property PACKAGE_PIN W3 [get_ports {SFP_MGT_TX_N[0]}]

set_property PACKAGE_PIN W10 [get_ports {SFP_control_RX_LOS[0]}]
set_property PACKAGE_PIN AA8 [get_ports {SFP_control_TX_FAULT[0]}]
set_property PACKAGE_PIN Y10 [get_ports {SFP_control_MOD_ABS[0]}]
set_property PACKAGE_PIN Y9 [get_ports {SFP_control_TX_DIS[0]}]

#set_property PACKAGE_PIN U4 [get_ports {SFP_MGT_TX_P[1]}]
#set_property PACKAGE_PIN U3 [get_ports {SFP_MGT_TX_N[1]}]
#set_property PACKAGE_PIN V2 [get_ports {SFP_MGT_RX_P[1]}]
#set_property PACKAGE_PIN V1 [get_ports {SFP_MGT_RX_N[1]}]

set_property PACKAGE_PIN AB10 [get_ports {SFP_control_RX_LOS[1]}]
set_property PACKAGE_PIN Y13 [get_ports {SFP_control_TX_FAULT[1]}]
set_property PACKAGE_PIN AB9 [get_ports {SFP_control_MOD_ABS[1]}]
set_property PACKAGE_PIN Y14 [get_ports {SFP_control_TX_DIS[1]}]

#set_property PACKAGE_PIN R4 [get_ports {SFP_MGT_TX_P[2]}]
#set_property PACKAGE_PIN R3 [get_ports {SFP_MGT_TX_N[2]}]
#set_property PACKAGE_PIN T2 [get_ports {SFP_MGT_RX_P[2]}]
#set_property PACKAGE_PIN T1 [get_ports {SFP_MGT_RX_N[2]}]

set_property PACKAGE_PIN W12 [get_ports {SFP_control_RX_LOS[2]}]
set_property PACKAGE_PIN AA12 [get_ports {SFP_control_TX_FAULT[2]}]
set_property PACKAGE_PIN W11 [get_ports {SFP_control_MOD_ABS[2]}]
set_property PACKAGE_PIN Y12 [get_ports {SFP_control_TX_DIS[2]}]

#set_property PACKAGE_PIN N4 [get_ports {SFP_MGT_TX_P[3]}]
#set_property PACKAGE_PIN N3 [get_ports {SFP_MGT_TX_N[3]}]
#set_property PACKAGE_PIN P2 [get_ports {SFP_MGT_RX_P[3]}]
#set_property PACKAGE_PIN P1 [get_ports {SFP_MGT_RX_N[3]}]

set_property PACKAGE_PIN AF13 [get_ports {SFP_control_RX_LOS[3]}]
set_property PACKAGE_PIN AG11 [get_ports {SFP_control_TX_FAULT[3]}]
set_property PACKAGE_PIN AC13 [get_ports {SFP_control_MOD_ABS[3]}]
set_property PACKAGE_PIN AD15 [get_ports {SFP_control_TX_DIS[3]}]

set_property PACKAGE_PIN AF10 [get_ports {SFP_i2c_SCL[0]}]
set_property PACKAGE_PIN AB11 [get_ports {SFP_i2c_SCL[1]}]
set_property PACKAGE_PIN AH11 [get_ports {SFP_i2c_SCL[2]}]
set_property PACKAGE_PIN AD10 [get_ports {SFP_i2c_SCL[3]}]

set_property PACKAGE_PIN AG13 [get_ports {SFP_i2c_SDA[0]}]
set_property PACKAGE_PIN AC11 [get_ports {SFP_i2c_SDA[1]}]
set_property PACKAGE_PIN AA10 [get_ports {SFP_i2c_SDA[2]}]
set_property PACKAGE_PIN AA11 [get_ports {SFP_i2c_SDA[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports SFP_control*]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_i2c*]

#############################
## clock chips monitor/config
#############################
set_property PACKAGE_PIN K7 [get_ports Synth_Control_INTR]
set_property PACKAGE_PIN J7 [get_ports Synth_Control_LOS_XAXB]
set_property PACKAGE_PIN U8 [get_ports Synth_Control_LOL]
set_property PACKAGE_PIN Y8 [get_ports Synth_Control_RST]

set_property PACKAGE_PIN H7 [get_ports Jitter_Control_INTR]
set_property PACKAGE_PIN K8 [get_ports Jitter_Control_LOS_XAXB]
set_property PACKAGE_PIN K4 [get_ports Jitter_Control_LOL]
set_property PACKAGE_PIN N8 [get_ports Jitter_Control_RST]

set_property PACKAGE_PIN W8 [get_ports Synth_i2c_SDA]
set_property PACKAGE_PIN V9 [get_ports Synth_i2c_SCL]
set_property PACKAGE_PIN N9 [get_ports Jitter_i2c_SDA]
set_property PACKAGE_PIN K3 [get_ports Jitter_i2c_SCL]

set_property IOSTANDARD LVCMOS18 [get_ports Synth_Control*]
set_property IOSTANDARD LVCMOS18 [get_ports Jitter_Control*]
set_property IOSTANDARD LVCMOS18 [get_ports Synth_i2c*]
set_property IOSTANDARD LVCMOS18 [get_ports Jitter_i2c*]

#############################
## clock chips monitor/config
#############################
set_property PACKAGE_PIN AH7 [get_ports {RM_control_PEN[0]}]
set_property PACKAGE_PIN AH3 [get_ports {RM_control_PEN[1]}]
set_property PACKAGE_PIN AC7 [get_ports {RM_control_PEN[2]}]
set_property PACKAGE_PIN AC8 [get_ports {RM_control_PEN[3]}]
set_property PACKAGE_PIN AE8 [get_ports {RM_control_PEN[4]}]
set_property PACKAGE_PIN AF6 [get_ports {RM_control_PEN[5]}]

set_property PACKAGE_PIN AE2 [get_ports {RM_control_RESET[0]}]
set_property PACKAGE_PIN AH8 [get_ports {RM_control_RESET[1]}]
set_property PACKAGE_PIN AD2 [get_ports {RM_control_RESET[2]}]
set_property PACKAGE_PIN AB7 [get_ports {RM_control_RESET[3]}]
set_property PACKAGE_PIN AC9 [get_ports {RM_control_RESET[4]}]
set_property PACKAGE_PIN AE9 [get_ports {RM_control_RESET[5]}]

set_property PACKAGE_PIN AD9 [get_ports {RM_control_PGOOD[0]}]
set_property PACKAGE_PIN AB8 [get_ports {RM_control_PGOOD[1]}]
set_property PACKAGE_PIN AD1 [get_ports {RM_control_PGOOD[2]}]
set_property PACKAGE_PIN AG3 [get_ports {RM_control_PGOOD[3]}]
set_property PACKAGE_PIN AF2 [get_ports {RM_control_PGOOD[4]}]
set_property PACKAGE_PIN AF5 [get_ports {RM_control_PGOOD[5]}]

set_property IOSTANDARD LVCMOS18 [get_ports RM_control*]

set_property PACKAGE_PIN AD14 [get_ports {RM_i2c_SCL[0]}]
set_property PACKAGE_PIN AE14 [get_ports {RM_i2c_SCL[1]}]
set_property PACKAGE_PIN AH12 [get_ports {RM_i2c_SCL[2]}]
set_property PACKAGE_PIN AD12 [get_ports {RM_i2c_SCL[3]}]
set_property PACKAGE_PIN AH14 [get_ports {RM_i2c_SCL[4]}]
set_property PACKAGE_PIN AE13 [get_ports {RM_i2c_SCL[5]}]

set_property PACKAGE_PIN AE15 [get_ports {RM_i2c_SDA[0]}]
set_property PACKAGE_PIN AG14 [get_ports {RM_i2c_SDA[1]}]
set_property PACKAGE_PIN AC12 [get_ports {RM_i2c_SDA[2]}]
set_property PACKAGE_PIN AB14 [get_ports {RM_i2c_SDA[3]}]
set_property PACKAGE_PIN AC14 [get_ports {RM_i2c_SDA[4]}]
set_property PACKAGE_PIN AH13 [get_ports {RM_i2c_SDA[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports RM_i2c*]

#############################
## clock IO
#############################

set_property PACKAGE_PIN AD5 [get_ports MCLK_BUF_SEL]
set_property IOSTANDARD LVCMOS18 [get_ports MCLK_BUF_SEL]

set_property PACKAGE_PIN Y5 [get_ports CLKGEN_MGTCLK_AC_N]
set_property PACKAGE_PIN Y6 [get_ports CLKGEN_MGTCLK_AC_P]
#set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports "CLKGEN_MGTCLK_AC_*"];

set_property PACKAGE_PIN J1 [get_ports LED_FROM_SOC_P]
set_property PACKAGE_PIN H1 [get_ports LED_FROM_SOC_N]
set_property IOSTANDARD LVDS [get_ports LED_FROM_SOC_*]

set_property PACKAGE_PIN N7 [get_ports BCR_FROM_SOC_P]
set_property PACKAGE_PIN N6 [get_ports BCR_FROM_SOC_N]
set_property IOSTANDARD LVDS [get_ports BCR_FROM_SOC_*]

set_property PACKAGE_PIN H4 [get_ports MCLK_FROM_SOC_P]
set_property PACKAGE_PIN H3 [get_ports MCLK_FROM_SOC_N]
set_property IOSTANDARD LVDS [get_ports MCLK_FROM_SOC_*]

set_property PACKAGE_PIN J5 [get_ports MCLK_REF_P]
set_property PACKAGE_PIN J4 [get_ports MCLK_REF_N]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports MCLK_REF_*]

set_property PACKAGE_PIN V6 [get_ports MGTREFCLK1_AC_P]
set_property PACKAGE_PIN V5 [get_ports MGTREFCLK1_AC_N]
#set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports "MGTREFCLK1_AC_*"];

set_property PACKAGE_PIN H9 [get_ports SOC_CLKREF_TO_CLKGEN_P]
set_property PACKAGE_PIN H8 [get_ports SOC_CLKREF_TO_CLKGEN_N]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports SOC_CLKREF_TO_CLKGEN_*]

set_property PACKAGE_PIN L7 [get_ports CLKGEN_CLK0_TO_SOC_AC_P]
set_property PACKAGE_PIN L6 [get_ports CLKGEN_CLK0_TO_SOC_AC_N]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports CLKGEN_CLK0_TO_SOC_AC_*]

set_property PACKAGE_PIN R7 [get_ports BEAMCLK_P]
set_property PACKAGE_PIN T7 [get_ports BEAMCLK_N]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports BEAMCLK_*]

set_property PACKAGE_PIN L3 [get_ports SYNTH_TO_SOC_AC_P]
set_property PACKAGE_PIN L2 [get_ports SYNTH_TO_SOC_AC_N]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports SYNTH_TO_SOC_AC_*]

#set_property PACKAGE_PIN AF12 [get_ports "PL_STAT_LED0"];
#set_property PACKAGE_PIN AG10 [get_ports "PL_STAT_LED1"];
#set_property PACKAGE_PIN AH10 [get_ports "PL_STAT_LED2"];
#set_property PACKAGE_PIN AF11 [get_ports "PL_STAT_LED3"];
#set_property IOSTANDARD LVCMOS33 [get_ports "PL_STAT_LED*"];


create_generated_clock -name dmaClk [get_pins {U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT0}]
create_generated_clock -name axilClk [get_pins {U_Core/REAL_CPU.U_CPU/U_Pll/PllGen.U_Pll/CLKOUT1}]

create_clock -name appFcRefClk -period 5.384 [get_ports CLKGEN_MGTCLK_AC_P]

create_clock -name appFcRxOutClk -period 5.384 [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/RXOUTCLK}]
create_generated_clock -name appFcRxOutClkMmcm [get_pins  U_App/U_FcReceiver_1/U_LdmxPgpFcLane_1/RX_CLK_MMCM_GEN.U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0 ]

create_generated_clock -name appFcTxOutClkPcs [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/TXOUTCLKPCS}]
create_generated_clock -name appFcTxOutClk [get_pins -hier * -filter {name=~*/U_FcReceiver_1/*/TXOUTCLK}]


set_clock_groups -asynchronous \
    -group [get_clocks dmaClk] \
    -group [get_clocks axilClk]

set_clock_groups -asynchronous \
    -group [get_clocks appFcRxOutClkMmcm] \
    -group [get_clocks appFcRefClk -include_generated_clocks] \    
    -group [get_clocks axilClk]
