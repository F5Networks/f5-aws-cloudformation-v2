#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

FLAG='FAIL'
PASSWORD='<SECRET VALUE>'


bigip1_stackname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstance01") | .OutputValue')
bigip1_instance_id=$(aws cloudformation describe-stacks --stack-name  ${bigip1_stackname} --region <REGION> | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="bigIpInstanceId")| .OutputValue')
bigip2_stackname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstance02") | .OutputValue')
bigip2_instance_id=$(aws cloudformation describe-stacks --stack-name  ${bigip2_stackname} --region <REGION> | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="bigIpInstanceId")| .OutputValue')


echo "BIGIP1 Instance Id: $bigip1_instance_id"
echo "BIGIP2 Instance Id: $bigip2_instance_id"

if [[ '<PROVISION MGMT PUBLIC IP>' == 'false' ]]; then
    echo 'MGMT PUBLIC IP IS NOT ENABLED'
    if [[ "<STACK TYPE>" == "existing-stack" ]]; then
        bastion_public_ip=$(aws cloudformation describe-stacks --stack-name bastion-<STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionPublicIp") | .OutputValue')
    else
        bastion_instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionHostInstanceId") | .OutputValue')
        echo "BASTION Instance Id: $bastion_instance_id"

        bastion_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $bastion_instance_id | jq -r .Reservations[0].Instances[0].PublicIpAddress)
    fi
    echo "BASTION PUBLIC IP: $bastion_public_ip"
    bigip1_private_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $bigip1_instance_id | jq -r .Reservations[0].Instances[0].PrivateIpAddress)
    echo "BIGIP1 PRIVATE IP: $bigip1_private_ip"
    bigip2_private_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $bigip2_instance_id | jq -r .Reservations[0].Instances[0].PrivateIpAddress)
    echo "BIGIP2 PRIVATE IP: $bigip2_private_ip"

    BIGIP1_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i /etc/ssl/private/dewpt_private.pem -W %h:%p ubuntu@$bastion_public_ip" admin@${bigip1_private_ip} "tmsh list auth user admin")
    echo "BIGIP1_RESPONSE: ${BIGIP1_SSH_RESPONSE}"
    BIGIP2_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i /etc/ssl/private/dewpt_private.pem -W %h:%p ubuntu@$bastion_public_ip" admin@${bigip2_private_ip} "tmsh list auth user admin")
    echo "BIGIP2_RESPONSE: ${BIGIP2_SSH_RESPONSE}"

    BIGIP1_RESPONSE=$(ssh -i /etc/ssl/private/dewpt_private.pem ubuntu@$bastion_public_ip "curl -sku admin:${PASSWORD} https://${bigip1_private_ip}:443/mgmt/tm/auth/user/admin" | jq -r .description)
    echo "BIGIP1_RESPONSE: ${BIGIP1_RESPONSE}"

    BIGIP2_RESPONSE=$(ssh -i /etc/ssl/private/dewpt_private.pem ubuntu@$bastion_public_ip "curl -sku admin:${PASSWORD} https://${bigip2_private_ip}:443/mgmt/tm/auth/user/admin" | jq -r .description)
    echo "BIGIP2_RESPONSE: ${BIGIP2_RESPONSE}"

else
    echo 'MGMT PUBLIC IP IS ENABLED'

    bigip1_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $bigip1_instance_id | jq -r .Reservations[0].Instances[0].PublicIpAddress)
    echo "BIGIP1 PRIVATE IP: $bigip1_public_ip"
    bigip2_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $bigip2_instance_id | jq -r .Reservations[0].Instances[0].PublicIpAddress)
    echo "BIGIP2 PRIVATE IP: $bigip2_public_ip"

    BIGIP1_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip1_public_ip} "tmsh list auth user admin")
    echo "BIGIP1_RESPONSE: ${BIGIP1_SSH_RESPONSE}"
    BIGIP2_SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o "StrictHostKeyChecking no" admin@${bigip2_public_ip} "tmsh list auth user admin")
    echo "BIGIP2_RESPONSE: ${BIGIP2_SSH_RESPONSE}"

    BIGIP1_RESPONSE=$(curl -sku admin:${PASSWORD} https://${bigip1_public_ip}:443/mgmt/tm/auth/user/admin | jq -r .description)
    echo "BIGIP1_RESPONSE: ${BIGIP1_RESPONSE}"

    BIGIP2_RESPONSE=$(curl -sku admin:${PASSWORD} https://${bigip2_public_ip}:443/mgmt/tm/auth/user/admin | jq -r .description)
    echo "BIGIP2_RESPONSE: ${BIGIP2_RESPONSE}"
fi

# evaluate responses
if echo ${BIGIP1_SSH_RESPONSE} | grep -q "encrypted-password" && echo ${BIGIP2_SSH_RESPONSE} | grep -q "encrypted-password" && echo ${BIGIP1_RESPONSE} | grep -q "Admin User" && echo ${BIGIP2_RESPONSE} | grep -q "Admin User"; then
    FLAG='SUCCESS'
fi

echo $FLAG
