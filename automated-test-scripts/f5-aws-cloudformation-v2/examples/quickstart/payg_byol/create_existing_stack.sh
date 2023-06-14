#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"
region=$(aws s3api get-bucket-location --bucket $bucket_name | jq -r .LocationConstraint)

artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

private_key=''
if [[ "<CREATE NEW KEY PAIR>" == 'false' ]]; then
    private_key='<SSH KEY>'
fi
echo "Private key: ${private_key}"

extAz=''
intAz=''
networkBorderGroup=''
vpcId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="vpcId").OutputValue')
mgmtAz=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)

case <NIC COUNT> in
1)
    echo "Deploying 1 NIC" ;;
2)
    extAz=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1) ;;
3)
    extAz=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    intAz=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 3) ;;
*)
    echo "Unrecognized number of NICs" ;;
esac

## for testing local zones (us-west-2 only)
# mgmtAz='subnet-039af0b70fbdb1064'
# extAz='subnet-07785c9c63a93a05a'
# intAz='subnet-005f3267acdf91721'
# vpcId='vpc-0ff232a8a13fcfa09'
# networkBorderGroup='us-west-2-phx-1'

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
        "ParameterKey": "bigIpExternalSubnetId",
        "ParameterValue": "$extAz"
    },
    {
        "ParameterKey": "bigIpInternalSubnetId",
        "ParameterValue": "$intAz"
    },
    {
        "ParameterKey": "bigIpMgmtSubnetId",
        "ParameterValue": "$mgmtAz"
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
        "ParameterKey": "networkBorderGroup",
        "ParameterValue": "$networkBorderGroup"
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
        "ParameterKey": "bigIpExternalServiceIps",
        "ParameterValue": "<EXTERNAL SERVICE IPS>"
    },
    {
        "ParameterKey": "numSecondaryPrivateIpAddresses",
        "ParameterValue": "<NUMBER SECONDARY PRIVATE IPS>"
    },
    {
        "ParameterKey": "numExternalPublicIpAddresses",
        "ParameterValue": "<NUMBER PUBLIC EXTERNAL IPS>"
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
    },
    {
        "ParameterKey": "vpcId",
        "ParameterValue": "$vpcId"
EOF
if [[ "<DYNAMIC IPS>" == "true" ]]; then
cat <<EOF >> parameters.json
    },
    {
        "ParameterKey": "bigIpExternalSelfIp",
        "ParameterValue": ""
    },
    {
        "ParameterKey": "bigIpInternalSelfIp",
        "ParameterValue": ""
    },
    {
        "ParameterKey": "bigIpMgmtAddress",
        "ParameterValue": ""
    }
]
EOF
else
cat <<EOF >> parameters.json
    }
]
EOF
fi
cat parameters.json | jq .

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_NAMED_IAM \
--parameters file://parameters.json
