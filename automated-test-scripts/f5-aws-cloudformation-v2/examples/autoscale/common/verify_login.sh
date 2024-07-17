#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5

FLAG='FAIL'

TMP_DIR='/tmp/<DEWPOINT JOB ID>'
if [ "<LICENSE TYPE>" == "bigiq" ]; then
    bigiq_stack_name=<STACK NAME>-bigiq
    bigiq_password=''
    if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
        echo "Found existing BIG-IQ StackId"
        cat ${TMP_DIR}/bigiq_info.json
        bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
        bigiq_password=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_password)
    fi
    PASSWORD=$bigiq_password
else
    PASSWORD='<SECRET VALUE>'
fi
echo "BigIp password=$PASSWORD"

bigip_private_key='/etc/ssl/private/dewpt_private.pem'
bastion_private_key='/etc/ssl/private/dewpt_private.pem'
if [[ "<CREATE NEW KEY PAIR>" == 'true' ]]; then
    bigip_private_key='/etc/ssl/private/new_key.pem'
    key_pair_name=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bigIpKeyPairName") | .OutputValue')
    key_pair_id=$(aws ec2 describe-key-pairs --key-name ${key_pair_name} --region <REGION> | jq -r .KeyPairs[0].KeyPairId)
    private_key_value=$(aws ssm get-parameter --name /ec2/keypair/${key_pair_id} --with-decryption --region <REGION> | jq -r .Parameter.Value > ${bigip_private_key})
    chmod 0600 ${bigip_private_key}
    echo "Key pair name: ${key_pair_name}"
    echo "Key pair ID: ${key_pair_id}"
    if [[ "<STACK TYPE>" == "full-stack" ]]; then
        bastion_private_key='/etc/ssl/private/new_key.pem'
    fi
fi
echo "Private key: ${bigip_private_key}"
echo "Bastion private key: ${bastion_private_key}"

MGMT_PORT='8443'
SSH_PORT='22'
group_name=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] |select (.AutoScalingGroupARN |contains("<UNIQUESTRING>-bigip"))|.AutoScalingGroupName')
echo "Autoscale group name: $group_name"

test_instance_id=$(aws autoscaling describe-auto-scaling-groups --region  <REGION> --auto-scaling-group-name $group_name | jq .AutoScalingGroups[0].Instances[0].InstanceId | tr -d '"')
echo "BIGIP Instance Id: $test_instance_id"

if [[ "<PROVISION PUBLIC IP>" == "false" ]]; then
    if [[ "<STACK TYPE>" == "existing-stack" ]]; then
        bastion_autoscale_group_name=$(aws cloudformation describe-stacks --stack-name bastion-<STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionAutoscaleGroupName") | .OutputValue')
    else
        bastion_autoscale_group_name=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionAutoscaleGroupName") | .OutputValue')
    fi

	echo "Autoscale group name: $bastion_autoscale_group_name"

	bastion_instance_id=$(aws autoscaling describe-auto-scaling-groups --region <REGION> --auto-scaling-group-name ${bastion_autoscale_group_name} | jq -r .AutoScalingGroups[0].Instances[0].InstanceId)

	echo "Bastion Name: $bastion_instance_id"

	bastion_ip=$(aws ec2 describe-instances --region <REGION> --instance-ids ${bastion_instance_id} --query "Reservations[*].Instances[*].PublicIpAddress" --output=text)
    bigip_private_ip=$(aws ec2 describe-instances  --region <REGION> --instance-ids $test_instance_id |jq -r '.Reservations[0].Instances[0].PrivateIpAddress')

    echo "Bastion IP: $bastion_ip"
    echo "BIGIP Private Ip: $bigip_private_ip"

    SSH_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i ${bigip_private_key} -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i ${bastion_private_key} -W %h:%p ec2-user@$bastion_ip" admin@"$bigip_private_ip" 'tmsh list auth user admin')
    PASSWORD_RESPONSE=$(ssh -o "StrictHostKeyChecking=no" -o ConnectTimeout=7 -i ${bastion_private_key} ec2-user@"$bastion_ip" "curl -skvvu 'admin:${PASSWORD}' https://${bigip_private_ip}:${MGMT_PORT}/mgmt/tm/auth/user/admin")
else
    test_instance_public_ip=$(aws ec2 describe-instances --region <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

    echo "BIGIP Public IP: $test_instance_public_ip"

    SSH_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no admin@${test_instance_public_ip} "tmsh list auth user admin")
    PASSWORD_RESPONSE=$(curl -sku "admin:${PASSWORD}" https://${test_instance_public_ip}:${MGMT_PORT}/mgmt/tm/auth/user/admin)
fi

echo "SSH_RESPONSE: ${SSH_RESPONSE}"
echo "PASSWORD_RESPONSE: ${PASSWORD_RESPONSE}"

if echo ${SSH_RESPONSE} | grep -q "encrypted-password" && echo ${PASSWORD_RESPONSE} | grep -q "Admin User"; then
    FLAG='SUCCESS'
fi

echo $FLAG
