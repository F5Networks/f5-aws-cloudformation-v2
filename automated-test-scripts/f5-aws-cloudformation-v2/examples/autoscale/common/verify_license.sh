#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 180

# supports utility license only atm
autoscale_group=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] |select (.AutoScalingGroupARN |contains("<STACK NAME>"))|.AutoScalingGroupName' | grep 'bigip')
instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $autoscale_group --region <REGION> | jq -r .AutoScalingGroups[].Instances[].InstanceId)

running_macs=$(aws ec2 describe-instances --instance-ids $instances --region <REGION> --filters Name=instance-state-name,Values=running | jq -r '.Reservations[].Instances[].NetworkInterfaces[].MacAddress' | sort -f)
running_macs=$(echo "$running_macs" | tr '[:upper:]' '[:lower:]')
echo "Running MACs: ${running_macs}"

bigiq_address=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME>-bigiq | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="device1ManagementEipAddress")|.OutputValue')

auth_token=`curl -ks -X POST -d '{"username":"admin", "password":"<BIGIQ PASSWORD>", "loginProviderName":"local"}' https://${bigiq_address}/mgmt/shared/authn/login | jq -r .token.token`

production_key=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/ | jq -r '.items[] | select(.name=="production")' | jq -r .regKey`
offer_id=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/${production_key}/offerings | jq -r '.items[] | select(.name=="F5-BIG-MSP-BT-1G")' | jq -r .id`

licensed_macs=`curl -sk -H "X-F5-Auth-Token: $auth_token" https://${bigiq_address}/mgmt/cm/device/licensing/pool/utility/licenses/${production_key}/offerings/${offer_id}/members | jq -r '.items[] | select(.status=="LICENSED")' | jq -r .macAddress | sort -f`
licensed_macs=$(echo "$licensed_macs" | tr '[:upper:]' '[:lower:]')
echo "Licensed MACs: ${licensed_macs}"

if [[ ${running_macs} == ${licensed_macs} ]]; then
    echo "Succeeded"
else
    echo "Failed"
fi