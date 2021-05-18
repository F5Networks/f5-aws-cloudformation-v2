#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

FLAG='FAIL'
PASSWORD='<SECRET VALUE>'
MGMT_PORT='8443'
group_name=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] |select (.AutoScalingGroupARN |contains("<UNIQUESTRING>-bigip"))|.AutoScalingGroupName')
echo "Autoscale group name: $group_name"

test_instance_id=$(aws autoscaling describe-auto-scaling-groups --region  <REGION> --auto-scaling-group-name $group_name | jq .AutoScalingGroups[0].Instances[0].InstanceId | tr -d '"')
echo "BIGIP Instance Id: $test_instance_id"
test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

echo "BIGIP Public IP: $test_instance_public_ip"

TS_RESPONSE=$(curl -sku admin:${PASSWORD} https://${test_instance_public_ip}:${MGMT_PORT}/mgmt/shared/telemetry/declare | jq -r .)
echo "TS_RESPONSE: ${TS_RESPONSE}"

if echo ${TS_RESPONSE} | grep -q "<REGION>"; then
    FLAG='SUCCESS'
fi

echo $FLAG
