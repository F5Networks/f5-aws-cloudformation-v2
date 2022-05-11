#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 10


if [[ "<PROVISION EXAMPLE APP>" == 'false' ]]; then
    echo "SUCCESS"
else
    bigip2_stack_name=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstance02") | .OutputValue')

    bigip2_instanceid=$(aws cloudformation describe-stacks --stack-name $bigip2_stack_name --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstanceId") | .OutputValue')

    application_public_ip_2=$(aws ec2 describe-instances --region <REGION> --instance-ids $bigip2_instanceid | jq -r '.Reservations[].Instances[].NetworkInterfaces[].PrivateIpAddresses[] |select (.Primary=='false') | .Association.PublicIp')

    echo "Application Public IP: $application_public_ip_2"
    httpsResponse=$(curl -sk https://$application_public_ip_2)
    httpResponse=$(curl -sk http://$application_public_ip_2)

    if echo ${httpsResponse} | grep -q "Demo" && echo ${httpResponse} | grep -q "Demo"; then
        echo "SUCCESS"
    fi
fi