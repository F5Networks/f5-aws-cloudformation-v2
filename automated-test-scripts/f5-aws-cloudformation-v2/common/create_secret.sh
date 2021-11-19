#  expectValue = "ARN"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

aws secretsmanager create-secret --name <DEWPOINT JOB ID>-secret --secret-string '{"username":"admin","password":"<BIGIQ PASSWORD>"}' --region <REGION> | jq -r .
aws secretsmanager create-secret --name <DEWPOINT JOB ID>-secret-runtime --secret-string '<BIGIQ PASSWORD>' --region <REGION> | jq -r .