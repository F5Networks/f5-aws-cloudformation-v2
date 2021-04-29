#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

lambda_access_role=''
copy_zips_role=''
security_group_id=''
subnet_id=''

if [[ <CREATE REVOKE FUNCTION> == 'true' ]]; then
    revoke_lambda_access_role=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="lambdaAccessRole").OutputValue' | cut -d ',' -f 1)
    copy_zips_role=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="copyZipsRole").OutputValue' | cut -d ',' -f 1)
    bigiq_secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)

    if [[ <BIGIQ ADDRESS TYPE> == 'private' ]]; then
        security_group_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpExternalSecurityGroup").OutputValue' | cut -d ',' -f 1)
        subnet_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    fi
    revoke_parameters="\
    ParameterKey=bigIqAddress,ParameterValue=<BIGIQ ADDRESS> \
    ParameterKey=bigIqAddressType,ParameterValue=<BIGIQ ADDRESS TYPE> \
    ParameterKey=bigIqLicensePool,ParameterValue=<BIGIQ LICENSE POOL> \
    ParameterKey=bigIqSecretArn,ParameterValue=$bigiq_secret_arn \
    ParameterKey=bigIqSubnetId,ParameterValue=$subnet_id \
    ParameterKey=bigIqTenant,ParameterValue=<TENANT> \
    ParameterKey=bigIqUsername,ParameterValue=admin \
    ParameterKey=bigIqSecurityGroupId,ParameterValue=$security_group_id \
    ParameterKey=copyZipsRole,ParameterValue=$copy_zips_role \
    ParameterKey=createRevokeFunction,ParameterValue=<CREATE REVOKE FUNCTION> \
    ParameterKey=lambdaAccessRole,ParameterValue=$revoke_lambda_access_role \
    ParameterKey=lambdaS3BucketName,ParameterValue=f5-aws-bigiq-revoke \
    ParameterKey=lambdaS3Key,ParameterValue=develop/"
fi
if [[ <CREATE AMI LOOKUP FUNCTION> == 'true' ]]; then
    ami_lambda_access_role=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="lambdaAmiExecutionRole").OutputValue' | cut -d ',' -f 1)
    
    ami_parameters="\
    ParameterKey=createAmiLookupFunction,ParameterValue=<CREATE AMI LOOKUP FUNCTION> \
    ParameterKey=amiLookupRole,ParameterValue=$ami_lambda_access_role"
fi

echo "Parameters:$revoke_parameters $ami_parameters"


aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_IAM --parameters $revoke_parameters $ami_parameters
