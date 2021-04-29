#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false


autoscaleGroupName=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] | select(.AutoScalingGroupName | contains("<DEWPOINT JOB ID>")) | .AutoScalingGroupName')
enabledAutoscalePolicies=$(aws autoscaling describe-policies --region <REGION> --auto-scaling-group-name $autoscaleGroupName | jq -r '.ScalingPolicies')

bigipScaleDownPolicy=$(echo $enabledAutoscalePolicies | jq -r '.[] | select(.PolicyName | contains("BigipScaleDownPolicy"))')
bigipScaleUpPolicy=$(echo $enabledAutoscalePolicies | jq '.[] | select(.PolicyName | contains("BigipScaleUpPolicy"))')

if [[ -z "$bigipScaleDownPolicy" || -z  "$bigipScaleUpPolicy" ]]; then
    echo "FAIL"
fi
