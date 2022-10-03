#  expectValue = "Succeeded"
#  scriptTimeout = 10
#  replayEnabled = false
#  replayTimeout = 0


cat <<EOF > trust.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

cat <<EOF > permissions.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:DescribeAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeNetworkInterfaceAttribute",
                "ec2:DescribeTags"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:DescribeSubnets",
                "ec2:DescribeRouteTables"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/f5_cloud_failover_label": "<DEWPOINT JOB ID>"
                }
            },
            "Action": [
                "ec2:AssociateAddress",
                "ec2:DisassociateAddress",
                "ec2:AssignPrivateIpAddresses",
                "ec2:UnassignPrivateIpAddresses",
                "ec2:AssignIpv6Addresses",
                "ec2:UnassignIpv6Addresses",
                "ec2:CreateRoute",
                "ec2:ReplaceRoute"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketTagging"
            ],
            "Resource": "arn:*:s3:::bigip-ha-solution-<DEWPOINT JOB ID>",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:*:s3:::bigip-ha-solution-<DEWPOINT JOB ID>/*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "secretsmanager:DescribeSecret",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "cloudformation:ListStackResources",
                "cloudformation:SignalResource"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF

aws iam create-role --role-name <DEWPOINT JOB ID>-EC2-Instance-Profile --assume-role-policy-document file://trust.json

aws iam put-role-policy --role-name <DEWPOINT JOB ID>-EC2-Instance-Profile --policy-name <DEWPOINT JOB ID>-EC2-Permissions --policy-document file://permissions.json

aws iam create-instance-profile --instance-profile-name <DEWPOINT JOB ID>-EC2-Instance-Profile

aws iam add-role-to-instance-profile --instance-profile-name <DEWPOINT JOB ID>-EC2-Instance-Profile --role-name <DEWPOINT JOB ID>-EC2-Instance-Profile

result=$(aws iam get-instance-profile --instance-profile-name <DEWPOINT JOB ID>-EC2-Instance-Profile | jq -r .InstanceProfile.Arn)

if echo $result | grep '<DEWPOINT JOB ID>-EC2-Instance-Profile'; then
    echo "Succeeded"
else
    echo "Failed"
fi
