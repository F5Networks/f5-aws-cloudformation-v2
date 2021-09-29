#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 20


if [[ "<CREATE AUTOSCALE GROUP>" == "true" ]]; then

	autoscale_group_name=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionAutoscaleGroupName") | .OutputValue')

	echo "Autoscale group name: $autoscale_group_name"

	instance_id=$(aws autoscaling describe-auto-scaling-groups --region <REGION> --auto-scaling-group-name ${autoscale_group_name} | jq -r .AutoScalingGroups[0].Instances[0].InstanceId)

	echo "Bastion Name: $instance_id"

	BASTION_IP=$(aws ec2 describe-instances --region <REGION> --instance-ids ${instance_id} --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

    echo "Bastion IP: $BASTION_IP"
    ## Curl IP for response
    if [ -n "$BASTION_IP" ]; then
        response=$(ssh -o "StrictHostKeyChecking=no" -o ConnectTimeout=7 -i /etc/ssl/private/dewpt_private.pem ubuntu@"$BASTION_IP" "cat /etc/motd")
    fi

	if echo $response | grep "Welcome to Bastion Host"; then
        echo "SUCCESS"
    fi

else
	instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionInstanceId") | .OutputValue')

	echo "Instance Name: $instance_id"

	BASTION_IP=$(aws ec2 describe-instances --region <REGION> --instance-ids ${instance_id} --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)

    echo "Bastion IP: $BASTION_IP"
    ## Curl IP for response
    if [ -n "$BASTION_IP" ]; then
        response=$(ssh -o "StrictHostKeyChecking=no" -o ConnectTimeout=7 -i /etc/ssl/private/dewpt_private.pem ubuntu@"$BASTION_IP" "cat /etc/motd")
    fi

	if echo $response | grep "Welcome to Bastion Host"; then
        echo "SUCCESS"
    fi
fi
