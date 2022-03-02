#  expectValue = "ARN"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


TMP_DIR='/tmp/<DEWPOINT JOB ID>'

bigiq_stack_name=<STACK NAME>-bigiq
bigiq_stack_region=<REGION>
bigiq_password=''
if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
    echo "Found existing BIG-IQ StackId"
    cat ${TMP_DIR}/bigiq_info.json
    bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
    bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
    bigiq_password=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_password)
fi

aws secretsmanager create-secret --name <DEWPOINT JOB ID>-secret --secret-string '{"username":"admin","password":"'"${bigiq_password}"'"}' --region <REGION> | jq -r .
aws secretsmanager create-secret --name <DEWPOINT JOB ID>-secret-runtime --secret-string ${bigiq_password} --region <REGION> | jq -r .
