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


if [[ "<PROVISION PUBLIC IP>" == "false" ]]; then
    bastion_autoscale_group_name=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionAutoscaleGroupName") | .OutputValue')

	echo "Autoscale group name: $bastion_autoscale_group_name"

	bastion_instance_id=$(aws autoscaling describe-auto-scaling-groups --region <REGION> --auto-scaling-group-name ${bastion_autoscale_group_name} | jq -r .AutoScalingGroups[0].Instances[0].InstanceId)

	echo "Bastion Name: $bastion_instance_id"

	bastion_ip=$(aws ec2 describe-instances --region <REGION> --instance-ids ${bastion_instance_id} --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)
    bigip_private_ip=$(aws ec2 describe-instances  --region <REGION> --instance-ids $test_instance_id |jq -r '.Reservations[0].Instances[0].PrivateIpAddress')

    echo "Bastion IP: $bastion_ip"
    echo "BIGIP Private Ip: $bigip_private_ip"

    TS_RESPONSE=$(ssh -o "StrictHostKeyChecking=no" -o ConnectTimeout=7 -i /etc/ssl/private/dewpt_private.pem ubuntu@"$bastion_ip" "curl -skvvu admin:${PASSWORD} https://${bigip_private_ip}:${MGMT_PORT}/mgmt/shared/telemetry/declare" | jq -r .)
else
    test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

    echo "BIGIP Public IP: $test_instance_public_ip"

    TS_RESPONSE=$(curl -sku admin:${PASSWORD} https://${test_instance_public_ip}:${MGMT_PORT}/mgmt/shared/telemetry/declare | jq -r .)
fi

echo "TS_RESPONSE: ${TS_RESPONSE}"

if echo ${TS_RESPONSE} | grep -q "<REGION>"; then
    FLAG='SUCCESS'
fi

echo $FLAG
