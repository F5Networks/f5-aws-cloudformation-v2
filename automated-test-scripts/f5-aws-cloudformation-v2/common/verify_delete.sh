#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 180

case <STACK TYPE> in
existing-stack)
  appServer_response=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME> 2>&1)
production-stack)
  appServer_response=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME> 2>&1)
esac

# verify delete
if echo $appServer_response | grep 'does not exist'; then
  echo "SUCCESS"
else
  echo "FAILED"
fi
