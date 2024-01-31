##-----------------------------------------------------------------------------
## File          : sim/Makefile
## Author        : Ryan Herbst  <rherbst@slac.stanford.edu>
## Created       : 04/16/2009
##-----------------------------------------------------------------------------
## Description :
## Makefile for simulation.
##-----------------------------------------------------------------------------
## Copyright (c) 2009 by SLAC. All rights reserved.
## Proprietary and confidential to SLAC.
##-----------------------------------------------------------------------------
## Modification history :
## 04/16/2009: created
##-----------------------------------------------------------------------------

# Set Default Output
SIM_DIR=$(PWD)/../../../build/FrontEndTestTb

# Analog netlist
#ANA_NET = kpix_c.cir

# Shared memory id. Changed this if you need to run multiple instances
# Resulting shared memory file is simlink_username_id
SHM_ID=1
SHM_NAME="hps"

# Set Top Level
DIG_TOP=FrontEndTestTb

# Set 64-bit mode
EN64=-full64

# HDL Source Files
HDL_SRC= $(PWD)/../../../modules/gen_daq/simlink/SimLinkPkg.vhd \
	 $(PWD)/../../../modules/gen_daq/simlink/SimLinkRx.vhd \
	 $(PWD)/../../../modules/gen_daq/simlink/SimLinkTx.vhd \
        $(PWD)/../../../modules/StdLib/general/rtl/StdRtlPkg.vhd \
        $(PWD)/../../../modules/StdLib/general/tb/TextUtilPkg.vhd \
	 $(PWD)/../Version.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/ArbiterPkg.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/CRC32Rtl.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/ClkOutBufDiff.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/ClkOutBufSingle.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/Code8b10bPkg.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/DS2411Core.vhd \
	$(PWD)/../../../modules/StdLib/sync/rtl/Synchronizer.vhd \
	$(PWD)/../../../modules/StdLib/sync/rtl/RstSync.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/Debouncer.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/Decoder8b10b.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/DspAddSub.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/DspCounter.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/Encoder8b10b.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/Heartbeat.vhd \
	$(PWD)/../../../modules/StdLib/general/rtl/PwrUpRst.vhd \
	$(PWD)/../../../modules/StdLib/sync/rtl/SynchronizerEdge.vhd \
	$(PWD)/../../../modules/StdLib/sync/rtl/SynchronizerVector.vhd \
	$(PWD)/../../../modules/StdLib/ram/rtl/SimpleDualPortRam.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/FifoAsync.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/FifoSync.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/FifoSyncBuiltIn.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/FifoAsyncBuiltIn.vhd \
	$(PWD)/../../../modules/StdLib/sync/rtl/SynchronizerFifo.vhd \
	$(PWD)/../../../modules/StdLib/sync/rtl/SynchronizerOneShot.vhd \
	$(PWD)/../../../modules/StdLib/ram/rtl/TrueDualPortRam.vhd \
	$(PWD)/../../../modules/StdLib/ram/rtl/QuadPortRam.vhd \
	$(PWD)/../../../modules/StdLib/ram/rtl/DualPortRam.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/Fifo.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/FifoCascade.vhd \
	$(PWD)/../../../modules/StdLib/fifo/rtl/FifoMux.vhd \
	$(PWD)/../../../modules/StdLib/xilinx7/rtl/DeviceDna.vhd \
	$(PWD)/../../../modules/StdLib/xilinx7/rtl/Iprog7Series.vhd \
	$(PWD)/../../../modules/StdLib/xilinx7/rtl/XadcSimpleCore.vhd \
	$(PWD)/../../../modules/StdLib/axi/rtl/AxiLitePkg.vhd \
	$(PWD)/../../../modules/StdLib/axi/rtl/AxiLiteCrossbar.vhd \
	$(PWD)/../../../modules/StdLib/axi/rtl/AxiDualPortRam.vhd \
	$(PWD)/../../../modules/StdLib/axi/rtl/AxiVersion.vhd \
         $(PWD)/../../../modules/VcLib/rtl/VcPkg.vhd \
         $(PWD)/../../../modules/VcLib/rtl/VcCmdSlave.vhd \
         $(PWD)/../../../modules/VcLib/rtl/VcRegSlave.vhd \
         $(PWD)/../../../modules/VcLib/rtl/VcAxiMaster.vhd \
         $(PWD)/../../../modules/VcLib/rtl/VcUsBuff.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/stdlib.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/i2c_master_bit_ctrl.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/i2c_master_byte_ctrl.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cPkg.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cMaster.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cRegMaster.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cRegMasterAxiBridge.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cRegMasterMux.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cSlave.vhd \
         $(PWD)/../../../modules/i2c_core/rtl/I2cRegSlave.vhd \
	$(PWD)/../../../projects/FrontEndTest/rtl/XilCoresPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/HpsPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcReadoutPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/PowerMonitorPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/DataPathPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/FrontEndConfigRegsPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/MmcmPhaseShiftPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/FrontEndConfigRegs.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/RceConfigRegsPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/SpiMaster.vhd \
        $(PWD)/../../../modules/HeavyPDaq/rtl/Ad5144SpiAxiBridge.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcCore.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcConfig.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcDeframer.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcDeserializer.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcFramer.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AdcReadout7.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/Ads1115AxiBridge.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/MmcmPhaseShiftCtrl.vhd \
	$(PWD)/../../../build/FrontEndTest/FrontEndTest_project.srcs/sources_1/ip/PhaseShiftMmcm/*.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/ClockPhaseShifter.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/DaqTiming.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/SyncDetect.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/SampleExtractor.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/Threshold.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/DataPath.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/EventBuilder.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/FrontEndConfigRegsPkg.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/FrontEndConfigRegs.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/TrigControl.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/PowerMonitor.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/HybridIoCore.vhd \
	$(PWD)/../../../build/FrontEndTest/FrontEndTest_project.srcs/sources_1/ip/AxiXadcCore/AxiXadcCore_funcsim.vhdl \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AxiXadcWrapper.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/AxiEmcWrapper.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/HpsFrontEndCore.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/RceConfigRegs.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7QuadPll.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7TxRst.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7RxRst.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7AutoPhaseAligner.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7TxManualPhaseAligner.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7RxFixedLatPhaseAligner.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7RxRst.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7RecClkMonitor.vhd \
        $(PWD)/../../../modules/MgtLib/gtp7/rtl/Gtp7Core.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2CoreTypesPkg.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2CorePackage.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2RxCell.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2RxPhy.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2Rx.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2RxWrapper.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2TxPhy.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2TxSched.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2TxCell.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2Tx.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/core/Pgp2TxWrapper.vhd \
        $(PWD)/../../../modules/pgp2_core/rtl/gtp7/Pgp2Gtp7MultiLane.vhd \
        $(PWD)/../../../modules/VcLib/rtl/VcUsBuff16.vhd \
        $(PWD)/../../../modules/VcLib/rtl/VcPrbsTx.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/PgpFrontEndTest.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/HpsRceCore.vhd \
	$(PWD)/../../../modules/HeavyPDaq/rtl/SpiSlave.vhd \
	$(PWD)/../../../build/FrontEndTest/FrontEndTest_project.srcs/sources_1/ip/SysClkMmcm/*.vhd \
	$(PWD)/../../../build/FrontEndTest/FrontEndTest_project.srcs/sources_1/ip/DaqClkMmcm/*.vhd \
	 $(PWD)/../rtl/FrontEndTest.vhd \
         $(PWD)/../../../modules/StdLib/general/tb/ClkRst.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Ad5144.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/AdiConfigSlave.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Ad9252Serializer.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Ad9252.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Ads1115.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Apv25.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Hybrid.vhd \
	$(PWD)/../../../modules/HeavyPDaq/sim/Ltc2991.vhd \
	 $(PWD)/../../../modules/HeavyPDaq/sim/FrontEndBoardModel.vhd \
	 $(PWD)/FrontEndTestTb.vhd

# Verilog Source Files
#VLOG = $(PWD)/../../../modules/KpixCore/sim/Kpix.v 

# Targets
all:    dir env syn_setup rtl_src vhpi_src sim_dig
#analog: dir env syn_setup rtl_src vhpi_src ana_files ana_partition sim_ana

# Directory
dir:
	@mkdir -p $(SIM_DIR)

# RTL Files
rtl_src:
	@cd $(SIM_DIR); vhdlan $(EN64) $(HDL_SRC) 
#	@cd $(SIM_DIR); vlogan +v2k $(EN64) $(VLOG)

# VHPI Library
vhpi_src:
	@cd $(SIM_DIR); gcc -Wall -c -fPIC -O -DSHM_ID=$(SHM_ID) -DSHM_NAME=\"$(SHM_NAME)\" -I$(VCS_HOME)/include/ $(PWD)/../../../modules/gen_daq/simlink/VhpiGeneric.c
	@cd $(SIM_DIR); gcc -Wall -c -fPIC -O -DSHM_ID=$(SHM_ID) -DSHM_NAME=\"$(SHM_NAME)\" -I$(VCS_HOME)/include/ $(PWD)/../../../modules/gen_daq/simlink/SimLinkRx.c
	@cd $(SIM_DIR); gcc -Wall -c -fPIC -O -DSHM_ID=$(SHM_ID) -DSHM_NAME=\"$(SHM_NAME)\" -I$(VCS_HOME)/include/ $(PWD)/../../../modules/gen_daq/simlink/SimLinkTx.c
	@cd $(SIM_DIR); gcc -Wall -shared -o libSimSw_lib.so VhpiGeneric.o SimLinkRx.o SimLinkTx.o

sim_dig:
	@cd $(SIM_DIR); vcs $(EN64) $(DIG_TOP) -cpp g++ -cc gcc -lrt -debug_all -time "ns" -time_res "1ps"

clean: 
	@rm -rf $(SIM_DIR)/*
	@rm -rf $(SIM_DIR)/.synopsys_vss.setup

# Create Synopsis Setup File
syn_setup:
	@rm -f $(SIM_DIR)/.synopsys_vss.setup
	@echo "UNISIM:$(XIL_SIMLIB)/unisim"                >  $(SIM_DIR)/.synopsys_vss.setup
	@echo "XILINXCORELIB:$(XIL_SIMLIB)/xilinxcorelib"  >> $(SIM_DIR)/.synopsys_vss.setup
	@echo "SIMPRIM:$(XIL_SIMLIB)/simprim"              >> $(SIM_DIR)/.synopsys_vss.setup
	@echo "SECUREIP:$(XIL_SIMLIB)/secureip"            >> $(SIM_DIR)/.synopsys_vss.setup
	@echo "UNIMACRO:$(XIL_SIMLIB)/unimacro"            >> $(SIM_DIR)/.synopsys_vss.setup

# Create setup env script
env:
	@rm -f $(SIM_DIR)/setup_env.csh
	@echo "limit stacksize 60000"                                 >> $(SIM_DIR)/setup_env.csh
	@echo "setenv LD_LIBRARY_PATH $(SIM_DIR):${LD_LIBRARY_PATH}"  >> $(SIM_DIR)/setup_env.csh

