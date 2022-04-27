# Deploying BIG-IP Autoscale Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)




## Contents

- [Deploying BIG-IP Autoscale Template](#deploying-bigip-autoscale-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Resources Provisioning](#resources-provisioning)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)



## Introduction

This solution uses an AWS CloudFormation template to launch a stack for provisioning an Autoscale Group of BIG-IP VEs. It also utilizes the BIG-IP Runtime Init tool to initialize and onboard the BIG-IP system.

  
## Prerequisites

  - This template requires the following resources:
    * Network module:
        * VPC
        * Subnets
    * Access module
        * IAM Instance Profile
    * DAG module
        * LoadBalancer
  
  
## Resources Provisioning

  * [Autoscale Group](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html)
  * [AutoScaling Launch Configuration](https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html)
  * [AutoScaling Scaling Policy](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scale-based-on-demand.html)
  * [CloudWatch Alarm](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
  * [SNS Topic](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html)

    
### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| bigIpExternalSecurityGroup | Yes | BIG-IP external security group. |
| bigIpInstanceProfile | Yes | BIG-IP instance profile with applied IAM policy. |
| bigIpRuntimeInitConfig | Yes | Delivery URL for config file (YAML/JSON) or JSON string. |
| bigIpRuntimeInitPackageUrl | Yes | URL for f5-bigip-runtime-init package. |
| bigIqLicenseRevokeSnsTopic | No | Provides SNS Topic ARN used for triggering Lambda Function for revoking license on BIG-IQ. |
| bigIqNotificationRole | No | The ARN of the IAM role to assign to the Lifecycle Hook. |
| costCenter | No | Cost Center Tag. |
| customImageId | No | If you would like to deploy using a custom BIG-IP image, provide the AMI ID. |
| environment | No | Environment Tag. |
| externalTargetGroup | No | External Load Balancer Target Group with BIG-IP VEs. |
| group | No | Group Tag. |
| highCpuThreshold | No | High CPU Percentage threshold to begin scaling up BIG-IP VE instance. |
| imageName | No | F5 BIG-IP Performance Type. |
| instanceType | No | Enter valid instance type. |
| internalTargetGroup | No | Internal Load Balancer Target Group with BIG-IP VEs. |
| licenseType | Yes | Specifies license type used for BIG-IP VE. |
| lowCpuThreshold | No | Low CPU Percentage threshold to begin scaling down BIG-IP VE instances. |
| maxBatchSize | No | Specifies the maximum number of instances that CloudFormation updates. |
| metricNameSpace | Yes | CloudWatch namespace used for custom metrics. This should match the namespace defined in your telemetry services declaration within bigipRuntimInitConfig. |
| minInstancesInService | No | Specifies the minimum number of instances that must be in service within the Auto Scaling group while CloudFormation updates old instances. |
| notificationEmail | Yes | Valid email address to send Auto Scaling event notifications. |
| owner | No | Application Tag. |
| pauseTime | No | The amount of time in seconds that CloudFormation pauses after making a change to a batch of instances to give those instances time to start software applications. |
| provisionPublicIp | No |  Whether or not to provision Public IP Addresses for the BIG-IP Network Interfaces. By default, no Public IP addresses are provisioned. |
| scaleInCpuThreshold | No | Low CPU Percentage threshold to begin scaling in BIG-IP VE instances. | 
| scaleInThroughputThreshold | No | Incoming throughput threshold to begin scaling in BIG-IP VE instances. | 
| scaleOutCpuThreshold | No | High CPU Percentage threshold to begin scaling out BIG-IP VE instances. | 
| scaleOutThroughputThreshold | No | Incoming throughput threshold to begin scaling out BIG-IP VE instances. |
| scalingMaxSize | No |  Maximum number of BIG-IP instances (2-100) that can be created in the Autoscale Group. |
| scalingMinSize | No | Minimum number of BIG-IP instances (1-99) you want available in the Autoscale Group. |
| snsEvents | No | Provide a list of SNS Topics used on Autoscale Group. |
| sshKey | Yes | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. | 
| subnets | Yes | Public or external subnets for the availability zones. | 
| throughput | No | Maximum amount of throughput for BIG-IP VE. |
| uniqueString | No | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| stackName | bigip-autoscale nested stack name | bigip-autoscale template deployment | String |
| bigIpAutoscaleGroup | BIG-IP Autoscale Group | None | String |
| snsTopic | SNS topic Autoscale should notify | None | String |

## Resource Creation Flow Chart


![Resource Creation Flow Chart](../../../images/aws-bigip-autoscale-module.png)






