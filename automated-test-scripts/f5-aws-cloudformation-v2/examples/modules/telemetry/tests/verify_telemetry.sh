#!/usr/bin/env bash
#  expectValue = "PASS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


# since there are no user configurable properties we are just testing for successful resource deployment
log_group=<UNIQUESTRING>-<LOG GROUP NAME>
log_stream=<UNIQUESTRING>-<LOG STREAM NAME>
dashboard=<METRIC NAMESPACE NAME>
logging_bucket=<S3 BUCKET NAME>

if [[ <CREATE LOG GROUP> == "true" ]]; then 
    log_group=$(aws logs describe-log-groups --region <REGION> --log-group-name-prefix <UNIQUESTRING> | jq .logGroups)
fi
if [[ <CREATE LOG STREAM> == "true" ]]; then 
    log_stream=$(aws logs describe-log-streams --region <REGION> --log-group-name <UNIQUESTRING>-<LOG GROUP NAME> | jq .)
fi
if [[ <CREATE DASHBOARD> == "true" ]]; then 
    dashboard=$(aws cloudwatch get-dashboard --region <REGION> --dashboard-name <UNIQUESTRING>-<DASHBOARD NAME> | jq .DashboardBody)
fi
if [[ <CREATE S3 BUCKET> == "true" ]]; then 
    logging_bucket=$(aws s3api get-bucket-tagging --bucket <S3 BUCKET NAME> | jq .)
fi

echo "Log group: $log_group"
echo "Log stream: $log_stream"
echo "Dashboard: $dashboard"
echo "Logging bucket: $logging_bucket"

if echo "${log_group}" | grep -q "<UNIQUESTRING>-<LOG GROUP NAME>" && \
echo "${log_stream}" | grep -q "<UNIQUESTRING>-<LOG STREAM NAME>" && \
echo "${dashboard}" | grep -q "<METRIC NAMESPACE NAME>" && \
echo "${logging_bucket}" | grep -q "<S3 BUCKET NAME>"; then
    echo "PASS"
fi