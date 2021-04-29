#  expectFailValue = "FAIL"
#  scriptTimeout = 3
#  replayEnabled = false

enabledAlarms=$(aws cloudwatch describe-alarms --region <REGION> | jq -r '.MetricAlarms[] | select(.AlarmName | contains("<DEWPOINT JOB ID>"))')

bigipHighCpuAlarm=$(echo $enabledAlarms | jq 'select(.AlarmName | contains("BigipHighCpuAlarm"))')
bigipHighbytesAlarm=$(echo $enabledAlarms | jq 'select(.AlarmName | contains("BigipHighbytesAlarm"))')
bigipLowCpuAlarm=$(echo $enabledAlarms | jq 'select(.AlarmName | contains("BigipLowCpuAlarm"))')
bigipLowbytesAlarm=$(echo $enabledAlarms | jq 'select(.AlarmName | contains("BigipLowbytesAlarm"))')


[[ $(echo $bigipHighCpuAlarm | jq '.Threshold') != '<HIGH CPU THRESHOLD>'  ]] && echo 'FAIL'
[[ $(echo $bigipHighbytesAlarm | jq '.Threshold') != '<SCALE UP BYTES THRESHOLD>'  ]] && echo 'FAIL'
[[ $(echo $bigipLowCpuAlarm | jq '.Threshold') != '<LOW CPU THRESHOLD>'  ]] && echo 'FAIL'
[[ $(echo $bigipLowbytesAlarm | jq '.Threshold') != '<SCALE DOWN BYTES THRESHOLD>' ]] && echo 'FAIL'

