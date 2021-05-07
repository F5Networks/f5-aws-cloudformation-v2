# Deploying Access Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)


## Contents

- [Deploying Access Template](#deploying-access-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Resources Provisioning](#resources-provisioning)
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
    - Cloudwatch Metrics and Logging *(used by Telemetry Streaming)*
    - CloudFormation Status Update *(Used by templates)*
  - secret
    - permissions from standard +
    - access a secret from secret-manager *(used by Runtime-Init)*
  - s3
    - permissions from standard + 
    - S3 bucket *(used by Telemetry Streaming for remote S3 Logging or Cloud Failover Extension for State File Storage)*
  - secretS3
    - permissions from standard + 
    - access a secret from secret-manager *(used by Runtime-Init)*
    - S3 bucket *(used by Telemetry Streaming for remote S3 Logging or Cloud Failover Extension for State File Storage)*
  - failover
    - permissions from standard + 
    - access a secret from secret-manager *(used by Runtime-Init)*
    - S3 bucket *(used by Telemetry Streaming for remote S3 Logging or Cloud Failover Extension for State File Storage)*
    - Update permissions for IP addresses/Routes *(used by Cloud Failover Extension)*


***DISCLAIMER:*** *These example IAM roles provide the permissions required for BIG-IP VE solutions to function and are for illustration purposes only. They are created more generically in a provider context to accommodate varying inputs, environments, and use cases. However, in production, they can often be further locked down via more specific `resource statements` and/or `ResourceTag conditions`. Please see each individual tool's documentation (for example, [Cloud Failover](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/aws.html#create-and-assign-an-iam-role)), for the most up-to-date permissions required. See your cloud provider resources for IAM Best Practices (for example, [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)).*


## Prerequisites

  - None. This template does not require provisioning of additional resources.
  
  
## Resources Provisioning

  * [AWS IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html):
    - Creates IAM roles for standalone, failover, and autoscale solutions.
  * [AWS IAM Instance Profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)
    - Instance profile is associated with IAM Role and assigned to EC2 instance used for hosting BIG-IP system.


## Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| bigIqSecretArn | No | The ARN of the AWS secret containing the password used during BIG-IP licensing via BIG-IQ. |
| cost | No | Cost Center Tag. |
| createAmiRole | No | Value of 'true' creates IAM roles required for AMI lookup function. |
| createBigIqRoles | No | Value of 'true' creates IAM roles required to revoke license assignments from BIG-IQ. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
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






