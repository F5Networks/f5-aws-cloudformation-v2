#  expectValue = "PASS"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

aws cloudformation delete-stack --region <REGION> --stack-name bastion-<STACK NAME>
echo "PASS"
