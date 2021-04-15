#  expectValue = "PASS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 5

flag=PASS
dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="vip1PublicUrl") | .OutputValue')

echo "Executing HTTPS calls to Application"
httpsResponse=$(curl -sk $dnsAppname)
echo "Validating HTTPS call:"
if ! echo $httpsResponse | grep "Demo"; then
 echo "HTTPS traffic is not working"
 flag=FAIL
fi

echo $flag
