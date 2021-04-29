#  expectValue = "DeletionDate"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0

aws secretsmanager delete-secret --secret-id <DEWPOINT JOB ID>-secret --region <REGION> | jq -r .
aws secretsmanager delete-secret --secret-id <DEWPOINT JOB ID>-secret-runtime --region <REGION> | jq -r .
