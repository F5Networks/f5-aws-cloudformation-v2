#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

group_name=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] | select(.AutoScalingGroupName | contains("<DEWPOINT JOB ID>")) | .AutoScalingGroupName')
test_instance_id=$(aws autoscaling describe-auto-scaling-groups --region  <REGION> --auto-scaling-group-name $group_name | jq .AutoScalingGroups[0].Instances[0].InstanceId | tr -d '"')

echo "BIGIP Instance Id: $test_instance_id"

test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

echo "BIGIP Public IP: $test_instance_public_ip"
ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/dewpt_private.pem admin@${test_instance_public_ip} 'modify auth user admin shell bash'
SSH_RESPONSE=$(ssh -o 'StrictHostKeyChecking no' -i /etc/ssl/private/dewpt_private.pem admin@${test_instance_public_ip} 'cat /config/cloud/telemetry_install_params.tmp')

if echo $SSH_RESPONSE | grep "/examples/modules/bigip-autoscale/bigip-autoscale.yaml"; then
    echo "SUCCESS"
fi