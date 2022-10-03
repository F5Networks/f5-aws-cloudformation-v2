#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

curl <TEMPLATE URL> -o <DEWPOINT JOB ID>-template.yaml
artifact_location=$(cat <DEWPOINT JOB ID>-template.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "using default bucket region:$region"
fi

if echo "<TEMPLATE URL>" | grep -q "existing-network"; then
    echo "Setting existing stack variables"
    mgmtAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
    extAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    intAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 3)
    mgmtAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 2)
    extAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 1)
    intAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 3)
    vpcId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="vpcId").OutputValue')
fi

# Here we use a static secret that matches the default in the runtime init config
# The secret is replicated to the US regions and Canada central
secret_arn="arn:aws:secretsmanager:<REGION>:089591600128:secret:mySecretId-n0PHSR"

# upload to s3
aws s3 cp --region <REGION> <DEWPOINT JOB ID>-template.yaml s3://"$bucket_name"/<DEWPOINT JOB ID>-template.yaml --acl public-read

# create parameters
parameters="ParameterKey=allowUsageAnalytics,ParameterValue=false \
ParameterKey=restrictedSrcAddressMgmt,ParameterValue=$src_ip \
ParameterKey=restrictedSrcAddressApp,ParameterValue=$src_ip \
ParameterKey=cloudWatchLogGroupName,ParameterValue=<UNIQUESTRING>-f5telemetry \
ParameterKey=cloudWatchDashboardName,ParameterValue=<UNIQUESTRING>-F5-BIGIP-WAF-View \
ParameterKey=notificationEmail,ParameterValue=<NOTIFICATION EMAIL> \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
ParameterKey=sshKey,ParameterValue=<SSH KEY> \
ParameterKey=bigIpSecretArn,ParameterValue=$secret_arn"

if echo "<TEMPLATE URL>" | grep -q "existing-network"; then
    echo "Adding existing stack parameters"
    parameters+=" ParameterKey=bigIpSubnetAz1,ParameterValue=$mgmtAz1 \
    ParameterKey=bigIpSubnetAz2,ParameterValue=$mgmtAz2 \
    ParameterKey=externalSubnetAz1,ParameterValue=$extAz1 \
    ParameterKey=externalSubnetAz2,ParameterValue=$extAz2 \
    ParameterKey=internalSubnetAz1,ParameterValue=$extAz1 \
    ParameterKey=internalSubnetAz2,ParameterValue=$extAz2 \
    ParameterKey=vpcId,ParameterValue=$vpcId"
fi
echo "Parameters:$parameters"

# create stack
aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<DEWPOINT JOB ID>-template.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameters $parameters
