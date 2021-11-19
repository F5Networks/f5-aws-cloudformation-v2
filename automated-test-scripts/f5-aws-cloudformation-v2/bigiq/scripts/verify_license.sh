#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180


# supports utility license only atm
TMP_DIR='/tmp/<DEWPOINT JOB ID>'
autoscale_group=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] |select (.AutoScalingGroupARN |contains("<UNIQUESTRING>-bigip"))|.AutoScalingGroupName')
instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $autoscale_group --region <REGION> | jq -r .AutoScalingGroups[].Instances[].InstanceId)

running_macs=$(aws ec2 describe-instances --instance-ids $instances --region <REGION> --filters Name=instance-state-name,Values=running | jq -r '.Reservations[].Instances[].NetworkInterfaces[].MacAddress' | sort -f)
running_macs=$(echo "$running_macs" | tr '[:upper:]' '[:lower:]')
echo "Running MACs: ${running_macs}"

bigiq_stack_name=<STACK NAME>-bigiq
bigiq_stack_region=<REGION>
bigiq_password=''
if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
    echo "Found existing BIG-IQ"
    cat ${TMP_DIR}/bigiq_info.json
    bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
    bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
    bigiq_password=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_password)
fi

bigiq_address=$(aws cloudformation describe-stacks --region $bigiq_stack_region --stack-name $bigiq_stack_name | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="device1ManagementEipAddress")|.OutputValue')

auth_token=`curl -ks -X POST -d '{"username":"admin", "password":"'"${bigiq_password}"'", "loginProviderName":"local"}' https://${bigiq_address}/mgmt/shared/authn/login | jq -r .token.token`

production_key=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/ | jq -r '.items[] | select(.name=="production")' | jq -r .regKey`
offer_id=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/${production_key}/offerings | jq -r '.items[] | select(.name=="F5-BIG-MSP-BT-1G")' | jq -r .id`

licensed_macs=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/${production_key}/offerings/${offer_id}/members | jq -r '.items[] | select((.status=="LICENSED") and (.tenant | startswith("<DEWPOINT JOB ID>")))' | jq -r .macAddress | sort -f`
licensed_macs=$(echo "$licensed_macs" | tr '[:upper:]' '[:lower:]')
echo "Licensed MACs: ${licensed_macs}"

if [[ ${running_macs} == ${licensed_macs} ]]; then
    echo "Succeeded"
else
    echo "Failed"
fi
