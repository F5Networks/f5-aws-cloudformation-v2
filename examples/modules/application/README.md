
# Deploying Application Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Deploying Application Template](#deploying-application-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)

## Introduction

This template deploys a simple example application. It launches a CentOS Linux VM used for hosting applications and can be customized to deploy your own startup script:

1) [Cloud-init](https://cloudinit.readthedocs.io/en/latest/)
2) Bash script


## Prerequisites

- Requires existing network infrastructure and subnet
- Accept any Marketplace "License/Terms and Conditions" for the [image](https://aws.amazon.com/marketplace/pp/B00O7WM7QW) used for the application.

## Important Configuration Notes

- Public IPs won't be provisioned for this template.
- This template downloads and renders custom configs (i.e. cloud-init or bash script) as external files and therefore, the custom configs must be reachable from the Virtual Machine (i.e. routing to any remotely hosted files must be provided for outside of this template).
- Examples of custom configs are provided under scripts directory.
- This template uses the Linux CentOS 7 as Virtual Machine operational system.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| appContainerName | No | Name of the docker container to deploy in cloud-init script. |
| application | No | Application Tag. |
| applicationSubnet | No | Private subnet names for the stack in case of standalone template. |
| applicationSubnets | No | Private subnet names for the stack. |
| appSecurityGroupId | No | ID of Security Group to apply to application. |
| cost | No | Cost Center Tag. |
| createAutoscaleGroup | No | Choose true to create the application instances in an autoscaling configuration. |
| customAppImageId | No | Custom Image AMI ID you wish to deploy. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| instanceType | No | App EC2 instance type. e.g. t2.small |
| owner | No | Application Tag. |
| restrictedSrcAddress | Yes | The IP address range that can be used to SSH to the EC2 instances. |
| scalingMaxSize | No | Maximum number of BIG-IP instances (2-100) that can be created in the Auto Scale Group. |
| scalingMinSize | No | Minimum number of BIG-IP instances (1-99) you want available in the Auto Scale Group. |
| setAppPublicIp | No | To create a Public IP and connect it to the application. |
| sshKey | Yes | Name of an existing EC2 KeyPair to enable SSH access to the instance. |
| staticIp | No | The private IP address to apply as primary private address. |
| vpc | Yes | Common VPC for whole deployment. |

### Template Outputs

| Name | Description | Type |
| --- | --- | --- | --- |
| stackName | Application nested stack name | Application template deployment | String |
| appAutoscaleGroupName | Autoscale Group Name | string |
| appInstanceId | Standalone Instance ID | string |
