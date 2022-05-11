
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

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details.

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| application | No | f5app | string | Application Tag. |
| bastionSecurityGroupId | No |  | string | ID of Security Group to apply to Bastion. |
| mgmtSubnet | No |  | string | Private subnet names for the stack in case of standalone template. |
| mgmtSubnets | No |  | string | Private subnet names for the stack. |
| mgmtSecurityGroupId | No |  | string | ID of Security Group to apply to Bastion host(s). |
| cost | No | f5cost | string | Cost Center Tag. |
| createAutoscaleGroup | No | false | boolean | Choose 'true' to create the bastion instances in an autoscaling configuration. |
| customImageId | No |  | string | Custom Image AMI ID you wish to deploy. |
| environment | No | f5env | string | Environment Tag. |
| group | No | f5group | string | Group Tag. |
| instanceType | No | t2.small | string | App EC2 instance type. For example: `t2.small`. |
| owner | No | f5owner | string | Application Tag. |
| restrictedSrcAddress | Yes |  | string | An IP address or address range (in CIDR notation) used to restrict SSH and management GUI access to the BIG-IP Management or bastion host instances. **IMPORTANT**: The VPC CIDR is automatically added for internal use (access via bastion host, clustering, etc.). Please do NOT use "0.0.0.0/0". Instead, restrict the IP address range to your client or trusted network, for example "55.55.55.55/32". Production should never expose the BIG-IP Management interface to the Internet. |
| scalingMaxSize | No | 2 | integer | The maximum number of BIG-IP instances (2-100) that can be created in the Autoscale Group. |
| scalingMinSize | No | 1 | integer | The minimum number of BIG-IP instances (1-99) you want available in the Autoscale Group. |
| sshKey | Yes |  | string | Name of an existing EC2 KeyPair to enable SSH access to the instance. |
| staticIp | No |  | string | The private IP address to apply as the primary private address. |
| uniqueString | Yes | myUniqStr | string | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| vpc | Yes |  | string | Common VPC for the whole deployment. |

### Template Outputs

| Name | Required Resource | Type | Description | 
| --- | --- | --- | --- |
| stackName |  | string | Bastion nested stack name. |
| bastionAutoscaleGroupName |  | string | Autoscale Group name. |
| bastionInstanceId |  | string | Standalone Bastion Instance ID. |
| bastionPublicIp |  | string | Standalone Bastion Public IP address. |
