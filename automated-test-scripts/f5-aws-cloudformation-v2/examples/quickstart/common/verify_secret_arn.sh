#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 5


if [[ "<CREATE NEW SECRET>" == 'true' ]]; then
    FLAG='FAIL'
    SSH_PORT='22'

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
            bastion_instance_id=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionInstanceId") | .OutputValue')
            echo "BASTION Instance Id: $bastion_instance_id"

            bastion_public_ip=$(aws ec2 describe-instances --region <REGION> --instance-ids $bastion_instance_id | jq -r .Reservations[0].Instances[0].PublicIpAddress)
        fi
        bigip_private_ip=$(aws ec2 describe-instances  --region <REGION> --instance-ids $test_instance_id |jq -r '.Reservations[0].Instances[0].PrivateIpAddress')

        echo "Bastion IP: $bastion_public_ip"
        echo "BIGIP Private Ip: $bigip_private_ip"

        SECRET_RESPONSE=$(ssh -o "StrictHostKeyChecking no" -i ${bigip_private_key} -o ProxyCommand="ssh -o 'StrictHostKeyChecking no' -i ${bastion_private_key} -W %h:%p ec2-user@$bastion_public_ip" admin@"$bigip_private_ip" 'cat /config/cloud/secret_id')
    else
        test_instance_public_ip=$(aws ec2 describe-instances --region  <REGION> --instance-ids $test_instance_id | jq .Reservations[0].Instances[0].PublicIpAddress | tr -d '"')

        echo "BIGIP Public IP: $test_instance_public_ip"

        SECRET_RESPONSE=$(sshpass -p ${PASSWORD} ssh -o StrictHostKeyChecking=no <BIGIP USER>@${test_instance_public_ip} "cat /config/cloud/secret_id")
    fi

    echo "SECRET_RESPONSE: ${SECRET_RESPONSE}"
    if echo ${SECRET_RESPONSE} | grep -q "<UNIQUESTRING>-bigIpSecret"; then
        FLAG='SUCCESS'
    fi
    echo $FLAG
else
    echo "SUCCESS"
fi
