#  expectValue = "Succeeded"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


aws iam remove-role-from-instance-profile --instance-profile-name <DEWPOINT JOB ID>-EC2-Instance-Profile --role-name <DEWPOINT JOB ID>-EC2-Instance-Profile

aws iam delete-role-policy --role-name <DEWPOINT JOB ID>-EC2-Instance-Profile --policy-name <DEWPOINT JOB ID>-EC2-Permissions

aws iam delete-role --role-name <DEWPOINT JOB ID>-EC2-Instance-Profile

aws iam delete-instance-profile --instance-profile-name <DEWPOINT JOB ID>-EC2-Instance-Profile

if [ $? -eq 0 ]; then
    echo "Succeeded"
else
    echo "Failed"
fi
