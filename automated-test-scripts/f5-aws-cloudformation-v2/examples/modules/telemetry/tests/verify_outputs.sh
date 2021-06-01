#  expectValue = "SUCCESS"
#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false


stack_outputs=$(aws cloudformation describe-stacks --region <REGION> --stack-name dewdrop-<TEMPLATE NAME>-<DEWPOINT JOB ID> | jq .Stacks[0].Outputs)

if [[ <CREATE LOG GROUP> == "true" ]]; then 
   if echo $stack_outputs | grep -q "cloudWatchLogGroup"; then
      echo "Log group output found"
   else
      echo "FAIL"
   fi
fi

if [[ <CREATE LOG STREAM> == "true" ]]; then 
   if echo $stack_outputs | grep -q "cloudWatchLogStream"; then
      echo "Log stream output found"
   else
      echo "FAIL"
   fi
fi

if [[ <CREATE DASHBOARD> == "true" ]]; then 
   if echo $stack_outputs | grep -q "cloudWatchDashboard"; then
      echo "Dashboard output found"
   else
      echo "FAIL"
   fi
fi

if [[ <CREATE S3 BUCKET> == "true" ]]; then 
   if echo $stack_outputs | grep -q "s3Bucket"; then
      echo "S3 bucket output found"
   else
      echo "FAIL"
   fi
fi

echo "SUCCESS"
