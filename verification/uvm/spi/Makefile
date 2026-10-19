VCS_OPTS := -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert
VCS_OPTS += -o simv

VCS_SRC_FILES = ./rtl/spi_top.sv ./rtl/spi_master.sv ./rtl/spi_slave.sv \
                ./tb/spi_if.sv ./tb/spi_pkg.sv ./tb/tb_top.sv

VCS_INCDIR = +incdir+tb +incdir+rtl

TEST       ?= spi_basic_test
SEED       ?= 1234
INFO_LEVEL ?= UVM_DEBUG

SIMV_OPTS  = +UVM_TESTNAME=$(TEST)
SIMV_OPTS += +UVM_VERBOSITY=$(INFO_LEVEL)
SIMV_OPTS += +ntb_random_seed=$(SEED)
SIMV_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIMV_OPTS += -cm_dir coverage.vdb
SIMV_OPTS += -cm_name sim1

.PHONY: all compile run clean

all: run

compile:
	vcs $(VCS_OPTS) $(VCS_INCDIR) $(VCS_SRC_FILES)
	@echo "컴파일 완료"

run: compile
	./simv $(SIMV_OPTS)
	@echo "시뮬레이션 완료"

wave:
	//verdi -sv -ssf spi_tb.fsdb &
	verdi -dbdir ./simv.daidir -ssf spi_tb.fsdb

clean:
	rm -rf simv* csrc *.log *.key *.h
	@echo "정리 완료"
