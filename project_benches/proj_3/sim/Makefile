export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/parameter_pkg/Makefile

GEN_TRANS_TYPE ?= wb_transaction
TEST_SEED ?= 12345

clean: 
	rm -rf work *.wlf transcript

comp_I2C_MB:
	vcom -cover f ../rtl/iicmb_int_pkg.vhd
	vcom -cover f ../rtl/iicmb_pkg.vhd
	vcom -cover f ../rtl/mbyte.vhd
	vcom -cover f ../rtl/mbit.vhd
	vcom -cover f ../rtl/bus_state.vhd
	vcom -cover f ../rtl/filter.vhd
	vcom -cover f ../rtl/conditioner.vhd
	vcom -cover f ../rtl/conditioner_mux.vhd
	vcom -cover f ../rtl/iicmb_m.vhd
	vcom -cover f ../rtl/regblock.vhd
	vcom -cover f ../rtl/wishbone.vhd
	vcom -cover f ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_parameter_pkg comp_i2c_pkg comp_wb_pkg comp_i2cmb_env_pkg
	vlog ../testbench/top.sv 

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

debug: clean compile simulate

run_cli:
	vsim -coverage -c -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value i2cmb_test; coverage save $(GEN_TRANS_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile run_cli

run_cov:
	vsim -i -classdebug -msgmode both -do "do load_ucdbs_and_merge_with_test_plan.do" optimized_debug_top_tb

merge_coverage_with_test_plan: clean compile run_cov

covert_testplan:
	xml2ucdb -formal Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	add testbrowser ./*.ucdb

merge_coverage:
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb
	coverage open ./sim_and_testplan_merged.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code -bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb
