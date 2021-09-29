
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

This Cloudformation template creates Telemetry module intended to setup infrastructure (i.e. CloudWatch) to enable Remote Logging

## Prerequisites

 - None
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add telemetry.yaml as a linked template into your templated solution.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| cost | No | Cost Center Tag. |
| cloudWatchLogGroupName | No | The name of the CloudWatch Log Group. |
| cloudWatchLogStreamName | No | The name of the CloudWatch Log Stream. |
| cloudWatchDashboardName | No | The name of the CloudWatch Dashboard. |
| createCloudWatchDashboard | No | Choose true to create CloudWatch Dashboard. If true, Log Group Name and metricsNameSpace are required. |
| createCloudWatchLogGroup | No | Choose true to create CloudWatch Log Group. |
| createCloudWatchLogStream | No | Choose true to create CloudWatch Log Stream. Log Group Name must be provided. |
| createS3Bucket | No | Choose true to creates S3 Bucket. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| metricNameSpace | No | CloudWatch namespace used for custom metrics. This should match the namespace defined in your telemetry services declaration within bigipRuntimInitConfig. |
| owner | No | Owner Tag. |
| s3BucketName | No | S3 bucket name for the WAF logs. S3 bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-). |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| cloudwatchLogGroup | CloudWatch Log Group Name | CloudWatch Log Group | string |
| cloudwatchLogStream | CloudWatch Log Stream Name | CloudWatch Log Stream  | string |
| cloudwatchDashboard | CloudWatch Dashboard | CloudWatch Dashboard | string |
| s3Bucket | S3 Bucket Name | S3 Bucket | string |
