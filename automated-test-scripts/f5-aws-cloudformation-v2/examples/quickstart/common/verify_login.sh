#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

FLAG='FAIL'
SSH_PORT='22'

test_instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpInstanceId") | .OutputValue')
if [[ <NIC COUNT> == 1 ]]; then
    MGMT_PORT='8443'
else
    MGMT_PORT='443'
fi

# note quickstarts use instance id for password
PASSWORD="$test_instance_id"
echo "BIGIP Instance Id: $test_instance_id"

if [[ "<PROVISION PUBLIC IP>" == "false" ]]; then
    if echo "<TEMPLATE URL>" | grep -q "existing-network"; then
        bastion_public_ip=$(aws cloudformation describe-stacks --stack-name bastion-<STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionPublicIp") | .OutputValue')
    else
        bastion_instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionHostInstanceId") | .OutputValue')
        echo "BASTION Instance Id: $bastion_instance_id"

        bastion_public_ip=$(aws ec2 describe-instances --region <REGION> --instance-ids $bastion_instance_id | jq -r .Reservations[0].Instances[0].PublicIpAddress)
    fi
    bigip_private_ip=$(aws ec2 describe-instances  --region <REGION> --instance-ids $test_instance_id |jq -r '.Reservations[0].Instances[0].PrivateIpAddress')

    echo "Bastion IP: $bastion_public_ip"
    echo "BIGIP Private Ip: $bigip_private_ip"

    SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i /etc/ssl/private/dewpt_private.pem -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i /etc/ssl/private/dewpt_private.pem -W %h:%p ubuntu@$bastion_public_ip" admin@"$bigip_private_ip" 'tmsh list auth user admin')
    PASSWORD_RESPONSE=$(ssh -o "StrictHostKeyChecking=no" -o ConnectTimeout=7 -i /etc/ssl/private/dewpt_private.pem ubuntu@"$bastion_public_ip" "curl -skvvu <BIGIP USER>:${PASSWORD} https://${bigip_private_ip}:${MGMT_PORT}/mgmt/tm/auth/user/admin")
else
    test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

    echo "BIGIP Public IP: $test_instance_public_ip"

    SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no <BIGIP USER>@${test_instance_public_ip} "tmsh list auth user <BIGIP USER>")
    PASSWORD_RESPONSE=$(curl -sku <BIGIP USER>:${PASSWORD} https://${test_instance_public_ip}:${MGMT_PORT}/mgmt/tm/auth/user/admin | jq -r .description)
fi

echo "SSH_RESPONSE: ${SSH_RESPONSE}"
echo "PASSWORD_RESPONSE: ${PASSWORD_RESPONSE}"

if echo ${SSH_RESPONSE} | grep -q "encrypted-password" && echo ${PASSWORD_RESPONSE} | grep -q "Admin User"; then
    FLAG='SUCCESS'
fi

echo $FLAG
