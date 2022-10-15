#!/bin/sh

#FSM test
make cli GEN_TEST_TYPE=transitions
#compulsory tests
make cli GEN_TEST_TYPE=rand_rd
make cli GEN_TEST_TYPE=rand_wr
make cli GEN_TEST_TYPE=alternate
#register tests
make cli GEN_TEST_TYPE=invalid
make cli GEN_TEST_TYPE=read_only
make cli GEN_TEST_TYPE=default_vals
#merge coverage and testplan
make merge_coverage_with_test_plan
