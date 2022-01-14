#  expectValue = "SUCCESS"
#  expectFailValue = "FAILED"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 360


TMP_DIR='/tmp/<DEWPOINT JOB ID>'
signal="config_complete"
failed_signal="activation_failed"
case <LICENSE TYPE> in
bigiq)
  bigiq_stack_name=<STACK NAME>-bigiq
  bigiq_stack_region=<REGION>
  if [ -f "${TMP_DIR}/bigiq_info.json" ]; then
      echo "Found existing BIG-IQ StackId"
      cat ${TMP_DIR}/bigiq_info.json
      bigiq_stack_name=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_name)
      bigiq_stack_region=$(cat ${TMP_DIR}/bigiq_info.json | jq -r .bigiq_stack_region)
  fi
  bigiq_ip=$(aws cloudformation describe-stacks --region $bigiq_stack_region --stack-name $bigiq_stack_name | jq -r '.Stacks[0].Outputs[]|select (.OutputKey=="device1Url")|.OutputValue|split(":")[1]|.[2:]')
  echo "BigIqPublicIP=$bigiq_ip"

  ssh-keygen -R $bigiq_ip 2>/dev/null
  ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/<SSH KEY>.pem admin@${bigiq_ip} 'modify auth user admin shell bash'
  response=$(ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/<SSH KEY>.pem admin@${bigiq_ip} 'ls -al /config/cloud')
  echo "response: $response" ;;
*)
  echo "BIG-IQ not required for test!"
  response=$signal  ;;
esac

if echo $response | grep $signal; then
  echo "SUCCESS"
fi

if echo $response | grep $failed_signal; then
  echo "FAILED"
fi