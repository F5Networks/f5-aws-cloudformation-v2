
# Deploying Network Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Deploying Telemetry Template](#deploying-telemetry-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)

## Introduction

This CloudFormation template creates a Telemetry module intended to setup infrastructure (i.e. CloudWatch) to enable Remote Logging.

## Prerequisites

 - None
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add telemetry.yaml as a linked template into your templated solution.


### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details. 

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| application | No | f5app | string | Application Tag. |
| cost | No | f5cost | string | Cost Center Tag. |
| cloudWatchLogGroupName | No | f5telemetry | string | The name of the CloudWatch Log Group. |
| cloudWatchLogStreamName | No | f5-waf-logs | string | The name of the CloudWatch Log Stream. |
| cloudWatchDashboardName | No | F5-BIGIP-WAF-View | string | The name of the CloudWatch Dashboard. |
| createCloudWatchDashboard | No | false | boolean | Choose true to create CloudWatch Dashboard. If true, Log Group Name and metricsNameSpace are required. |
| createCloudWatchLogGroup | No | false | boolean | Choose true to create CloudWatch Log Group. |
| createCloudWatchLogStream | No | false | boolean | Choose true to create CloudWatch Log Stream. Log Group Name must be provided. |
| createS3Bucket | No | false | boolean | Choose true to creates S3 Bucket. |
| environment | No | f5env | string | Environment Tag. |
| group | No | f5group | ---string| Group Tag. |
| metricNameSpace | No | f5-scaling-metrics | string | CloudWatch namespace used for custom metrics. This should match the namespace defined in your telemetry services declaration within bigipRuntimInitConfig. |
| owner | No | f5owner | string | Owner Tag. |
| s3BucketName | No |  | string | S3 bucket name for the WAF logs. S3 bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-). |

### Template Outputs

| Name | Required Resource | Type | Description | 
| --- | --- | --- | --- |
| cloudwatchLogGroup | CloudWatch Log Group | string | CloudWatch Log Group Name | 
| cloudwatchLogStream | CloudWatch Log Stream  | string | CloudWatch Log Stream Name |
| cloudwatchDashboard | CloudWatch Dashboard | string | CloudWatch Dashboard |
| s3Bucket | S3 Bucket | string | S3 Bucket Name |
