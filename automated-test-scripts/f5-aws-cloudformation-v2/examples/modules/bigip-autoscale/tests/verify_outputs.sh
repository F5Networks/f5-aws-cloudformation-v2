#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false


stack_outputs=$(aws cloudformation describe-stacks --region <REGION> --stack-name dewdrop-<TEMPLATE NAME>-<DEWPOINT JOB ID> | jq .Stacks[0].Outputs)
autoscaleGroup='bigIputoscaleGroup01'
snsTopic='snsTopic'

if echo $stack_outputs | grep $autoscaleGroup; then
    if echo $stack_outputs | grep $snsTopic; then
        echo "SUCCESS"
    fi
fi
