#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 20


if [[ "<CREATE AUTOSCALE GROUP>" == "true" ]]; then

	autoscale_group_name=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="appAutoscaleGroupName") | .OutputValue')

	echo "Autoscale group name: $autoscale_group_name"

	instance_id=$(aws autoscaling describe-auto-scaling-groups --region <REGION> --auto-scaling-group-name ${autoscale_group_name} | jq -r .AutoScalingGroups[0].Instances[0].InstanceId)

	echo "Instance Name: $instance_id"

	PublicIpAddress=$(aws ec2 describe-instances --region <REGION> --instance-ids ${instance_id} --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

	echo "Public IP Address: $PublicIpAddress"

	if curl $PublicIpAddress | grep "Demo App"; then
	    echo "SUCCESS"
	else
		echo "FAIL"
	fi
else
	instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="appInstanceId") | .OutputValue')
	
	echo "Instance Name: $instance_id"
	
	PublicIpAddress=$(aws ec2 describe-instances --region <REGION> --instance-ids ${instance_id} --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)
	
	echo "Public IP Address: $PublicIpAddress"
	
	if curl $PublicIpAddress | grep "Demo App"; then
	    echo "SUCCESS"
	else
		echo "FAIL"
	fi
fi