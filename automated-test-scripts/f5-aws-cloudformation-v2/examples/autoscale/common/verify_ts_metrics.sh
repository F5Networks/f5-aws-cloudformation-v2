#  expectValue = "SUCCESS"
#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false


namespace=$(aws cloudwatch list-metrics --region <REGION> --namespace "<METRIC NAME SPACE>" | jq '.Metrics[] |select(.Namespace=="<METRIC NAME SPACE>")| select (.MetricName=="F5_system_cpu", .MetricName=="F5_throughputIn_sys/performance/throughput/In_Current")')

if echo $namespace | grep "<METRIC NAME SPACE>"; then
    echo "SUCCESS: $namespace"
else
    echo "FAIL: $namespace"
fi