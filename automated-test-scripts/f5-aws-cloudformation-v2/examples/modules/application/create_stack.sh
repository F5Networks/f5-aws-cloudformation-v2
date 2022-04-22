#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


src_ip=$(curl ifconfig.me)/32
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

# test for s3 prefix
if [[ "<S3 PREFIX>" == *"<"* ]]; then
   prefix=""
else   
   prefix="<S3 PREFIX>/"
fi

# test for App security group 
if [[ "<CREATE APP SECURITY GROUP>" == "No" ]]; then
   appSecurityGroupId=''
else   
   appSecurityGroupId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="appSecurityGroupId").OutputValue')
fi
vpcId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="vpcId").OutputValue')
subnetAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
subnetAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 2)

if [[ "<CREATE AUTOSCALE GROUP>" == "true" ]]; then
    parameters="ParameterKey=applicationSubnet,ParameterValue=\"$subnetAz1\" "
    parameters+="ParameterKey=applicationSubnets,ParameterValue=\"$subnetAz1,$subnetAz2\" "
else
   parameters="ParameterKey=applicationSubnet,ParameterValue=\"$subnetAz1\" "
   parameters+="ParameterKey=applicationSubnets,ParameterValue=\"$subnetAz1\" "
fi

parameters+="ParameterKey=appSecurityGroupId,ParameterValue=$appSecurityGroupId \
ParameterKey=createAutoscaleGroup,ParameterValue=<CREATE AUTOSCALE GROUP> \
ParameterKey=customImageId,ParameterValue=<CUSTOM APP IMAGE> \
ParameterKey=restrictedSrcAddress,ParameterValue=$src_ip \
ParameterKey=provisionPublicIp,ParameterValue=<PROVISION PUBLIC IP> \
ParameterKey=sshKey,ParameterValue=dewpt \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
ParameterKey=vpc,ParameterValue=$vpcId"
echo "Parameters:$parameters"


# aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
# --template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
# --capabilities CAPABILITY_IAM --parameters $parameters




# mgmt_sub_az1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME>-vpc | jq -r '.Stacks[].Outputs[]|select (.OutputKey=="managementSubnetAz1")|.OutputValue')
# echo "mgmt subnet $mgmt_sub_az1"

# Create Stack
aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop \
Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_IAM \
--parameters $parameters

# ParameterKey=sshKey,ParameterValue=<SSH KEY> ParameterKey=restrictedSrcAddress,ParameterValue=<ACCESS> ParameterKey=vpc,ParameterValue=<STACK NAME>-vpc ParameterKey=applicationSubnets,ParameterValue=${mgmt_sub_az1}