#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false

autoscaleGroup=$(aws autoscaling describe-auto-scaling-groups --region <REGION> | jq -r '.AutoScalingGroups[] | select(.AutoScalingGroupName | contains("<DEWPOINT JOB ID>"))')

minSize=$(echo $autoscaleGroup | jq .MinSize)
maxSize=$(echo $autoscaleGroup | jq .MaxSize)
[[ $minSize != '<SCALE MIN SIZE>' ]] && echo "MinSize is incorrect - FAIL"
[[ $maxSize != '<SCALE MAX SIZE>' ]] && echo "MaxSize is incorrect - FAIL"


targetGroupArnsCount=$(echo $autoscaleGroup | jq '.TargetGroupARNs | length')
expectedNumberOfTargetGroupsArns=0
if [[ '<PROVISION EXTERNAL LB>' == 'true' ]]; then
    ((expectedNumberOfTargetGroupsArns=expectedNumberOfTargetGroupsArns+1))
fi

if [[ '<PROVISION INTERNAL LB>' == 'true' ]]; then
    ((expectedNumberOfTargetGroupsArns=expectedNumberOfTargetGroupsArns+1))
fi

[[ $targetGroupArnsCount != $expectedNumberOfTargetGroupsArns ]] && echo 'Number of TargetGroups is incorrect - FAIL'
