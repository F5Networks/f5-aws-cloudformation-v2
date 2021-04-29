#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false

instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstanceId") | .OutputValue')
bigip_instance_metadata=$(aws ec2 describe-instances --region <REGION> --instance-ids $instance_id | jq -r .Reservations[0].Instances[0])

[[ "<PUBLIC IP>" == "Yes" ]] && [[ -z $(echo $bigip_instance_metadata | jq .PublicIpAddress) ]] && echo "FAIL"
[[ $(echo $bigip_instance_metadata | jq .NetworkInterfaces | jq length) != "<NUMBER SUBNETS>" ]] && echo "FAIL"
