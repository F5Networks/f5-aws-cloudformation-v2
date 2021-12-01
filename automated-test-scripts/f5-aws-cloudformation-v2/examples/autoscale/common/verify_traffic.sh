#  expectValue = "Succeeded"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 40


if [[ "<PROVISION EXAMPLE APP>" == "false" ]]; then
    echo "Not deploying app..."
    echo "Succeeded"
else
    dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="wafExternalDnsName") | .OutputValue')

    echo "Executing HTTP and HTTPS calls to application $dnsAppname"
    httpsResponse=$(curl -sk https://$dnsAppname)
    httpResponse=$(curl -sk http://$dnsAppname)

    echo "HTTPS response: $httpsResponse"
    echo "HTTP response: $httpResponse"

    if echo ${httpsResponse} | grep -q "Demo" && echo ${httpResponse} | grep -q "Demo"; then
        echo "Succeeded"
    else
        echo "Failed"
    fi
fi
