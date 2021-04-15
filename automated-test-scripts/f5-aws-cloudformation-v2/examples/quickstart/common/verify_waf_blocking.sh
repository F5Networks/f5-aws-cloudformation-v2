#  expectValue = "PASS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

flag=FAIL
dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="vip1PublicUrl") | .OutputValue')

echo "Attempting illegal action (enforcement mode should be set to blocking by default)"
REJECTED_RESPONSE=$(curl -ks -X DELETE ${dnsAppname})
echo "REJECTED_RESPONSE: ${REJECTED_RESPONSE}"

if echo $REJECTED_RESPONSE | grep -q "The requested URL was rejected"; then
    flag=PASS
fi

echo $flag