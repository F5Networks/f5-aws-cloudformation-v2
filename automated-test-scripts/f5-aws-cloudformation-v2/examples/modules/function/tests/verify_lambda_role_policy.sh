#!/usr/bin/env bash
#  expectValue = "LAMBDA POLICY PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_lambda_role_policy associative_array
# Array: [rule]="expected_value"
function verify_lambda_role_policy() {
    local -n _arr=$1
    local function_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq '.StackResourceSummaries[] | select(.LogicalResourceId=="LambdaBigIqRevoke")' | jq -r .PhysicalResourceId)
    local lambda_role_policy_object=$(aws lambda get-policy --function-name $function_name --region <REGION> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${lambda_role_policy_object} | jq -r .$r)
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

if [[ <CREATE AMI LOOKUP FUNCTION> == 'true' ]]; then
    declare -A lambda_role_policy
    sns_arn=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq '.StackResourceSummaries[] | select(.LogicalResourceId=="SNSTopic")' | jq -r .PhysicalResourceId)

    lambda_role_policy[Policy]=$sns_arn

    # Run array through function
    response=$(verify_lambda_role_policy "lambda_role_policy")
else
    response='No revoke function to test'
fi
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "LAMBDA POLICY PASSED ${spacer}${response}"
fi