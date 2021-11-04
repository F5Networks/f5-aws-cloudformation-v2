#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

vpcId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="vpcId").OutputValue')
subnetAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
subnetAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 1)

parameters="\
ParameterKey=application,ParameterValue=f5-app-<DEWPOINT JOB ID> \
ParameterKey=createAppSecurityGroup,ParameterValue=<CREATE APP SECURITY GROUP> \
ParameterKey=createBastionSecurityGroup,ParameterValue=<CREATE BASTION SECURITY GROUP> \
ParameterKey=createExternalSecurityGroup,ParameterValue=<CREATE EXTERNAL SECURITY GROUP> \
ParameterKey=createInternalSecurityGroup,ParameterValue=<CREATE INTERNAL SECURITY GROUP> \
ParameterKey=externalSubnetAz1,ParameterValue=$subnetAz1 \
ParameterKey=externalSubnetAz2,ParameterValue=$subnetAz2 \
ParameterKey=internalSubnetAz1,ParameterValue=$subnetAz1 \
ParameterKey=internalSubnetAz2,ParameterValue=$subnetAz2 \
ParameterKey=numberPublicExternalIpAddresses,ParameterValue=<NUM SECONDARY PRIVATE IP> \
ParameterKey=numberPublicMgmtIpAddresses,ParameterValue=<NUM PUBLIC MGMT IP> \
ParameterKey=provisionExternalBigipLoadBalancer,ParameterValue=<PROVISION EXTERNAL LB> \
ParameterKey=provisionInternalBigipLoadBalancer,ParameterValue=<PROVISION INTERNAL LB> \
ParameterKey=restrictedSrcAddressApp,ParameterValue=0.0.0.0/0 \
ParameterKey=restrictedSrcAddressMgmt,ParameterValue=0.0.0.0/0 \
ParameterKey=vpcCidr,ParameterValue=10.0.0.0/16 \
ParameterKey=uniqueString,ParameterValue=<UNIQUESTRING> \
ParameterKey=vpc,ParameterValue=$vpcId"
echo "Parameters:$parameters"


aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_IAM --parameters $parameters
