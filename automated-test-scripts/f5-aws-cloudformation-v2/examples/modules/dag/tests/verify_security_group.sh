#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = false


stack_outputs=$(aws cloudformation describe-stacks --region <REGION> --stack-name dewdrop-<TEMPLATE NAME>-<DEWPOINT JOB ID> | jq .Stacks[0].Outputs)
bigIpMgmtSecurityGroup='bigIpMgmtSecurityGroup'
bigIpExternalSecurityGroup='bigIpMgmtSecurityGroup'
bigIpInternalSecurityGroup='bigIpMgmtSecurityGroup'
appSecurityGroupId='bigIpMgmtSecurityGroup'
bastionSecurityGroupId='bigIpMgmtSecurityGroup'

if [[ <CREATE EXTERNAL SECURITY GROUP> == 'true' ]]; then
     bigIpExternalSecurityGroup='bigIpExternalSecurityGroup'
fi
if [[ <CREATE INTERNAL SECURITY GROUP> == 'true' ]]; then
     bigIpInternalSecurityGroup='bigIpInternalSecurityGroup'
fi
if [[ <CREATE APP SECURITY GROUP> == 'true' ]]; then
     appSecurityGroupId='appSecurityGroupId'
fi
if [[ <CREATE BASTION SECURITY GROUP> == 'true' ]]; then
     bastionSecurityGroupId='bastionSecurityGroupId'
fi

if echo $stack_outputs | grep $bigIpMgmtSecurityGroup && echo $stack_outputs | grep $bastionSecurityGroupId && echo $stack_outputs && echo $stack_outputs | grep $appSecurityGroupId && echo $stack_outputs | grep $bigIpExternalSecurityGroup && echo $stack_outputs | grep $bigIpInternalSecurityGroup; then
     echo "SUCCESS"
fi
