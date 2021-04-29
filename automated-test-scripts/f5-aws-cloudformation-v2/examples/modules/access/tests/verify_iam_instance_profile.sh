#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false

iamRoleName=$(aws iam list-roles | jq .Roles[].RoleName | grep <DEWPOINT JOB ID>-BigIp | tr -d '"')
instanceProfileDefinition=$(aws iam list-instance-profiles-for-role --role-name $iamRoleName)

[[ $(echo $instanceProfileDefinition | jq -r .InstanceProfiles[0].Roles[0].AssumeRolePolicyDocument.Statement[].Action | tr -d '"') == "sts:AssumeRole" ]] && \
[[ $(echo $instanceProfileDefinition | jq -r .InstanceProfiles[0].Roles[0].AssumeRolePolicyDocument.Statement[].Effect | tr -d '"') == "Allow" ]] && \
[[ $(echo $instanceProfileDefinition | jq -r .InstanceProfiles[0].Roles[0].AssumeRolePolicyDocument.Statement[].Principal.Service | tr -d '"') == "ec2.amazonaws.com" ]] && echo "SUCCESS"
