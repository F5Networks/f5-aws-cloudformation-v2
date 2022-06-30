#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

if [[ "<S3 PREFIX>" == *"<"* ]]; then
   prefix=""
else
   prefix="<S3 PREFIX>/"
fi

if [[ "<PROVISION PUBLIC IP>" == *"<"* ]]; then
    provisionMgmtPublicIp="<PROVISION MGMT PUBLIC IP>"
else
    provisionMgmtPublicIp="<PROVISION PUBLIC IP>"
fi

parameters="\
ParameterKey=numAzs,ParameterValue=<NUMBER AZS> \
ParameterKey=numSubnets,ParameterValue=<NUMBER SUBNETS> \
ParameterKey=setPublicSubnet1,ParameterValue=$provisionMgmtPublicIp \
ParameterKey=subnetMask,ParameterValue=<SUBNETMASK> \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
ParameterKey=vpcCidr,ParameterValue=<CIDR> \
ParameterKey=vpcTenancy,ParameterValue=<TENANCY>"


echo "Parameters:$parameters"

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <NETWORK STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/"$artifact_location"modules/network/<NETWORK TEMPLATE NAME>.yaml \
--capabilities CAPABILITY_NAMED_IAM --parameters $parameters
