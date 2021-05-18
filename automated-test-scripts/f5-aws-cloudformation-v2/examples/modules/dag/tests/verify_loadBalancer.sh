#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false

if [[ "<PROVISION EXTERNAL LB>" == "Yes" ]]; then
    [[ $(aws elbv2 describe-load-balancers --region <REGION> --names <DEWPOINT JOB ID>-external-lb | jq -r .LoadBalancers[0].Scheme) == 'internet-facing' ]] && externalLb='PASS'
else
    externalLB="PASS"
fi


if [[ "<PROVISION INTERNAL LB>" == "Yes" ]]; then
    [[ $(aws elbv2 describe-load-balancers --region <REGION> --names <DEWPOINT JOB ID>-internal-lb | jq -r .LoadBalancers[0].Scheme) == 'internal' ]] && internalLb='PASS'
else
    internalLb="PASS"
fi

if [[ $externalLb != "PASS" || $internalLb != "PASS" ]]; then
    echo 'FAIL'
fi
