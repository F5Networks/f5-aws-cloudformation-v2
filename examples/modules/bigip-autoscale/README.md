# Deploying BIGIP Autoscale Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)




## Contents

- [Deploying BIGIP Autoscale Template](#deploying-bigip-autoscale-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Resources Provisioning](#resources-provisioning)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)



## Introduction

This solution uses an AWS Cloud Formation template to launch a stack for provisioning Autoscale Group of BIGIP VEs as well as it utilizes BIGIP Runtime Init tool to initialize and onboard BIGIP system.

  
## Prerequisites

  - This template requires the following resources:
    * Network module:
        * VPC
        * Subnets
    * Acess module
        * IAM Instance Profile
    * DAG module
        * LoadBalancer
  
  
## Resources Provisioning

  * [Autoscale Group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)
  * [AutoScaling Launch Configuration](https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html)
  * [AutoScaling Scaling Policy](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scale-based-on-demand.html)
  * [Cloudwatch Alarm](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
  * [SNS Topic](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html)

    
### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| bigIpExternalSecurityGroup | Yes | BIG-IP external security group. |
| bigIpInstanceProfile | Yes | BIG-IP instance profile with applied IAM policy. |
| bigIpRuntimeInitConfig | Yes | Delivery URL for config file (YAML/JSON) or JSON string. |
| bigIpRuntimeInitPackageUrl | Yes | Url for f5-bigip-runtime-init package. |
| bigIqLicenseRevokeSnsTopic | No | Provides SNS Topic ARN used for triggering Lambda Function for revoking license on BIGIQ. |
| bigIqNotificationRole | No | The ARN of the IAM role to assign to the Lifecycle Hook. |
| costCenter | No | Cost Center Tag. |
| customImageId | No | If you would like to deploy using a custom BIG-IP image, provide the AMI Id. |
| environment | No | Environment Tag. |
| externalTargetGroup | No | External Load Balancer Targert Group with BIG-IP VEs. |
| group | No | Group Tag. |
| highCpuThreshold | No | High CPU Percentage threshold to begin scaling up BIG-IP VE instance. |
| imageName | No | F5 BIG-IP Performance Type. |
| instanceType | No | Enter valid instance type. |
| internalTargetGroup | No | Internal Load Balancer Target Group with BIG-IP VEs. |
| licenseType | Yes | Specifies licence type used for BIG-IP VE. |
| lowCpuThreshold | No | Low CPU Percentage threshold to begin scaling down BIG-IP VE instances. |
| metricNameSpace | Yes | CloudWatch namespace used for custom metrics. This should match the namespace defined in your telemetry services declaration within bigipRuntimInitConfig. |
| notificationEmail | Yes | Valid email address to send Auto Scaling event notifications. |
| owner | No | Application Tag. |
| provisionPublicIp | No |  Whether or not to provision Public IP Addresses for the BIG-IP Network Interfaces. By Default no Public IP addresses are provisioned. |
| scaleDownBytesThreshold | No | Incoming bytes threshold to begin scaling down BIG-IP VE instances. | 
| scaleUpBytesThreshold | No | Incoming bytes threshold to begin scaling up BIG-IP VE instances. |
| scalingMaxSize | No |  Maximum number of BIG-IP instances (2-100) that can be created in the Auto Scale Group. |
| scalingMinSize | No | Minimum number of BIG-IP instances (1-99) you want available in the Auto Scale Group. |
| snsEvents | No | Provides list of SNS Topics used on Autoscale Group. |
| sshKey | Yes | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. | 
| subnets | Yes | Public or external subnets for the availability zones. | 
| throughput | No | Maximum amount of throughput for BIG-IP VE. |


### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| stackName | bigip-autoscale nested stack name | bigip-autoscale template deployment | String |
| bigIpAutoscaleGroup | BIG-IP Autoscale Group | None | String |
| snsTopic | SNS topic Autoscale should notify | None | String |

## Resource Creation Flow Chart


![Resource Creation Flow Chart](../../../images/aws-bigip-autoscale-module.png)






