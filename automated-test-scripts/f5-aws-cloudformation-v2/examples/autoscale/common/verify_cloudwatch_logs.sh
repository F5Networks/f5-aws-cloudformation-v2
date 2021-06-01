#  expectValue = "SUCCESS"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10


log_events=$(aws logs get-log-events --region <REGION> --log-group-name <UNIQUESTRING>-<CLOUDWATCH LOG GROUP NAME> --log-stream-name <UNIQUESTRING>-<CLOUDWATCH LOG STREAM NAME> | jq .events[].message)

echo "Log events: $log_events"

if [[ <CREATE LOG DESTINATION> == "true" ]]; then 
    if echo "${log_events}" | grep -q "DELETE"; then
        echo "SUCCESS"
    fi
else 
    echo "SUCCESS"
fi