#!/usr/bin/env bash
#  expectValue = "LAMBDA IAM POLICY PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_lambda_iam_policy associative_array
# Array: [rule]="expected_value"
function verify_lambda_iam_policy() {
    local -n _arr=$1
    local role_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq '.StackResourceSummaries[] | select(.LogicalResourceId=="LamdaAccessRole")' | jq -r .PhysicalResourceId)
    local lambda_iam_policy_object=$(aws iam get-role-policy --role-name $role_name --policy-name LambdaAccessPolicy --region <REGION> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${lambda_iam_policy_object} | jq -r .$r)
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
declare -A lambda_iam_policy
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="ec2:DescribeInstances"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="autoscaling:CompleteLifecycleAction"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="autoscaling:DescribeAutoScalingGroups"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="xray:PutTraceSegments"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="xray:PutTelemetryRecords"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="ec2:DescribeNetworkInterfaces"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="ec2:CreateNetworkInterface"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="ec2:DeleteNetworkInterface"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="secretsmanager:GetSecretValue"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="logs:CreateLogGroup"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="logs:CreateLogStream"
lambda_iam_policy[PolicyDocument.Statement\[\].Action\[\]]="logs:PutLogEvents"

# Run array through function
response=$(verify_lambda_iam_policy "lambda_iam_policy")
spacer=$'\n============\n'

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "LAMBDA IAM POLICY PASSED ${spacer}${response}"
fi