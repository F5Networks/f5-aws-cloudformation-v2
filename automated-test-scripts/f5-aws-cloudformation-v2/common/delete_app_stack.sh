#  expectValue = "PASS"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

aws cloudformation delete-stack --region <REGION> --stack-name app-<STACK NAME>
echo "PASS"
