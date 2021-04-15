#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

runtimeConfig='"<UPDATE CONFIG>"'
secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
secret_name=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .Name)
bigiq_address=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME>-bigiq | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="device1ManagementEipAddress")|.OutputValue')

if [[ "<UPDATE CONFIG>" == *{* ]]; then
    config_with_added_address="${runtimeConfig//<BIGIQ ADDRESS>/$bigiq_address}"
    config_with_added_secret_id="${config_with_added_address//<SECRET_ID>/$secret_name}"
    config_with_all_replaced_values="${config_with_added_secret_id//<BUCKET_ID>/$bucket_name}"
    runtimeConfig=$config_with_all_replaced_values
fi

echo "Runtime Init Config: $runtimeConfig"

region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "bucket region:$region"
else
    echo "bucket region:$region"
fi

# Set Parameters using file to eiliminate issues when passing spaces in parameter values
cat <<EOF > parameters.json
[
    { 
        "ParameterKey": "application",
        "ParameterValue": "f5-app-<DEWPOINT JOB ID>"
    },
    { 
        "ParameterKey": "bigIpRuntimeInitConfig",
        "ParameterValue": $runtimeConfig
    },
    {
        "ParameterKey": "bigIqAddress",
        "ParameterValue": "$bigiq_address"
    },
    {   "ParameterKey": "bigIqAddressType",
        "ParameterValue": "public"
    },
    {   "ParameterKey": "bigIqLicensePool",
        "ParameterValue": "production"
    },
    {   "ParameterKey": "bigIqSecretArn",
        "ParameterValue": "$secret_arn"
    },
    {   "ParameterKey": "bigIqTenant",
        "ParameterValue": "myTenant"
    },
    {   
        "ParameterKey": "bigIqUsername",
        "ParameterValue": "admin"
    },
    {   "ParameterKey": "bigIqUtilitySku",
        "ParameterValue": "F5-BIG-MSP-BT-1G"
    },
    { 
        "ParameterKey": "customImageId",
        "ParameterValue": "<CUSTOM IMAGE ID>"
    },
    { 
        "ParameterKey": "imageName",
        "ParameterValue": "<BIGIP IMAGE NAME>"
    },
    { 
        "ParameterKey": "instanceType",
        "ParameterValue": "<BIGIP INSTANCE TYPE>"
    },
    {   "ParameterKey": "lambdaS3BucketName",
        "ParameterValue": "f5-aws-bigiq-revoke"
    },
    {   "ParameterKey": "lambdaS3Key",
        "ParameterValue": "develop/"
    },
    { 
        "ParameterKey": "metricNameSpace",
        "ParameterValue": "<METRIC NAME SPACE>"
    },
    { 
        "ParameterKey": "notificationEmail",
        "ParameterValue": "<NOTIFICATION EMAIL>"
    },
    { 
        "ParameterKey": "numAzs",
        "ParameterValue": "<NUMBER AZS>"
    },
    { 
        "ParameterKey": "numSubnets",
        "ParameterValue": "<NUMBER SUBNETS>"
    },
    { 
        "ParameterKey": "provisionExternalBigipLoadBalancer",
        "ParameterValue": "<PROVISION EXTERNAL LB>"
    },
    { 
        "ParameterKey": "provisionInternalBigipLoadBalancer",
        "ParameterValue": "<PROVISION INTERNAL LB>"
    },
    { 
        "ParameterKey": "provisionPublicIp",
        "ParameterValue": "<PROVISION PUBLIC IP>"
    },
    { 
        "ParameterKey": "restrictedSrcAddressApp",
        "ParameterValue": "0.0.0.0/0"
    },
    { 
        "ParameterKey": "restrictedSrcAddressMgmt",
        "ParameterValue": "0.0.0.0/0"
    },
    { 
        "ParameterKey": "s3BucketName",
        "ParameterValue": "$bucket_name"
    },
    { 
        "ParameterKey": "s3BucketRegion",
        "ParameterValue": "$region"
    },
    { 
        "ParameterKey": "loggingS3BucketName",
        "ParameterValue": "$bucket_name"
    },
    { 
        "ParameterKey": "secretArn",
        "ParameterValue": "$secret_arn"
    },
    { 
        "ParameterKey": "setPublicSubnet1",
        "ParameterValue": "<SUBNET1 PUBLIC>"
    },
    { 
        "ParameterKey": "snsEvents",
        "ParameterValue": "<SNS EVENTS>"
    },
    { 
        "ParameterKey": "sshKey",
        "ParameterValue": "<SSH KEY>"
    },
    { 
        "ParameterKey": "subnetMask",
        "ParameterValue": "<SUBNETMASK>"
    },
    { 
        "ParameterKey": "uniqueString",
        "ParameterValue": "<UNIQUESTRING>"
    },
    {
        "ParameterKey": "bigIpRuntimeInitPackageUrl",
        "ParameterValue": "<BIGIP RUNTIME INIT PACKAGEURL>"
    },
    { 
        "ParameterKey": "vpcCidr",
        "ParameterValue": "<CIDR>"
    }
]
EOF

cat parameters.json

aws cloudformation update-stack --use-previous-template --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--capabilities CAPABILITY_IAM \
--parameters file://parameters.json
