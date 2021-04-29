#!/usr/bin/env bash
#  expectValue = "LAMBDA IAM POLICY PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# usage: verify_lambda_iam_policy associative_array resource policy_name
# Array: [rule]="expected_value"
function verify_iam_policy() {
    local -n _arr=$1
    local role_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq --arg resourceId "${2}" '.StackResourceSummaries[] | select(.LogicalResourceId==$resourceId)' | jq -r .PhysicalResourceId)
    local iam_policy_object=$(aws iam get-role-policy --role-name $role_name --policy-name "${3}" --region <REGION> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${iam_policy_object} | jq -r .$r)
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

# usage: verify_notifications_iam_policy associative_array resource
# Array: [rule]="expected_value"
function verify_iam_role() {
    local -n _arr=$1
    local role_name=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq --arg resourceId "${2}" '.StackResourceSummaries[] | select(.LogicalResourceId==$resourceId)' | jq -r .PhysicalResourceId)
    local iam_policy_object=$(aws iam get-role --role-name $role_name --region <REGION> | jq -r .)
    for r in "${!_arr[@]}";
    do
        local response=$(echo ${iam_policy_object} | jq -r .$r)
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
# Build associative arrays
# array_name[jq_filter]=expected_response
declare -A lambda_iam_policy
lambda_iam_policy[PolicyDocument.Statement\[0\].Action\[0\]]="ec2:DescribeInstances"
lambda_iam_policy[PolicyDocument.Statement\[0\].Action\[1\]]="autoscaling:CompleteLifecycleAction"
lambda_iam_policy[PolicyDocument.Statement\[0\].Action\[2\]]="autoscaling:DescribeAutoScalingGroups"
lambda_iam_policy[PolicyDocument.Statement\[0\].Action\[3\]]="xray:PutTraceSegments"
lambda_iam_policy[PolicyDocument.Statement\[0\].Action\[4\]]="xray:PutTelemetryRecords"
lambda_iam_policy[PolicyDocument.Statement\[1\].Action\[0\]]="ec2:DescribeNetworkInterfaces"
lambda_iam_policy[PolicyDocument.Statement\[1\].Action\[1\]]="ec2:CreateNetworkInterface"
lambda_iam_policy[PolicyDocument.Statement\[1\].Action\[2\]]="ec2:DeleteNetworkInterface"
lambda_iam_policy[PolicyDocument.Statement\[2\].Action\[0\]]="secretsmanager:GetSecretValue"
lambda_iam_policy[PolicyDocument.Statement\[3\].Action\[0\]]="logs:CreateLogGroup"
lambda_iam_policy[PolicyDocument.Statement\[3\].Action\[1\]]="logs:CreateLogStream"
lambda_iam_policy[PolicyDocument.Statement\[3\].Action\[2\]]="logs:PutLogEvents"
lambda_iam_policy[PolicyDocument.Statement\[0\].Resource]="*"
lambda_iam_policy[PolicyDocument.Statement\[1\].Resource]="*"
lambda_iam_policy[PolicyDocument.Statement\[3\].Resource]="arn:aws:logs:*:*:*"
lambda_iam_policy[PolicyDocument.Statement\[0\].Effect]="Allow"
lambda_iam_policy[PolicyDocument.Statement\[1\].Effect]="Allow"
lambda_iam_policy[PolicyDocument.Statement\[2\].Effect]="Allow"
lambda_iam_policy[PolicyDocument.Statement\[3\].Effect]="Allow"

declare -A copyzips_iam_policy
copyzips_iam_policy[PolicyDocument.Statement\[0\].Action\[0\]]="s3:ListBucket"
copyzips_iam_policy[PolicyDocument.Statement\[0\].Action\[1\]]="s3:GetObject"
copyzips_iam_policy[PolicyDocument.Statement\[0\].Action\[2\]]="s3:PutObject"
copyzips_iam_policy[PolicyDocument.Statement\[0\].Action\[3\]]="s3:PutObjectAcl"
copyzips_iam_policy[PolicyDocument.Statement\[0\].Action\[4\]]="s3:DeleteObject"
copyzips_iam_policy[PolicyDocument.Statement\[0\].Resource]="arn:aws:s3:::*"
copyzips_iam_policy[PolicyDocument.Statement\[0\].Effect]="Allow"

declare -A notifications_iam_policy
notifications_iam_policy[Role.AssumeRolePolicyDocument.Statement\[0\].Effect]="Allow"
notifications_iam_policy[Role.AssumeRolePolicyDocument.Statement\[0\].Action]="sts:AssumeRole"
notifications_iam_policy[Role.AssumeRolePolicyDocument.Statement\[0\].Principal.Service]="autoscaling.amazonaws.com"

declare -A lambda_ami_iam_policy
lambda_ami_iam_policy[PolicyDocument.Statement\[0\].Action\[0\]]="logs:CreateLogGroup"
lambda_ami_iam_policy[PolicyDocument.Statement\[0\].Action\[1\]]="logs:CreateLogStream"
lambda_ami_iam_policy[PolicyDocument.Statement\[0\].Action\[2\]]="logs:PutLogEvents"
lambda_ami_iam_policy[PolicyDocument.Statement\[1\].Action\[0\]]="ec2:DescribeImages"
lambda_ami_iam_policy[PolicyDocument.Statement\[0\].Resource]="arn:aws:logs:*:*:*"
lambda_ami_iam_policy[PolicyDocument.Statement\[0\].Effect]="Allow"

# Run arrays through function
response=''
spacer=$'\n============\n'
if [[ <LICENSE TYPE> == 'bigiq' ]]; then
    response=$(verify_iam_policy "lambda_iam_policy" "LambdaAccessRole" "LambdaAccessPolicy")${spacer}
    response=${response}$(verify_iam_policy "copyzips_iam_policy" "CopyZipsRole" "lambda-copier")${spacer}
    response=${response}$(verify_iam_role "notifications_iam_policy" "BigIqNotificationRole")${spacer}
fi

if [[ <CREATE AMI ROLE> == 'true' ]]; then
    response=${response}$(verify_iam_policy "lambda_ami_iam_policy" "LambdaAmiExecutionRole" "LambdaAmiAccessPolicy")${spacer}
fi

# Evaluate results
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "LAMBDA IAM POLICY PASSED ${spacer}${response}"
fi