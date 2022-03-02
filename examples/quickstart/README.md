# Example Quickstart - BIG-IP Virtual Edition with WAF (LTM + ASM)

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Example Quickstart - BIG-IP Virtual Edition with WAF (LTM + ASM)](#example-quickstart---big-ip-virtual-edition-with-waf-ltm--asm)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Diagram](#diagram)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
    - [Existing Network Template Input Parameters](#existing-network-template-input-parameters)
    - [Existing Network Template Outputs](#existing-network-template-outputs)
  - [Deploying this Solution](#deploying-this-solution)
    - [Deploying via the AWS Launch Stack button](#deploying-via-the-aws-launch-stack-button)
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
  - [Deleting this Solution](#deleting-this-solution)
    - [Deleting this Solution using the AWS Console](#deleting-this-solution-using-the-aws-console)
    - [Deleting this Solution using the AWS CLI](#deleting-this-solution-using-the-aws-cli)
  - [Troubleshooting Steps](#troubleshooting-steps)
  - [Security](#security)
  - [BIG-IP Versions](#big-ip-versions)
  - [Documentation](#documentation)
  - [Getting Help](#getting-help)
    - [Filing Issues](#filing-issues)


## Introduction

With this solution, you can quickly deploy a BIG-IP and begin exploring the BIG-IP platform in a working full-stack deployment that can pass traffic.

This solution uses a parent template to launch several linked child templates (modules) to create an example BIG-IP solution. The linked templates are in the [examples/modules](https://github.com/F5Networks/f5-aws-cloudformation-v2/tree/main/examples/modules) directory in this repository. *F5 recommends you clone this repository and modify these templates to fit your use case.*

***Full Stack (quickstart.yaml)***<br>
Use the *quickstart.yaml* parent template to deploy an example full stack BIG-IP solution, complete with network, bastion *(optional)*, dag/ingress, bigip and application.  

***Existing Network Stack (quickstart-existing-network.yaml)***<br>
Use *quickstart-existing-network.yaml* parent template to deploy an example BIG-IP solution into an existing infrastructure. This template expects vpc and subnets have already been deployed. A demo application is also not part of this parent template as it intended use is for an existing environment.

The modules below create the following resources:

- **Network**: A virtual network (also known as VPC), subnets, internet/NAT gateways, DHCP options, network ACLs, and other network-related resources. *(Full stack only)*
- **Bastion**: This template creates a bastion host for accessing the BIG-IP instances when no public IP address is used for the management interfaces. *(Full stack only)*
- **Application**: A generic application for use when demonstrating live traffic through the BIG-IP. *(Full stack only)*
- **Disaggregation** *(DAG/Ingress)*: Resources required to get traffic to the BIG-IP, including AWS Security Groups and Public IP Addresses.
- **BIG-IP**: a BIG-IP instance provisioned with Local Traffic Manager (LTM) and Application Security Manager (ASM). 


By default, this solution creates a single Availability Zone VPC with four subnets, an example Web Application instance and a PAYG BIG-IP instance with three network interfaces (one for management and two for dataplane/application traffic - called external and internal). Application traffic from the Internet traverses an external network interface configured with both public and private IP addresses. Traffic to the application traverses an internal network interface configured with a private IP address.

***DISCLAIMER/WARNING***: To reduce prerequisites and complexity to a bare minimum for evaluation purposes only, this quickstart provides immediate access to the management interface via a Public IP (AWS EIP). At the very *minimum*, configure the **restrictedSrcAddressMgmt** parameter to limit access to your client IP or trusted network. In production deployments, management access should never be directly exposed to the Internet and instead should be accessed via typical management best practices like jumpboxes/bastion hosts, vpns, etc. 

## Diagram

![Configuration Example](diagram.png)

## Prerequisites


- An SSH Key pair in AWS for management access to BIG-IP VE. For more information about creating and/or importing the key pair in AWS, see AWS's SSH key [documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).
- Accepted the EULA for the F5 image in the AWS marketplace. If you have not deployed BIG-IP VE in your environment before, search for F5 in the Marketplace and then click **Accept Software Terms**. This only appears the first time you attempt to launch an F5 image. By default, this solution deploys the [F5 BIG-IP Best 25Mbps](https://aws.amazon.com/marketplace/pp/F5-Networks-F5-BIG-IP-Virtual-Edition-BEST-PAYG-25/B079C4WR32) images. For more information, see [K14810: Overview of BIG-IP VE license and throughput limits](https://support.f5.com/csp/article/K14810).
- The appropriate permission in AWS to launch CloudFormation (CFT) templates. You must be using an IAM user with the AdministratorAccess policy attached and have permission to create the objects contained in this solution. VPCs, Routes, EIPs, EC2 Instances. For details on permissions and all AWS configuration, see AWS's [documentation](https://aws.amazon.com/documentation/). 
- Sufficent **EC2 Resources** to deploy this solution. For more information, see AWS's resource limit [documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html). *NOTE:* The most likely resource limit to be hit by this solution is for Public IP addresses (AWS EIPs). This solution requires a minimum of two EIP addresses (for Single NIC deployments - one for the External Self-IP and one for an example Virtual Service) or three for Multi-Nic deployments (one for the Management Port, one for the External Self-IP and one for an example Virtual Service). By default, this solution deploys a 3NIC BIG-IP with 3 EIPs. 


## Important Configuration Notes

- By default, this solution creates a username **quickstart** with a **temporary** password set to value of the instance-id **bigIpInstanceId** which is provided in the output of the parent template. **IMPORTANT**: You should change this temporary password immediately following deployment. Alternately, you may remove the quickstart user class from the runtime-init configuration prior to deployment to prevent this user account from being created. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more details.

- This solution requires Internet Access for: 
  1. Downloading additional F5 software components used for onboarding and configuring the BIG-IP (via GitHub.com). Internet access is required via the management interface and then via a dataplane interface (for example, external Self-IP) once a default route is configured. See [Overview of Mgmt Routing](https://support.f5.com/csp/article/K13284) for more details. By default, as a convenience, this solution provisions Public IPs to enable this but in a production environment, outbound access should be provided by a `routed` SNAT service (for example, NAT Gateway, custom firewall, etc). *NOTE: access via web proxy is not currently supported. Other options include 1) hosting the file locally and modifying the runtime-init package url and configuration files to point to local URLs instead or 2) baking them into a custom image, using the [F5 Image Generation Tool](https://clouddocs.f5.com/cloud/public/v1/ve-image-gen_index.html).*
  2. Contacting native cloud services (for example, s3.amazonaws.com, ec2.amazonaws.com, etc.) for various cloud integrations: 
    - *Onboarding*:
        - [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) - to fetch secrets from native vault services
    - *Operation*:
        - [F5 Application Services 3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/) - for features like Service Discovery
        - [F5 Telemetry Streaming](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/) - for logging and reporting
        - [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/) - for updating IP and route mappings
      - Additional cloud services like [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) can be used to address calls to native services traversing the Internet.
  - See [Security](#security) section for more details. 

- This solution template provides an **initial** deployment only for an "infrastructure" use case (meaning that it does not support managing the entire deployment exclusively via the template's "Update-Stack" function). This solution leverages cloud-init to send the instance **user_data**, which is only used to provide an initial BIG-IP configuration and not as the primary configuration API for a long-running platform. Although "Update-Stack" can be used to update some cloud resources, as the BIG-IP configuration needs to align with the cloud resources, like IPs to NICs, updating one without the other can result in inconsistent states, while updating other resources, like the **imageName** or **instanceType**, can trigger an entire instance re-deloyment. For instance, to upgrade software versions, traditional in-place upgrades should be leveraged. See [AskF5 Knowledge Base](https://support.f5.com/csp/article/K84554955) and [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more information.

- If you have cloned this repository to modify the templates or BIG-IP config files and published to your own location (NOTE: CloudFormation can only reference S3 locations for templates and not generic URLs like from GitHub), you can use the **s3BucketName**, **s3BucketRegion** and **artifactLocation** input parameters to specify the new location of the customized templates and the **bigIpRuntimeInitConfig** input parameter to specify the new location of the BIG-IP Runtime-Init config. See main [/examples/README.md](../README.md#cloud-configuration) for more template customization details. See [Changing the BIG-IP Deployment](#changing-the-big-ip-deployment) for more BIG-IP customization details. 

- In this solution, the BIG-IP VE has the [LTM](https://f5.com/products/big-ip/local-traffic-manager-ltm) and [ASM](https://f5.com/products/big-ip/application-security-manager-asm) modules enabled to provide advanced traffic management and web application security functionality. 

- This solution has specifically been tested in AWS Commercial Cloud. Additional cloud environments such as AWS China Cloud have not yet been tested.

- This template can send non-identifiable statistical information to F5 Networks to help us improve our templates. You can disable this functionality by setting the **autoPhonehome** system class property value to false in the F5 Declarative Onboarding declaration. See [Sending statistical information to F5](#sending-statistical-information-to-f5).

- See [trouble shooting steps](#troubleshooting-steps) for more details.

### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| appContainerName | No | Application docker image name. |
| application | No | Application Tag. |
| bigIpCustomImageId | No | Provide BIG-IP AMI ID you wish to deploy. |
| bigIpImage | No | F5 BIG-IP Performance Type. |
| bigIpInstanceType | No | Enter valid instance type. |
| bigIpRuntimeInitConfig | No | URL or JSON string for BIGIP Runtime Init config. |
| bigIpRuntimeInitPackageUrl | No | Supply a URL to the bigip-runtime-init package |
| cost | No | Cost Center Tag. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| licenseType | No | Specifies licence type used for BIG-IP VE. Default is payg. If select byol, see additional configuration notes. |
| numAzs | No | Number of Availability Zones. Default = 1 |
| numSubnets | No | Number of Subnets. NOTE: Quickstart requires leaving at Default = 4 as Application Subnet is hardcoded to be in 4th subnet |
| numNics | No | Number of interfaces to create on BIG-IP instance. Maximum of 3 allowed. Minimum of 1 allowed. |
| owner | No | Owner Tag. |
| provisionPublicIp | No | Whether or not to provision Public IP Addresses for the BIG-IP Management Network Interface. By default, Public IP addresses are provisioned. See the restrictedSrcAddressMgmt parameter below. If set to false, a bastion host will be provisioned instead. See [diagram](diagram-w-bastion.png). |
| restrictedSrcAddressMgmt | Yes | An IP address range (CIDR) used to restrict SSH and management GUI access to the BIG-IP Management or bastion host instances. **IMPORTANT**: The VPC CIDR is automatically added for internal use (access via bastion host, clustering, etc.). Please restrict the IP address range to your client, for example 'X.X.X.X/32'. Production should never expose the BIG-IP Management interface to the Internet. |
| restrictedSrcAddressApp | Yes | An IP address range (CIDR) that can be used to restrict access web traffic (80/443) to the BIG-IP instances, for example 'X.X.X.X/32' for a host, '0.0.0.0/0' for the Internet, etc. **NOTE**: The VPC CIDR is automatically added for internal use. |
| s3BucketRegion | No | AWS Region which contains the S3 Bucket containing templates |
| s3BucketName | No | S3 bucket name for the modules. S3 bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-). |
| artifactLocation | No | S3 key prefix for the Quickstart assets. Quickstart key prefix can include numbers, lowercase letters, uppercase letters, hyphens (-), and forward slash (/). |
| sshKey | Yes | Supply the key pair name as listed in AWS that will be used for SSH authentication to the BIG-IP and application virtual machines. Example: ``myAWSkey`` |
| subnetMask | No | Mask for subnets. Valid values include 16-28. Note supernetting of VPC occurs based on mask provided; therefore, number of networks must be >= to the number of subnets created. Mask for subnets. Valid values include 16-28. |
| throughput | No | Maximum amount of throughput for BIG-IP VE.. |
| version | No | Select version of BIG-IP you wish to deploy. |
| vpcCidr | No | CIDR block for the VPC. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| bastionInstanceId | Instance ID of standalone Bastion instance. | Bastion Module | string |
| bastionPublicIp | Public IP address of standalone Bastion instance. | Bastion Module | string |
| bigIpInstanceId | Instance ID of BIG-IP VE instance | BigipStandalone Module | string |
| bigIpManagementPrivateIp | Private management address | BigipStandalone Module | string |
| bigIpManagementPublicIp | Public management address | Dag Module | string |
| bigIpManagementSsh | SSH Command to Public Management IP | Dag Module | string |
| bigIpManagementUrl443 | Url to public management address | Dag Module | string |
| bigIpManagementUrl8443 | Url to public management address | Dag Module | string |
| vipPublicUrl | Url to public application address | Dag Module | string | 

### Existing Network Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| artifactLocation | No | S3 key prefix for the Quickstart assets. Quickstart key prefix can include numbers, lowercase letters, uppercase letters, hyphens (-), and forward slash (/). |
| bigIpExternalSubnetId | Yes | Subnet id used for BIGIP instance external interface. |
| bigIpInternalSubnetId | Yes | Subnet id used for BIGIP instance internal interface. |
| bigIpMgmtSubnetId | Yes | Subnet id used for BIGIP instance management interface. |
| bigIpRuntimeInitConfig | No | Supply a URL to the bigip-runtime-init configuration file in YAML or JSON format, or an escaped JSON string to use for f5-bigip-runtime-init configuration. |
| bigIpRuntimeInitPackageUrl | No | Supply a URL to the bigip-runtime-init package. |
| bigIpCustomImageId | No | Provide BIG-IP AMI ID you wish to deploy. |
| bigIpImage | No | F5 BIG-IP Performance Type. |
| bigIpInstanceType | No | Enter a valid instance type. |
| cost | No | Cost Center Tag. |
| environment | No | Environment Tag. |
| group | No | Group Tag. |
| owner | No | Owner Tag. |
| provisionPublicIp | No | Whether or not to provision Public IP Addresses for the BIG-IP Management Network Interface. By default, Public IP addresses are provisioned. See the restrictedSrcAddressMgmt parameter below. If set to false, a bastion host will be provisioned instead. See [diagram](diagram-w-bastion.png). |
| restrictedSrcAddressMgmt | Yes | An IP address range (CIDR) used to restrict SSH and management GUI access to the BIG-IP Management or bastion host instances. **IMPORTANT**: The VPC CIDR is automatically added for internal use (access via bastion host, clustering, etc.). Please restrict the IP address range to your client, for example 'X.X.X.X/32'. Production should never expose the BIG-IP Management interface to the Internet. |
| restrictedSrcAddressApp | Yes | An IP address range (CIDR) that can be used to restrict access web traffic (80/443) to the BIG-IP instances, for example 'X.X.X.X/32' for a host, '0.0.0.0/0' for the Internet, etc. **NOTE**: The VPC CIDR is automatically added for internal use. |
| s3BucketRegion | No | AWS Region which contains the S3 Bucket containing templates |
| sshKey | Yes | Supply the key pair name as listed in AWS that will be used for SSH authentication to the BIG-IP and application virtual machines. Example: ``myAWSkey`` |
| uniqueString | Yes | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| vpcId | Yes | Id for VPC to use with deployment. |

<br>

### Existing Network Template Outputs


| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| bigIpInstanceId | Instance ID of BIG-IP VE instance | BigipStandalone Module | string |
| bigIpManagementPrivateIp | Private management address | BigipStandalone Module | string |
| bigIpManagementPublicIp | Public management address | Dag Module | string |
| bigIpManagementSsh | SSH Command to Public Management IP | Dag Module | string |
| bigIpManagementUrl443 | Url to public management address | Dag Module | string |
| bigIpManagementUrl8443 | Url to public management address | Dag Module | string |
| vipPublicUrl | Url to public application address | Dag Module | string | 


## Deploying this Solution

Two options for deploying this solution:
  - Using the [Launch Stack button](#deploying-via-the-aws-launch-stack-button)
  - Using the [AWS CLI](#deploying-via-the-aws-cli)

### Deploying via the AWS Launch Stack button
The easiest way to deploy this CloudFormation template is to use the Launch button.<br>
**Important**: By default, the link takes you to an AWS console set to the us-east-1 region. Select the AWS region (upper right) in which you want to deploy after clicking the Launch Stack button. 

**Quickstart**<br>
<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=BigIp-Quickstart-Example&templateURL=https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v2.0.0.0/examples/quickstart/quickstart.yaml">
    <img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/></a>

**Quickstart Existing Network**<br>
<a href="https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=BigIp-Quickstart-Existing-Network-Example&templateURL=https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v2.0.0.0/examples/quickstart/quickstart-existing-network.yaml">
    <img src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/></a>

*Step 1: Specify template* 
  - Click "Next".

*Step 2: Specify stack details* 
  - Fill in the *REQUIRED* parameters. For example:
    - **sshKey**
    - **restrictedSrcAddressMgmt**
    - **restrictedSrcAddressApp**
  - Click "Next"

*Step 3: Configure Stack Options*
  - Click "Next".

*Step 4: Review*
  - Navigate to **Capabilities** > Check "Acknowledgment" Boxes.
  - Click **Create Stack**.

For next steps, see [Validating the Deployment](#validating-the-deployment).


### Deploying via the AWS CLI

By default, the templates in this repository are also publicly hosted on S3 at [https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/[VERSION]/](https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/). If you want deploy the template using the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), provide url of the parent template and REQUIRED parameters:

```bash
 aws cloudformation create-stack --region ${REGION} --stack-name ${STACK_NAME} \
  --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v2.0.0.0/examples/quickstart/quickstart.yaml \
  --parameters "ParameterKey=<KEY>,ParameterValue=<VALUE> ParameterKey=<KEY>,ParameterValue=<VALUE>"
```

or with a local parameters file (see `autoscale-parameters.json` example in this directory):
```bash
 aws cloudformation create-stack --region ${REGION} --stack-name ${STACK_NAME} \
  --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v2.0.0.0/examples/quickstart/quickstart.yaml \
  --parameters file://quickstart-parameters.json
```

Example:

```bash
 aws cloudformation create-stack --region us-east-1 --stack-name myQuickstart \
  --template-url https://f5-cft-v2.s3.amazonaws.com/f5-aws-cloudformation-v2/v2.0.0.0/examples/quickstart/quickstart.yaml \
  --parameters "ParameterKey=sshKey,ParameterValue=MY_SSH_KEY_NAME ParameterKey=restrictedSrcAddressMgmt,ParameterValue=55.55.55.55/32 ParameterKey=restrictedSrcAddressApp,ParameterValue=0.0.0.0/0"
```

For next steps, see [Validating the Deployment](#validating-the-deployment).



### Changing the BIG-IP Deployment


You will most likely want or need to change the BIG-IP configuration. This generally involves referencing or customizing a [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) configuration file and passing it through the **bigIpRuntimeInitConfig** template parameter.

**IMPORTANT**: Any URLs pointing to git **must** use the raw file format (for example, "raw.githubusercontent.com").

F5 has provided the following example configuration files in the `examples/quickstart/bigip-configurations` folder:

- These examples install Automation Tool Chain packages and create WAF-protected services for a PAYG licensed deployment.
  - `runtime-init-conf-1nic-payg.yaml`
  - `runtime-init-conf-2nic-payg.yaml`
  - `runtime-init-conf-3nic-payg.yaml`
- These examples install Automation Tool Chain packages and create WAF-protected services for a BYOL licensed deployment.
  - `runtime-init-conf-1nic-byol.yaml`
  - `runtime-init-conf-2nic-byol.yaml`
  - `runtime-init-conf-3nic-byol.yaml`
- `Rapid_Deployment_Policy_13_1.xml`: This ASM security policy is supported for BIG-IP 13.1 and later.

See [F5 BIG-IP Runtime Init](https://github.com/f5networks/f5-bigip-runtime-init) for more examples.

By default, this solution deploys a 3NIC BIG-IP using the example `runtime-init-conf-3nic-payg.yaml` runtime-init config file.

To deploy a **1NIC** instance:
  1. Update the **bigIpRuntimeInitConfig** input parameter to reference a corresponding `1nic` config file (for example, runtime-init-conf-1nic-payg.yaml )
  2. Update the **numNics** input parameter to **1**

To deploy a **2NIC** instance:
  1. Update the **bigIpRuntimeInitConfig** input parameter to reference a corresponding `2nic` config file (for example, runtime-init-conf-2nic-payg.yaml )
  2. Update the **numNics** input parameter to **2**


Some changes require republishing/rehosting configuration files (git, s3, etc). For example:

To deploy a **BYOL** instance:

  1. Edit/modify the Declarative Onboarding (DO) declaration in a corresponding `byol` runtime-init config file with the new `regKey` value. 

Example:
```yaml
          My_License:
            class: License
            licenseType: regKey
            regKey: AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE
```
  2. Publish/host the customized runtime-init config file at a location reachable by the BIG-IP at deploy time (for example: git, S3, etc.). 
  3. Update the **bigIpRuntimeInitConfig** input parameter to reference the new URL of the updated configuration.
  4. Update the **licenseType** input parameter to use `byol` or **bigIpCustomImageId** input parameter to a valid byol image.


In order deploy additional virtual services:

For illustration purposes, this solution pre-provisions IP addresses needed for an example virtual service and the runtime-init configurations contain an AS3 declaration with a virtual service. However, in practice, cloud-init runs once and is typically used for initial provisioning, not as the primary configuration API for a long-running platform. More typically in an infrastructure use case, virtual services are added post initial deployment and involves:
  1. *Cloud* - Provisioning additional IPs on the desired Network Interfaces.
      - [Assigning a Private IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/MultipleIP.html#ManageMultipleIP)
      - [Allocating a Public IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-allocating)
      - [Associating a Public IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-associating)
  2. *BIG-IP* - Creating Virtual Services that match those additional Secondary IPs.
      - Updating the [AS3](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/composing-a-declaration.html) declaration with additional Virtual Services (see **virtualAddresses:**).

*NOTE: For cloud resources, templates can be customized to pre-provision and update addtional resources (for example, various combinations of NICs, IPs, Public IPs, etc). Please see [Getting Help](#getting-help) for more information. For BIG-IP configurations, you can leverage any REST or Automation Tool Chain clients like [Ansible](https://ansible.github.io/workshops/exercises/ansible_f5/3.0-as3-intro/),[Terraform](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs/resources/bigip_as3), etc.*

## Validation

This section describes how to validate the template deployment, test the WAF service, and troubleshoot common problems.

### Validating the Deployment

To view the status of the example and module stack deployments in the AWS Console, navigate to **CloudFormation > Stacks > *Your stack name***. You should see a series of stacks, including one for the Parent Quickstart template as well as the Network, Application, DAG, BIG-IP nested templates. The creation status for each stack deployment should be "CREATE_COMPLETE".

Expected Deploy time for entire stack =~ 13-15 minutes.

If any of the stacks are in a failed state, proceed to the [Troubleshooting Steps](#troubleshooting-steps) section below.

### Accessing the BIG-IP

From Parent Template Outputs:
  - **Console**: Navigate to **CloudFormation > *STACK_NAME* > Outputs**.
  - **AWS CLI**: 
      ```bash
      aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME}  --query  "Stacks[0].Outputs" 
      ```

  - Obtain the Instance Id *(will be used for password later)*:
    - **Console**: Navigate to **CloudFormation > *STACK_NAME* > Outputs > *bigIpInstanceId***.
    - **AWS CLI**: 
        ```bash
        aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bigIpInstanceId'].OutputValue" --output text
        ```

  - Obtain the IP address of the BIG-IP Management Port:
    - **Console**: Navigate to **CloudFormation > *STACK_NAME* > Outputs > *bigIpManagementPublicIp***.
    - **AWS CLI**: 
      - Public IPs: 
          ```bash
          aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bigIpManagementPublicIp'].OutputValue" --output text
          ```
      - Private IPs: 
          ```bash 
          aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bigIpManagementPrivateIp'].OutputValue" --output text
          ```
    - Or if you are going through a bastion host (when **provisionPublicIP** = **false**):

        Obtain the Public IP address of the bastion host:
            ```bash 
            aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bastionPublicIp'].OutputValue" --output text
            ```
#### SSH
  
  - **SSH key authentication**: 
      ```bash
      ssh admin@${IP_ADDRESS_FROM_OUTPUT} -i ${YOUR_PRIVATE_SSH_KEY}
      ```
  - **Password authentication**: 
      ```bash 
      ssh quickstart@${IP_ADDRESS_FROM_OUTPUT}
      ``` 
      at prompt, enter your **bigIpInstanceId** (see above to obtain from template "Outputs")


- OR if you are going through a bastion host (when **provisionPublicIP** = **false**):

    From your desktop client/shell, create an SSH tunnel:
    ```bash
    ssh -i [keyname-passed-to-template.pem] -o ProxyCommand='ssh -i [keyname-passed-to-template.pem] -W %h:%p ubuntu@[BASTION-HOST-PUBLIC-IP]' admin@[BIG-IP-MGMT-PRIVATE-IP]
    ```

    Replace the variables in brackets before submitting the command.

    For example:
    ```bash
    ssh -i ~/.ssh/mykey.pem -o ProxyCommand='ssh -i ~/.ssh/mykey.pem -W %h:%p ubuntu@34.82.102.190' admin@10.0.1.11

#### WebUI 

1. Obtain the URL address of the BIG-IP Management Port.
    - *NOTE*: Multi-NIC, will use https://host. Single NIC will use https://host:8443. 
    - **Console**: Navigate to **CloudFormation > *STACK_NAME* > Outputs > *bigIpManagementUrl443* for multi-NIC or *bigIpManagementUrl8443* for single NIC**.
    - **AWS CLI**: 
      - 3-NIC (default): 
          ```bash
          aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bigIpManagementUrl443'].OutputValue" --output text
          ```
      - 1-NIC: 
          ```bash
          aws --region ${REGION} cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='bigIpManagementUrl8443'].OutputValue" --output text

    - OR when you are going through a bastion host (when **provisionPublicIP** = **false**):

        From your desktop client/shell, create an SSH tunnel:
        ```bash
        ssh -i [keyname-passed-to-template.pem] ubuntu@[BASTION-HOST-PUBLIC-IP] -L 8443:[BIG-IP-MGMT-PRIVATE-IP]:[BIGIP-GUI-PORT]
        ```
        For example:
        ```bash
        ssh -i ~/.ssh/mykey.pem ubuntu@34.82.102.190 -L 8443:10.0.1.11:443
        ```

        You should now be able to open a browser to the BIG-IP UI from your desktop:

        https://localhost:8443



2. Open a browser to the Management URL.
  - *NOTE: By default, the BIG-IP system's WebUI starts with a self-signed cert. Follow your browser's instructions for accepting self-signed certs (for example, if using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, click "Accept Risk and Continue").*
  - To Login: 
    - username: quickstart
    - password: **bigIpInstanceId** (see above to obtain from template "Outputs")


### Further Exploring

#### WebUI
 - Navigate to **Virtual Services**. 
    - From the drop down menu **Partition** (upper right), select Partition = `Tenant_1`.
    - Navigate to **Local Traffic > Virtual Servers**. You should see two Virtual Services (one for HTTP and one for HTTPS). This should show up as Green. Click on them to look at the configuration *(declared in the AS3 declaration)*.

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

1. Obtain the address of the WAF service:
  - **Console**: Navigate to **CloudFormation > *STACK_NAME* > Outputs > *vip1PublicUrl***. 
  - **AWS CLI**: 
      ```bash 
      aws --region ${REGION}  cloudformation describe-stacks --stack-name ${STACK_NAME} --query  "Stacks[0].Outputs[?OutputKey=='vip1PublicUrl'].OutputValue" --output text
      ```

2. Verify the application is responding:
  - Paste the IP address in a browser: ```https://${IP_ADDRESS_FROM_OUTPUT}```
      - *NOTE: By default, the Virtual Service starts with a self-signed cert. Follow your browsers instructions for accepting self-signed certs (for example, if using Chrome, click inside the page and type this "thisisunsafe". If using Firefox, click "Advanced" button, click "Accept Risk and Continue", etc.).*
  - Use curl: 
      ```shell
       curl -sko /dev/null -w '%{response_code}\n' https://${IP_ADDRESS_FROM_OUTPUT}
       ```

3. Verify the WAF is configured to block illegal requests:
    ```shell
    curl -sk -X DELETE https://${IP_ADDRESS_FROM_OUTPUT}
    ```
  - The response should include a message that the request was blocked, and a reference support ID.
    Example:
    ```shell
    $ curl -sko /dev/null -w '%{response_code}\n' https://55.55.55.55
    200
    $ curl -sk -X DELETE https://55.55.55.55
    <html><head><title>Request Rejected</title></head><body>The requested URL was rejected. Please consult with your administrator.<br><br>Your support ID is: 2394594827598561347<br><br><a href='javascript:history.back();'>[Go Back]</a></body></html>
    ```

## Deleting this Solution


### Deleting this Solution using the AWS Console

1. Navigate to **CloudFormation > Stacks**.

2. Select the radio button to highlight the Parent Template.

3. Click **Delete**.

4. At the confirm pop up "Deleting this stack will delete all stack resources. Resources will be deleted according to their DeletionPolicy. Learn more", click **Delete Stack**.

### Deleting this Solution using the AWS CLI

```bash
 aws cloudformation delete-stack --region ${REGION} --stack-name ${STACK_NAME}
```

## Troubleshooting Steps

There are generally two classes of issues:

1. Stack creation itself failed
2. Resource(s) within the stack failed to deploy

In the even that a template in the stack failed, click on the name of a failed stack and then click `Events`. Check the `Status Reason` column for the failed event for details about the cause. 

**When creating a GitHub issue for a template, please include as much information as possible from the failed CloudFormation stack events.**

Common deployment failure causes include:
- Required fields were left empty or contained incorrect values (input type mismatch, prohibited characters, etc) causing template validation failure
- Insufficient permissions to create the deployment or resources created by a deployment (IAM roles, etc)
- Resource limitations (exceeded limit of IP addresses or compute resources, etc)
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
- *GENERAL LOG TIP*: Search most critical error level errors first (for example, egrep -i err /var/log/<Logname>).

If you are unable to login to the BIG-IP instance, you can navigate to **EC2 > Instances**, select the check box next to the instance you want to troubleshoot, and then click **Actions > Monitor and Troubleshoot > Get System Log** or **Get Instance Screenshot** for potential logging to serial console.

```
aws ec2 get-console-output --region ${REGION}  --instance-id <ID>'
```


## Security

This CloudFormation template downloads helper code to configure the BIG-IP system:

- f5-bigip-runtime-init.gz.run: The self-extracting installer for the F5 BIG-IP Runtime Init RPM can be verified against a SHA256 checksum provided as a release asset on the F5 BIG-IP Runtime Init public GitHub repository, for example: https://github.com/F5Networks/f5-bigip-runtime-init/releases/download/1.3.2/f5-bigip-runtime-init-1.3.2-1.gz.run.sha256.
- F5 BIG-IP Runtime Init: The self-extracting installer script extracts, verifies, and installs the F5 BIG-IP Runtime Init RPM package. Package files are signed by F5 and automatically verified using GPG.
- F5 Automation Toolchain components: F5 BIG-IP Runtime Init downloads, installs, and configures the F5 Automation Toolchain components. Although it is optional, F5 recommends adding the extensionHash field to each extension install operation in the configuration file. The presence of this field triggers verification of the downloaded component package checksum against the provided value. The checksum values are published as release assets on each extension's public GitHub repository, for example: https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.30.0/f5-appsvcs-3.30.0-5.noarch.rpm.sha256

The following configuration file will verify the Declarative Onboarding and Application Services extensions before configuring AS3 from a local file:

```yaml
runtime_parameters: []
extension_packages:
    install_operations:
        - extensionType: do
          extensionVersion: 1.23.0
          extensionHash: bfe88c7cf3fdb24adc4070590c27488e203351fc808d57ae6bbb79b615d66d27
        - extensionType: as3
          extensionVersion: 3.30.0
          extensionHash: 47cc7bb6962caf356716e7596448336302d1d977715b6147a74a142dc43b391b
extension_services:
    service_operations:
      - extensionType: as3
        type: url
        value: file:///examples/declarations/as3.json
```

More information about F5 BIG-IP Runtime Init and additional examples can be found in the [GitHub repository](https://github.com/F5Networks/f5-bigip-runtime-init/blob/main/README.md).


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

These templates have only been explicitly tested and validated with the following versions of BIG-IP.

| BIG-IP Version | Build Number |
| --- | --- |
| 16.1.0 | 0.0.19 |
| 14.1.4.4 | 0.0.4 |

These templates leverage Runtime-Init, which requires BIG-IP Versions 14.1.2.6 and up, and are assumed compatible to work. 

## Documentation

For more information on F5 solutions for AWS, including manual configuration procedures for some deployment scenarios, see the AWS section of [Public Cloud Docs](http://clouddocs.f5.com/cloud/public/v1/).

For information on getting started using F5's CloudFormation templates on GitHub, see [Amazon Web Services: Solutions 101](https://clouddocs.f5.com/cloud/public/v1/aws/AWS_solutions101.html). 


## Getting Help

Due to the heavy customization requirements of external cloud resources and BIG-IP configurations in these solutions, F5 does not provide technical support for deploying, customizing, or troubleshooting the templates themselves. However, the various underlying products and components used (for example: [F5 BIG-IP Virtual Edition](https://clouddocs.f5.com/cloud/public/v1/), [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init), [F5 Automation Toolchain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) extensions, and [Cloud Failover Extension (CFE)](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/)) in the solutions located here are F5-supported and capable of being deployed with other orchestration tools. Read more about [Support Policies](https://www.f5.com/company/policies/support-policies). Problems found with the templates deployed as-is should be reported via a GitHub issue.

For help with authoring and support for custom CST2 templates, we recommend engaging F5 Professional Services (PS).


### Filing Issues

Use the **Issues** link on the GitHub menu bar in this repository for items such as enhancement or feature requests and bugs found when deploying the example templates as-is. Tell us as much as you can about what you found and how you found it.
