#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


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

runtimeConfig='"<RUNTIME INIT CONFIG>"'

# Download and modify runtime-init, then upload to s3.
curl https://f5-cft-v2.s3.amazonaws.com/${artifact_location}autoscale/bigip-configurations/runtime-init-conf-payg_with_app.yaml -o <DEWPOINT JOB ID>-config.yaml

# Create user for tests that connect to the REST API
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>-config.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"<SECRET VALUE>\"" -i <DEWPOINT JOB ID>-config.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>-config.yaml
/usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>-config.yaml

# Telemetry settings (uncomment when telmetry module is released)
# these names must be unique to avoid conflicts when using default values
# /usr/bin/yq e ".extension_services.service_operations.[2].value.My_Metrics_Namespace.My_Cloudwatch_Metrics.metricNamespace = \"<METRIC NAME SPACE>\"" -i <DEWPOINT JOB ID>-config.yaml
# /usr/bin/yq e ".extension_services.service_operations.[2].value.My_Remote_Logs_Namespace.My_Cloudwatch_Logs.logGroup = \"<UNIQUESTRING>-f5telemetry\"" -i <DEWPOINT JOB ID>-config.yaml
# /usr/bin/yq e ".extension_services.service_operations.[2].value.My_Remote_Logs_Namespace.My_Cloudwatch_Logs.logStream = \"<UNIQUESTRING>-f5-waf-logs\"" -i <DEWPOINT JOB ID>-config.yaml

# print out config file
/usr/bin/yq e <DEWPOINT JOB ID>-config.yaml

# upload to s3
aws s3 cp --region <REGION> <DEWPOINT JOB ID>-template.yaml s3://"$bucket_name"/<DEWPOINT JOB ID>-template.yaml --acl public-read
aws s3 cp --region <REGION> <DEWPOINT JOB ID>-config.yaml s3://"$bucket_name"/<DEWPOINT JOB ID>-config.yaml --acl public-read

# create stack
aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url <TEMPLATE S3 URL> \
--capabilities CAPABILITY_IAM \
--parameters ParameterKey=notificationEmail,ParameterValue=<NOTIFICATION EMAIL> \
ParameterKey=bigIpRuntimeInitConfig,ParameterValue=$runtimeConfig \
ParameterKey=restrictedSrcAddressMgmt,ParameterValue=<RESTRICTED SRC> \
ParameterKey=restrictedSrcAddressApp,ParameterValue=<RESTRICTED SRC> \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
ParameterKey=sshKey,ParameterValue=<SSH KEY>
