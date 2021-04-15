#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

parameters="\
ParameterKey=numAzs,ParameterValue=<NUMBER AZS> \
ParameterKey=numSubnets,ParameterValue=<NUMBER SUBNETS> \
ParameterKey=setPublicSubnet1,ParameterValue=<SUBNET1 PUBLIC> \
ParameterKey=subnetMask,ParameterValue=<SUBNETMASK> \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
ParameterKey=vpcCidr,ParameterValue=<CIDR> \
ParameterKey=vpcTenancy,ParameterValue=<TENANCY>"


echo "Parameters:$parameters"

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_IAM --parameters $parameters