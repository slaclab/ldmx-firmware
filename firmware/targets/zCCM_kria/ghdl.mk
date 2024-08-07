# Makefile automatically generated by ghdl
# Version: GHDL 0.34-dev (2017-03-01) [Dunoon edition] - mcode code generator
# Command used to generate this makefile:
# ghdl --gen-makefile -v -P/afs/slac/g/reseng/vol20/ghdl/lib/ghdl/vendors/xilinx-vivado/ --workdir=work --ieee=synopsys -fexplicit -frelaxed-rules AxiLiteCrossbar

GHDL=ghdl
GHDL_WORKDIR=ghdl
GHDLFLAGS=  --ieee=synopsys -fexplicit -frelaxed-rules  --warn-no-library
GHDLRUNFLAGS=

all: syntax import makefiles

clean :
	$(GHDL) --clean $(GHDLFLAGS)

import : 
	@echo "============================================================================="
	@echo Importing: surf
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=surf ../../submodules/surf/build/SRC_VHDL/surf/*
	@echo "============================================================================="
	@echo Importing: ruckus
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=ruckus ../../submodules/surf/build/SRC_VHDL/ruckus/*
	@echo "============================================================================="
	@echo Importing: axi-soc-core
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=axi_soc_ultra_plus_core ../../submodules/axi-soc-ultra-plus-core/shared/rtl/AxiSocUltraPlusPkg.vhd
	@echo "============================================================================="
	@echo Importing: ldmx_tdaq
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=ldmx_tdaq ../../common/tdaq/rtl/*
	@echo "============================================================================="
	@echo Importing: ldmx_ts
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=ldmx_ts ../../common/ts/rtl/*

	$(GHDL) -i $(GHDLFLAGS) --work=work ../../common/ts/rtl/zccmApplication.vhd

syntax: import
	@echo "============================================================================="
	@echo Syntax Checking:
	@echo "============================================================================="
	$(GHDL) -s $(GHDLFLAGS) --work=work ../../common/ts/rtl/zccmApplication.vhd

makefiles: import
	@echo "============================================================================="
	@echo Compiling:
	@echo "============================================================================="
	$(GHDL) -m $(GHDLFLAGS) zccmApplication


elaborate: $(ENTITIES)

$(ENTITIES) : import syntax
	$(GHDL) -e $(GHDLFLAGS) $@

html : $(FILES)
	$(GHDL) --xref-html $(GHDLFLAGS) $(FILES)

$(MAKEFILES) : import
	$(GHDL) --gen-makefile $(GHDLFLAGS) $(patsubst %.mk,%,$@) > work/$@
   
force:
