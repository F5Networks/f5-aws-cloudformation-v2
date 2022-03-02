#!/usr/bin/env bash
#  expectValue = "LAMBDA CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_lambda_function associative_array
# Array: [rule]="expected_value"
function verify_lambda_function() {
    local -n _arr=$1
    local function_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq --arg resourceId "${2}" '.StackResourceSummaries[] | select(.LogicalResourceId==$resourceId)' | jq -r .PhysicalResourceId)
    local lambda_function_object=$(aws lambda get-function --function-name $function_name --region <REGION> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${lambda_function_object} | jq -r .$r)
        if echo "$response" | grep -q "${_arr[$r]}"; then
            rule_result="Rule:${r}    Response:$response    Value:${_arr[$r]}    PASSED"
        else
            rule_result="Rule:${r}    Response:$response    Value:${_arr[$r]}    FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${rule_result}${spacer}"
    done
    echo "$results"
}

# Build associative array
# array_name[jq_filter]=expected_response
if [[ <CREATE REVOKE FUNCTION> == 'true' ]]; then
    role_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq '.StackResourceSummaries[] | select(.LogicalResourceId=="LambdaAccessRole")' | jq -r .PhysicalResourceId)
    security_group_id=''
    subnet_id=''
    secret_arn=''
    if [[ <BIGIQ ADDRESS TYPE> == 'private' ]]; then
        security_group_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpMgmtSecurityGroup").OutputValue' | cut -d ',' -f 1)
        subnet_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    fi
    secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
    layer_arn=$(aws lambda list-layer-versions --layer-name <UNIQUESTRING>-lambda-revoke-layer --query 'LayerVersions[0].LayerVersionArn' --region <REGION> | jq -r .)

    declare -A revoke_lambda_function
    revoke_lambda_function[Configuration.Environment.Variables.BIGIP_RUNTIME_INIT_CONFIG]=<RUNTIME INIT CONFIG>
    revoke_lambda_function[Configuration.Environment.Variables.BIGIQ_SECRET_ARN]=$secret_arn
    revoke_lambda_function[Configuration.Environment.Variables.F5_DISABLE_SSL_WARNINGS]="false"
    revoke_lambda_function[Configuration.Runtime]="python3.7"
    revoke_lambda_function[Configuration.Role]=$role_name
    revoke_lambda_function[Configuration.Handler]="revoke.lambda_handler"
    revoke_lambda_function[Configuration.Layers\[\]]=$layer_arn
    revoke_lambda_function[Configuration.VpcConfig.SecurityGroupIds\[\]]=$security_group_id
    revoke_lambda_function[Configuration.VpcConfig.SubnetIds\[\]]=$subnet_id
fi
if [[ <CREATE AMI LOOKUP FUNCTION> == 'true' ]]; then
    ami_role_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq '.StackResourceSummaries[] | select(.LogicalResourceId=="LambdaAmiExecutionRole")' | jq -r .PhysicalResourceId)
    declare -A ami_lambda_function
    ami_lambda_function[Configuration.Role]=$ami_role_name
fi
# Run array through function
spacer=$'\n============\n'
response=''
if [[ <CREATE REVOKE FUNCTION> == 'true' ]]; then
response=${response}$(verify_lambda_function "revoke_lambda_function" "LambdaBigIqRevoke")${spacer}
fi
if [[ <CREATE AMI LOOKUP FUNCTION> == 'true' ]]; then
response=${response}$(verify_lambda_function "ami_lambda_function" "AMIInfoFunction")${spacer}
fi

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "LAMBDA CREATION PASSED ${spacer}${response}"
fi