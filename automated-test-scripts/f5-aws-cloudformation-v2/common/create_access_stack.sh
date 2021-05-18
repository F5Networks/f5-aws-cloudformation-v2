#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
bigiq_secret_arn=""
create_bigiq_roles="false"
if [[ <LICENSE TYPE> == 'bigiq' ]]; then
    bigiq_secret_arn=$secret_arn
    create_bigiq_roles="true"
fi
echo "secret_arn=$secret_arn"
echo "bigiq_secret_arn=$bigiq_secret_arn"
echo "create_bigiq_roles=$create_bigiq_roles"

parameters="\
ParameterKey=uniqueString,ParameterValue=myUniqStr \
ParameterKey=bigIqSecretArn,ParameterValue=$bigiq_secret_arn \
ParameterKey=secretArn,ParameterValue=$secret_arn \
ParameterKey=createBigIqRoles,ParameterValue=$create_bigiq_roles \
ParameterKey=createAmiRole,ParameterValue=<CREATE AMI ROLE> \
ParameterKey=s3Bucket,ParameterValue=<S3 BUCKET> \
ParameterKey=solutionType,ParameterValue=<ACCESS SOLUTION TYPE>"
echo "Parameters:$parameters"

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <ACCESS STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/"$artifact_location"modules/access/<ACCESS TEMPLATE NAME>.yaml \
--capabilities CAPABILITY_IAM --parameters $parameters
