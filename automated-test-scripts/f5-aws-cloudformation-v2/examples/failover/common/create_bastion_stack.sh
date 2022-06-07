#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

if [[ "<PROVISION MGMT PUBLIC IP>" == "false" ]]; then
  src_ip=$(curl ifconfig.me)/32
  bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
  echo "bucket_name=$bucket_name"
  # update this path once we move to a separate repo
  artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
  echo "artifact_location=$artifact_location"

  dag_stack_name=$(aws cloudformation describe-stacks --region <REGION> | jq -r '.Stacks[] | select(.StackName | contains("<STACK NAME>-Dag")) | .StackName')
  bastionSecurityGroupId=$(aws cloudformation describe-stacks --stack-name $dag_stack_name --region <REGION> | jq -r '.Stacks[].Outputs[] | select (.OutputKey=="bastionSecurityGroupId") | .OutputValue')
  vpcId=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="vpcId").OutputValue')

  if [[ '<NUMBER SUBNETS>' == '4' && '<PROVISION EXAMPLE APP>' == 'false' ]]; then
    mgmtSubnet=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnetAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 2)
    subnetAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 2)
  else
    mgmtSubnet=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnetAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
    subnetAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 1)
  fi

  cat <<EOF > parameters.json
[
  { 
    "ParameterKey": "bastionSecurityGroupId",
    "ParameterValue": "$bastionSecurityGroupId"
  },
  { 
    "ParameterKey": "mgmtSubnet",
    "ParameterValue": "$mgmtSubnet"
  },
  { 
    "ParameterKey": "mgmtSubnets",
    "ParameterValue": "${subnetAz1},${subnetAz2}"
  },
  { 
    "ParameterKey": "restrictedSrcAddress",
    "ParameterValue": "$src_ip"
  },
  { 
    "ParameterKey": "sshKey",
    "ParameterValue": "dewpt"
  },
  { 
    "ParameterKey": "uniqueString",
    "ParameterValue": "<UNIQUESTRING>"
  },
  { 
    "ParameterKey": "vpc",
    "ParameterValue": "$vpcId"
  }
]
EOF
  cat parameters.json

  # Create Stack
  aws cloudformation create-stack \
  --disable-rollback \
  --region <REGION> \
  --stack-name bastion-<STACK NAME> \
  --tags Key=creator,Value=dewdrop Key=delete,Value=True \
  --template-url https://s3.amazonaws.com/"$bucket_name"/"$artifact_location"modules/bastion/bastion.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters file://parameters.json
else
  echo "Bastion host not required"
  echo "StackId"
fi