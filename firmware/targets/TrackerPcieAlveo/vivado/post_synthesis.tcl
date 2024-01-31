##############################################################################
## This file is part of 'LCLS Laserlocker Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS Laserlocker Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

# Bypass the debug chipscope generation
return

# Get variables and procedures
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Open the synthesis design
open_run synth_1

# ILA Core
set ilaName u_ila_bar0

CreateDebugCore ${ilaName}

set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

SetDebugCoreClk ${ilaName} {U_Core/U_REG/U_XBAR/axiClk}

ConfigProbe ${ilaName} {U_Core/U_REG/regReadSlave[rdata][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[awaddr][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[awprot][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[wdata][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[wstrb][*]}

ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[awvalid]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[bready]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[wlast]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteMaster[wvalid]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteSlave[awready]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteSlave[bvalid]}
ConfigProbe ${ilaName} {U_Core/U_REG/regWriteSlave[wready]}

ConfigProbe ${ilaName} {U_Core/U_REG/U_XBAR/sAxiWriteMasters[0][awaddr][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/U_XBAR/sAxiWriteMasters[0][awprot][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/U_XBAR/sAxiWriteMasters[0][wdata][*]}
ConfigProbe ${ilaName} {U_Core/U_REG/U_XBAR/sAxiWriteMasters[0][awvalid]}
ConfigProbe ${ilaName} {U_Core/U_REG/U_XBAR/sAxiWriteMasters[0][wvalid]}
ConfigProbe ${ilaName} {U_Core/U_REG/U_XBAR/sAxiWriteSlaves[0][awready]}

WriteDebugProbes ${ilaName}
