#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 200

bigip=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME>)
events=$(aws cloudformation describe-stack-events --region <REGION> --stack-name <STACK NAME>|jq '.StackEvents[]|select (.ResourceStatus=="CREATE_FAILED")|(.ResourceType, .ResourceStatusReason)')

if echo $bigip | grep -w "UPDATE_COMPLETE"; then
  echo "SUCCESS"
else
  echo "FAILED"
  echo "EVENTS:${events}"
fi
