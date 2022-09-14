#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

subnetAz1=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsA").OutputValue' | cut -d ',' -f 1)
subnetAz2=$(aws cloudformation describe-stacks --region <REGION> --stack-name <NETWORK STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="subnetsB").OutputValue' | cut -d ',' -f 1)
internalTargetGroupHttp=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="internalTargetGroupHttp").OutputValue' | cut -d ',' -f 1)
internalTargetGroupHttps=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="internalTargetGroupHttps").OutputValue' | cut -d ',' -f 1)
externalTargetGroupHttps=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="externalTargetGroupHttps").OutputValue' | cut -d ',' -f 1)
externalTargetGroupHttp=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="externalTargetGroupHttp").OutputValue' | cut -d ',' -f 1)
bigIpInstanceProfile=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpInstanceProfile").OutputValue' | cut -d ',' -f 1)
bigIpExternalSecurityGroup=$(aws cloudformation describe-stacks --region <REGION> --stack-name <DAG STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIpMgmtSecurityGroup").OutputValue' | cut -d ',' -f 1)

bigiqNotificationRole=""
if [[ <LICENSE TYPE> == 'bigiq' ]]; then
    bigiqNotificationRole=$(aws cloudformation describe-stacks --region <REGION> --stack-name <ACCESS STACK NAME> | jq  -r '.Stacks[0].Outputs[] | select(.OutputKey=="bigIqNotificationRole").OutputValue' | cut -d ',' -f 1)
fi


subnets_param="$subnetAz1,$subnetAz2"

[[ -z $internalTargetGroupHttps ]] && internalTargetGroupHttps=''
[[ -z $internalTargetGroupHttp ]] && internalTargetGroupHttp=''
[[ -z $externalTargetGroupHttps ]] && externalTargetGroupHttps=''
[[ -z $externalTargetGroupHttp ]] && externalTargetGroupHttp=''
runtimeConfig='"<RUNTIME INIT CONFIG>"'

cat <<EOF > parameters.json
[
    {
        "ParameterKey": "allowUsageAnalytics",
        "ParameterValue": "No"
    },
    { 
        "ParameterKey": "bigIpExternalSecurityGroup",
        "ParameterValue": "$bigIpExternalSecurityGroup"
    },
    {
        "ParameterKey": "instanceProfile",
        "ParameterValue": "$bigIpInstanceProfile"
    },
    {   "ParameterKey": "bigIpRuntimeInitConfig",
        "ParameterValue": $runtimeConfig
    },
    {
        "ParameterKey": "bigIqNotificationRole",
        "ParameterValue": "$bigiqNotificationRole"
    },
    {
        "ParameterKey": "externalTargetGroupHttp",
        "ParameterValue": "$externalTargetGroupHttp"
    },
    {
        "ParameterKey": "externalTargetGroupHttps",
        "ParameterValue": "$externalTargetGroupHttps"
    },
    {
        "ParameterKey": "internalTargetGroupHttp",
        "ParameterValue": "$internalTargetGroupHttp"
    },
    {
        "ParameterKey": "internalTargetGroupHttps",
        "ParameterValue": "$internalTargetGroupHttps"
    },
    {
        "ParameterKey": "imageId",
        "ParameterValue": "<BIGIP AMI>"
    },
    {
        "ParameterKey": "instanceType",
        "ParameterValue": "<BIGIP INSTANCE TYPE>"
    },
    {
        "ParameterKey": "maxBatchSize",
        "ParameterValue": "<UPDATE MAX BATCH SIZE>"
    },
    {
        "ParameterKey": "metricNameSpace",
        "ParameterValue": "<METRIC NAME SPACE>"
    },
    {
        "ParameterKey": "minInstancesInService",
        "ParameterValue": "<UPDATE MIN INSTANCES>"
    },
    {
        "ParameterKey": "notificationEmail",
        "ParameterValue": "<NOTIFICATION EMAIL>"
    },
    {
        "ParameterKey": "pauseTime",
        "ParameterValue": "<UPDATE PAUSE TIME>"
    },
    {
        "ParameterKey": "provisionPublicIp",
        "ParameterValue": "<PROVISION PUBLIC IP>"
    },
    {
        "ParameterKey": "scaleInThroughputThreshold",
        "ParameterValue": "<SCALE DOWN BYTES THRESHOLD>"
    },
    {
        "ParameterKey": "scaleInCpuThreshold",
        "ParameterValue": "<LOW CPU THRESHOLD>"
    },
    {
        "ParameterKey": "scaleOutThroughputThreshold",
        "ParameterValue": "<SCALE UP BYTES THRESHOLD>"
    },
    {
        "ParameterKey": "scaleOutCpuThreshold",
        "ParameterValue": "<HIGH CPU THRESHOLD>"
    },
    {
        "ParameterKey": "scalingMaxSize",
        "ParameterValue": "<SCALE MAX SIZE>"
    },
    {
        "ParameterKey": "scalingMinSize",
        "ParameterValue": "<SCALE MIN SIZE>"
    },
    {
        "ParameterKey": "snsEvents",
        "ParameterValue": "<SNS EVENTS>"
    },
    {
        "ParameterKey": "sshKey",
        "ParameterValue": "<SSH KEY>"
    },
    {
        "ParameterKey": "subnets",
        "ParameterValue": "${subnets_param}"
    },
    {
        "ParameterKey": "uniqueString",
        "ParameterValue": "<UNIQUESTRING>"
    }
]
EOF

cat parameters.json


aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_NAMED_IAM \
--parameters file://parameters.json
