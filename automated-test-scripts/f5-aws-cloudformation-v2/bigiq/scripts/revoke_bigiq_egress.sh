#  expectValue = "SUCCESS"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


# roaches check in but they don't check out
TMP_DIR='/tmp/<DEWPOINT JOB ID>'

if [ <LICENSE TYPE> == "bigiq" ]; then
    bigiq_stack_name=<STACK NAME>-bigiq
    bigiq_stack_region=<REGION>
    if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
        echo "Found existing BIG-IQ StackId"
        cat ${TMP_DIR}/bigiq_info.json
        bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
        bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
    fi

    mgmt_security_group_id=$(aws cloudformation describe-stacks --region $bigiq_stack_region --stack-name $bigiq_stack_name | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="deviceManagementSecurityGroup")|.OutputValue')
    internal_security_group_id=$(aws cloudformation describe-stacks --region $bigiq_stack_region --stack-name $bigiq_stack_name | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="deviceInternalSecurityGroup")|.OutputValue')

    mgmt_response=$(aws ec2 revoke-security-group-egress --group-id $mgmt_security_group_id --ip-permissions '[{"IpProtocol": "-1","IpRanges": [{"CidrIp": "0.0.0.0/0"}],"Ipv6Ranges": [{"CidrIpv6": "::/0"}]}]'  | jq .Return)
    internal_response=$(aws ec2 revoke-security-group-egress --group-id $internal_security_group_id --ip-permissions '[{"IpProtocol": "-1","IpRanges": [{"CidrIp": "0.0.0.0/0"}],"Ipv6Ranges": [{"CidrIpv6": "::/0"}]}]' | jq .Return)
    echo 'SUCCESS'
else
    echo 'SUCCESS'
fi