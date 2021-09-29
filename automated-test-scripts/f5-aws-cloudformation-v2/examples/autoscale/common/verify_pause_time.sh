#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 100

bigip_stack_name=$(aws cloudformation describe-stack-resources --region <REGION> --stack-name <STACK NAME> --logical-resource-id BigipAutoscale | jq -r .StackResources[0].PhysicalResourceId | awk -F[/,] '{print $2}')
echo "BIG-IP stack name: $bigip_stack_name"

events=$(aws cloudformation describe-stack-events --region <REGION> --stack-name $bigip_stack_name | jq -c -r '.StackEvents[]|select (.ResourceStatus=="UPDATE_IN_PROGRESS")|(.ResourceStatusReason)')
echo "BIG-IP stack events: $events"

if echo ${events} | grep "Pausing for PT<UPDATE PAUSE TIME>S"; then
    echo "SUCCESS"
fi