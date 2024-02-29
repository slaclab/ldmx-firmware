

create_pblock root_infra
add_cells_to_pblock [get_pblocks root_infra] [get_cells -quiet [list U_XBAR U_axiInfra U_ApxTcds2 U_APxInfo]]
remove_cells_from_pblock root_infra [get_cells [list U_axiInfra/gen_osc_300.U_clk_gen_300/inst/*]]
resize_pblock root_infra -add {CLOCKREGION_X0Y7:CLOCKREGION_X1Y7}

# APx Sectors 0
   create_pblock S_0
   add_cells_to_pblock S_0 [get_cells gen_sector[0].*/*Ctrl*]
   add_cells_to_pblock S_0 [get_cells gen_sector[0].*/U_XBAR]
   add_cells_to_pblock S_0 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_XBAR_Sec0]] 
   resize_pblock S_0 -add {SLICE_X0Y0:SLICE_X28Y299 RAMB36_X0Y0:RAMB36_X1Y59}


# APx Sectors 1
   create_pblock S_1
   add_cells_to_pblock S_1 [get_cells gen_sector[1].*/*Ctrl*]
   add_cells_to_pblock S_1 [get_cells gen_sector[1].*/U_XBAR]
   add_cells_to_pblock S_1 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_XBAR_Sec1]]
   add_cells_to_pblock S_1 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec1*}]]
   resize_pblock S_1 -add {SLICE_X0Y300:SLICE_X28Y599 RAMB36_X0Y60:RAMB36_X1Y119}


# APx Sectors 2
   create_pblock S_2
   add_cells_to_pblock S_2 [get_cells gen_sector[2].*/U_XBAR]
   add_cells_to_pblock S_2 [get_cells gen_sector[2].*/*Ctrl*]
   resize_pblock [get_pblocks S_2] -add {SLICE_X0Y600:SLICE_X28Y899 RAMB36_X0Y120:RAMB36_X1Y179}

# APx Sectors 3
   create_pblock S_3
   add_cells_to_pblock S_3 [get_cells gen_sector[3].*/*Ctrl*]
   add_cells_to_pblock S_3 [get_cells gen_sector[3].*/U_XBAR]
   add_cells_to_pblock S_3 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_XBAR_Sec3]] 
   resize_pblock [get_pblocks S_3] -add {CLOCKREGION_X5Y0:CLOCKREGION_X5Y4}

# APx Sectors 4
   create_pblock S_4
   add_cells_to_pblock S_4 [get_cells gen_sector[4].*/*Ctrl*]
   add_cells_to_pblock S_4 [get_cells gen_sector[4].*/U_XBAR]
   add_cells_to_pblock S_4 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_XBAR_Sec4]] 
  resize_pblock [get_pblocks S_4] -add {CLOCKREGION_X5Y5:CLOCKREGION_X5Y9}

# APx Sectors 5
  create_pblock S_5
   add_cells_to_pblock S_5 [get_cells gen_sector[5].*/*Ctrl*]
add_cells_to_pblock S_5 [get_cells gen_sector[5].*/U_XBAR]
  resize_pblock [get_pblocks S_5] -add {CLOCKREGION_X5Y10:CLOCKREGION_X5Y14}


   create_pblock AxiRs0_Sec0
   add_cells_to_pblock AxiRs0_Sec0 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_Axi_RegSlice_0_Sec0]]
  add_cells_to_pblock AxiRs0_Sec0 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec0Stage0*}]]
resize_pblock AxiRs0_Sec0 -add {SLICE_X0Y286:SLICE_X28Y299 LAGUNA_X0Y212:LAGUNA_X3Y239}
set_property IS_SOFT 0 [get_pblocks AxiRs0_Sec0]

   create_pblock AxiRs1_Sec0
   add_cells_to_pblock AxiRs1_Sec0 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_Axi_RegSlice_1_Sec0]]
   add_cells_to_pblock AxiRs1_Sec0 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec0Stage1*}]]
   resize_pblock AxiRs1_Sec0 -add SLICE_X0Y0:SLICE_X28Y8
   set_property IS_SOFT 0 [get_pblocks AxiRs1_Sec0]

   create_pblock AxiRs_Sec2
   add_cells_to_pblock AxiRs_Sec2 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_Axi_RegSlice_Sec2]]
   add_cells_to_pblock AxiRs_Sec2 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec2*}]]
   resize_pblock AxiRs_Sec2 -add {SLICE_X0Y600:SLICE_X28Y609 LAGUNA_X0Y480:LAGUNA_X3Y499}
set_property IS_SOFT 0 [get_pblocks AxiRs_Sec2]

   create_pblock AxiRs_Sec3
   add_cells_to_pblock AxiRs_Sec3 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_Axi_RegSlice_Sec3]]
   add_cells_to_pblock AxiRs_Sec3 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec3*}]]
resize_pblock AxiRs_Sec3 -add SLICE_X142Y0:SLICE_X168Y8
set_property IS_SOFT 0 [get_pblocks AxiRs_Sec3]


  create_pblock AxiRs_Sec4
  add_cells_to_pblock AxiRs_Sec4 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_Axi_RegSlice_Sec4]]
  add_cells_to_pblock AxiRs_Sec4 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec4*}]]
  resize_pblock AxiRs_Sec4 -add {SLICE_X142Y300:SLICE_X168Y309 LAGUNA_X20Y240:LAGUNA_X23Y259}
  set_property IS_SOFT 0 [get_pblocks AxiRs_Sec4]

   create_pblock AxiRs_Sec5
   add_cells_to_pblock AxiRs_Sec5 [get_cells [list U_ApxSectorChassisWrapper/genApd1Fabric0.U_ChassisApd1Fabric0/U_Axi_RegSlice_Sec5]]
   add_cells_to_pblock AxiRs_Sec5 [get_cells [list {U_apxFsTcdsCmdChassisWrapper/genTcdsDistApd1.U_ChassisApd1/tcdsCmdsSec5*}]]
resize_pblock AxiRs_Sec5 -add {SLICE_X142Y600:SLICE_X168Y609 LAGUNA_X20Y480:LAGUNA_X23Y499}
set_property IS_SOFT 0 [get_pblocks AxiRs_Sec5]



# -- Sector 0, Subsector 0
create_pblock SS_0_0
add_cells_to_pblock [get_pblocks SS_0_0] [get_cells -quiet {get_cells */*/gen*[0].*}]
add_cells_to_pblock [get_pblocks SS_0_0] [get_cells -quiet {get_cells */*/gen*[1].*}]
add_cells_to_pblock [get_pblocks SS_0_0] [get_cells -quiet {get_cells */*/gen*[2].*}]
add_cells_to_pblock [get_pblocks SS_0_0] [get_cells -quiet {get_cells */*/gen*[3].*}]
resize_pblock SS_0_0 -add {SLICE_X0Y60:SLICE_X28Y119  RAMB36_X0Y12:RAMB36_X1Y23} 

# -- Sector 0, Subsector 1
create_pblock SS_0_1
add_cells_to_pblock [get_pblocks SS_0_1] [get_cells -quiet {get_cells */*/gen*[4].*}]
add_cells_to_pblock [get_pblocks SS_0_1] [get_cells -quiet {get_cells */*/gen*[5].*}]
add_cells_to_pblock [get_pblocks SS_0_1] [get_cells -quiet {get_cells */*/gen*[6].*}]
add_cells_to_pblock [get_pblocks SS_0_1] [get_cells -quiet {get_cells */*/gen*[7].*}]
resize_pblock SS_0_1 -add {SLICE_X0Y120:SLICE_X28Y179 RAMB36_X0Y24:RAMB36_X1Y35} 

# -- Sector 0, Subsector 2
create_pblock SS_0_2
add_cells_to_pblock [get_pblocks SS_0_2] [get_cells -quiet {get_cells */*/gen*[8].*}]
add_cells_to_pblock [get_pblocks SS_0_2] [get_cells -quiet {get_cells */*/gen*[9].*}]
add_cells_to_pblock [get_pblocks SS_0_2] [get_cells -quiet {get_cells */*/gen*[10].*}]
add_cells_to_pblock [get_pblocks SS_0_2] [get_cells -quiet {get_cells */*/gen*[11].*}]
resize_pblock SS_0_2 -add {SLICE_X0Y180:SLICE_X28Y239 RAMB36_X0Y36:RAMB36_X1Y47} 

# -- Sector 1, Subsector 0
create_pblock SS_1_0
add_cells_to_pblock [get_pblocks SS_1_0] [get_cells -quiet {get_cells */*/gen*[12].*}]
add_cells_to_pblock [get_pblocks SS_1_0] [get_cells -quiet {get_cells */*/gen*[13].*}]
add_cells_to_pblock [get_pblocks SS_1_0] [get_cells -quiet {get_cells */*/gen*[14].*}]
add_cells_to_pblock [get_pblocks SS_1_0] [get_cells -quiet {get_cells */*/gen*[15].*}]
resize_pblock SS_1_0 -add {SLICE_X0Y300:SLICE_X28Y359 RAMB36_X0Y60:RAMB36_X1Y71} 

# -- Sector 1, Subsector 1
create_pblock SS_1_1
add_cells_to_pblock [get_pblocks SS_1_1] [get_cells -quiet {get_cells */*/gen*[16].*}]
add_cells_to_pblock [get_pblocks SS_1_1] [get_cells -quiet {get_cells */*/gen*[17].*}]
add_cells_to_pblock [get_pblocks SS_1_1] [get_cells -quiet {get_cells */*/gen*[18].*}]
add_cells_to_pblock [get_pblocks SS_1_1] [get_cells -quiet {get_cells */*/gen*[19].*}]
resize_pblock SS_1_1 -add {SLICE_X0Y360:SLICE_X28Y419 RAMB36_X0Y72:RAMB36_X1Y83} 

# -- Sector 1, Subsector 2
create_pblock SS_1_2
add_cells_to_pblock [get_pblocks SS_1_2] [get_cells -quiet {get_cells */*/gen*[20].*}]
add_cells_to_pblock [get_pblocks SS_1_2] [get_cells -quiet {get_cells */*/gen*[21].*}]
add_cells_to_pblock [get_pblocks SS_1_2] [get_cells -quiet {get_cells */*/gen*[22].*}]
add_cells_to_pblock [get_pblocks SS_1_2] [get_cells -quiet {get_cells */*/gen*[23].*}]
resize_pblock SS_1_2 -add {SLICE_X0Y480:SLICE_X28Y539 RAMB36_X0Y96:RAMB36_X1Y107}

# -- Sector 1, Subsector 3
create_pblock SS_1_3
add_cells_to_pblock [get_pblocks SS_1_3] [get_cells -quiet {get_cells */*/gen*[24].*}]
add_cells_to_pblock [get_pblocks SS_1_3] [get_cells -quiet {get_cells */*/gen*[25].*}]
add_cells_to_pblock [get_pblocks SS_1_3] [get_cells -quiet {get_cells */*/gen*[26].*}]
add_cells_to_pblock [get_pblocks SS_1_3] [get_cells -quiet {get_cells */*/gen*[27].*}]
resize_pblock SS_1_3 -add {SLICE_X0Y540:SLICE_X28Y599 RAMB36_X0Y108:RAMB36_X1Y119}

# -- Sector 2, Subsector 0
create_pblock SS_2_0
add_cells_to_pblock [get_pblocks SS_2_0] [get_cells -quiet {get_cells */*/gen*[28].*}]
add_cells_to_pblock [get_pblocks SS_2_0] [get_cells -quiet {get_cells */*/gen*[29].*}]
add_cells_to_pblock [get_pblocks SS_2_0] [get_cells -quiet {get_cells */*/gen*[30].*}]
add_cells_to_pblock [get_pblocks SS_2_0] [get_cells -quiet {get_cells */*/gen*[31].*}]
resize_pblock SS_2_0 -add {SLICE_X0Y600:SLICE_X28Y659 RAMB36_X0Y120:RAMB36_X1Y131}



# -- Sector 2, Subsector 1
create_pblock SS_2_1
add_cells_to_pblock [get_pblocks SS_2_1] [get_cells -quiet {get_cells */*/gen*[32].*}]
add_cells_to_pblock [get_pblocks SS_2_1] [get_cells -quiet {get_cells */*/gen*[33].*}]
add_cells_to_pblock [get_pblocks SS_2_1] [get_cells -quiet {get_cells */*/gen*[34].*}]
add_cells_to_pblock [get_pblocks SS_2_1] [get_cells -quiet {get_cells */*/gen*[35].*}]
resize_pblock SS_2_1 -add {SLICE_X0Y660:SLICE_X28Y719 RAMB36_X0Y132:RAMB36_X1Y143}

# -- Sector 2, Subsector 2
create_pblock SS_2_2
add_cells_to_pblock [get_pblocks SS_2_2] [get_cells -quiet {get_cells */*/gen*[36].*}]
add_cells_to_pblock [get_pblocks SS_2_2] [get_cells -quiet {get_cells */*/gen*[37].*}]
add_cells_to_pblock [get_pblocks SS_2_2] [get_cells -quiet {get_cells */*/gen*[38].*}]
add_cells_to_pblock [get_pblocks SS_2_2] [get_cells -quiet {get_cells */*/gen*[39].*}]
resize_pblock SS_2_2 -add {SLICE_X0Y720:SLICE_X28Y779 RAMB36_X0Y144:RAMB36_X1Y155}

# -- Sector 2, Subsector 3
create_pblock SS_2_3
add_cells_to_pblock [get_pblocks SS_2_3] [get_cells -quiet {get_cells */*/gen*[40].*}]
add_cells_to_pblock [get_pblocks SS_2_3] [get_cells -quiet {get_cells */*/gen*[41].*}]
add_cells_to_pblock [get_pblocks SS_2_3] [get_cells -quiet {get_cells */*/gen*[42].*}]
add_cells_to_pblock [get_pblocks SS_2_3] [get_cells -quiet {get_cells */*/gen*[43].*}]
resize_pblock SS_2_3 -add {SLICE_X0Y780:SLICE_X28Y839 RAMB36_X0Y156:RAMB36_X1Y167}

# -- Sector 2, Subsector 4
create_pblock SS_2_4
add_cells_to_pblock [get_pblocks SS_2_4] [get_cells -quiet {get_cells */*/gen*[44].*}]
add_cells_to_pblock [get_pblocks SS_2_4] [get_cells -quiet {get_cells */*/gen*[45].*}]
add_cells_to_pblock [get_pblocks SS_2_4] [get_cells -quiet {get_cells */*/gen*[46].*}]
add_cells_to_pblock [get_pblocks SS_2_4] [get_cells -quiet {get_cells */*/gen*[47].*}]
resize_pblock SS_2_4 -add {SLICE_X0Y840:SLICE_X28Y899 RAMB36_X0Y168:RAMB36_X1Y179}



# -- Sector 3, Subsector 0
create_pblock SS_3_0
add_cells_to_pblock [get_pblocks SS_3_0] [get_cells -quiet {get_cells */*/gen*[48].*}]
add_cells_to_pblock [get_pblocks SS_3_0] [get_cells -quiet {get_cells */*/gen*[49].*}]
add_cells_to_pblock [get_pblocks SS_3_0] [get_cells -quiet {get_cells */*/gen*[50].*}]
add_cells_to_pblock [get_pblocks SS_3_0] [get_cells -quiet {get_cells */*/gen*[51].*}]
resize_pblock [get_pblocks SS_3_0] -add {CLOCKREGION_X5Y1:CLOCKREGION_X5Y1}



# -- Sector 3, Subsector 1
create_pblock SS_3_1
add_cells_to_pblock [get_pblocks SS_3_1] [get_cells -quiet {get_cells */*/gen*[52].*}]
add_cells_to_pblock [get_pblocks SS_3_1] [get_cells -quiet {get_cells */*/gen*[53].*}]
add_cells_to_pblock [get_pblocks SS_3_1] [get_cells -quiet {get_cells */*/gen*[54].*}]
add_cells_to_pblock [get_pblocks SS_3_1] [get_cells -quiet {get_cells */*/gen*[55].*}]
resize_pblock [get_pblocks SS_3_1] -add {CLOCKREGION_X5Y2:CLOCKREGION_X5Y2}



# -- Sector 3, Subsector 2
create_pblock SS_3_2
add_cells_to_pblock [get_pblocks SS_3_2] [get_cells -quiet {get_cells */*/gen*[56].*}]
add_cells_to_pblock [get_pblocks SS_3_2] [get_cells -quiet {get_cells */*/gen*[57].*}]
add_cells_to_pblock [get_pblocks SS_3_2] [get_cells -quiet {get_cells */*/gen*[58].*}]
add_cells_to_pblock [get_pblocks SS_3_2] [get_cells -quiet {get_cells */*/gen*[59].*}]
resize_pblock [get_pblocks SS_3_2] -add {CLOCKREGION_X5Y3:CLOCKREGION_X5Y3}




# -- Sector 4, Subsector 0
create_pblock SS_4_0
add_cells_to_pblock [get_pblocks SS_4_0] [get_cells -quiet {get_cells */*/gen*[60].*}]
add_cells_to_pblock [get_pblocks SS_4_0] [get_cells -quiet {get_cells */*/gen*[61].*}]
add_cells_to_pblock [get_pblocks SS_4_0] [get_cells -quiet {get_cells */*/gen*[62].*}]
add_cells_to_pblock [get_pblocks SS_4_0] [get_cells -quiet {get_cells */*/gen*[63].*}]
resize_pblock [get_pblocks SS_4_0] -add {CLOCKREGION_X5Y5:CLOCKREGION_X5Y5}




# -- Sector 4, Subsector 1
create_pblock SS_4_1
add_cells_to_pblock [get_pblocks SS_4_1] [get_cells -quiet {get_cells */*/gen*[64].*}]
add_cells_to_pblock [get_pblocks SS_4_1] [get_cells -quiet {get_cells */*/gen*[65].*}]
add_cells_to_pblock [get_pblocks SS_4_1] [get_cells -quiet {get_cells */*/gen*[66].*}]
add_cells_to_pblock [get_pblocks SS_4_1] [get_cells -quiet {get_cells */*/gen*[67].*}]
resize_pblock [get_pblocks SS_4_1] -add {CLOCKREGION_X5Y6:CLOCKREGION_X5Y6}


# -- Sector 4, Subsector 2
create_pblock SS_4_2
add_cells_to_pblock [get_pblocks SS_4_2] [get_cells -quiet {get_cells */*/gen*[68].*}]
add_cells_to_pblock [get_pblocks SS_4_2] [get_cells -quiet {get_cells */*/gen*[69].*}]
add_cells_to_pblock [get_pblocks SS_4_2] [get_cells -quiet {get_cells */*/gen*[70].*}]
add_cells_to_pblock [get_pblocks SS_4_2] [get_cells -quiet {get_cells */*/gen*[71].*}]
resize_pblock [get_pblocks SS_4_2] -add {CLOCKREGION_X5Y7:CLOCKREGION_X5Y7}


# -- Sector 4, Subsector 3
create_pblock SS_4_3
add_cells_to_pblock [get_pblocks SS_4_3] [get_cells -quiet {get_cells */*/gen*[72].*}]
add_cells_to_pblock [get_pblocks SS_4_3] [get_cells -quiet {get_cells */*/gen*[73].*}]
add_cells_to_pblock [get_pblocks SS_4_3] [get_cells -quiet {get_cells */*/gen*[74].*}]
add_cells_to_pblock [get_pblocks SS_4_3] [get_cells -quiet {get_cells */*/gen*[75].*}]
resize_pblock [get_pblocks SS_4_3] -add {CLOCKREGION_X5Y8:CLOCKREGION_X5Y8}


# -- Sector 4, Subsector 4
create_pblock SS_4_4
add_cells_to_pblock [get_pblocks SS_4_4] [get_cells -quiet {get_cells */*/gen*[76].*}]
add_cells_to_pblock [get_pblocks SS_4_4] [get_cells -quiet {get_cells */*/gen*[77].*}]
add_cells_to_pblock [get_pblocks SS_4_4] [get_cells -quiet {get_cells */*/gen*[78].*}]
add_cells_to_pblock [get_pblocks SS_4_4] [get_cells -quiet {get_cells */*/gen*[79].*}]
resize_pblock [get_pblocks SS_4_4] -add {CLOCKREGION_X5Y9:CLOCKREGION_X5Y9}


# -- Sector 5, Subsector 0
create_pblock SS_5_0
add_cells_to_pblock [get_pblocks SS_5_0] [get_cells -quiet {get_cells */*/gen*[80].*}]
add_cells_to_pblock [get_pblocks SS_5_0] [get_cells -quiet {get_cells */*/gen*[81].*}]
add_cells_to_pblock [get_pblocks SS_5_0] [get_cells -quiet {get_cells */*/gen*[82].*}]
add_cells_to_pblock [get_pblocks SS_5_0] [get_cells -quiet {get_cells */*/gen*[83].*}]
resize_pblock [get_pblocks SS_5_0] -add {CLOCKREGION_X5Y10:CLOCKREGION_X5Y10}


# -- Sector 5, Subsector 1
create_pblock SS_5_1
add_cells_to_pblock [get_pblocks SS_5_1] [get_cells -quiet {get_cells */*/gen*[84].*}]
add_cells_to_pblock [get_pblocks SS_5_1] [get_cells -quiet {get_cells */*/gen*[85].*}]
add_cells_to_pblock [get_pblocks SS_5_1] [get_cells -quiet {get_cells */*/gen*[86].*}]
add_cells_to_pblock [get_pblocks SS_5_1] [get_cells -quiet {get_cells */*/gen*[87].*}]
resize_pblock [get_pblocks SS_5_1] -add {CLOCKREGION_X5Y11:CLOCKREGION_X5Y11}



# -- Sector 5, Subsector 2
create_pblock SS_5_2
add_cells_to_pblock [get_pblocks SS_5_2] [get_cells -quiet {get_cells */*/gen*[88].*}]
add_cells_to_pblock [get_pblocks SS_5_2] [get_cells -quiet {get_cells */*/gen*[89].*}]
add_cells_to_pblock [get_pblocks SS_5_2] [get_cells -quiet {get_cells */*/gen*[90].*}]
add_cells_to_pblock [get_pblocks SS_5_2] [get_cells -quiet {get_cells */*/gen*[91].*}]
resize_pblock [get_pblocks SS_5_2] -add {CLOCKREGION_X5Y12:CLOCKREGION_X5Y12}



# -- Sector 5, Subsector 3
create_pblock SS_5_3
add_cells_to_pblock [get_pblocks SS_5_3] [get_cells -quiet {get_cells */*/gen*[92].*}]
add_cells_to_pblock [get_pblocks SS_5_3] [get_cells -quiet {get_cells */*/gen*[93].*}]
add_cells_to_pblock [get_pblocks SS_5_3] [get_cells -quiet {get_cells */*/gen*[94].*}]
add_cells_to_pblock [get_pblocks SS_5_3] [get_cells -quiet {get_cells */*/gen*[95].*}]
resize_pblock [get_pblocks SS_5_3] -add {CLOCKREGION_X5Y13:CLOCKREGION_X5Y13}



# -- Sector 5, Subsector 4
create_pblock SS_5_4
add_cells_to_pblock [get_pblocks SS_5_4] [get_cells -quiet {get_cells */*/gen*[96].*}]
add_cells_to_pblock [get_pblocks SS_5_4] [get_cells -quiet {get_cells */*/gen*[97].*}]
add_cells_to_pblock [get_pblocks SS_5_4] [get_cells -quiet {get_cells */*/gen*[98].*}]
add_cells_to_pblock [get_pblocks SS_5_4] [get_cells -quiet {get_cells */*/gen*[99].*}]
resize_pblock [get_pblocks SS_5_4] -add {CLOCKREGION_X5Y14:CLOCKREGION_X5Y14}


create_pblock algo_SLR0
add_cells_to_pblock algo_SLR0 [get_cells [list U_algoTopWrapper/U_algoSlice2]] -clear_locs
resize_pblock [get_pblocks algo_SLR0] -add {CLOCKREGION_X2Y1:CLOCKREGION_X3Y3}

create_pblock algo_SLR1
add_cells_to_pblock algo_SLR1 [get_cells [list U_algoTopWrapper/U_algoSlice1]] -clear_locs
resize_pblock [get_pblocks algo_SLR1] -add {CLOCKREGION_X2Y6:CLOCKREGION_X3Y8}


create_pblock algo_SLR2

resize_pblock [get_pblocks algo_SLR2] -add {CLOCKREGION_X2Y11:CLOCKREGION_X3Y13}
