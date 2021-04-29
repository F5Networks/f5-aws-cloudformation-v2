#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 90

bigip_response=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> 2>&1)
# verify delete
if echo $bigip_response | grep 'does not exist'; then
  echo "SUCCESS"
else
  echo "FAILED"
fi
