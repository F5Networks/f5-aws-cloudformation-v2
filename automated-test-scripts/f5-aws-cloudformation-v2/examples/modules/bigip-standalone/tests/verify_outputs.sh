#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false


stack_outputs=$(aws cloudformation describe-stacks --region <REGION> --stack-name dewdrop-<TEMPLATE NAME>-<DEWPOINT JOB ID> | jq .Stacks[0].Outputs)

if echo $stack_outputs | grep "bigIpInstanceId"; then
   echo "SUCCESS"
fi
