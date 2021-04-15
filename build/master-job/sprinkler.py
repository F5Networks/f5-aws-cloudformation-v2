#!/usr/bin/env python

import argparse
import yaml
import requests
import random
import os
from time import sleep

GITSWARM_PIPELINE_TRIGGER_URL = "https://gitswarm.f5net.com/api/v4/projects/5092/trigger/pipeline"


def main():
    parser = argparse.ArgumentParser("Dewdrop sprinkler")
    parser.add_argument('-p', '--test-plan', help="Test plan")
    parser.add_argument('-t', '--token', help="git ci token")
    parser.add_argument('-r', '--branch', help="branch")
    parser.add_argument('-s', '--stack-type', help="stack type for elastic search logging")
    args = parser.parse_args()
    with open(args.test_plan, "r") as f:
        plan = yaml.load(f.read())

    for test_name, test_info in plan.items():
        if isinstance(test_info['parameters-files'], list):
            if 'environment' in test_info:
                cloud_provider_environment = test_info['environment']
            else:
                cloud_provider_environment = None
            if test_info['run'] == 'all':
                run_all_input_params_files(args, test_info['test-url'], test_info['parameters-files'], cloud_provider_environment)
            if test_info['run'] == 'random':
                run_random_input_params_files(args, test_info['test-url'], test_info['parameters-files'], test_info['random-num-of-tests'], cloud_provider_environment)
        else:
            print("Test run skipped since no parameter-files defined for ", test_info['test-url'])


def run_all_input_params_files(args, test_url, parameters_files, cloud_provider_environment):
    for input_parameter_file in parameters_files:
        trigger_test_run(args, test_url, input_parameter_file, cloud_provider_environment)
        sleep(15)


def run_random_input_params_files(args, test_url, parameters_files, num_of_random_tests, cloud_provider_environment):
    index_of_tests_ran = []
    random_test_index = 0

    # if the number of tests to randomize over is greater that the defined list of tests then run all the tests
    if num_of_random_tests >= len(parameters_files):
        run_all_input_params_files(args, test_url, parameters_files, cloud_provider_environment)
        return
    # if the number of tests to randomize over is less than zero then don't run those tests
    elif num_of_random_tests < 0:
        return

    # Check if the test has already been ran if not then run else try running another test
    while num_of_random_tests != 0:
        random_test_index = random.randint(0, len(parameters_files) - 1)
        try:
            index_of_tests_ran.index(random_test_index)
        except ValueError:
            index_of_tests_ran.append(random_test_index)
            trigger_test_run(args, test_url, parameters_files[random_test_index], cloud_provider_environment)
            num_of_random_tests -= 1
        sleep(15)


def trigger_test_run(args, test_url, input_parameter_file, cloud_provider_environment):
    data = {
        'token': args.token,
        'ref': args.branch,
        'variables[RUN_SCHEDULED_DEWDROP_TEST]': 'true',
        'variables[TEMPLATE_URL]': test_url,
        'variables[TEMPLATE_PARAMETERS]': input_parameter_file,
        'variables[STACK_TYPE]': args.stack_type,
        'variables[DEWDROP_IMAGE_ID]': os.environ['DEWDROP_IMAGE_ID'],
        'variables[CLOUD_PROVIDER_ENVIRONMENT]': cloud_provider_environment
    }
    print("Running test with test_url: ", test_url, " with ", input_parameter_file)
    response = requests.post(GITSWARM_PIPELINE_TRIGGER_URL, data=data, verify=False)
    print("Response from trigger: ", response.text)


if __name__ == "__main__":
    main()
