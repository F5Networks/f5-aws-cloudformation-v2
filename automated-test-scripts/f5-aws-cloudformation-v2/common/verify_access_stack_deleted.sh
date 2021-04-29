#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 90

response=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> 2>&1)
# verify delete
if echo $response | grep 'does not exist'; then
  echo "SUCCESS"
else
  echo "FAILED"
fi
