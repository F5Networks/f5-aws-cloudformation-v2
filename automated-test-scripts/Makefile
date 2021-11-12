#!make
current_dir := $(shell pwd)
# Create an environmental script and refernce it here (.gitignore set to ignore env.sh)
# example: export GOOGLE_PROJECT_ID=my_project_id
# option 1 all env variables refrenced in rules need be defined in env.sh
# option 2 have env vars set prior to running make  rule
include env.sh
.PHONY: help
help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo " 'aws_network_mod' using dewdrop docker image:stable, runs network module test defined in env varable AWS_TEMPLATE_TEST_URL/AWS_TEMPLATE_TEST_PARMS"
	@echo " 'aws_autoscale2_payg' using dewdrop docker image:stable, runs autoscale test defined in env varable AWS_TEMPLATE_TEST_URL_API/AWS_TEMPLATE_TEST_PARAMS_API"
	@echo " 'aws_quickstart_payg' using dewdrop docker image:stable, runs quickstart test defined in env varable AWS_TEMPLATE_TEST_URL_LB/AWS_TEMPLATE_TEST_PARAMS_LB"

.PHONY: gce
env:
	env
# AWS V2
aws_failover_byol:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_FAILOVER_BYOL}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_FAILOVER_BYOL}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_failover_payg:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_FAILOVER_PAYG}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_FAILOVER_PAYG}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_failover_existing_payg:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_FAILOVER_EXISTING_PAYG}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_FAILOVER_EXISTING_PAYG}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_autoscale2_bigiq:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_AUTOSCALE_V2_BIGIQ}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_AUTOSCALE_V2_BIGIQ}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_autoscale2_payg:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_AUTOSCALE_V2_PAYG}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_AUTOSCALE_V2_PAYG}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_network_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_NETWORK_MOD}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_NETWORK_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_function_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_FUNCTION_MOD}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_FUNCTION_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_dag_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_DAG_MOD}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_DAG_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_quickstart_payg:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_QUICKSTART_PAYG}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_QUICKSTART_PAYG}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_quickstart_byol:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_QUICKSTART_BYOL}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_QUICKSTART_BYOL}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_bigip_standalone_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_BIGIP_STANDALONE}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_BIGIP_STANDALONE}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_bigip_autoscale_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_BIGIP_AUTOSCALE}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_BIGIP_AUTOSCALE}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_application_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_APPLICATION_MOD}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_APPLICATION_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_application_mod_autoscale:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_APPLICATION_MOD}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_APPLICATION_MOD_AUTOSCALE}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_access_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_ACCESS}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_ACCESS}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
aws_bastion_mod:
	docker run -it -v ${current_dir}:/automated-test-scripts -v ${current_dir}/../examples:/examples -e SSH_KEY="${DEWPT_PRIVATE_KEY}" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" -e STACK_TYPE="${STACK_TYPE}" -e TEMPLATE_URL="${AWS_TEMPLATE_TEST_URL_BASTION_MOD}" -e TEMPLATE_PARAMETERS="${AWS_TEMPLATE_TEST_PARAMS_BASTION_MOD}" artifactory.f5net.com/ecosystems-cloudsolutions-docker-dev/dewdrop:stable
