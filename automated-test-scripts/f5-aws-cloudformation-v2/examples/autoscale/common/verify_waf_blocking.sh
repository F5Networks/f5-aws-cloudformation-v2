#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 40

dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="wafExternalDnsName") | .OutputValue')

echo "Executing HTTP and HTTPS calls to application $dnsAppname"
REJECTED_RESPONSE=$(curl -ks -X DELETE https://$dnsAppname)

if echo ${REJECTED_RESPONSE} | grep -q "The requested URL was rejected"; then
    echo "Succeeded"
else
    echo "Failed"
fi