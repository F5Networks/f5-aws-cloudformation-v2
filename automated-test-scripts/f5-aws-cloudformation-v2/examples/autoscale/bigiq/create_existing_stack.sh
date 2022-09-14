#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


TMP_DIR='/tmp/<DEWPOINT JOB ID>'
src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/autoscale/<LICENSE TYPE>/autoscale.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

mgmtAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
extAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
intAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 3)
mgmtAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 2)
extAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 1)
intAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 3)
vpcId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="vpcId").OutputValue')

runtimeConfig='"<RUNTIME INIT CONFIG>"'
secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
secret_name=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .Name)

bigiq_stack_name=<STACK NAME>-bigiq
bigiq_stack_region=<REGION>
bigiq_address=''
if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
    echo "Found existing BIG-IQ"
    cat ${TMP_DIR}/bigiq_info.json
    bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
    bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
    bigiq_address=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_address)
    bigiq_password=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_password)
fi

region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "bucket region:$region"
else
    echo "bucket region:$region"
fi

# create a new bucket if deploying telemetry, otherwise pass existing bucket
if [[ <CREATE LOG DESTINATION> == "true" ]]; then
    logging_bucket_name="<DEWPOINT JOB ID>-logging-s3"
else
    logging_bucket_name=$bucket_name
fi

if [[ "<RUNTIME INIT CONFIG>" == *{* ]]; then
    config_with_added_address="${runtimeConfig//<BIGIQ ADDRESS>/$bigiq_address}"
    config_with_added_secret_id="${config_with_added_address//<SECRET_ID>/$secret_name}"
    config_with_all_replaced_values="${config_with_added_secret_id//<BUCKET_ID>/$bucket_name}"
    runtimeConfig=$config_with_all_replaced_values
    runtimeConfig="${runtimeConfig/<ARTIFACT LOCATION>/$artifact_location}"
else
    # Modify Runtime-init, then upload to s3.
    cp /$PWD/examples/autoscale/bigip-configurations/runtime-init-conf-bigiq-with-app.yaml <DEWPOINT JOB ID>.yaml

    # Create user for login tests
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"{{{BIGIQ_PASSWORD}}}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>.yaml

    # BIG-IQ license settings
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.bigIpPassword = \"{{{BIGIQ_PASSWORD}}}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.bigIpUsername = \"admin\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.bigIqHost = \"$bigiq_address\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.licensePool = \"production\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.overwrite = \"false\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_License.tenant = \"<DEWPOINT JOB ID>\"" -i <DEWPOINT JOB ID>.yaml

    # WAF policy settings
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.enforcementMode = \"transparent\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://<STACK NAME>.s3.<REGION>.amazonaws.com/examples/autoscale/bigip-configurations/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml

    # Telemetry settings
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.class = \"Telemetry_Consumer\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.type = \"AWS_S3\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.region = \"{{{REGION}}}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.bucket = \"{{{BUCKET_NAME}}}\"" -i <DEWPOINT JOB ID>.yaml

    # Runtime parameters
    /usr/bin/yq e ".runtime_parameters += {\"name\":\"BUCKET_NAME\"}" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].type = \"static\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].value = \"$logging_bucket_name\"" -i <DEWPOINT JOB ID>.yaml

    # print out config file
    /usr/bin/yq e <DEWPOINT JOB ID>.yaml

    # update copy
    cp <DEWPOINT JOB ID>.yaml update_<DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.enforcementMode = \"blocking\"" -i update_<DEWPOINT JOB ID>.yaml

    # upload to s3
    aws s3 cp --region <REGION> /$PWD/examples/autoscale/bigip-configurations/Rapid_Deployment_Policy_13_1.xml s3://"$bucket_name"/examples/autoscale/bigip-configurations/Rapid_Deployment_Policy_13_1.xml --acl public-read
    aws s3 cp --region <REGION> update_<DEWPOINT JOB ID>.yaml s3://"$bucket_name"/examples/autoscale/bigip-configurations/update_<DEWPOINT JOB ID>.yaml --acl public-read
    aws s3 cp --region <REGION> <DEWPOINT JOB ID>.yaml s3://"$bucket_name"/examples/autoscale/bigip-configurations/<DEWPOINT JOB ID>.yaml --acl public-read
fi
echo "Runtime Init Config: $runtimeConfig"

# Set Parameters using file to eiliminate issues when passing spaces in parameter values
cat <<EOF > parameters.json
[
    {
        "ParameterKey": "artifactLocation",
        "ParameterValue": "$artifact_location"
    },
    {
        "ParameterKey": "allowUsageAnalytics",
        "ParameterValue": "No"
    },
    {
        "ParameterKey": "application",
        "ParameterValue": "f5-app-<DEWPOINT JOB ID>"
    },
    {
        "ParameterKey": "bigIpCustomImageId",
        "ParameterValue": "<CUSTOM IMAGE ID>"
    },
    {
        "ParameterKey": "bigIpImage",
        "ParameterValue": "<BIGIP IMAGE>"
    },
    {
        "ParameterKey": "bigIpInstanceType",
        "ParameterValue": "<BIGIP INSTANCE TYPE>"
    },
    {
        "ParameterKey": "bigIpRuntimeInitConfig",
        "ParameterValue": $runtimeConfig
    },
    {
        "ParameterKey": "bigIpScaleInCpuThreshold",
        "ParameterValue": "<LOW CPU THRESHOLD>"
    },
    {
        "ParameterKey": "bigIpScaleInThroughputThreshold",
        "ParameterValue": "<SCALE DOWN BYTES THRESHOLD>"
    },
    {
        "ParameterKey": "bigIpScaleOutCpuThreshold",
        "ParameterValue": "<HIGH CPU THRESHOLD>"
    },
    {
        "ParameterKey": "bigIpScaleOutThroughputThreshold",
        "ParameterValue": "<SCALE UP BYTES THRESHOLD>"
    },
    {
        "ParameterKey": "bigIqAddressType",
        "ParameterValue": "public"
    },
    {
        "ParameterKey": "bigIqSecretArn",
        "ParameterValue": "$secret_arn"
    },
    {
        "ParameterKey": "lambdaS3BucketName",
        "ParameterValue": "f5-aws-bigiq-revoke"
    },
    {
        "ParameterKey": "lambdaS3Key",
        "ParameterValue": "develop/"
    },
    {
        "ParameterKey": "cloudWatchLogGroupName",
        "ParameterValue": "<UNIQUESTRING>-<CLOUDWATCH LOG GROUP NAME>"
    },
    {
        "ParameterKey": "cloudWatchLogStreamName",
        "ParameterValue": "<UNIQUESTRING>-<CLOUDWATCH LOG STREAM NAME>"
    },
    {
        "ParameterKey": "cloudWatchDashboardName",
        "ParameterValue": "<UNIQUESTRING>-<CLOUDWATCH DASHBOARD NAME>"
    },
    {
        "ParameterKey": "createLogDestination",
        "ParameterValue": "<CREATE LOG DESTINATION>"
    },
    {
        "ParameterKey": "loggingS3BucketName",
        "ParameterValue": "$logging_bucket_name"
    },
    {
        "ParameterKey": "bigIpMaxBatchSize",
        "ParameterValue": "<UPDATE MAX BATCH SIZE>"
    },
    {
        "ParameterKey": "metricNameSpace",
        "ParameterValue": "<METRIC NAME SPACE>"
    },
    {
        "ParameterKey": "bigIpMinInstancesInService",
        "ParameterValue": "<UPDATE MIN INSTANCES>"
    },
    {
        "ParameterKey": "notificationEmail",
        "ParameterValue": "<NOTIFICATION EMAIL>"
    },
    {
        "ParameterKey": "bigIpPauseTime",
        "ParameterValue": "<UPDATE PAUSE TIME>"
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
        "ParameterValue": "$src_ip"
    },
    {
        "ParameterKey": "restrictedSrcAddressMgmt",
        "ParameterValue": "$src_ip"
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
        "ParameterKey": "bigIpSecretArn",
        "ParameterValue": "$secret_arn"
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
        "ParameterKey": "uniqueString",
        "ParameterValue": "<UNIQUESTRING>"
    },
    {
        "ParameterKey": "bigIpSubnetAz1",
        "ParameterValue": "$mgmtAz1"
    },
    {
        "ParameterKey": "bigIpSubnetAz2",
        "ParameterValue": "$mgmtAz2"
    },
    {
        "ParameterKey": "externalSubnetAz1",
        "ParameterValue": "$extAz1"
    },
    {
        "ParameterKey": "externalSubnetAz2",
        "ParameterValue": "$extAz2"
    },
    {
        "ParameterKey": "internalSubnetAz1",
        "ParameterValue": "$extAz1"
    },
    {
        "ParameterKey": "internalSubnetAz2",
        "ParameterValue": "$extAz2"
    },
    {
        "ParameterKey": "vpcId",
        "ParameterValue": "$vpcId"
    },
    {
        "ParameterKey": "vpcCidr",
        "ParameterValue": "<CIDR>"
    }
]
EOF

cat parameters.json

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_NAMED_IAM \
--parameters file://parameters.json
