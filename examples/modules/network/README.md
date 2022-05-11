
# Deploying Network Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)

## Contents

- [Deploying Network Template](#deploying-network-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important Configuration Notes](#important-configuration-notes)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Understanding Subnet CIDR Assignments](#understanding-subnet-cidr-assignments)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)

## Introduction

This AWS template creates a virtual network and subnets required to support F5 solutions. Link this template to create networks and subnets required for F5 deployments.

## Prerequisites

 - None
 
## Important Configuration Notes

 - A sample template, 'sample_linked.json', has been included in this project. Use this example to see how to add network.yaml as a linked template into your templated solution.


### Template Input Parameters

**Required** means user input is required because there is no default value or an empty string is not allowed. If no value is provided, the template will fail to launch. In some cases, the default value may only work on the first deployment due to creating a resource in a global namespace and customization is recommended. See the Description for more details. 

| Parameter | Required | Default | Type | Description |
| --- | --- | --- | --- | --- |
| application | No | f5app | string | Application Tag. |
| cost | No | f5cost | string | Cost Center Tag. |
| environment | No | f5env | string | Environment Tag. |
| group | No | f5group | string | Group Tag. |
| numAzs | No | 2 | integer | Number of Availability Zones to use in the VPC. Region must support number of availability  zones entered. The minimum is 1 and maximum is 4.  |
| numSubnets | No | 3 | integer | Indicate the number of subnets to create. A minimum of 4 subnets required when provisionExampleApp = false |
| owner | No | f5owner | string | Application Tag. |
| setSubnet1Public | No | false | boolean | The value 'true' sets subnet1 in each AZ as a public subnet. The value 'false' sets subnet1 as a private network. |
| subnetMask | No | 24 | integer | Mask for subnets. Valid values include 16-28. Note: supernetting of VPC occurs based on mask provided; therefore, the number of networks must be >= to the number of subnets created. |
| uniqueString | Yes | myUniqStr | string | A prefix that will be used to name template resources. Because some resources require globally unique names, we recommend using a unique value. |
| vpcCidr | No | 10.0.0.0/16 | string | CIDR block for the VPC. |
| vpcTenancy | No | default | string | The allowed tenancy of instances launched into the VPC. Valid values include 'default' or 'dedicated' |

### Template Outputs

| Name | Required Parameter Value | Type | Description |
| --- | --- | --- | --- |
| stackName | Network template deployment | string | Network nested stack name. |
| natEipA | numAzs > 0 | string | IP address used for NAT gateway assigned to subnets in availability zone A. |
| natEipB | numAzs > 1 | string | IP address used for NAT gateway assigned to subnets in availability zone B. |
| natEipC | numAzs > 2 | string | IP address used for NAT gateway assigned to subnets in availability zone C. |
| natEipD | numAzs > 3 | string | IP address used for NAT gateway assigned to subnets in availability zone D. |
| privateRouteTableIdA | setSubnet1Public = true or numSubnets > 2 | string | Route table ID assigned to private subnets in availability zone A. |
| privateRouteTableIdB | setSubnet1Public or numSubnets > 2 and numAzs > 1 | string | Route table ID assigned to private subnets in availability zone B. |
| privateRouteTableIdC | setSubnet1Public or numSubnets > 2 and numAzs > 2 | string |  Route table ID assigned to private subnets in availability zone C. |
| privateRouteTableIdD | setSubnet1Public or numSubnets > 2 and numAzs > 3 | string | Route table ID assigned to private subnets in availability zone D. |
| publicSubnetRouteTableId | N/A | string | Route table ID assigned to public subnets. |
| subnetsA |  numAzs > 0 | array | Comma separated list of subnet IDs created for availability zone A. IDs listed in order of subnet numerical value. For example: subnet0 1st value, subnet1 2nd value, etc. |
| subnetsB | numAzs > 1 | array | Comma separated list of subnet IDs created for availability zone B. IDs listed in order of subnet numerical value. For example: subnet0 1st value, subnet1 2nd value, etc. |
| subnetsC |  numAzs > 2 | array | Comma-separated list of subnet IDs created for availability zone C. IDs listed in order of subnet numerical value. For example: subnet0 1st value, subnet1 2nd value, etc. |
| subnetsD |  numAzs > 3 | array | Comma-separated list of subnet IDs created for availability zone D. IDs listed in order of subnet numerical value. For example: subnet0 1st value, subnet1 2nd value, etc. |
| vpcCidr | 10.X.X.0/16-24 | string |  IPv4 CIDR associated to VPC. |
| vpcId | N/A | string | VPC ID. |
| vpcIpv6Cidr | N/A | string | IPv6 CIDR associated to VPC. |

## Understanding Subnet CIDR Assignments

This template utilizes [Fn::Cidr](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-cidr.html) combined with mapping to generate and assign networks to subnets created. For example: ```!Cidr [ "10.0.0.0/16", 5, 8]``` will return a list of the first 5 supernetted networks using number of subnet bits equal to ```8: [ 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0.24, 10.0.4.0/24 ]```. To establish mask, subtract the number of CIDR bits from 32. For this example: 32-8=24.

Each subnet resource within the template has an assigned map value which is assessed against the returned CIDR list. 
Example IPv4 CIDR assignment:
- numAzs = 1
- numSubnets = 5
- subnetMask = 24
- vpcCidr = 10.0.0.0/16
  - returns map value from subnetMap: '5,0,1,2,3,4'
    - index 0 of map is used to define number of CIDRs to generate
    - resource subnet0A always uses index 1 from returned map to define which network to use from returned CIDR list
    - resource subnet1A always uses index 2 from returned map to define which network to use from returned CIDR list 
    - resource subnet2A always uses index 3 from returned map to define which network to use from returned CIDR list 
    - resource subnet3A always uses index 4 from returned map to define which network to use from returned CIDR list
    - resource subnet4A always uses index 5 from returned map to define which network to use from returned CIDR list 
  - returns the map value from maskTocidrBits: '8'
  - returns the VPC network CIDR value: '10.0.0.0/16'
- Returned values are used to populate CIDR function ```!Cidr [ "10.0.0.0/16", 5, 8]```
- Returned CIDR list is used to assign CIDRs to subnets: ```[ 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0.24, 10.0.4.0/24]```
  - resource subnet0A uses index value of 0 which returns 10.0.0.0/24
  - resource subnet1A uses index value of 1 which returns 10.0.1.0/24
  - resource subnet2A uses index value of 2 which returns 10.0.2.0/24
  - resource subnet3A uses index value of 3 which returns 10.0.3.0/24
  - resource subnet4A uses index value of 4 which returns 10.0.4.0/24
- IPv6 CIDRs are assigned using the same methodology with a couple differences:
  - VPC IPv6 CIDR is assigned by AWS by using AmazonProvidedIpv6CidrBlock=true
  - AWS IPv6 suernetting only supports /64
    - Example IPv6 CIDR function: ```!Cidr [ "2406:da12:629:2d00::/56", 5, 64 ]``` Subtract the number of CIDR bits from 128 to establish mask. For this example: 128-64=64.

## Resource Creation Flow Chart

![Resource Creation Flow Chart](../../../images/aws-network-module.png)
