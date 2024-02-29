create_clock -period 6.400 -name refclk_c2c_clk [get_ports refclk_c2c_clk_p]
set_property PACKAGE_PIN AB35 [get_ports refclk_c2c_clk_n]
set_property PACKAGE_PIN AB34 [get_ports refclk_c2c_clk_p]

create_clock -period 3.118 -name tcdsRefclk -waveform {0.000 1.559} [get_ports tcdsRefclk_p]
set_property PACKAGE_PIN AC37 [get_ports tcdsRefclk_n]
set_property PACKAGE_PIN AC36 [get_ports tcdsRefclk_p]

create_clock -period 3.333 -name clk_300_clk_p [get_ports clk_300_clk_p]
set_property PACKAGE_PIN K29 [get_ports clk_300_clk_p]
set_property PACKAGE_PIN J29 [get_ports clk_300_clk_n]


set_property IOSTANDARD LVDS [get_ports clk_300_clk_n]
set_property IOSTANDARD LVDS [get_ports clk_300_clk_p]

set_property PACKAGE_PIN BF30 [get_ports I2C_C2C_scl_io]
set_property PACKAGE_PIN BE30 [get_ports I2C_C2C_sda_io]
set_property IOSTANDARD LVCMOS18 [get_ports I2C_C2C_scl_io]
set_property IOSTANDARD LVCMOS18 [get_ports I2C_C2C_sda_io] 

set_property PACKAGE_PIN H28 [get_ports clk_125_osc_in_p]
set_property PACKAGE_PIN H29 [get_ports clk_125_osc_in_n]

set_property PACKAGE_PIN N17 [get_ports clk_125_osc_out0_p]
set_property PACKAGE_PIN M17 [get_ports clk_125_osc_out0_n]

set_property PACKAGE_PIN M30 [get_ports clk_125_osc_out1_p]
set_property PACKAGE_PIN L30 [get_ports clk_125_osc_out1_n]

set_property PACKAGE_PIN AV31 [get_ports dplink_p2p_ecc_p]
set_property PACKAGE_PIN AW31 [get_ports dplink_p2n_ecc_n]


set_property LOC  GTYE4_CHANNEL_X0Y28 [get_cells -hierarchical -filter {NAME =~ U_axiInfra/*channel_inst[0].*CHANNEL_PRIM_INST}]
set_property LOC  GTYE4_CHANNEL_X0Y29 [get_cells -hierarchical -filter {NAME =~ U_axiInfra/*channel_inst[1].*CHANNEL_PRIM_INST}]

set_property LOC GTYE4_CHANNEL_X0Y30 [get_cells -hierarchical -filter {NAME =~ U_ApxTcds2/*GTYE4_CHANNEL_PRIM_INST}]

set_property  LOC BUFGCTRL_X0Y61 [get_cells [list U_ApxTcds2/*.U_BUFGMUX_CTRL]]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


######sss


create_generated_clock -name axiClk      [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT0]
create_generated_clock -name clk100osc   [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT1]
create_generated_clock -name clk200osc   [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT2]
create_generated_clock -name clk40osc    [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT3]
create_generated_clock -name clk80osc    [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT4]
create_generated_clock -name clk10osc    [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT5]

set_clock_groups -quiet -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*CHANNEL_PRIM_INST/RXOUTCLK}]]
set_clock_groups -quiet -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*CHANNEL_PRIM_INST/TXOUTCLK}]]

set_clock_groups -quiet -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*CHANNEL_PRIM_INST/TXOUTCLKPCS}]]
set_clock_groups -quiet -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*CHANNEL_PRIM_INST/RXOUTCLKPCS}]]

set_clock_groups -quiet -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*.bufg_gt_usrclk2_inst/O}]]
set_clock_groups -quiet -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ U_axiInfra/*.bufg_gt_usrclk2_inst/O}]]



create_generated_clock -name clk40osc_mux -source [get_pins U_ApxTcds2/*.U_BUFGMUX_CTRL/I0] -divide_by 1 [get_pins U_ApxTcds2/*.U_BUFGMUX_CTRL/O]
create_generated_clock -name clk40rec_mux -source [get_pins U_ApxTcds2/*.U_BUFGMUX_CTRL/I1] -divide_by 1 -add -master_clock clk40rec [get_pins U_ApxTcds2/*.U_BUFGMUX_CTRL/O]
set_clock_groups -logically_exclusive -group [get_clocks -include_generated_clocks clk40osc_mux] -group [get_clocks -include_generated_clocks clk40rec_mux]



set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKIN1]] -group axiClk

set_clock_groups -asynchronous -group {clk40osc clk80osc clk40osc_mux clk40rec_mux} -group axiClk


##====================##
## TIMING CONSTRAINTS (FOR TCDS2-Test ##
##====================##
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT0]] \
-group [get_clocks -include_generated_clocks  -of_objects [get_pins -hierarchical -filter {NAME =~ */tcds2_interface/*mgt*.GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] \
-group [get_clocks -include_generated_clocks  -of_objects [get_pins -hierarchical -filter {NAME =~ */tcds2_interface/*mgt*.GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]

#-----------------------------------------------------
# lpGBT10G Tx - lpGBT-FE Tx - MASTER + SLAVE
#-----------------------------------------------------
set_multicycle_path 9  -to [get_pins -hierarchical -filter {NAME =~ *cmp_lpgbt_fe_tx/txgearbox_inst/dataWord_reg*/D}] -through [get_nets -hierarchical -filter {NAME =~ *cmp_lpgbt_fe_tx/txdatapath_inst/fec5*}] -setup
set_multicycle_path 8 -to [get_pins -hierarchical -filter {NAME =~ *cmp_lpgbt_fe_tx/txgearbox_inst/dataWord_reg*/D}] -through [get_nets -hierarchical -filter {NAME =~ *cmp_lpgbt_fe_tx/txdatapath_inst/fec5*}] -hold

#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT0] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
#set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_axiInfra/*/inst/mmcme*_adv_inst/CLKOUT0] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks  txoutclkpcs_out[0]] \
-group [get_clocks rxoutclk_out[0]_1] \
-group [get_clocks txoutclk_out[0]_1]




set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]



set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins */*/*/U_BUFG_GT/O]] -group axiClk
set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins U_QpllServiceBank/U_Axic2cMgtRefClkBuf/U_BUFG_GT/O]]



set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/ggen_refclk_buf[*].gen_refclk0.U_MgtRefClkBuf/U_BUFG_GT/O}]]
set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/ggen_refclk_buf[*].gen_refclk1.U_MgtRefClkBuf/U_BUFG_GT/O}]]





#####

###### Sector 0 ######

set_property LOC GTYE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[0]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[1]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y6 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[2]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y7 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[3]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y8 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[4]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y9 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[5]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y10 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[6]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y11 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[7]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y12 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[8]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y13 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[9]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y14 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[10]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y15 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[11]*.GTYE4_CHANNEL_PRIM_INST}]

###### Sector 1 ######

set_property LOC GTYE4_CHANNEL_X0Y20 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[12]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y21 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[13]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y22 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[14]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y23 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[15]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y24 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[16]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y25 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[17]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y26 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[18]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y27 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[19]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y32 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[20]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y33 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[21]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y34 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[22]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y35 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[23]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y36 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[24]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y37 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[25]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y38 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[26]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y39 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[27]*.GTYE4_CHANNEL_PRIM_INST}]

###### Sector 2 ######

set_property LOC GTYE4_CHANNEL_X0Y40 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[28]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y41 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[29]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y42 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[30]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y43 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[31]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y44 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[32]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y45 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[33]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y46 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[34]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y47 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[35]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y48 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[36]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y49 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[37]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y50 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[38]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y51 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[39]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y52 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[40]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y53 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[41]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y54 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[42]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y55 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[43]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y56 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[44]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y57 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[45]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y58 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[46]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y59 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[47]*.GTYE4_CHANNEL_PRIM_INST}]

###### Sector 3 ######

set_property LOC GTYE4_CHANNEL_X1Y4 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[48]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y5 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[49]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y6 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[50]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y7 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[51]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y8 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[52]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y9 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[53]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y10 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[54]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y11 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[55]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y12 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[56]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y13 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[57]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y14 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[58]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y15 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[59]*.GTYE4_CHANNEL_PRIM_INST}]

###### Sector 4 ######

set_property LOC GTYE4_CHANNEL_X1Y20 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[60]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y21 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[61]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y22 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[62]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y23 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[63]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y24 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[64]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y25 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[65]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y26 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[66]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y27 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[67]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y28 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[68]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y29 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[69]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y30 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[70]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y31 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[71]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y32 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[72]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y33 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[73]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y34 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[74]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y35 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[75]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y36 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[76]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y37 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[77]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y38 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[78]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y39 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[79]*.GTYE4_CHANNEL_PRIM_INST}]

###### Sector 5 ######

set_property LOC GTYE4_CHANNEL_X1Y40 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[80]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y41 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[81]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y42 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[82]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y43 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[83]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y44 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[84]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y45 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[85]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y46 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[86]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y47 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[87]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y48 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[88]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y49 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[89]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y50 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[90]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y51 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[91]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y52 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[92]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y53 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[93]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y54 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[94]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y55 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[95]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y56 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[96]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y57 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[97]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y58 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[98]*.GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X1Y59 [get_cells -hierarchical -filter {NAME =~ *gen_mgt[99]*.GTYE4_CHANNEL_PRIM_INST}]

set_property ES_EYE_SCAN_EN TRUE [get_cells -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST}]



# False path constraints
# ----------------------------------------------------------------------------------------------------------------------
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}]
##set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}]
set_false_path -to [get_pins -filter REF_PIN_NAME=~*D -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]]
set_false_path -to [get_pins -filter REF_PIN_NAME=~*PRE -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]]
set_false_path -to [get_pins -filter REF_PIN_NAME=~*PRE -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1*}]]
set_false_path -to [get_pins -filter REF_PIN_NAME=~*PRE -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2*}]]
set_false_path -to [get_pins -filter REF_PIN_NAME=~*PRE -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3*}]]
set_false_path -to [get_pins -filter REF_PIN_NAME=~*PRE -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out*}]]


create_clock -period 1.9393939 -name refclk0_0 [get_ports {mgtRefClk0P[0]}]
create_clock -period 1.9393939 -name refclk1_0 [get_ports {mgtRefClk0P[1]}]
create_clock -period 1.9393939 -name refclk2_0 [get_ports {mgtRefClk0P[2]}]
create_clock -period 1.9393939 -name refclk3_0 [get_ports {mgtRefClk0P[3]}]
create_clock -period 1.9393939 -name refclk4_0 [get_ports {mgtRefClk0P[4]}]
create_clock -period 1.9393939 -name refclk5_0 [get_ports {mgtRefClk0P[5]}]
create_clock -period 1.9393939 -name refclk6_0 [get_ports {mgtRefClk0P[6]}]
create_clock -period 1.9393939 -name refclk7_0 [get_ports {mgtRefClk0P[7]}]
create_clock -period 1.9393939 -name refclk8_0 [get_ports {mgtRefClk0P[8]}]
create_clock -period 1.9393939 -name refclk9_0 [get_ports {mgtRefClk0P[9]}]
create_clock -period 1.9393939 -name refclk10_0 [get_ports {mgtRefClk0P[10]}]
create_clock -period 1.9393939 -name refclk11_0 [get_ports {mgtRefClk0P[11]}]
create_clock -period 1.9393939 -name refclk12_0 [get_ports {mgtRefClk0P[12]}]
create_clock -period 1.9393939 -name refclk13_0 [get_ports {mgtRefClk0P[13]}]
create_clock -period 1.9393939 -name refclk14_0 [get_ports {mgtRefClk0P[14]}]
create_clock -period 1.9393939 -name refclk15_0 [get_ports {mgtRefClk0P[15]}]

create_clock -period 1.9393939 -name refclk0_1 [get_ports {mgtRefClk1P[0]}]
create_clock -period 1.9393939 -name refclk1_1 [get_ports {mgtRefClk1P[1]}]
create_clock -period 1.9393939 -name refclk2_1 [get_ports {mgtRefClk1P[2]}]
create_clock -period 1.9393939 -name refclk3_1 [get_ports {mgtRefClk1P[3]}]
create_clock -period 1.9393939 -name refclk4_1 [get_ports {mgtRefClk1P[4]}]
create_clock -period 1.9393939 -name refclk5_1 [get_ports {mgtRefClk1P[5]}]
create_clock -period 1.9393939 -name refclk6_1 [get_ports {mgtRefClk1P[6]}]
create_clock -period 1.9393939 -name refclk7_1 [get_ports {mgtRefClk1P[7]}]
create_clock -period 1.9393939 -name refclk8_1 [get_ports {mgtRefClk1P[8]}]
create_clock -period 1.9393939 -name refclk9_1 [get_ports {mgtRefClk1P[9]}]
create_clock -period 1.9393939 -name refclk10_1 [get_ports {mgtRefClk1P[10]}]
create_clock -period 1.9393939 -name refclk11_1 [get_ports {mgtRefClk1P[11]}]
create_clock -period 1.9393939 -name refclk12_1 [get_ports {mgtRefClk1P[12]}]
create_clock -period 1.9393939 -name refclk13_1 [get_ports {mgtRefClk1P[13]}]
create_clock -period 1.9393939 -name refclk14_1 [get_ports {mgtRefClk1P[14]}]
create_clock -period 1.9393939 -name refclk15_1 [get_ports {mgtRefClk1P[15]}]



set_property PACKAGE_PIN AN36 [get_ports {mgtRefClk1P[0]}]
set_property PACKAGE_PIN AJ36 [get_ports {mgtRefClk1P[1]}]
set_property PACKAGE_PIN AE36 [get_ports {mgtRefClk1P[2]}]
#set_property PACKAGE_PIN AB34 [get_ports {mgtRefClk0P[3]}]
set_property PACKAGE_PIN AA36 [get_ports {mgtRefClk1P[4]}]
set_property PACKAGE_PIN R36 [get_ports {mgtRefClk1P[5]}]
set_property PACKAGE_PIN N36 [get_ports {mgtRefClk1P[6]}]
set_property PACKAGE_PIN L36 [get_ports {mgtRefClk1P[7]}]
set_property PACKAGE_PIN AN11 [get_ports {mgtRefClk1P[8]}]
set_property PACKAGE_PIN AJ11 [get_ports {mgtRefClk1P[9]}]
set_property PACKAGE_PIN AE11 [get_ports {mgtRefClk1P[10]}]
set_property PACKAGE_PIN AC11 [get_ports {mgtRefClk1P[11]}]
set_property PACKAGE_PIN AA11 [get_ports {mgtRefClk1P[12]}]
set_property PACKAGE_PIN R11 [get_ports {mgtRefClk1P[13]}]
set_property PACKAGE_PIN N11 [get_ports {mgtRefClk1P[14]}]
set_property PACKAGE_PIN L11 [get_ports {mgtRefClk1P[15]}]

set_property PACKAGE_PIN AM34 [get_ports {mgtRefClk0P[0]}]
set_property PACKAGE_PIN AH34 [get_ports {mgtRefClk0P[1]}]
set_property PACKAGE_PIN AD34 [get_ports {mgtRefClk0P[2]}]
set_property PACKAGE_PIN Y34 [get_ports {mgtRefClk0P[4]}]
set_property PACKAGE_PIN P34 [get_ports {mgtRefClk0P[5]}]
set_property PACKAGE_PIN M34 [get_ports {mgtRefClk0P[6]}]
set_property PACKAGE_PIN K34 [get_ports {mgtRefClk0P[7]}]
set_property PACKAGE_PIN AM13 [get_ports {mgtRefClk0P[8]}]
set_property PACKAGE_PIN AH13 [get_ports {mgtRefClk0P[9]}]
set_property PACKAGE_PIN AD13 [get_ports {mgtRefClk0P[10]}]
set_property PACKAGE_PIN AB13 [get_ports {mgtRefClk0P[11]}]
set_property PACKAGE_PIN Y13 [get_ports {mgtRefClk0P[12]}]
set_property PACKAGE_PIN P13 [get_ports {mgtRefClk0P[13]}]
set_property PACKAGE_PIN M13 [get_ports {mgtRefClk0P[14]}]
set_property PACKAGE_PIN K13 [get_ports {mgtRefClk0P[15]}]

set_false_path -from [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]] -to [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]


set_false_path -from [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]] -to [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_false_path -from [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[1].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]] -group [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1]]


set_false_path -from [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.gtwiz_buffbypass_tx_done_out_reg/C}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/TXRATE[*]}]


set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]

set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/ggen_refclk_buf[*].gen_refclk0.U_MgtRefClkBuf/U_BUFG_GT/O}]]
set_clock_groups -asynchronous -group axiClk -group [get_clocks -of_objects [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/ggen_refclk_buf[*].gen_refclk1.U_MgtRefClkBuf/U_BUFG_GT/O}]]

set_false_path -from [get_pins {gen_sector[*].U_apxSector/U_IridisCSPTxCtrl/r_reg[iridisSfTxCtrlArr][*][resyncDly][*]/C}]
set_false_path -from [get_pins {gen_sector[*].U_apxSector/U_IridisCSPTxCtrl/genIridisSfTx[*].genIridisSfTxEn.U_IridisSfTx/r_iCSPFSM_reg[crcLatched][*]/C}]

set_false_path -from [get_pins {gen_sector[*].U_apxSector/U_IridisCSPRxCtrl/genIridisSfRx[*].genIridisSfRxEn.U_IridisCSPRx/U_LinkResyncCtrl/r_reg[resyncOut]/C}] -to [get_pins {gen_sector[*].U_apxSector/U_IridisCSPRxCtrl/genIridisSfRx[*].genIridisSfRxEn.U_IridisCSPRx/U_RstSync/Synchronizer_1/GEN.ASYNC_RST.crossDomainSyncReg_reg[0]/PRE}]
set_false_path -from [get_pins {U_ApxTcds2/tcds2_interface/tcds2_interface/tclink/cmp_cdc_rx/data_b_reg_reg[29]/C}] 

set_false_path -from [get_clocks -of_objects [get_pins U_axiInfra/gen_osc_300.U_clk_gen_300/inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1] -filter {IS_GENERATED && MASTER_CLOCK == clk40osc_mux}]


set_false_path -from [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_reset_controller_internal.gen_single_instance.gtwiz_reset_inst/reset_synchronizer_rx_done_inst/rst_in_out_reg/C}] -to [get_pins {gen_sector[*].U_apxSector/U_IridisCSPRxCtrl/genIridisSfRx[*].genIridisSfRxEn.U_IridisCSPRx/U_LinkResyncCtrl/FSM_onehot_r_reg[state][*]/CE}]

set_false_path -from [get_pins {gen_sector[*].U_apxSector/U_MgtCtrl/gen_mgt[*].gen_mgt_en.U_MgtWrapper/gen_mgt_25g.U_gty25g/inst/gen_gtwizard_gtye4_top.gty25g_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_rx_buffer_bypass_internal.gen_single_instance.gtwiz_buffbypass_rx_inst/gen_gtwiz_buffbypass_rx_main.gen_auto_mode.gtwiz_buffbypass_rx_done_out_reg/C}] 

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/RXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_ApxTcds2/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0]] -group [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *gen_mgt[*]*.GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]]
set_clock_groups -asynchronous -group  mgtRefClkBufg* -group axiClk
