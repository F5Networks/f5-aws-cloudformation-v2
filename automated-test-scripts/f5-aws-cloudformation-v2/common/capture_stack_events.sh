#  expectValue = "Stack Events"
#  scriptTimeout = 2
#  replayEnabled = false
#  replayTimeout = 10


echo "-------------------------------Stack Events---------------------------------"
aws cloudformation describe-stack-events --region <REGION> --stack-name <STACK NAME>|jq '.StackEvents[]'
echo "----------------------------End Stack Events--------------------------------"