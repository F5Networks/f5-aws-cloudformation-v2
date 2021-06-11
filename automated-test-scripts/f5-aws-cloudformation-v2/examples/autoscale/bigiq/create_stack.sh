#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/autoscale/<LICENSE TYPE>/autoscale.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

runtimeConfig='"<RUNTIME INIT CONFIG>"'
secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
secret_name=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .Name)
bigiq_address=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME>-bigiq | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="device1ManagementEipAddress")|.OutputValue')

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
    cp /$PWD/examples/autoscale/bigip-configurations/runtime-init-conf-bigiq.yaml <DEWPOINT JOB ID>.yaml

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

    # WAF policy settings
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTPS_Service.WAFPolicy.enforcementMode = \"transparent\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTP_Service.WAFPolicy.enforcementMode = \"transparent\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTPS_Service.WAFPolicy.url = \"https://<STACK NAME>.s3.<REGION>.amazonaws.com/examples/autoscale/bigip-configurations/Rapid_Depolyment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTP_Service.WAFPolicy.url = \"https://<STACK NAME>.s3.<REGION>.amazonaws.com/examples/autoscale/bigip-configurations/Rapid_Depolyment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml

    # Telemetry settings
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_Metrics_Namespace.My_Cloudwatch_Metrics.metricNamespace = \"<METRIC NAME SPACE>\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_Remote_Logs_Namespace.My_Cloudwatch_Logs.logGroup = \"<UNIQUESTRING>-<CLOUDWATCH LOG GROUP NAME>\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_Remote_Logs_Namespace.My_Cloudwatch_Logs.logStream = \"<UNIQUESTRING>-<CLOUDWATCH LOG STREAM NAME>\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.class = \"Telemetry_Consumer\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.type = \"AWS_S3\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.region = \"{{{REGION}}}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.bucket = \"{{{BUCKET_NAME}}}\"" -i <DEWPOINT JOB ID>.yaml

    # Runtime parameters
    /usr/bin/yq e ".runtime_parameters.[2].secretProvider.secretId = \"$secret_name\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters += {\"name\":\"BUCKET_NAME\"}" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[3].type = \"static\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[3].value = \"$logging_bucket_name\"" -i <DEWPOINT JOB ID>.yaml

    # print out config file
    /usr/bin/yq e <DEWPOINT JOB ID>.yaml

    # update copy
    cp <DEWPOINT JOB ID>.yaml update_<DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTPS_Service.WAFPolicy.enforcementMode = \"blocking\"" -i update_<DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.HTTP_Service.WAFPolicy.enforcementMode = \"blocking\"" -i update_<DEWPOINT JOB ID>.yaml

    # upload to s3
    aws s3 cp --region <REGION> /$PWD/examples/autoscale/bigip-configurations/Rapid_Depolyment_Policy_13_1.xml s3://"$bucket_name"/examples/autoscale/bigip-configurations/Rapid_Depolyment_Policy_13_1.xml --acl public-read
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
        "ParameterKey": "application",
        "ParameterValue": "f5-app-<DEWPOINT JOB ID>"
    },
    {
        "ParameterKey": "appScalingMaxSize",
        "ParameterValue": "<APP SCALE MAX SIZE>"
    },
    {
        "ParameterKey": "appScalingMinSize",
        "ParameterValue": "<APP SCALE MIN SIZE>"
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
        "ParameterKey": "bigIpRuntimeInitPackageUrl",
        "ParameterValue": "<BIGIP RUNTIME INIT PACKAGEURL>"
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
        "ParameterKey": "bigIqAddress",
        "ParameterValue": "$bigiq_address"
    },
    {
        "ParameterKey": "bigIqAddressType",
        "ParameterValue": "public"
    },
    {
        "ParameterKey": "bigIqLicensePool",
        "ParameterValue": "production"
    },
    {
        "ParameterKey": "bigIqSecretArn",
        "ParameterValue": "$secret_arn"
    },
    {
        "ParameterKey": "bigIqTenant",
        "ParameterValue": "myTenant"
    },
    {
        "ParameterKey": "bigIqUsername",
        "ParameterValue": "admin"
    },
    {
        "ParameterKey": "bigIqUtilitySku",
        "ParameterValue": "F5-BIG-MSP-BT-1G"
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
        "ParameterKey": "vpcCidr",
        "ParameterValue": "<CIDR>"
    }
]
EOF

cat parameters.json

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_IAM \
--parameters file://parameters.json
