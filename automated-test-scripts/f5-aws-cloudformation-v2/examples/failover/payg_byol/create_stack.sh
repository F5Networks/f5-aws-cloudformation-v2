#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/failover/failover.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

private_key=''
if [[ "<CREATE NEW KEY PAIR>" == 'false' ]]; then
    private_key='<SSH KEY>'
fi
echo "Private key: ${private_key}"

secret_arn=''
if [[ "<CREATE NEW SECRET>" == 'false' ]]; then
    secret_name=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .Name)
    secret_arn=$(aws secretsmanager describe-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .ARN)
    echo "Secret name: ${secret_name}"
    echo "Secret arn: ${secret_arn}"
fi

runtimeConfig01='"<RUNTIME INIT CONFIG 01>"'
runtimeConfig02='"<RUNTIME INIT CONFIG 02>"'
region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "bucket region:$region"
else
    echo "bucket region:$region"
fi

regKey01=''
regKey02=''
if [[ "<LICENSE TYPE>" == "byol" ]]; then
    regKey01='<AUTOFILL EVAL LICENSE KEY>'
    regKey02='<AUTOFILL EVAL LICENSE KEY 2>'
fi

do_index=2
if [[ "<PROVISION EXAMPLE APP>" == "true" ]]; then
    do_index=3
fi

if [[ "<PROVISION EXAMPLE APP>" == "false" ]]; then
    declare -a runtime_init_config_files=(/$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NUMBER NICS>nic-<LICENSE TYPE>-instance01.yaml /$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NUMBER NICS>nic-<LICENSE TYPE>-instance02.yaml)
else
    declare -a runtime_init_config_files=(/$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NUMBER NICS>nic-<LICENSE TYPE>-instance01-with-app.yaml /$PWD/examples/failover/bigip-configurations/runtime-init-conf-<NUMBER NICS>nic-<LICENSE TYPE>-instance02-with-app.yaml)
fi
counter=1
for config_path in "${runtime_init_config_files[@]}"; do
    # Modify Runtime-init, then upload to s3.
    cp -avr $config_path <DEWPOINT JOB ID>-0$counter.yaml

    # Create user for login tests
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.password = \"{{{BIGIP_PASSWORD}}}\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[0].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>-0$counter.yaml

    /usr/bin/yq e ".extension_services.service_operations.[${do_index}].value.Common.admin.class = \"User\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[${do_index}].value.Common.admin.password = \"{{{BIGIP_PASSWORD}}}\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[${do_index}].value.Common.admin.shell = \"bash\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[${do_index}].value.Common.admin.userType = \"regular\"" -i <DEWPOINT JOB ID>-0$counter.yaml

    # Update CFE tag
    /usr/bin/yq e ".extension_services.service_operations.[1].value.externalStorage.scopingTags.f5_cloud_failover_label = \"<DEWPOINT JOB ID>\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.failoverAddresses.scopingTags.f5_cloud_failover_label = \"<DEWPOINT JOB ID>\"" -i <DEWPOINT JOB ID>-0$counter.yaml

    # Update WAF policy URL
    if [[ "<PROVISION EXAMPLE APP>" == "true" ]]; then
        /usr/bin/yq e ".extension_services.service_operations.[2].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://cdn.f5.com/product/cloudsolutions/solution-scripts/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>-0$counter.yaml
    fi

    # print out config file
    /usr/bin/yq e <DEWPOINT JOB ID>-0$counter.yaml

    # update copy
    cp <DEWPOINT JOB ID>-0$counter.yaml update_<DEWPOINT JOB ID>-0$counter.yaml

    # upload to s3
    aws s3 cp --region <REGION> update_<DEWPOINT JOB ID>-0$counter.yaml s3://"$bucket_name"/examples/failover/bigip-configurations/update_<DEWPOINT JOB ID>-0$counter.yaml --acl public-read
    aws s3 cp --region <REGION> <DEWPOINT JOB ID>-0$counter.yaml s3://"$bucket_name"/examples/failover/bigip-configurations/<DEWPOINT JOB ID>-0$counter.yaml --acl public-read

    ((counter=counter+1))
done

# Set Parameters using file to eiliminate issues when passing spaces in parameter values
cat <<EOF > parameters.json
[
    {
        "ParameterKey": "artifactLocation",
        "ParameterValue": "$artifact_location"
    },
    {
        "ParameterKey": "allowUsageAnalytics",
        "ParameterValue": "false"
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
        "ParameterKey": "bigIpLicenseKey01",
        "ParameterValue": "$regKey01"
    },
    {
        "ParameterKey": "bigIpLicenseKey02",
        "ParameterValue": "$regKey02"
    },
    {
        "ParameterKey": "bigIpRuntimeInitConfig01",
        "ParameterValue": $runtimeConfig01
    },
    {
        "ParameterKey": "bigIpRuntimeInitConfig02",
        "ParameterValue": $runtimeConfig02
    },
    {
        "ParameterKey": "bigIpPeerAddr",
        "ParameterValue": "<BIGIP PEER ADDR>"
    },
    {
        "ParameterKey": "numAzs",
        "ParameterValue": "<NUMBER AZS>"
    },
    {
        "ParameterKey": "numNics",
        "ParameterValue": "<NUMBER NICS>"
    },
    {
        "ParameterKey": "numSubnets",
        "ParameterValue": "<NUMBER SUBNETS>"
    },
    {
        "ParameterKey": "provisionPublicIpMgmt",
        "ParameterValue": "<PROVISION MGMT PUBLIC IP>"
    },
    {
        "ParameterKey": "provisionExampleApp",
        "ParameterValue": "<PROVISION EXAMPLE APP>"
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
        "ParameterKey": "cfeS3Bucket",
        "ParameterValue": "bigip-ha-solution-<DEWPOINT JOB ID>"
    },
    {
        "ParameterKey": "cfeTag",
        "ParameterValue": "<DEWPOINT JOB ID>"
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
        "ParameterKey": "sshKey",
        "ParameterValue": "$private_key"
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
EOF
if [[ "<PROVISION EXAMPLE APP>" == "false" ]]; then
cat <<EOF >> parameters.json
    },
    {
        "ParameterKey": "bigIpExternalSelfIp01",
        "ParameterValue": "10.0.3.11"
    },
    {
        "ParameterKey": "bigIpExternalVip01",
        "ParameterValue": "10.0.3.101"
    },
    {
        "ParameterKey": "bigIpExternalSelfIp02",
        "ParameterValue": "10.0.7.11"
    },
    {
        "ParameterKey": "bigIpExternalVip02",
        "ParameterValue": "10.0.7.101"
    },
    {
        "ParameterKey": "bigIpInternalSelfIp02",
        "ParameterValue": "10.0.6.11"
    },
    {
        "ParameterKey": "bigIpMgmtAddress02",
        "ParameterValue": "10.0.5.11"
    }
]
EOF
else
cat <<EOF >> parameters.json
    }
]
EOF
fi
cat parameters.json

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_NAMED_IAM \
--parameters file://parameters.json
