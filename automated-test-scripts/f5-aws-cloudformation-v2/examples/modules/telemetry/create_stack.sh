#  expectValue = "StackId"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`
echo "bucket_name=$bucket_name"

parameters="\
ParameterKey=cloudWatchLogGroupName,ParameterValue=<UNIQUESTRING>-<LOG GROUP NAME> \
ParameterKey=cloudWatchLogStreamName,ParameterValue=<UNIQUESTRING>-<LOG STREAM NAME> \
ParameterKey=cloudWatchDashboardName,ParameterValue=<UNIQUESTRING>-<DASHBOARD NAME> \
ParameterKey=createCloudWatchDashboard,ParameterValue=<CREATE DASHBOARD> \
ParameterKey=createCloudWatchLogGroup,ParameterValue=<CREATE LOG GROUP> \
ParameterKey=createCloudWatchLogStream,ParameterValue=<CREATE LOG STREAM> \
ParameterKey=createS3Bucket,ParameterValue=<CREATE S3 BUCKET> \
ParameterKey=metricNameSpace,ParameterValue=<METRIC NAMESPACE NAME> \
ParameterKey=s3BucketName,ParameterValue=<S3 BUCKET NAME>"

echo "Parameters:$parameters"

aws cloudformation create-stack --disable-rollback --region <REGION> --stack-name <STACK NAME> --tags Key=creator,Value=dewdrop Key=delete,Value=True \
--template-url https://s3.amazonaws.com/"$bucket_name"/<TEMPLATE NAME> \
--capabilities CAPABILITY_NAMED_IAM --parameters $parameters