#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

# Construct an IP address belong to a specific subnet
#
# usage: get_ip ip offset
#
# NOTE: this is a hack (best guess), It will not work if the constructed IP address is already
# been used
function get_ip() {
    ip=$(echo $1 | cut -d "/" -f 1)
    RET=$(echo $ip | awk -F. '{ printf "%d.%d.%d.%d", $1, $2, $3, $4+'$2' }')
    echo $RET
}


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

bigIpExternalSecurityGroup=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpExternalSecurityGroup").OutputValue')
bigiMgmtPublicIpAllocationId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpManagementEipAllocationId01").OutputValue')
bigiExternalPublicIpAllocationId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpExternalEipAllocationId00").OutputValue')
bigIpInstanceProfile=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpInstanceProfile").OutputValue')

extArray=()
if [[ '<NUM SECONDARY PRIVATE IP>' == '4' ]]; then
    extArray+=($(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="bigIpExternalEipAllocationId04") | .OutputValue'))
fi
if [[ '<NUM SECONDARY PRIVATE IP>' == '3' || '<NUM SECONDARY PRIVATE IP>' == '4' ]]; then
    extArray+=("$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="bigIpExternalEipAllocationId03") | .OutputValue')")
fi
if [[ '<NUM SECONDARY PRIVATE IP>' == '2' || '<NUM SECONDARY PRIVATE IP>' == '3' || '<NUM SECONDARY PRIVATE IP>' == '4' ]]; then
    extArray+=("$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="bigIpExternalEipAllocationId02") | .OutputValue')")
fi
if [[ '<NUM SECONDARY PRIVATE IP>' == '1' || '<NUM SECONDARY PRIVATE IP>' == '2' || '<NUM SECONDARY PRIVATE IP>' == '3' || '<NUM SECONDARY PRIVATE IP>' == '4' ]]; then
    extArray+=("$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="bigIpExternalEipAllocationId01") | .OutputValue')")
    oldIFS="$IFS"
    IFS=','
    externalPublicIpIds=$(echo "${extArray[*]}")
    IFS="$oldIFS"
else
    externalPublicIpIds=''
    bigiExternalPublicIpAllocationId=''
fi


if [[ '<NUMBER SUBNETS>' == '3' ]]; then
    # This is 3 nic case
    subnet1Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnet2Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
    subnet3Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 3)
elif [[ '<NUMBER SUBNETS>' == '2' ]]; then
    # This is 2 nic case
    subnet1Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnet2Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
    subnet3Az1=''
elif [[ '<NUMBER SUBNETS>' == '1' ]]; then
    # This is 1 nic case
    subnet1Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnet2Az1=''
    subnet3Az1=''
else
    subnet1Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnet2Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
    subnet3Az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 3)
fi

security_groups_param="$bigIpExternalSecurityGroup,$bigIpExternalSecurityGroup,$bigIpExternalSecurityGroup"

runtimeConfig='"<RUNTIME INIT CONFIG>"'
if [[ "<RUNTIME INIT CONFIG>" == *{* ]]; then
    config_with_added_regkey="${runtimeConfig/<REGKEY>/<AUTOFILL EVAL LICENSE KEY>}"
    runtimeConfig=$config_with_added_regkey
fi

if [[ "<PRIVATE IP TYPE>" == *"STATIC"* ]]; then
    num=$(shuf -i 150-200 -n1)
    num2=$(shuf -i 100-149 -n1)
    num3=$(shuf -i 201-255 -n1)
    # used in all templates
    mgmt_ip=$(get_ip "$(aws ec2 describe-subnets --subnet-ids $subnet1Az1 --region <REGION>| jq .Subnets[0].CidrBlock -r)" ${num})

    if [[ '<NUMBER SUBNETS>' == '1' ]]; then
      # used with 1nic only
      externalServiceIps=$(get_ip "$(aws ec2 describe-subnets --subnet-ids $subnet1Az1 --region <REGION>| jq .Subnets[0].CidrBlock -r)" ${num2})
    elif [[ '<NUMBER SUBNETS>' == '2' || '<NUMBER SUBNETS>' == '3' ]]; then
        subnet1_ip_external=$(get_ip "$(aws ec2 describe-subnets --subnet-ids $subnet2Az1 --region <REGION>| jq .Subnets[0].CidrBlock -r)" ${num})
	    subnet1_ip_vip=$(get_ip "$(aws ec2 describe-subnets --subnet-ids $subnet2Az1 --region <REGION>| jq .Subnets[0].CidrBlock -r)" ${num2})
        subnet1_ip="$subnet1_ip_external,$subnet1_ip_vip"
    	externalSelfIp=$subnet1_ip_vip
	    externalServiceIps=$subnet1_ip_external
        if [[ '<NUM SECONDARY PRIVATE IP>' == 2 ]]; then
            subnet1_ip_external2=$(get_ip "$(aws ec2 describe-subnets --subnet-ids $subnet2Az1 --region <REGION>| jq .Subnets[0].CidrBlock -r)" ${num3})
            externalServiceIps="${subnet1_ip_external},$subnet1_ip_external2"
        fi
        if [[ '<NUMBER SUBNETS>' == '3' ]]; then
	        subnet2_ip=$(get_ip "$(aws ec2 describe-subnets --subnet-ids ${subnet3Az1} --region <REGION>| jq .Subnets[0].CidrBlock -r)" ${num})
	        internalSelfIp=$subnet2_ip
        fi
    fi
else
    mgmt_ip=''
    externalSelfIp=''
    internalSelfIp=''
    externalServiceIps=''
fi


parameters="\
ParameterKey=bigIpInstanceProfile,ParameterValue=$bigIpInstanceProfile \
ParameterKey=bigIpRuntimeInitConfig,ParameterValue=$runtimeConfig \
ParameterKey=bigIpRuntimeInitPackageUrl,ParameterValue=<RUNTIME_URL> \
ParameterKey=externalPrimaryPublicId,ParameterValue=$bigiExternalPublicIpAllocationId \
ParameterKey=externalPublicIpIds,ParameterValue=\"${externalPublicIpIds}\" \
ParameterKey=externalSecurityGroupId,ParameterValue=$bigIpExternalSecurityGroup \
ParameterKey=externalSelfIp,ParameterValue=$externalSelfIp \
ParameterKey=externalServiceIps,ParameterValue=\"${externalServiceIps}\" \
ParameterKey=externalSubnetId,ParameterValue=$subnet2Az1 \
ParameterKey=imageId,ParameterValue=<BIGIP AMI> \
ParameterKey=instanceType,ParameterValue=<BIGIP INSTANCE TYPE> \
ParameterKey=internalSecurityGroupId,ParameterValue="${bigIpExternalSecurityGroup}" \
ParameterKey=internalSelfIp,ParameterValue=$internalSelfIp \
ParameterKey=internalSubnetId,ParameterValue=$subnet3Az1 \
ParameterKey=mgmtPublicIpId,ParameterValue=$bigiMgmtPublicIpAllocationId \
ParameterKey=mgmtSecurityGroupId,ParameterValue=$bigIpExternalSecurityGroup \
ParameterKey=mgmtSelfIp,ParameterValue=$mgmt_ip \
ParameterKey=mgmtSubnetId,ParameterValue=$subnet1Az1 \
ParameterKey=numSecondaryPrivateIpAddress,ParameterValue=<NUM SECONDARY PRIVATE IP> \
ParameterKey=sshKey,ParameterValue=<SSH KEY> \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING>"

echo "Parameters:$parameters"

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_IAM --parameters $parameters
