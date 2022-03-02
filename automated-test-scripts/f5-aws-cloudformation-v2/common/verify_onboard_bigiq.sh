#  expectValue = "SUCCESS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 180

signal="config_complete"
case <LICENSE TYPE> in
bigiq)
   IP=$(aws cloudformation describe-stacks  --region <REGION> --stack-name <STACK NAME>-bigiq|jq -r '.Stacks[0].Outputs[]|select (.OutputKey=="device1Url")|.OutputValue|split(":")[1]|.[2:]')
   echo "BigIqPublicIP=$IP"
   ssh-keygen -R $IP 2>/dev/null
   ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/<SSH KEY>.pem admin@${IP} 'modify auth user admin shell bash'
   response=$(ssh -o "StrictHostKeyChecking no" -o ConnectTimeout=5 -i /etc/ssl/private/<SSH KEY>.pem admin@${IP} 'ls -al /config/cloud')
   echo "response: $response" ;;
*)
  echo "BIG-IQ not required for test!"
  response=$signal  ;;
esac

if echo $response | grep $signal; then
  echo "SUCCESS"
else
  echo "FAILED"
fi
