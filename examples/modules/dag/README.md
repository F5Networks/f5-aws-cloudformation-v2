# Deploying Dag/Ingress Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)




## Contents

- [Deploying Dag/Ingress Template](#deploying-dagingress-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Resources Provisioning](#resources-provisioning)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)



## Introduction

This solution uses an AWS Cloud Formation template to launch a stack for provisioning Dag/Ingress related items. This template can be deployed as a standalone; however the main intention is to use as a module for provisioning Dag/Ingress related resources:


  
## Prerequisites

  - None. This template does not require provisioning of additional resources.
  
  
## Resources Provisioning

   - [External Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-internet-facing-load-balancers.html)
   - [Internal Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-internal-load-balancers.html)
   - Public IP Addresses
     * Management
     * External 

### Template Input Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| application | No | Application Tag. |
| cost | No | Cost Center Tag. |
| createFailoverIngress | No | Creates Security Group rules to allow Config Sync and HA between peer BIG-IP instances |
| environment | No | Environment Tag. |
| externalSubnetAz1 | No | Availability Zone 1 External Subnet Id |
| externalSubnetAz2 | No | Availability Zone 2 External Subnet Id |
| group | No | Group Tag. |
| internalSubnetAz1 | No | Availability Zone 1 Internal Subnet Id |
| internalSubnetAz2 | No | Availability Zone 2 Internal Subnet Id |
| numberPublicExternalIpAddresses | No | Min 0, Max 4 - Number of external public ip address to create |
| numberPublicMgmtIpAddresses | No | Min 0, Max 4 - Number of public management ip addresses to create |
| owner | No | Application Tag. |
| provisionExternalBigipLoadBalancer | No | Flag to provision external Load Balancer |
| provisionInternalBigipLoadBalancer | No | Flag to provision internal Load Balancer |
| provisionPublicIp | No | Flag to provision Management and External Public IPs |
| restrictedSrcAddress | Yes |The IP address range used to SSH and access management GUI on the EC2 instances. |
| restrictedSrcAddressApp | Yes | The IP address range that can be used to access web traffic (80/443) to the EC2 |
| restrictedSrcPort | Yes | The management port used for BIGIP management GUI |
| uniqueString | Yes | Unique String used when creating object names or Tags |
| vpc | No | Provides VPC Id |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| stackName | DAG nested stack name | DAG template deployment | String |
| externalElasticLoadBalancer | External Load Balancer Id | None | string |
| externalElasticLoadBalancerDnsName | External Load Balancer DNS Name | None | string |
| externalTargetGroupHttps |  External Target Group Id | None | string |
| externalTargetGroupHttp |  External Target Group Id | None | string |  
| internalElasticLoadBalancer | Internal Load Balancer Id  | None | string |
| internalElasticLoadBalancerDnsName | Internal Load Balancer DNS Name  | None | string |
| internalTargetGroupHttps | Internal Target Group Id | None | string |
| internalTargetGroupHttp | Internal Target Group Id | None | string |
| bigIpManagementEipAddress01 | BIG-IP Management Public IP  | None | string |
| bigIpManagementEipAllocationId01 | Allocation Id for Elastic IP for BIG-IP Management Interface | None | string | 
| bigIpManagementEipAddress02 | BIG-IP Management Public IP  | None | string |
| bigIpManagementEipAllocationId02 | Allocation Id for Elastic IP for BIG-IP Management Interface | None | string | 
| bigIpManagementEipAddress03 | BIG-IP Management Public IP  | None | string |
| bigIpManagementEipAllocationId03 | Allocation Id for Elastic IP for BIG-IP Management Interface| None | string | 
| bigIpManagementEipAddress04 | BIG-IP Management Public IP  | None | string |
| bigIpManagementEipAllocationId04 | Allocation Id for Elastic IP for BIG-IP Management Interface | None | string | 
| bigIpExternalEipAddress00 | BIG-IP External Public IP  | None | string |
| bigIpExternalEipAllocationId00 | Allocation Id for Elastic IP for BIG-IP External Interface | None | string | 
| bigIpExternalEipAddress01 | BIG-IP External Public IP  | None | string |
| bigIpExternalEipAllocationId01 | Allocation Id for Elastic IP for BIG-IP External Interface| None | string | 
| bigIpExternalEipAddress02 | BIG-IP External Public IP  | None | string |
| bigIpExternalEipAllocationId02 | Allocation Id for Elastic IP for BIG-IP External Interface | None | string | 
| bigIpExternalEipAddress03 | BIG-IP External Public IP  | None | string |
| bigIpExternalEipAllocationId03 | Allocation Id for Elastic IP for BIG-IP External Interface | None | string | 
| bigIpExternalEipAddress04 | BIG-IP External Public IP  | None | string |
| bigIpExternalEipAllocationId04 | Allocation Id for Elastic IP for BIG-IP External Interface | None | string | 
| bigIpExternalSecurityGroup | BIG-IP Security Group Id | None | string |
| appSecurityGroupId | Application Security Group Id | None | string |  

## Resource Creation Flow Chart


![Resource Creation Flow Chart](../../../images/aws-dag-module.png)






