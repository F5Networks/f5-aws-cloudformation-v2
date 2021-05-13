# Cloud factory top-level Makefile

CUR_DIR := $(cwd)
PROJECT_DIR := .
LINK_CHECK_DIR := cloud-tools/link_checker
PARSER_DIR := cloud-tools/parameter-parser
DIFF_VAR :=`diff automated-test-scripts/parameters_diff_expected.yaml ${PARSER_DIR}/parameters_diff.yaml`
DIFF_VAR_OUTPUTS :=`diff automated-test-scripts/outputs_diff_expected.yaml ${PARSER_DIR}/outputs_diff.yaml`


.PHONY: help
help:
	@echo "Check MakeFile"
link_check:
	echo "Running link checker against all markdown files";
	cd ${LINK_CHECK_DIR} && npm install && cd ${CUR_DIR};
	${LINK_CHECK_DIR}/link_checker.sh ${PROJECT_DIR} "cloud-tools automated-test-scripts"
run_parameter_parser:
	echo "Generating v2 parameter config file"
	cd ${PARSER_DIR} &&	pip install -r requirements.txt && python parameter_parser.py --cloud aws
run_compare_parameters: run_parameter_parser
	echo "Comparing given outputs config file against golden parameters config file"
	cd ${PARSER_DIR} && python compare_parameters.py -g golden_parameters.yaml -l 2 &&	echo '*********' && echo 'The following files have parameters that do not match what is in golden_parameters.yaml' && cat parameters_diff.yaml
run_expected_diff:
	# Need to run run_compare_parser before running expected diff or DIFF_VAR variable will not be correct
	if [ -n ${DIFF_VAR} ]; then echo "Diff files for parmaters match!"; else echo "========================================"; echo "Diff files do not match: ${DIFF_VAR}"; exit 1; fi
run_outputs_parser:
	echo "Generating v2 parameter config file"
	cd ${PARSER_DIR} &&	pip install -r requirements.txt && python parameter_parser.py --type outputs --output-file outputs_config.yaml --cloud aws
run_compare_outputs: run_outputs_parser
	echo "Comparing given outputs config file against golden outputs config file"
	cd ${PARSER_DIR} && python compare_parameters.py -g golden_outputs.yaml --output-file outputs_diff.yaml --input-parameters-file outputs_config.yaml -l 2 &&	echo '*********' && echo 'The following files have outputs that do not match what is in golden_outputs.yaml' && cat outputs_diff.yaml
run_expected_outputs_diff:
	# Need to run run_compare_parser before running expected diff or DIFF_VAR variable will not be correct
	if [ -n ${DIFF_VAR_OUTPUTS} ]; then echo "Diff files for outputs match!"; else echo "========================================"; echo "Diff files do not match: ${DIFF_VAR_OUTPUTS}"; exit 1; fi
