#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"
region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

private_key=''
if [[ "<CREATE NEW KEY PAIR>" == 'false' ]]; then
    private_key='<SSH KEY>'
fi
echo "Private key: ${private_key}"

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "bucket region:$region"
else
    echo "bucket region:$region"
fi

# Replace LICENSE in case of BYOL
regKey=''
if [[ <LICENSE TYPE> == "byol" ]]; then
    regKey='<AUTOFILL EVAL LICENSE KEY>'
fi

runtimeConfig='<RUNTIME INIT CONFIG>'

if [[ '<RUNTIME INIT CONFIG>' == *{* ]]; then
    runtimeConfig=$runtimeConfig
else
    # Modify Runtime-init, then upload to s3.
    cp /$PWD/examples/quickstart/bigip-configurations/runtime-init-conf-<NIC COUNT>nic-<LICENSE TYPE>-with-app.yaml <DEWPOINT JOB ID>.yaml
    /usr/bin/yq e ".extension_services.service_operations.[1].value.Tenant_1.Shared.Custom_WAF_Policy.url = \"https://<STACK NAME>.s3.<REGION>.amazonaws.com/examples/quickstart/bigip-configurations/Rapid_Deployment_Policy_13_1.xml\"" -i <DEWPOINT JOB ID>.yaml

    # print out config file
    /usr/bin/yq e <DEWPOINT JOB ID>.yaml
    # upload to s3
    aws s3 cp --region <REGION> /$PWD/examples/quickstart/bigip-configurations/Rapid_Deployment_Policy_13_1.xml s3://"$bucket_name"/examples/quickstart/bigip-configurations/Rapid_Deployment_Policy_13_1.xml --acl public-read
    aws s3 cp --region <REGION> <DEWPOINT JOB ID>.yaml s3://"$bucket_name"/examples/quickstart/bigip-configurations/<DEWPOINT JOB ID>.yaml --acl public-read
fi
echo "RUNTIME CONFIG:$runtimeConfig"

# Set Parameters using file to eiliminate issues when passing spaces in parameter values
cat <<EOF > parameters.json
[
    {
        "ParameterKey": "allowUsageAnalytics",
        "ParameterValue": "false"
    },
    {
        "ParameterKey": "appContainerName",
        "ParameterValue": "<DOCKER IMAGE>"
    },
    {
        "ParameterKey": "application",
        "ParameterValue": "f5-app-<DEWPOINT JOB ID>"
    },
    {
        "ParameterKey": "artifactLocation",
        "ParameterValue": "$artifact_location"
    },
    {
        "ParameterKey": "bigIpCustomImageId",
        "ParameterValue": "<CUSTOM IMAGE>"
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
        "ParameterKey": "bigIpLicenseKey",
        "ParameterValue": "$regKey"
    },
    {
        "ParameterKey": "bigIpRuntimeInitConfig",
        "ParameterValue": "$runtimeConfig"
    },
    {
        "ParameterKey": "licenseType",
        "ParameterValue": "<LICENSE TYPE>"
    },
    {
        "ParameterKey": "numNics",
        "ParameterValue": "<NIC COUNT>"
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
        "ParameterValue": ""
    },
    {
        "ParameterKey": "provisionSecret",
        "ParameterValue": "<CREATE NEW SECRET>"
    },
    {
        "ParameterKey": "sshKey",
        "ParameterValue": "$private_key"
    },
    {
        "ParameterKey": "throughput",
        "ParameterValue": "<THROUGHPUT>"
    },
    {
        "ParameterKey": "uniqueString",
        "ParameterValue": "<UNIQUESTRING>"
    },
    {
        "ParameterKey": "version",
        "ParameterValue": "<VERSION>"
    }
]
EOF

cat parameters.json | jq .

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_NAMED_IAM \
--parameters file://parameters.json