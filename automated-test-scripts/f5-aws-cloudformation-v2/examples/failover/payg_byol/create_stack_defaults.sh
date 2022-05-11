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

secret_name=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .Name)
secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "using default bucket region:$region"
fi

runtimeConfig01='"<RUNTIME INIT CONFIG 01>"'
runtimeConfig02='"<RUNTIME INIT CONFIG 02>"'

if [[ "<PROVISION EXAMPLE APP>" == "false" ]]; then
    declare -a runtime_init_config_files=(/$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance01.yaml /$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance02.yaml)
else
    declare -a runtime_init_config_files=(/$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance01-with-app.yaml /$PWD/examples/failover/bigip-configurations/runtime-init-conf-3nic-payg-instance02-with-app.yaml)
fi
counter=1
for config_name in "${runtime_init_config_files[@]}"; do

    # Download and modify runtime-init, then upload to s3.
    curl https://f5-cft-v2.s3.amazonaws.com/${artifact_location}failover/bigip-configurations/$config_name -o <DEWPOINT JOB ID>-config.yaml

    # Create user for tests that connect to the REST API
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>-config.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"{{{BIGIP_PASSWORD}}}\"" -i <DEWPOINT JOB ID>-config.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>-config.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>-config.yaml

    # Disable AutoPhoneHome
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.My_System.autoPhonehome = false" -i <DEWPOINT JOB ID>-0$counter.yaml

    # Runtime parameters
    /usr/bin/yq e ".runtime_parameters += {\"name\":\"BIGIP_PASSWORD\"}" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".runtime_parameters.[4].type = \"secret\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".runtime_parameters.[4].secretProvider.environment = \"aws\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".runtime_parameters.[4].secretProvider.secretId = \"$secret_name\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".runtime_parameters.[4].secretProvider.type = \"SecretsManager\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".runtime_parameters.[4].secretProvider.version = \"AWSCURRENT\"" -i <DEWPOINT JOB ID>-0$counter.yaml

    # print out config file
    /usr/bin/yq e <DEWPOINT JOB ID>-config.yaml

    # upload to s3
    aws s3 cp --region <REGION> <DEWPOINT JOB ID>-template.yaml s3://"$bucket_name"/<DEWPOINT JOB ID>-template.yaml --acl public-read
    aws s3 cp --region <REGION> <DEWPOINT JOB ID>-config.yaml s3://"$bucket_name"/<DEWPOINT JOB ID>-config.yaml --acl public-read

    ((counter=counter+1))
done

    # create stack
    aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
    --template-url <TEMPLATE S3 URL> \
    --capabilities CAPABILITY_IAM \
    --parameters ParameterKey=bigIpRuntimeInitConfig01,ParameterValue=$runtimeConfig01 \
    ParameterKey=bigIpRuntimeInitConfig02,ParameterValue=$runtimeConfig02 \
    ParameterKey=restrictedSrcAddressMgmt,ParameterValue=$src_ip \
    ParameterKey=restrictedSrcAddressApp,ParameterValue=$src_ip \
    ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
    ParameterKey=sshKey,ParameterValue=<SSH KEY>