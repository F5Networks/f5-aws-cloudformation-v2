#  expectValue = "SUCCESS"
#  expectFailValue = "failed to create:"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 120

bigip=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME>)
events=$(aws cloudformation describe-stack-events --region <REGION> --stack-name <ACCESS STACK NAME>|jq '.StackEvents[]|select (.ResourceStatus=="CREATE_FAILED")|(.ResourceType, .ResourceStatusReason)')

if echo $bigip | grep 'CREATE_COMPLETE'; then
  echo "SUCCESS"
else
  echo "FAILED"
  echo "EVENTS:${events}"
fi
