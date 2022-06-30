#  expectValue = "PASS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


if [[ "<PROVISION EXAMPLE APP>" == 'false' ]]; then
    echo "PASS"
else
    dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="vipPublicUrl") | .OutputValue')

    echo "Executing HTTPS call to Application ${dnsAppname}"

    RESPONSE=$(curl -sk ${dnsAppname})
    echo "RESPONSE: ${RESPONSE}"

    if echo ${RESPONSE} | grep -q "Demo"; then
        echo "PASS"
    fi
fi
