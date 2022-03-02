#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5


test_instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstanceId") | .OutputValue')

echo "BIGIP Instance Id: $test_instance_id"

test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

echo "BIGIP Public IP: $test_instance_public_ip"
ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/dewpt.pem admin@${test_instance_public_ip} 'modify auth user admin shell bash'
SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/dewpt.pem admin@${test_instance_public_ip} 'cat /config/cloud/telemetry_install_params.tmp')

if echo $SSH_RESPONSE | grep "/examples/modules/bigip-standalone/bigip-standalone.yaml"; then
    echo "SUCCESS"
fi