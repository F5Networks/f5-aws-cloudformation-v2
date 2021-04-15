#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

FLAG='FAIL'

if [[ "<SOLUTION TYPE>" == "standalone" ]]; then
    test_instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstanceId") | .OutputValue')
    if [[ <NIC COUNT> == 1 ]]; then
        MGMT_PORT='8443'
    else
        MGMT_PORT='443'
    fi
else
    MGMT_PORT='8443'
    group_name=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] |select (.AutoScalingGroupARN |contains("<STACK NAME>"))|.AutoScalingGroupName' | grep 'BigipAutoscale')
    echo "Autoscale group name: $group_name"

    test_instance_id=$(aws autoscaling describe-auto-scaling-groups --region  <REGION> --auto-scaling-group-name $group_name | jq .AutoScalingGroups[0].Instances[0].InstanceId | tr -d '"')
fi

echo "BIGIP Instance Id: $test_instance_id"
PASSWORD="$test_instance_id"
test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

echo "BIGIP Public IP: $test_instance_public_ip"

AS3_RESPONSE=$(curl -sku <BIGIP USER>:${PASSWORD} https://${test_instance_public_ip}:${MGMT_PORT}/mgmt/shared/appsvcs/declare | jq -r .)
echo "AS3_RESPONSE: ${AS3_RESPONSE}"

if echo ${AS3_RESPONSE} | grep -q "Quickstart"; then
    FLAG='SUCCESS'
fi

echo $FLAG
