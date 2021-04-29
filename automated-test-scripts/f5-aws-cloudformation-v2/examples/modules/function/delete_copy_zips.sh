#  expectValue = "delete"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 5

# Use this script to empty the leftover copyZips function bucket so it can be deleted

stack_resources=$(aws cloudformation list-stack-resources --stack-name <STACK NAME> --region <REGION> | jq -r .)

zips_bucket=$(echo $stack_resources | jq '.StackResourceSummaries[] | select(.LogicalResourceId=="LambdaZipsBucket")' | jq -r .PhysicalResourceId)

aws s3 rm --region <REGION> s3://"$zips_bucket" --recursive 2>&1