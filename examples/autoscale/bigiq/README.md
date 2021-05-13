# Deploying the BIG-IP VE in AWS - Example Auto Scale BIG-IP WAF (LTM + ASM) - Autoscale Group (Frontend via ALB) - PAYG Licensing

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Deploying the BIG-IP VE in AWS - Example Auto Scale BIG-IP WAF (LTM + ASM) - Autoscale Group (Frontend via ALB) - PAYG Licensing](#deploying-the-big-ip-ve-in-aws---example-auto-scale-big-ip-waf-ltm--asm---autoscale-group-frontend-via-alb---payg-licensing)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Diagram](#diagram)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Deploying this Solution](#deploying-this-solution)
    - [Deploying via the AWS Launch Stack Button](#deploying-via-the-aws-launch-stack-button)
    - [Deploying via the AWS CLI](#deploying-via-the-aws-cli)
    - [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment)
  - [Validation](#validation)
    - [Validating the Deployment](#validating-the-deployment)
    - [Accessing the BIG-IP](#accessing-the-big-ip)
      - [SSH](#ssh)
      - [WebUI](#webui)
    - [Further Exploring](#further-exploring)
      - [WebUI](#webui-1)
      - [SSH](#ssh-1)
    - [Testing the WAF Service](#testing-the-waf-service)
  - [Updating this Solution](#updating-this-solution)
  - [Deleting this Solution](#deleting-this-solution)
      - [Deleting this Solution Using the AWS Console](#deleting-this-solution-using-the-aws-console)
      - [Deleting this Solution using the AWS CLI](#deleting-this-solution-using-the-aws-cli)
    - [Delete Cloudwatch Log Groups created by Lambda functions](#delete-cloudwatch-log-groups-created-by-lambda-functions)
      - [Deleting Log Groups using the AWS Console](#deleting-log-groups-using-the-aws-console)
      - [Deleting Log groups using the AWS CLI](#deleting-log-groups-using-the-aws-cli)
  - [Troubleshooting Steps](#troubleshooting-steps)
  - [Security](#security)
  - [BIG-IP Versions](#big-ip-versions)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)
  - [Documentation](#documentation)
  - [Getting Help](#getting-help)
    - [Filing Issues](#filing-issues)

## Introduction

This solution uses a parent template to launch several linked child templates (modules) to create a full example stack for the BIG-IP autoscale solution. The linked templates are located in the examples/modules directories in this repository. **F5 encourages you to clone this repository and modify these templates to fit your use case.** 

The modules below create the following resources:

- **Network**: This template creates AWS VPC, subnets.
- **Application**: This template creates a generic application for use when demonstrating live traffic through the BIG-IP system.
- **Disaggregation** *(DAG)*: This template creates resources required to get traffic to the BIG-IP, including AWS Security Groups, Public IP Addresses, internal/external Load Balancers, and accompanying resources such as load balancing rules, NAT rules, and probes.
- **Access**: This template creates an AWS InstanceProfile, IAM Roles.
- **BIG-IP**: This template creates the AWS Autoscale Group with F5 BIG-IP Virtual Editions provisioned with Local Traffic Manager (LTM) and Application Security Manager (ASM). Traffic flows from the AWS load balancer to the BIG-IP VE instances and then to the application servers. The BIG-IP VE(s) are configured in single-NIC mode. Auto scaling means that as certain thresholds are reached, the number of BIG-IP VE instances automatically increases or decreases accordingly. The BIG-IP module template can be deployed separately from the example template provided here into an "existing" stack.
- **Function**: This template creates AWS Lambda functions for revoking licenses from BIG-IP instances that were licensed via a BIG-IQ license pool or utility offer *(BIG-IQ only)*, looking up AMI by name, file cleanup, etc.

This solution leverages more traditional Auto Scale configuration management practices where each instance is created with an identical configuration as defined in the Autoscale Group's "model" (i.e. "launch config"). Scale Max sizes are no longer restricted to the small limitations of the cluster. The BIG-IP's configuration, now defined in a single convenient YAML or JSON [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init) configuration file, leverages [F5 Automation Tool Chain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations which are easier to author, validate, and maintain as code. For instance, if you need to change the configuration on the BIG-IPs in the deployment, you update the instance model by passing a new config file (which references the updated Automation Toolchain declarations) via the template's bigIpRuntimeInitConfig input parameter. New instances will be deployed with the updated configurations.  


## Diagram

![Configuration Example](diagram.png)

## Prerequisites


- An SSH Key pair in AWS for management access to BIG-IP VE. For more information about creating and/or importing the key pair in AWS, see AWS SSH key [documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).
- Accepted the EULA for the F5 image in the AWS marketplace. If you have not deployed BIG-IP VE in your environment before, search for F5 in the Marketplace and then click **Accept Software Terms**. This only appears the first time you attempt to launch an F5 image. By default, this solution deploys the [F5 BIG-IP Advanced WAF PAYG 25Mbps](https://aws.amazon.com/marketplace/pp/B08R5W828T) images. For more information, see [K14810: Overview of BIG-IP VE license and throughput limits](https://support.f5.com/csp/article/K14810).
- A BIG-IQ with License Manager (LM) configured with a valid license pool that is reachable by the BIG-IP system. See the [documentation](https://support.f5.com/csp/article/K77706009) for more details. ***NOTE: For this example solution, "reachable" implies the BIG-IQ LM has a Public IP and is reachable over the Internet. However, in a production deployment, the BIG-IQ would be internally routable (for example, with shared services VPC, VPN, etc.) ***
- A secret stored in AWS [Secrets Manager](https://aws.amazon.com/secrets-manager/) containing the password to use to obtain a license from BIG-IQ.
    ```bash
    # secret-string in single quotes to avoid bash special character interpolation
    aws secretsmanager create-secret --region ${REGION} --name ${YOUR_SECRET_NAME} --secret-string 'YOUR_BIGIQ_PASSWORD'
    ```
  - *NOTE: You will need both the Name/ID (for example, 'myBigIqSecret') and ARN (for example, 'arn:aws:secretsmanager:us-east-1:111111111111:secret:myBigIqSecret-xdg0kdf')*
- A remote log destination that is pre-provisioned in the same region. 
  - By default, this solution logs to a Cloudwatch destination:
    - logGroup: f5telemetry
    - logstream: f5-waf-logs
       ```bash
       aws logs create-log-group --region ${REGION} --log-group-name f5telemetry
       aws logs create-log-stream --region ${REGION} --log-group-name f5telemetry --log-stream-name f5-waf-logs
       ```
    - **Important**: If the destination above does not exist, the solution will deploy but BIG-IP's Telemetry Streaming will complain. 
  - See AWS [documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) for more information and [Changing the BIG-IP Deployment](#remote-logging) for customization details.
- You need the appropriate permission in AWS to launch CloudFormation Templates (CFT). You must be using an IAM user with the Administrator Access policy attached and have permission to create the objects contained in this solution (VPCs, Routes, EIPs, EC2 Instances, etc). For details on permissions and all AWS configuration, see AWS [documentation](https://aws.amazon.com/documentation/). 
- Sufficent **EC2 Resources** to deploy this solution. For more information, see AWS resource limit [documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html).


## Important Configuration Notes

- By default, this solution does not create a password authenticated BIG-IP user as it follows the immutable model (i.e. individual instances are not meant to be actively managed post-deployment, and configuration is instead defined through the model). However, sshKey is required here to provide minimal admin access. 
   -  **Disclaimer:** ***Accessing or logging into the instances themselves is for demonstration and debugging purposes only. All configuration changes should be applied by updating the model via the template instead. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more details.***

- In the autoscale model, instances are ephemeral so remote logging is required. By default, this example logs to Cloudwatch. However, there are many possible destinations. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more details.

- This solution requires Internet Access for: 
  1. Downloading additional F5 software components used for onboarding and configuring the BIG-IP (via github.com). By default and as a convenience, this solution provisions Public IPs to enable this, but in a production environment outbound access should be provided by a `routed` SNAT service (for example NAT Gateway, custom firewall, etc.). *NOTE: access via web proxy is not currently supported. Other options include 1) hosting the file locally and modifying the runtime-init package URL and configuration files to point to local URLs instead or 2) baking them into a custom image, using the [F5 Image Generation Tool](https://clouddocs.f5.com/cloud/public/v1/ve-image-gen_index.html) (BYOL only).*
  2. Contacting native cloud services (ex. s3.amazonaws.com, ec2.amazonaws.com, etc.) for various cloud integrations: 
    - *Onboarding*:
        - [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) - to fetch secrets from native vault services
    - *Operation*:
        - [F5 Application Services 3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/) - for features like Service Discovery
        - [F5 Telemetry Streaming](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/) - for logging and reporting
      - Additional cloud services like [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) can be used to address calls to native services traversing the Internet.
  - See [Security](#security) section for more details. 

- If you have cloned this repository in order to modify the templates or BIG-IP config files and published to your own location (NOTE: CloudFormation can only reference S3 locations for templates and not generic URLs like from GitHub), you can use the **s3BucketName**, **s3BucketRegion** and **artifactLocation** input parameters to specify the new location of the customized templates and the **bigIpRuntimeInitConfig** input parameter to specify the new location of the BIG-IP Runtime-Init config. See main [/examples/README.md](../../README.md#cloud-configuration) for more template customization details. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more BIG-IP customization details.

- In this solution, the BIG-IP VE has the [LTM](https://f5.com/products/big-ip/local-traffic-manager-ltm) and [ASM](https://f5.com/products/big-ip/application-security-manager-asm) modules enabled to provide advanced traffic management and web application security functionality. 

- This solution has specifically been tested in AWS Commercial Cloud. Additional cloud environments such as AWS China cloud have not yet been tested.

- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. You can disable this functionality by setting the **autoPhonehome** system class property value to false in the F5 Declarative Onboarding declaration. See [Sending statistical information to F5](#sending-statistical-information-to-f5).

- See [Troubleshooting steps](#troubleshooting-steps) for more details.


### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| appContainerName | No | The name of the public container used when configuring the application server. If this value is left blank, the application module template is not deployed. |
| application | No | Application Tag. |
| appScalingMaxSize | No | Maximum number of Application instances (2-50) that can be created in the Auto Scale Group. |
| appScalingMinSize | No | Minimum number of Application instances (1-49) you want available in the Auto Scale Group. |
| artifactLocation | No | The path in the S3Bucket where the modules folder is located. |
| bigIpCustomImageId | No | Provide BIG-IP AMI ID you wish to deploy. bigIpCustomImageId is required when bigIpImage is not specified. |
| bigIpImage | No | F5 BIG-IP market place image. See [Understanding AMI Lookup Function](../../modules/function/README.md#understanding-ami-lookup-function) for valid string options. bigIpImage is required when bigIpCustomImageId is not specified. | 
| bigIpInstanceType | No | Enter valid instance type. |
| bigIpRuntimeInitConfig | No | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format. |
| bigIpRuntimeInitPackageUrl | No | Supply a URL to the bigip-runtime-init package. |
| bigIpScaleInCpuThreshold | No | Low CPU Percentage threshold to begin scaling in BIG-IP VE instances. | 
| bigIpScaleInThroughputThreshold | No | Incoming bytes threshold to begin scaling in BIG-IP VE instances. | 
| bigIpScaleOutCpuThreshold | No | High CPU Percentage threshold to begin scaling out BIG-IP VE instances. | 
| bigIpScaleOutThroughputThreshold | No | Incoming bytes threshold to begin scaling out BIG-IP VE instances. |
| bigIpScalingMaxSize | No | Maximum number of BIG-IP instances (2-100) that can be created in the AutoScale Group. |
| bigIpScalingMinSize | No | Minimum number of BIG-IP instances (1-99) you want available in the AutoScale Group. |
| bigIqAddress | Yes | The IP address (or hostname) for the BIG-IQ used when licensing the BIG-IP. Note: The AWS function created by this template will make a REST call to the BIG-IQ (already existing) to revoke a license assignment when a BIG-IP instance is deallocated. This value should match the BIG-IQ address specified in the F5 Declarative Onboarding declaration passed to the bigIpRuntimeInitConfig template parameter. |
| bigIqAddressType | No | The type (public or private) of IP address or hostname for the BIG-IQ to be used when licensing the BIG-IP. Note: When using a private IP address or hostname, you must provide values for the bigIqSecurityGroupId and bigIqSubnetId parameters. |
| bigIqLicensePool | Yes | The BIG-IQ license pool to use during BIG-IP licensing via BIG-IQ. This value should match the BIG-IQ license pool specified in the F5 Declarative Onboarding declaration passed to the bigIpRuntimeInitConfig template parameter. |
| bigIqSecretArn | Yes | The ARN of the AWS secret containing the password used during BIG-IP licensing via BIG-IQ. |
| bigIqSecurityGroupId | No | The ID of the security group where BIG-IQ is deployed. You must provide a value for this parameter when using a private BIG-IP address. |
| bigIqSubnetId | No | The ID of the subnet where BIG-IQ is deployed. You must provide a value for this parameter when using a private BIG-IP address. |
| bigIqTenant | Yes | The BIG-IQ tenant used during BIG-IP licensing via BIG-IQ. This value should match the BIG-IQ tenant specified in the F5 Declarative Onboarding declaration passed to the bigIpRuntimeInitConfig template parameter. |
| bigIqUsername | Yes | The BIG-IQ username used during BIG-IP licensing via BIG-IQ. This value should match the BIG-IQ username specified in the F5 Declarative Onboarding declaration passed to the bigIpRuntimeInitConfig template parameter. |
| bigIqUtilitySku | No | The BIG-IQ utility license SKU used during BIG-IP licensing via BIG-IQ. This value should match the BIG-IQ utilty SKU specified in the F5 Declarative Onboarding declaration passed to the bigIpRuntimeInitConfig template parameter. |
| cost | No | Cost Center Tag. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| lambdaS3BucketName | Yes | S3 bucket with BIG-IQ Revoke function. |
| lambdaS3Key | Yes | The top-level key in the lambda S3 bucket where the lambda function is located. |
| loggingS3BucketName | No | The name of the existing S3 bucket where BIG-IP logs will be sent. |
| metricNameSpace | Yes | CloudWatch namespace used for custom metrics. This should match the namespace defined in your telemetry services declaration within bigipRuntimInitConfig. |
| notificationEmail | Yes | Valid email address to send Auto Scaling event notifications. |
| numAzs | No | Number of Availability Zones to use in the VPC. Region must support number of availability zones entered. The minimum is 1 and the maximum is 4. |
| numSubnets | No | Number of subnets per AZ to create. Subnets are labeled subnetx where x is the subnet number. The minimum is 1 and the maximum is 8. |
| owner | No | Application Tag. |
| provisionExternalBigipLoadBalancer | No | Flag to provision external Load Balancer. |
| provisionInternalBigipLoadBalancer | No | Flag to provision internal Load Balancer. |
| provisionPublicIp | No | Whether or not to provision Public IP Addresses for the BIG-IP Network Interfaces. By Default no Public IP addresses are provisioned. |
| restrictedSrcAddressApp | Yes | The IP address range that can be used to access web traffic (80/443) to the EC2 instances. |
| restrictedSrcAddressMgmt | Yes | The IP address range used to SSH and access management GUI on the EC2 instances. **IMPORTANT**: Please restrict to your client IP. |
| s3BucketName | No | S3 bucket name for the modules. S3 bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen. |
| s3BucketRegion | No | The AWS Region where the Quick Start S3 bucket (s3BucketName) is hosted. When using your own bucket, you must specify this value. |
| secretArn | No | The ARN of a Secrets Manager secret. |
| setPublicSubnet1 | No | Value of true sets subnet1 in each AZ as a public subnet, value of false sets subnet1 as private network. |
| snsEvents | No | Provides list of SNS Topics used on Autoscale Group. | 
| sshKey | Yes | Supply the key pair name as listed in AWS that will be used for SSH authentication to the BIG-IP and application virtual machines. For example, myAWSkey. |
| subnetMask | No | Mask for subnets. Valid values include 16-28. Note supernetting of VPC occurs based on the mask provided; therefore, number of networks must be >= to the number of subnets created. |
| uniqueString | Yes | Unique String used when creating object names or Tags. |
| vpcCidr | No | CIDR block for the VPC. |

### Template Outputs

| Name | Description | Type |
| --- | --- | --- |
| appAutoScaleGroupName | Application Auto Scale Group Name| String |
| bigIpAutoScaleGroupName | BIG-IP Auto Scale Group Name | String |
| wafExternalDnsName | WAF External DNS Name | String |
| wafExternalHttpsUrl | WAF External HTTPS URL | String |
| wafInternalDnsName | WAF Internal DNS Name | String |
| wafInternalHttpsUrl | WAF Internal HTTPS URL | String |
| amiId | AMI ID | String |

## Deploying this Solution

Be sure to check the [Prerequisites](#prerequisites) before you begin.
 
You have two options for deploying this solution:
  - Using the [Launch Stack button](#deploying-via-the-aws-launch-stack-button)
  - Using the [AWS CLI](#deploying-via-the-aws-cli)

### Deploying via the AWS Launch Stack Button

An easy first way to deploy this solution is to use the deploy button below. However, you must first provide/host a custom **bigIpRuntimeInitConfig** with your BIG-IQ information. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more details. <br>

**NOTE**: By default, the link takes you to an AWS console set to the us-east-1 region. Select the AWS region (upper right) in which you want to deploy after clicking the Launch Stack button. 

<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=BigIp-Autoscale-WAF-Example&templateURL=https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml">
    <img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/></a>


*Step 1: Specify template* 
  - Click "Next".

*Step 2: Specify stack details* 
  - Fill in the *REQUIRED* parameters. 
    - **sshKey**
    - **restrictedSrcAddressMgmt**
    - **restrictedSrcAddressApp**
    - **uniqueString**
    - **notificationEmail**
    - **bigIqAddress**
    - **bigIqAddressType**
    - **bigIqUsername**
    - **bigIqSecretArn**
    - **bigIqLicensePool**
    - **bigIqUtilitySku**
    - **bigIqTenant**
    - **bigIpRuntimeInitConfig** - *Pointing at new URL with your Custom BIG-IQ License Config* 
  - Click "Next".

*Step 3: Configure Stack Options*
  - Click "Next".

*Step 4: Review*
  - Go to Capabilities > Check "Acknowledgement" Boxes.
  - Click "Create Stack".

For next steps, see [Validating the Deployment](#validating-the-deployment).


### Deploying via the AWS CLI

By default, the templates in this repository are also publicly hosted on S3 at [https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/[VERSION]/](https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/)). If you want deploy the template using the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), provide the URL of the parent template and the required parameters:

```bash
 aws cloudformation create-stack --region ${REGION} --stack-name ${STACK_NAME} \
  --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml \
  --parameters "ParameterKey=<KEY>,ParameterValue=<VALUE> ParameterKey=<KEY>,ParameterValue=<VALUE>"
```

or with a local parameters file (see `autoscale-parameters.json` example in this directory):
```bash
 aws cloudformation create-stack --region us-east-1 --stack-name mywaf \
  --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml \
  --parameters file://autoscale-parameters.json
```

Example:

```bash
 aws cloudformation create-stack --region us-east-1 --stack-name mywaf \
  --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml \
  --parameters "ParameterKey=sshKey,ParameterValue=MY_SSH_KEY_NAME ParameterKey=restrictedSrcAddressMgmt,ParameterValue=55.55.55.55/32 ParameterKey=restrictedSrcAddressApp,ParameterValue=0.0.0.0/0 ParameterKey=uniqueString,ParameterValue=mywaf ParameterKey=bigIqAddress,ParameterValue=1.1.1.1 ParameterKey=bigIqAddressType,ParameterValue=public ParameterKey=bigIqUsername,ParameterValue=bigiq_license_user ParameterKey=bigIqSecretArn ParameterValue=arn:aws:secretsmanager:us-east-1:111111111111:secret:myBigIqSecret-xdg0kdf ParameterKey=bigIqLicensePool ParameterValue=myUtilityPool ParameterKey=bigIqUtilitySku,ParameterValue=F5-BIG-MSP-BT-1G ParameterKey=bigIqTenant,ParameterValue=myAutoScaleDeployment ParameterKey=bigIpRuntimeInitConfig,ParameterValue=https://raw.githubusercontent.com/myAccount/myRepo/0.0.1/runtime-init.conf" 
```

For next steps, see [Validating the Deployment](#validating-the-deployment).


### Changing the BIG-IP Deployment


For Bring Your Own License (BYOL) deployments, you will need to change the BIG-IP configuration. This involves customizing the licensing portion of Declarative Onboarding declaration in [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) configuration file, republishing/rehosting it, and passing a new URL through the **bigIpRuntimeInitConfig** template parameter.

**IMPORTANT**: Any URLs pointing to git **must** use the raw file format (for example, "raw.githubusercontent.com").

F5 has provided the following example configuration files in the `examples/autoscale/bigip-configurations` folder:

- `runtime-init-conf-bigiq.yaml`: This configuration file installs packages and creates WAF-protected services for a BIG-IQ licensed deployment.
- `runtime-init-conf-payg.yaml`: This configuration file installs packages and creates WAF-protected services for a PAYG licensed deployment.
- `Rapid_Deployment_Policy_13_1.xml`: This ASM security policy is supported for BIG-IP 13.1 and later.

See [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) for more examples.

By default, this solution references the example `runtime-init-conf-bigiq.yaml` runtime-init config file. However this file must be customized and republished before deploying. 


In order to change the BIG-IQ Licensing configuration:

  1. Edit/modify the Declarative Onboarding (DO) declaration in the runtime-init config file [runtime-init-conf-bigiq.yaml](../bigip-configurations/runtime-init-conf-bigiq.yaml) with the new `License` values. 

Example:
```yaml
          My_License:
            class: License
            hypervisor: aws
            licenseType: <YOUR_LICENSE_TYPE>
            licensePool: <YOUR_LICENSE_POOL>
            bigIqHost: <YOUR_BIG_IQ_HOST>
            bigIqUsername: <YOUR_BIG_IQ_USERNAME>
            bigIqPassword: '{{{BIGIQ_PASSWORD}}}'
            tenant: <YOUR_TENANT>
            skuKeyword1: <YOUR_SKU_KEYWORD>
            unitOfMeasure: <YOUR_UNIT_OF_MEASURE>
            reachable: false
```
  2. Edit/modify the BIG-IQ secret runtime-parameter in the runtime-init config file [runtime-init-conf-bigiq.yaml](../bigip-configurations/runtime-init-conf-bigiq.yaml) with your `secretId` value. 

```yaml
  - name: BIGIQ_PASSWORD
    type: secret
    secretProvider:
      type: SecretsManager
      environment: aws
      version: AWSCURRENT
      secretId: <YOUR_SECRET_NAME>
```
  3. Publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (for example, git, S3, etc.)
  4. Update the **bigIpRuntimeInitConfig** input parameter to reference the URL of the customized configuration file.
  5. Update the **bigIqSecretArn** input parameter with the ARN that corresponds to the customized **secretId** as well as the other required BIG-IQ related input parameters to match.
      - **bigIqAddress**
      - **bigIqAddressType**
      - **bigIqUsername**
      - **bigIqLicensePool**
      - **bigIqUtilitySku**
      - **bigIqTenant**


By default, this solution logs to a Cloudwatch destination:
  - logGroup: f5telemetry
  - logstream: f5-waf-logs
See [Prerequisites](#prerequisites).

In order to change the Cloudwatch logging group:

  1. Edit/modify the Telemetry Streaming (TS) declaration in a corresponding runtime-init config file [runtime-init-conf-bigiq.yaml](../bigip-configurations/runtime-init-conf-bigiq.yaml) with the new `logGroup` and `logStream` values. 

Example:
```yaml
        My_Cloudwatch:
          class: Telemetry_Consumer
          type: AWS_CloudWatch
          region: '{{{ REGION }}}'
          logGroup: <YOUR_CUSTOM_LOG_GROUP>
          logStream: <YOUR_CUSTOM_LOG_STREAM>
```
  2. Publish/host the cus tomized runtime-init config file at a location reachable by the BIG-IP at deploy time (for example, git, S3, etc.)
  3. Update the **bigIpRuntimeInitConfig** input parameter to reference the URL of the customized configuration file.


In order to log to an S3 Bucket:
  1. Ensure the target S3 Logging destination exists in same region. See AWS [documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-buckets-s3.html) for more information.
  2. Edit/modify the Telemetry Streaming (TS) declaration in the example runtime-init config file in the corresponding `bigiq`[runtime-init-conf-bigiq.yaml](../bigip-configurations/runtime-init-conf-bigiq.yaml) with the new `Telemetry_Consumer` configuration.

For example, Replace 
```yaml
        My_Cloudwatch:
          class: Telemetry_Consumer
          type: AWS_CloudWatch
          region: '{{{ REGION }}}'
          logGroup: f5telemetry
          logStream: f5-waf-logs
```
with: 
```yaml
        My_S3:
          class: Telemetry_Consumer
          type: AWS_S3
          region: '{{{ REGION }}}'
          bucket: <YOUR_BUCKET_NAME>
  ```
  3. Publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (ex. git, S3, etc.)
  4. Update the **bigIpRuntimeInitConfig** input parameter to reference the URL of the customized configuration file.
  5. Update the **loggingS3BucketName** input parameter with name of your logging destination. 
      - An IAM role will be created with permissions to log to that bucket.


In order to log to another remote destination that may require authentication:
  1. edit/modify the `runtime_parameters:` in the runtime-init config file to ADD a secret. Example: Add a section below with your `secretId` value. 

```yaml
  - name: LOGGING_API_KEY
    type: secret
    secretProvider:
      type: SecretsManager
      environment: aws
      version: AWSCURRENT
      secretId: <YOUR_SECRET_NAME>
```
  2. Edit/modify the Telemetry Streaming (TS) declaration in the example runtime-init config with the new `Telemetry_Consumer` configuration.

```yaml
        My_Consumer:
          class: Telemetry_Consumer
          type: Splunk
          host: <YOUR_HOST>
          protocol: https
          port: 8088
          passphrase:
            cipherText: '{{{ LOGGING_API_KEY }}}'
          compressionType: gzip
```
  3. Publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (for example: S3, git, etc.)
  4. Update the **bigIpRuntimeInitConfig** input parameter to reference the URL of the customized configuration file.
  5. Update **secretArn** with Arn for your `YOUR_SECRET_NAME`. 
     - An IAM role will be created with permissions to fetch that secret.


## Validation

This section describes how to validate the template deployment, test the WAF service, and troubleshoot common problems.

### Validating the Deployment

To view the status of the example and module stack deployments in the AWS Console, navigate to CloudFormation->Stacks->***Your stack name***. You should see a series of stacks, including one for the Parent Quickstart template as well as the Network, Application, DAG, BIG-IP nested templates. The creation status for each stack deployment should be "CREATE_COMPLETE". 

Expected Deploy time for entire stack =~ 15 minutes.

If any of the stacks are in a failed state, proceed to the [Troubleshooting Steps](#troubleshooting-steps) section below.

### Accessing the BIG-IP

As mentioned in [Configuration notes](#important-configuration-notes), by default, this solution does not create a password authenticated user and accessing or logging into the instances themselves is for demonstration or debugging purposes only.

From Template Outputs:
  - **Console**: Navigate to **CloudFormation > STACK_NAME > Outputs**
  - **AWS CLI**: 
      ```bash
      aws cloudformation describe-stacks --region ${REGION} --stack-name ${STACK_NAME}  --query  "Stacks[0].Outputs"
      ```

  - Obtain an Instance ID of one of the instances from the Autoscale Group:
    - **Console**:
      - Gather BigipAutoscaleGroup name
      - Navigate to CloudFormation->**STACK_NAME**->Outputs->**BigipAutoscaleGroup** 
      - Navigate to EC2->Autos Scaling Groups->**BigipAutoscaleGroup**->"Instance Management" Tab
    - **AWS CLI**: 
        ```bash
        aws cloudformation describe-stacks --region ${REGION} --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bigIpAutoscaleGroup'].OutputValue" --output text
        ```
        ```bash
        aws autoscaling describe-auto-scaling-groups --region ${REGION} --auto-scaling-group-name ${bigIpAutoscaleGroup} --query 'AutoScalingGroups[*].Instances[*]'
        ```

  - Obtain the IP address of the BIG-IP Mangement Port:
      - **Console**: Navigate to EC2->Instances->**INSTANCE_ID**->Instance Summary->**Public IPv4 address** or **Private IPv4 address**
      - **AWS CLI**: 
        - Public IPs: 
            ```bash
            aws ec2 describe-instances --region ${REGION} --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=${INSTANCE_ID}" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text
            ```
        - Private IPs: 
            ```bash
            aws ec2 describe-instances --region ${REGION} --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=${INSTANCE_ID}" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text
            ```

#### SSH

  - **SSH key authentication**: 
      ```bash
      ssh admin@${IP_ADDRESS_FROM_OUTPUT} -i ${YOUR_PRIVATE_SSH_KEY}
      ```

#### WebUI 

- As mentioned above, no password is configured by default. If you would like or need to login to the GUI for debugging or inspection, you can create a custom username/password by logging in to admin account via SSH (per above) and use tmsh to create one:
    At the TMSH prompt ```admin@(ip-10-0-0-100)(cfg-sync Standalone)(Active)(/Common)(tmos)#```:
      ```shell
      create auth user <YOUR_WEBUI_USERNAME> password <YOUR_STRONG_PASSWORD> partition-access add { all-partitions { role admin } }

      save sys config
      ```

- Open a browser to the Management IP
  - ```https://${IP_ADDRESS_FROM_OUTPUT}:8443```
  - NOTE: 
    - By default, for Single NIC deployments, the management port is 8443
    - By default, the BIG-IP's WebUI starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (ex. If using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, Click "Accept Risk and Continue" ).
  - To Login: 
    - username: `<YOUR_WEBUI_USERNAME>`
    - password: `<YOUR_STRONG_PASSWORD>`


### Further Exploring

#### WebUI
 - Navigate to Virtual Services 
    - From Drop Down Box named "Partition" *(Upper Right)*
      - Select Partition = `Tenant_1`
    - Navigate to Local Traffic *(Tabs on Left)*
        - Select `Virtual Servers`
          - You should see two Virtual Services (one for HTTP and one for HTTPS). The should show up as Green. Click on them to look at the configuration *(declared in the AS3 declaration)*

#### SSH

  - From tmsh shell, type 'bash' to enter the bash shell
    - Examine BIG-IP configuration via [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations:
    ```bash
    curl -u admin: http://localhost:8100/mgmt/shared/declarative-onboarding | jq .
    curl -u admin: http://localhost:8100/mgmt/shared/appsvcs/declare | jq .
    curl -u admin: http://localhost:8100/mgmt/shared/telemetry/declare | jq . 
    ```
  - Examine the Runtime-Init Config downloaded: 
    ```bash 
    cat /config/cloud/runtime-init.conf
    ```


### Testing the WAF Service

To test the WAF service, perform the following steps:
- Obtain the address of the WAF service:
  - **Console**: Navigate to CloudFormation>**STACK_NAME**->Outputs->**wafExternalHttpsUrl** 
  - **AWS CLI**: 
      ```bash
      aws cloudformation describe-stacks --region ${REGION} --stack-name ${STACK_NAME}  --query  "Stacks[0].Outputs[?OutputKey=='wafExternalHttpsUrl'].OutputValue" --output text
      ```


- Verify the application is responding:
  - Paste the IP address in a browser: ```https://${IP_ADDRESS_FROM_OUTPUT}```
      - NOTE: By default the Virtual Service starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (ex. If using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, Click "Accept Risk and Continue", etc. ).
  - Use curl: 
      ```shell
       curl -sko /dev/null -w '%{response_code}\n' https://${IP_ADDRESS_FROM_OUTPUT}
       ```
- Verify the WAF is configured to block illegal requests:
    ```shell
    curl -sk -X DELETE https://${IP_ADDRESS_FROM_OUTPUT}
    ```
  - The response should include a message that the request was blocked, and a reference support ID
    ex.
    ```shell
    $ curl -sko /dev/null -w '%{response_code}\n' https://55.55.55.55
    200
    $ curl -sk -X DELETE https://55.55.55.55
    <html><head><title>Request Rejected</title></head><body>The requested URL was rejected. Please consult with your administrator.<br><br>Your support ID is: 2394594827598561347<br><br><a href='javascript:history.back();'>[Go Back]</a></body></html>
    ```


## Updating this Solution

As mentioned in [Introduction](#introduction), this solution leverages more traditional Auto Scale configuration management practices where the entire configuration and lifecycle of each instance is exclusively managed via the Autoscale Group's "model" (i.e. "launch config"). If you need to change the configuration on the BIG-IPs in the deployment, you update the instance model by passing a new config file via template's **bigIpRuntimeInitConfig** input parameter. New instances will be deployed with the updated configurations according the Rolling Update Policy.

In order to update the BIG-IP configuration:

  1. edit/modify the runtime-init config file. 
  2. publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (ex. git, S3, etc.)
  3. Update the **bigIpRuntimeInitConfig** input parameter to reference the new URL of the updated configuration file.
      ex. if versioning with git tag
      - ```https://raw.githubusercontent.com/myAccount/myRepo/0.0.1/runtime-init.conf```
      - to
      - ```https://raw.githubusercontent.com/myAccount/myRepo/0.0.2/runtime-init.conf```
  4. Update the CloudFormation Stack with new **bigIpRuntimeInitConfig** parameter
      ```bash
      aws cloudformation update-stack --region ${REGION} --stack-name ${STACK_NAME} \
        --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml \
        --parameters "ParameterKey=bigIpRuntimeInitConfig,ParameterValue=https://<YOUR_NEW_LOCATION> ParameterKey=<KEY>,ParameterValue=<VALUE>"
      ```

All lifecycle elements are now managed by the model as well. For example:

In order to update the BIG-IP OS version:
  1. Update the CloudFormation Stack with new **imageName** parameter
      ```bash
      aws cloudformation update-stack --region ${REGION} --stack-name ${STACK_NAME} \
        --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml \
        --parameters "ParameterKey=imageName,ParameterValue=${imageName} ParameterKey=<KEY>,ParameterValue=<VALUE>"
      ```

In order to update the BIG-IP instance size:
  2. Update the CloudFormation Stack with new **instanceType** parameter
      ```bash
      aws cloudformation update-stack --region ${REGION} --stack-name ${STACK_NAME} \
        --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v0.0.0.1/examples/autoscale/bigiq/autoscale.yaml \
        --parameters "ParameterKey=instanceSize,ParameterValue=${instanceType} ParameterKey=<KEY>,ParameterValue=<VALUE>"
      ```

See [Launch Configuration](https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchConfiguration.html) and [Rolling Update](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html#cfn-attributes-updatepolicy-rollingupdate) documentation for more information.


## Deleting this Solution


#### Deleting this Solution Using the AWS Console

CloudFormation -> Stacks
  - Select Radio Button to highlight Parent Template
    - Click "Delete" (Upper Right)
      - At confirm pop up "Deleting this stack will delete all stack resources. Resources will be deleted according to their DeletionPolicy. Learn more"
      - Click "Delete Stack"

#### Deleting this Solution using the AWS CLI

```
 aws cloudformation delete-stack --region ${REGION} --stack-name ${STACK_NAME}
```

### Delete Cloudwatch Log Groups created by Lambda functions

By default, this solution creates log groups with the following naming convention

    - ```/aws/lambda/<STACK_NAME>-Function-<UNIQUE_STACK_STRING>-LambdaBigIqRevoke-<UNIQUE_OBJECT_STRING>``` 
    - ```/aws/lambda/<STACK_NAME>-Function-<UNIQUE_STACK_STRING>-AMIInfoFunction-<UNIQUE_OBJECT_STRING>``` 
    - ```/aws/lambda/<STACK_NAME>-Function-<UNIQUE_STACK_STRING>-CopyZipsFunction-<UNIQUE_OBJECT_STRING>``` 
    - ```/aws/lambda/<STACK_NAME>-Function-<UNIQUE_STACK_STRING>-LambdaDeploymentCleanup-<UNIQUE_OBJECT_STRING>``` 

that are not [deleted](https://github.com/aws/serverless-application-model/issues/1216) when the stack is deleted. 


#### Deleting Log Groups using the AWS Console
CloudWatch -> Log groups
  - Use Filter bar to filter for Log Groups with your stack name,:
    ```bash
    /aws/lambda/${STACK_NAME}-Function
    ``` 
    ex.
    ```bash
    /aws/lambda/mywaf-Function
    ```
  - Select Radio Button to highlight Log Group(s)
      - Click "Actions" Menu Button (Upper Right)
        - Select "Delete Log Group(s)" 

#### Deleting Log groups using the AWS CLI

```bash
aws logs delete-log-group --region ${REGION} --log-group-name ${LOG_GROUP_NAME}
```

ex. Simple bash loop to first LIST all log groups from a stack named "mywaf":
```bash
LOG_GROUPS_TO_SEARCH='/aws/lambda/mywaf-Function'; for i in $(aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUPS_TO_SEARCH} --query logGroups[].logGroupName --output text); do echo "Log Group: ${i}"; done
```

ex. Simple bash loop to DELETE all log groups from a stack named "mywaf":
```bash
LOG_GROUPS_TO_SEARCH='/aws/lambda/mywaf-Function'; for i in $(aws logs describe-log-groups --log-group-name-prefix ${LOG_GROUPS_TO_SEARCH} --query logGroups[].logGroupName --output text); do echo "Deleting Log Group: ${i}"; aws logs delete-log-group --log-group-name ${i}; done
```

## Troubleshooting Steps

There are generally two classes of issues:

1. Stack creation itself failed
2. Resource(s) within the stack failed to deploy

In the even that a template in the stack failed, click on the name of a failed stack and then click `Events`. Check the `Status Reason` column for the failed event for details about the cause. 

**When creating a Github issue for a template, please include as much information as possible from the failed CloudFormation stack events.**

Common deployment failure causes include:
- Required fields were left empty or contained incorrect values (input type mismatch, prohibited characters, etc.) causing template validation failure
- Insufficient permissions to create the deployment or resources created by a deployment (IAM roles, etc.)
- Resource limitations (exceeded limit of IP addresses or compute resources, etc.)
- AWS service issues (service health can be checked from the AWS [Service Health Dashboard](https://status.aws.amazon.com/)

If all stacks were created "successfully" but maybe the BIG-IP or Service is not reachable, then log in to the BIG-IP instance via SSH to confirm BIG-IP deployment was successful (for example, if startup scripts completed as expected on the BIG-IP). To verify BIG-IP deployment, perform the following steps:
- Obtain the IP address of the BIG-IP instance. See instructions [above](#accessing-the-bigip-ip)
- Check startup-script to make sure was installed/interpolated correctly:
  - ```cat /opt/cloud/instance/user-data.txt```
- Check the logs (in order of invocation):
  - cloud-init Logs:
    - */var/log/boot.log*
    - */var/log/cloud-init.log*
    - */var/log/cloud-init-output.log*
  - runtime-init Logs:
    - */var/log/cloud/startup-script.log*: This file contains events that happen prior to execution of f5-bigip-runtime-init. If the files required by the deployment fail to download, for example, you will see those events logged here.
    - */var/log/cloud/bigipRuntimeInit.log*: This file contains events logged by the f5-bigip-runtime-init onboarding utility. If the configuration is invalid causing onboarding to fail, you will see those events logged here. If deployment is successful, you will see an event with the body "All operations completed successfully".
  - Automation Tool Chain Logs:
    - */var/log/restnoded/restnoded.log*: This file contains events logged by the F5 Automation Toolchain components. If an Automation Toolchain declaration fails to deploy, you will see more details for those events logged here.
- *GENERAL LOG TIP*: Search most critical error level errors first (ex. egrep -i err /var/log/<Logname>).


If you are unable to login to the BIG-IP instance, you can navigate to EC2->Instances, select the check box next to the instance you want to troubleshoot, and then click Actions->Monitor and Troubleshoot->**Get System Log** or **Get Instance Screenshot** for potential logging to serial console.

```bash
aws ec2 get-console-output --region ${REGION}  --instance-id ${INSTANCE_ID}
```

If Licenses are not revoked from BIG-IQ after scaling down, check the Revoke Function's logs in Cloudwatch.

- Log Groups
  - Click on Log Group
    ```bash
    /aws/lambda/${STACK_NAME}-Function-<UNIQUE-STACK-STRING>-LambdaBigIqRevoke-<UNIQUE-OBJECT-STRING>
    ``` 
    ex. 
    ```bash
    /aws/lambda/mywaf-Function-1BFXP4VCXHV-LambdaBigIqRevoke-1QLU68ANVLHLO
    ```


## Security

This CloudFormation template downloads helper code to configure the BIG-IP system:

- f5-bigip-runtime-init.gz.run: The self-extracting installer for the F5 BIG-IP Runtime Init RPM can be verified against a SHA256 checksum provided as a release asset on the F5 BIG-IP Runtime Init public Github repository, for example: https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.2.0/f5-bigip-runtime-init-1.2.0-1.gz.run.sha256.
- F5 BIG-IP Runtime Init: The self-extracting installer script extracts, verifies, and installs the F5 BIG-IP Runtime Init RPM package. Package files are signed by F5 and automatically verified using GPG.
- F5 Automation Toolchain components: F5 BIG-IP Runtime Init downloads, installs, and configures the F5 Automation Toolchain components. Although it is optional, F5 recommends adding the extensionHash field to each extension install operation in the configuration file. The presence of this field triggers verification of the downloaded component package checksum against the provided value. The checksum values are published as release assets on each extension's public Github repository, for example: https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.26.0/f5-appsvcs-3.26.0-5.noarch.rpm.sha256

The following configuration file will verify the Declarative Onboarding and Application Services extensions before configuring AS3 from a local file:

```yaml
runtime_parameters: []
extension_packages:
    install_operations:
        - extensionType: do
          extensionVersion: 1.16.0
          extensionHash: 536eccb9dbf40aeabd31e64da8c5354b57d893286ddc6c075ecc9273fcca10a1
        - extensionType: as3
          extensionVersion: 3.23.0
          extensionHash: de615341b91beaed59195dceefc122932580d517600afce1ba8d3770dfe42d28
extension_services:
    service_operations:
      - extensionType: as3
        type: url
        value: file:///examples/declarations/as3.json
```

More information about F5 BIG-IP Runtime Init and additional examples can be found in the [Github repository](https://github.com/F5Networks/f5-bigip-runtime-init/blob/main/README.md).

List of endpoints BIG-IP may contact during onboarding:
- BIG-IP image default:
    - vector2.brightcloud.com (by BIG-IP image for [IPI subscription validation](https://support.f5.com/csp/article/K03011490) )
- Solution / Onboarding:
    - github.com (for downloading helper packages mentioned above)
    - f5-cft.s3.amazonaws.com (downloading GPG Key and other helper configuration files)
    - license.f5.com (licensing functions)
- Telemetry:
    - www-google-analytics.l.google.com
    - product-s.apis.f5.com.
    - f5-prod-webdev-prod.apigee.net.
    - global.azure-devices-provisioning.net.
    - id-prod-global-endpoint.trafficmanager.net.


## BIG-IP Versions

| BIG-IP Version | Build Number |
| --- | --- |
| 16.0.1.1 | 0.0.6 |
| 14.1.4 | 0.0.11 |


## Resource Creation Flow Chart

![Resource Creation Flow Chart](../../images/aws-payg-autoscale-example.png)


## Documentation

For more information on F5 solutions for AWS, including manual configuration procedures for some deployment scenarios, see the AWS section on [Clouddocs.f5.com](http://clouddocs.f5.com/cloud/public/v1/).

For information on getting started using F5's CloudFormation templates on GitHub, see [Amazon Web Services: Solutions 101](https://clouddocs.f5.com/cloud/public/v1/aws/AWS_solutions101.html). 


## Getting Help

Due to the heavy customization requirements of external cloud resources and BIG-IP configurations in these solutions, F5 does not provide technical support for deploying, customizing, or troubleshooting the templates themselves. However, the various underlying products and components used (for example: [F5 BIG-IP Virtual Edition](https://clouddocs.f5.com/cloud/public/v1/), [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init), [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) extensions, and [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/)) in the solutions located here are F5-supported and capable of being deployed with other orchestration tools. Read more about [Support Policies](https://www.f5.com/company/policies/support-policies). Problems found with the templates deployed as-is should be reported via a GitHub issue.

For help with authoring and support for custom CST2 templates, we recommend engaging F5 Professional Services (PS).


### Filing Issues

Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and bugs found when deploying the example templates as-is. Tell us as much as you can about what you found and how you found it.
