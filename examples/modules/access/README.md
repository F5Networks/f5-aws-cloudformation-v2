# Deploying Access Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Deploying Access Template](#deploying-access-template)
    - [Contents](#contents)
    - [Prerequisites](#prerequisites)
    - [Important Configuration Notes](#important-configuration-notes)
    - [Resources Provisioning](#resources-provisioning)
        - [IAM Permissions by Solution Type](#iam-permissions-by-solution-type)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
    - [Resource Creation Flow Chart](#resource-creation-flow-chart)

## Introduction

This solution uses an AWS CloudFormation template to launch a stack for provisioning Access-related items commonly required in BIG-IP VE Solutions. This template can be deployed as a standalone; however the main intention is to use as a module for provisioning Access-related resources:

  - AWS IAM Role
  - AWS IAM Instance Profile

This solution creates IAM roles based on the following **solutionTypes**:

  - standard
    - Service Discovery *(used by AS3)*
    - CloudWatch Metrics and Logging *(used by Telemetry Streaming)*
    - CloudFormation Status Update *(Used by templates)*
  - secret
    - Permissions from standard +
    - Access a secret from secret-manager *(used by Runtime-Init)*
  - s3
    - Permissions from standard + 
    - S3 bucket *(used by Telemetry Streaming for remote S3 Logging or Cloud Failover Extension for State File Storage)*
  - secretS3
    - Permissions from standard + 
    - Access a secret from secret-manager *(used by Runtime-Init)*
    - S3 bucket *(used by Telemetry Streaming for remote S3 Logging or Cloud Failover Extension for State File Storage)*
  - failover
    - Permissions from standard + 
    - Access a secret from secret-manager *(used by Runtime-Init)*
    - S3 bucket *(used by Telemetry Streaming for remote S3 Logging or Cloud Failover Extension for State File Storage)*
    - Update permissions for IP addresses/routes *(used by Cloud Failover Extension)*


***DISCLAIMER:*** *These example IAM roles provide the permissions required for BIG-IP VE solutions to function and are for illustration purposes only. They are created more generically in a provider context to accommodate varying inputs, environments, and use cases. However, in production, they can often be further locked down via more specific `resource statements` and/or `ResourceTag conditions`. Please see each individual tool's documentation (for example, [Cloud Failover](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/aws.html#create-and-assign-an-iam-role)), for the most up-to-date permissions required. See your cloud provider resources for IAM Best Practices (for example, [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)).*


## Prerequisites

  - None. This template does not require provisioning of additional resources.

## Important Configuration Notes

  - This template provisions resources based on conditions. See [Resources Provisioning](#resources-provisioning) for more details on each resource's minimal requirements.
  - A sample template, 'sample_linked.yaml', is included in the project. Use this example to see how to add a template as a linked template into your templated solution.
  
## Resources Provisioning

  * [AWS IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html):
    - Creates IAM roles for standalone, failover, and autoscale solutions.
  * [AWS IAM Instance Profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)
    - Instance profile is associated with IAM Role and assigned to EC2 instance used for hosting BIG-IP system.


### IAM Permissions by Solution Type

These are the IAM permissions produced by each type of solution supported by this template. For more details about the purpose of each permission, see the [CFE documentation for AWS Cloud](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/aws.html#create-and-assign-an-iam-role)

| Permission | Solution Type |
| --- | --- |
| autoscaling:DescribeAutoScalingGroups | standard, secret, s3, secrets3, failover |
| autoscaling:DescribeAutoScalingInstances | standard, secret, s3, secrets3, failover |
| cloudformation:ListStackResources | standard, secret, s3, secrets3, failover | 
| cloudformation:SignalResource | standard, secret, s3, secrets3, failover | 
| cloudwatch:PutMetricData | standard, secret, s3, secrets3, failover | 
| ec2:AssignIpv6Addresses | failover |
| ec2:AssignPrivateIpAddresses | failover | 
| ec2:AssociateAddress | failover | 
| ec2:CreateRoute | failover |
| ec2:DescribeAddresses | standard, secret, s3, secrets3, failover | 
| ec2:DescribeInstances | standard, secret, s3, secrets3, failover | 
| ec2:DescribeInstanceStatus | standard, secret, s3, secrets3, failover | 
| ec2:DescribeNetworkInterfaceAttribute | standard, secret, s3, secrets3, failover | 
| ec2:DescribeNetworkInterfaces | standard, secret, s3, secrets3, failover | 
| ec2:DescribeRouteTables | failover | 
| ec2:DescribeSubnets | failover | 
| ec2:DescribeTags | standard, secret, s3, secrets3, failover | 
| ec2:DisassociateAddress | failover | 
| ec2:ReplaceRoute | failover |
| ec2:UnassignIpv6Addresses | failover |
| ec2:UnassignPrivateIpAddresses | failover |
| logs:DescribeLogGroups | standard, secret, s3, secrets3, failover | 
| logs:DescribeLogStreams | standard, secret, s3, secrets3, failover | 
| logs:PutLogEvents | standard, secret, s3, secrets3, failover | 
| s3:DeleteObject | secrets3, failover | 
| s3:GetBucketLocation | failover |
| s3:GetBucketTagging | failover |
| s3:GetObject | secrets3, failover | 
| s3:ListAllMyBuckets | failover |
| s3:ListBucket | secrets3, failover | 
| s3:PutObject | secrets3, failover | 
| secretsmanager:DescribeSecret | secret, s3, secrets3, failover | 
| secretsmanager:GetResourcePolicy | secret, s3, secrets3, failover | 
| secretsmanager:GetSecretValue | secret, s3, secrets3, failover | 
| secretsmanager:ListSecretVersionIds | secret, s3, secrets3, failover |


## Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| bigIqSecretArn | No | The ARN of the AWS secret containing the password used during BIG-IP licensing via BIG-IQ. |
| cfeTag | No | Cloud Failover deployment tag value. |
| cloudWatchLogGroup | No | Provide the CloudWatch Log Group name used for telemetry. |
| cost | No | Cost Center Tag. |
| createAmiRole | No | Value of 'true' creates IAM roles required for AMI lookup function. |
| createBigIqRoles | No | Value of 'true' creates IAM roles required to revoke license assignments from BIG-IQ. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| metricNameSpace | No | CloudWatch namespace used for custom metrics. This should match the namespace defined in your telemetry services declaration within bigipRuntimInitConfig. |
| owner | No | Application Tag. |
| s3Bucket | No | Provide the S3 Bucket name used for for remote logging, failover solution, etc. |
| secretArn | No | The ARN of an AWS secrets manager secret. |
| solutionType| No | Defines solution type to select provision correct IAM role. Allowed Values = 'standard', 'secret', 's3', 'secretS3' and 'failover'. |
| uniqueString | Yes | Unique String used when creating object names and/or Tags. |

## Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| stackName | Access nested stack name | Access template deployment | String |
| bigIpInstanceProfile | BIG-IP instance profile with applied IAM policy.  | IAM Instance Profile and IAM Instance Role | String |
| bigIqNotificationRole | IAM policy for BIG-IQ Lifecycle Hook notifications | BIG-IQ notification IAM role | String |
| copyZipsRole | IAM policy for CopyZips lambda function | CopyZips IAM role | String |
| lambdaAccessRole | IAM policy for BIG-IQ lambda function  | Lambda IAM role | String |
| lambdaAmiExecutionRole| IAM policy for ami lookup function  | Lambda ami IAM role | String |

## Resource Creation Flow Chart

![Resource Creation Flow Chart](../../../images/aws-access-module.png)






