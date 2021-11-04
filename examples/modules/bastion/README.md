
# Deploying Bastion Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Deploying Bastion Template](#deploying-bastion-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)

## Introduction

This template deploys a simple example Bastion host(s). It launches a Ubuntu OS Linux VM used for hosting bastion and can be customized to deploy your own startup script.


## Prerequisites

- Requires existing network infrastructure and subnet.
- Accept any Marketplace "License/Terms and Conditions" for the [image](https://aws.amazon.com/marketplace/pp/B00O7WM7QW) used for the bastion.

## Important Configuration Notes

- Public IPs will not be provisioned for this template.
- This template downloads and renders custom configs (i.e. cloud-init or bash script) as external files and therefore, the custom configs must be reachable from the Virtual Machine (i.e. routing to any remotely hosted files must be provided for outside of this template).
- Examples of custom configs are provided under the scripts directory.
- This template uses the Linux CentOS 7 as Virtual Machine operational system.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| bastionSecurityGroupId | No | ID of Security Group to apply to Bastion. |
| mgmtSubnet | No | Private subnet names for the stack in case of standalone template. |
| mgmtSubnets | No | Private subnet names for the stack. |
| mgmtSecurityGroupId | No | ID of Security Group to apply to Bastion host(s). |
| cost | No | Cost Center Tag. |
| createAutoscaleGroup | No | Choose 'true' to create the bastion instances in an autoscaling configuration. |
| customImageId | No | Custom Image AMI ID you wish to deploy. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| instanceType | No | App EC2 instance type. For example: `t2.small`. |
| owner | No | Application Tag. |
| restrictedSrcAddress | Yes | The IP address range that can be used to SSH to the EC2 instances. |
| scalingMaxSize | No | The maximum number of BIG-IP instances (2-100) that can be created in the Autoscale Group. |
| scalingMinSize | No | The minimum number of BIG-IP instances (1-99) you want available in the Autoscale Group. |
| sshKey | Yes | Name of an existing EC2 KeyPair to enable SSH access to the instance. |
| staticIp | No | The private IP address to apply as the primary private address. |
| uniqueString | Yes | Unique String used when creating object names or Tags. |
| vpc | Yes | Common VPC for the whole deployment. |

### Template Outputs

| Name | Description | Type |
| --- | --- | --- |
| stackName | Bastion nested stack name. | String |
| bastionAutoscaleGroupName | Autoscale Group name. | String |
| bastionInstanceId | Standalone Bastion Instance ID. | String |
| bastionPublicIp | Standalone Bastion Public IP address. | String |
