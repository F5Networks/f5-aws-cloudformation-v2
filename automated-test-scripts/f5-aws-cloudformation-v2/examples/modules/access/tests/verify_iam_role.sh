#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false

iamRoleName=$(aws iam list-roles | jq .Roles[].RoleName | grep <DEWPOINT JOB ID>-BigIp | tr -d '"')
echo "Role Name: $iamRoleName"
iamRoleDefinition=$(aws iam get-role --role-name "$iamRoleName")
echo "Role Definition: $iamRoleDefinition"

[[ $(echo $iamRoleDefinition | jq .Role.AssumeRolePolicyDocument.Statement[0].Effect | tr -d '"') == "Allow"  ]] && \
[[ $(echo $iamRoleDefinition | jq .Role.AssumeRolePolicyDocument.Statement[0].Action | tr -d '"') == "sts:AssumeRole" ]] && \
[[ $(echo $iamRoleDefinition | jq .Role.AssumeRolePolicyDocument.Statement[0].Principal.Service | tr -d '"') == "ec2.amazonaws.com" ]] && \
[[ $(echo $iamRoleDefinition | jq .Role.Path | tr -d '"') == "/" ]] &&  echo "SUCCESS"
