#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false


# Tests validates traffic is working as expected

execution_time_in_seconds=120
end=$((SECONDS+execution_time_in_seconds))

successes=0
failures=0

echo "Grabbing Application DNS name..."
dnsAppname=$(aws cloudformation describe-stacks --stack-name <STACK NAME> --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="wafExternalDnsName") | .OutputValue')
dnsAppname="${dnsAppname%\"}"
dnsAppname="${dnsAppname#\"}"

echo "Excuting HTTPS calls to Application for $execution_time_in_seconds seconds"
while [ $SECONDS -lt $end ]; do
    result=$(curl -sk --retry 1 --retry-max-time 10  --max-time 5 https://$dnsAppname | grep "Demo" | wc -l | xargs)
    echo "*********************"
    if [[ $result != 0 ]] ; then
        echo 'alive-check succeded'
        ((successes=successes+1))
    else
        echo 'alive-check failed'
        ((failures=failures+1))
    fi
    echo '.....................'
done


echo "Test execution results:"
echo ">>>> Successes: $successes"
echo ">>>> Failures: $failures"
requests_count=$(( successes + failures ))
echo ">>>> Total number requests: ${requests_count}"
fp=$(( (failures * 100)/ requests_count ))
sp=$(( (successes * 100)/ requests_count ))
echo ">>>> Failures: $fp%"
echo ">>>> Successes: $sp%"
if [ $sp -ge 95 ]; then
    echo "SUCCESS"
fi


