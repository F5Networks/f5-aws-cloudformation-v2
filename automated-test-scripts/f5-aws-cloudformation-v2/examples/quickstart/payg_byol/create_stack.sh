#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"
region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

if [ -z $region ] || [ $region == null ]; then
    region="us-east-1"
    echo "bucket region:$region"
else
    echo "bucket region:$region"
fi

runtimeConfig='<RUNTIME INIT CONFIG>'

if [[ '<RUNTIME INIT CONFIG>' == *{* ]]; then
    runtimeConfig=$runtimeConfig
else
    runtimeConfig="${runtimeConfig/<ARTIFACT LOCATION>/$artifact_location}"
fi
echo "RUNTIME CONFIG:$runtimeConfig"

# Set Parameters using file to eiliminate issues when passing spaces in parameter values
cat <<EOF > parameters.json
[
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
        "ParameterKey": "bigIpRuntimeInitConfig",
        "ParameterValue": "$runtimeConfig"
    },
    {
        "ParameterKey": "bigIpRuntimeInitPackageUrl",
        "ParameterValue": "<BIGIP RUNTIME INIT PACKAGEURL>"
    },
    { 
        "ParameterKey": "customImageId",
        "ParameterValue": "<CUSTOM IMAGE>"
    },
    { 
        "ParameterKey": "imageName",
        "ParameterValue": "<BIGIP IMAGE NAME>"
    },
    { 
        "ParameterKey": "instanceType",
        "ParameterValue": "<BIGIP INSTANCE TYPE>"
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
        "ParameterKey": "sshKey",
        "ParameterValue": "<SSH KEY>"
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
--capabilities CAPABILITY_IAM \
--parameters file://parameters.json
