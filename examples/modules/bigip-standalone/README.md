# Deploying BIG-IP Standalone Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)



## Contents

- [Deploying BIG-IP Standalone Template](#deploying-bigip-standalone-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Resources Provisioning](#resources-provisioning)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)
  - [Customization options](#customization-options)
    - [Multiple secondary private external IP addresses](#multiple-secondary-private-external-ip-addresses)
    - [Multiple public external IP addresses](#multiple-public-external-ip-addresses)


## Introduction

This solution uses an AWS CloudFormation template to launch a stack for provisioning a standalone BIG-IP VE.

  
## Prerequisites

  - This template requires the following cloud resources:
      * VPC
      * Subnet(s)
      * Security Group(s)
      * IAM Instance Profile
  
  
## Resources Provisioning

  * [EC2 Instance](https://aws.amazon.com/ec2/)
  * [Network Interface](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)

    
### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| bigIpInstanceProfile | No | BIG-IP instance profile with applied IAM policy. |
| bigIpRuntimeInitConfig | Yes | Delivery URL for config file (YAML/JSON) or JSON string. |
| bigIpRuntimeInitPackageUrl | No | URL for BIG-IP Runtime Init package. |
| bigIpPeerAddr | No | Type the static self IP address of the remote host here. Set to empty string if not configuring peering with a remote host on this device. |
| cfeTag | No | Cloud Failover deployment tag value. |
| cost | No | Cost Center Tag. |
| environment | No | Environment Tag. |
| externalPrimaryPublicId | No | The resource ID of the public IP address to apply to the primary IP configuration on the external network interface. The default is an empty string which does not provision public IP. |
| externalSecurityGroupId | No | The optional resource ID of a security group to apply to the external network interface. |
| externalSelfIp | No | The private IP address to apply to external network interfaces as primary private address. The address must reside in the subnet provided in the externalSubnetId parameter. ***Note:*** When set to an empty string, DHCP will be used for allocating the IP address. The default value is empty string. |
| externalServiceIps | No | An array of one or more private IP addresses to apply to the secondary external IP configurations. |
| externalSubnetId | No | The resource ID of the external subnet. ***Note:*** SubnetId parameters used for identifying number of network interfaces. Example: *1NIC* - only Mgmt subnet ID provided; *2NIC* - Mgmt and External subnets ID provided; *3NIC* - Mgmt, External, and Internal subnets ID provided. |
| group | No | Group Tag. |
| imageId | Yes | Provide BIG-IP AMI ID you wish to deploy. |
| instanceType | No | Enter valid instance type. |
| internalSecurityGroupId | No | The optional resource ID of a security group to apply to the internal network interface. |
| internalSelfIp | No | The private IP address to apply to the primary IP configuration on the internal network interface. The address must reside in the subnet provided in the internalSubnetId parameter.|
| internalSubnetId | No | The resource ID of the internal subnet. SubnetId parameters used for identifying number of network interfaces. Example: *1NIC* - only Mgmt subnet ID provided; *2NIC* - Mgmt and External subnets ID provided; *3NIC* - Mgmt, External, and Internal subnets ID provided. |
| mgmtPublicIpId | No | The resource ID of the public IP address to apply to the management network interface. Leave this parameter blank to create a management network interface without a public IP address. Default is empty string which does not provision public IP. |
| mgmtSecurityGroupId | Yes | The resource ID of a security group to apply to the management network interface. |
| mgmtSelfIp | No | The private IP address to apply to the primary IP configuration on the management network interface. The address must reside in the subnet provided in the mgmtSubnetId parameter. ***Note:*** When set to empty string, DHCP will be used for allocating ip address. |
| mgmtSubnetId | Yes | The resource ID of the management subnet. ***Note:*** SubnetId parameters used for identifying number of network interfaces. Example: *1NIC* - only Mgmt subnet ID provided; *2NIC* - Mgmt and External subnets ID provided; *3NIC* - Mgmt, External and Internal subnets ID provided.|
| owner | No | Application Tag. |
| sshKey | Yes | Supply the public key that will be used for SSH authentication to the BIG-IP and application virtual machines. | 
| uniqueString | Yes | Unique String used when creating object names or Tags. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| stackName | The bigip-standalone nested stack name. | bigip-standalone template deployment | String |
| bigIpInstanceId | BIG-IP instance ID. | None | String |
| bigIpManagementInterfacePrivateIp | Internally routable IP of BIG-IP instance NIC eth0.| None | String |
| bigIp2nicExternalInterfacePrivateIp | Internally routable IP of BIG-IP instance NIC eth1. | None | String |
| bigIp3NicExternalInterfacePrivateIp | Internally routable IP of BIG-IP instance NIC eth1. | None | String |
| bigIp3NicInternalInterfacePrivateIp | Internally routable IP of BIG-IP instance NIC eth2. | None | String |


## Resource Creation Flow Chart


![Resource Creation Flow Chart](../../../images/aws-bigip-standalone-module.png)


## Customization options

This section provides instuctions on how to customize BIG-IP standalone template for various use cases.

### Multiple secondary private external IP addresses 

The *externalServiceIps* parameter allows you to provide a list of secondary private external IP addresses. However, due to limitations in AWS CloudFormation DSL, it is not possible to dynamically add secondary IP addresses to the network interface. Instead, you can add secondary IP addresses by updating *BigIpStaticExternalInterface* resource and including the additional private addresses. The same approach can be used for private internal interface (aka *BigipStaticInternalInterface*). 

```yaml
  BigipStaticExternalInterface:
    Condition: useStaticExternalIpAddr
    Properties:
      Description: Public External Interface for the BIG-IP
      GroupSet:
        - !Ref externalNsgId
      PrivateIpAddresses:
        - Primary: 'true'
          PrivateIpAddress: !Ref externalSelfIp
        - Primary: 'false'
          PrivateIpAddress: !Select
            - '0'
            - !Ref externalServiceIps
        - Primary: 'false'
          PrivateIpAddress: !Select
            - '1'
            - !Ref externalServiceIps
        - Primary: 'false'
          PrivateIpAddress: !Select
            - '2'
            - !Ref externalServiceIps
      SubnetId: !Ref externalSubnetId
    Type: 'AWS::EC2::NetworkInterface'
```

### Multiple public external IP addresses

You can enable multiple public external addresses by using the following steps:

1. Create parameter for passing list of Elastic IP Allocation IDs.
 
```yaml
  externalPublicIpsAllocationIds:
    Description: >-
      List of public ip addresses allocations ids.
    Type: CommaDelimitedList

```

2. Create EIP Association resource for associating public IP with external network interface.
  
```yaml
  BigipVipEipAssociation00:
    Condition: useExternalPublicIP
    Properties:
      AllocationId: !Select
        - '0'
        - !Ref externalPublicIpsAllocationIds
      NetworkInterfaceId: !If
        - useDynamicExternalIpAddr
        - !Ref BigipExternalInterface
        - !Ref BigipStaticExternalInterface
      PrivateIpAddress: !If
        - useDynamicExternalIpAddr
        - !Select
          - '0'
          - !GetAtt
            - BigipExternalInterface
            - SecondaryPrivateIpAddresses
        - !Select
          - '0'
          - !GetAtt
            - BigipStaticExternalInterface
            - SecondaryPrivateIpAddresses
    Type: 'AWS::EC2::EIPAssociation'
  BigipVipEipAssociation01:
    Condition: useExternalPublicIP
    Properties:
      AllocationId: !Select
        - '1'
        - !Ref externalPublicIpsAllocationIds
      NetworkInterfaceId: !If
        - useDynamicExternalIpAddr
        - !Ref BigipExternalInterface
        - !Ref BigipStaticExternalInterface
      PrivateIpAddress: !If
        - useDynamicExternalIpAddr
        - !Select
          - '0'
          - !GetAtt
            - BigipExternalInterface
            - SecondaryPrivateIpAddresses
        - !Select
          - '0'
          - !GetAtt
            - BigipStaticExternalInterface
            - SecondaryPrivateIpAddresses
    Type: 'AWS::EC2::EIPAssociation'
```
