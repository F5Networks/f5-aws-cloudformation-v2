#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false

stack_outputs=$(aws cloudformation describe-stacks --region <REGION> --stack-name dewdrop-<LICENSE TYPE>-<IMAGE NAME>-<DEWPOINT JOB ID> | jq .Stacks[0].Outputs)

if [[ "<CREATE AUTOSCALE GROUP>" == "true" ]]; then
    appAutoscaleGroupName='<UNIQUESTRING>-application-autoscale-group'
    if echo $stack_outputs | grep $appAutoscaleGroupName; then
        echo "SUCCESS"
    else
        echo "FAIL"
    fi
else   
    stack_name='dewdrop-<LICENSE TYPE>-<IMAGE NAME>-<DEWPOINT JOB ID>'
    if echo $stack_outputs | grep $stack_name; then
        echo "SUCCESS"
    else
        echo "FAIL"
    fi
fi