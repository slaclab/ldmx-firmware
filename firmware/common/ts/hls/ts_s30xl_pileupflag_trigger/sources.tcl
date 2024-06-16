##############################################################################
## This file is part of 'Vivado HLS Example'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'Vivado HLS Example', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

## Set the top level module
set_top ts_s30xl_pileupflag_trigger_hw

## Add source code
add_files ${PROJ_DIR}/src/ts_s30xl_pileupflag_trigger_hw.cpp

## Add testbed files
add_files -tb ${PROJ_DIR}/src/ts_s30xl_pileupflag_trigger_test.cpp
add_files -tb ${PROJ_DIR}/src/TestVec.dat
