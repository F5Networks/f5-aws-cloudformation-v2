#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 150


TMP_DIR='/tmp/<DEWPOINT JOB ID>'
echo "License type:<LICENSE TYPE>"
case <LICENSE TYPE> in
bigiq)
    bigiq_stack_name=<STACK NAME>-bigiq
    bigiq_stack_region=<REGION>
    if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
        echo "Found existing BIG-IQ StackId"
        cat ${TMP_DIR}/bigiq_info.json
        bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
        bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
    fi
    bigiq=$(aws cloudformation describe-stacks --region $bigiq_stack_region --stack-name $bigiq_stack_name)
    events=$(aws cloudformation describe-stack-events --region $bigiq_stack_region --stack-name $bigiq_stack_name | jq '.StackEvents[]|select (.ResourceStatus=="CREATE_FAILED")|(.ResourceType, .ResourceStatusReason)')
    echo "Verifying BIG-IQ stack creation...";;
*)
  echo "BIG-IQ not required for test!"
  bigiq="CREATE_COMPLETE"
esac

# verify stacks created - verifies both BIGIQ (if created)
if echo $bigiq | grep 'CREATE_COMPLETE'; then
  echo "SUCCESS"
else
  echo "FAILED"
  echo "EVENTS:${events}"
fi
