VIVADO=
TARGETDIR=$(PWD)
PROJECTDIR=$(TARGETDIR)/../../
GHDL=ghdl
GHDL_WORKDIR=ghdl
GHDLFLAGS=  --ieee=synopsys -fexplicit -frelaxed-rules  --warn-no-library
GHDLRUNFLAGS=

all: syntax import makefiles

clean :
	$(GHDL) --clean $(GHDLFLAGS)

import :
	@echo "============================================================================="
	@echo Setting up surf
	@echo "============================================================================="
	cd $(PROJECTDIR)/submodules/surf/ && make src
	@echo "============================================================================="
	@echo Importing: surf
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=surf $(PROJECTDIR)/submodules/surf/build/SRC_VHDL/surf/*
	@echo "============================================================================="
	@echo Importing: ruckus
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=ruckus $(PROJECTDIR)/submodules/surf/build/SRC_VHDL/ruckus/*
	@echo "============================================================================="
	@echo Importing: axi-soc-core
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=axi_soc_ultra_plus_core $(PROJECTDIR)/submodules/axi-soc-ultra-plus-core/shared/rtl/AxiSocUltraPlusPkg.vhd
	@echo "============================================================================="
	@echo Importing: unisim
	@echo "============================================================================="
	ghdl -i ${GHDLFLAGS} --work=unisim $(VIVADO)/data/vhdl/src/unisims/*vhd
	@echo "============================================================================="
	@echo Importing: lcls_timing_core
	@echo "============================================================================="
	cd $(PROJECTDIR)/submodules/lcls-timing-core && $(MAKE) && cp ghdl/work-obj93.cf $(TARGETDIR)/lcls_timing_core-obj93.cf
	@echo "============================================================================="
	@echo Importing: ldmx_tdaq
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=ldmx_tdaq $(PROJECTDIR)/common/tdaq/rtl/*
	@echo "============================================================================="
	@echo Importing: ldmx_ts
	@echo "============================================================================="
	$(GHDL) -i $(GHDLFLAGS) --work=ldmx_ts $(PROJECTDIR)/common/ts/rtl/*

	$(GHDL) -i $(GHDLFLAGS) --work=work $(PROJECTDIR)/common/ts/rtl/zccmApplication.vhd

syntax: import
	@echo "============================================================================="
	@echo Syntax Checking:
	@echo "============================================================================="
	$(GHDL) -s $(GHDLFLAGS) --work=work $(PROJECTDIR)/common/ts/rtl/zccmApplication.vhd

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
