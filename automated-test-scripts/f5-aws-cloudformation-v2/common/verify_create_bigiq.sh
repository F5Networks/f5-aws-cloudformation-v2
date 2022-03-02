#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 150

# Grab stack info based on license type
echo "License type:<LICENSE TYPE>"
case <LICENSE TYPE> in
bigiq)
    bigiq=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME>-bigiq)
    events=$(aws cloudformation describe-stack-events --region <REGION> --stack-name <STACK NAME>-bigiq|jq '.StackEvents[]|select (.ResourceStatus=="CREATE_FAILED")|(.ResourceType, .ResourceStatusReason)')
    echo "Creating BIGIQ...";;
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
