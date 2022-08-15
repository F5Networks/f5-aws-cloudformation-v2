#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/autoscale/<LICENSE TYPE>/autoscale.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

runtimeConfig='"<RUNTIME INIT CONFIG>"'
secret_name=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .Name)
secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)

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
    config_with_added_secret_id="${runtimeConfig/<SECRET_ID>/$secret_name}"
    config_with_added_ids="${config_with_added_secret_id/<BUCKET_ID>/$bucket_name}"
    runtimeConfig=$config_with_added_ids
    runtimeConfig="${runtimeConfig/<ARTIFACT LOCATION>/$artifact_location}"
else
    # Modify Runtime-init, then upload to s3.
    cp /$PWD/examples/autoscale/bigip-configurations/runtime-init-conf-payg-with-app.yaml <DEWPOINT JOB ID>.yaml

    # Create user for login tests
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"{{{BIGIP_PASSWORD}}}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>.yaml

    # Disable AutoPhoneHome
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>.yaml

    # WAF policy settings
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.enforcementMode = \"transparent\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://<STACK NAME>.s3.<REGION>.amazonaws.com/examples/autoscale/bigip-configurations/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml

    # Telemetry settings
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.class = \"Telemetry_Consumer\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.type = \"AWS_S3\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.region = \"{{{REGION}}}\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[2].value.My_S3.bucket = \"{{{BUCKET_NAME}}}\"" -i <DEWPOINT JOB ID>.yaml

    # Runtime parameters
    /usr/bin/yq e ".runtime_parameters += {\"name\":\"BIGIP_PASSWORD\"}" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].type = \"secret\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].secretProvider.environment = \"aws\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].secretProvider.secretId = \"$secret_name\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].secretProvider.type = \"SecretsManager\"" -i <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".runtime_parameters.[-1].secretProvider.version = \"AWSCURRENT\"" -i <DEWPOINT JOB ID>.yaml
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
        "ParameterKey": "bastionScalingMaxSize",
        "ParameterValue": "<BASTION SCALE MAX SIZE>"
    },
    {
        "ParameterKey": "bastionScalingMinSize",
        "ParameterValue": "<BASTION SCALE MIN SIZE>"
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
--capabilities CAPABILITY_NAMED_IAM \
--parameters file://parameters.json
