#  expectValue = "PASS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


if [[ "<PROVISION EXAMPLE APP>" == 'false' || ( "<PROVISION PUBLIC IP>" == 'false' && "<NIC COUNT>" == '1' ) ]]; then
    echo "PASS"
else
    dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="vipPublicUrl") | .OutputValue')

    echo "Attempting illegal action (enforcement mode should be set to blocking by default) on ${dnsAppname}"

    REJECTED_RESPONSE=$(curl -sk -X DELETE ${dnsAppname})
    echo "REJECTED_RESPONSE: ${REJECTED_RESPONSE}"

    if echo ${REJECTED_RESPONSE} | grep -q "The requested URL was rejected"; then
        echo "PASS"
    fi
fi
