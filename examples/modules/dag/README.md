# Deploying DAG/Ingress Template

[![Releases](https://img.shields.io/github/release/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/releases)
[![Issues](https://img.shields.io/github/issues/f5networks/f5-aws-cloudformation-v2.svg)](https://github.com/f5networks/f5-aws-cloudformation-v2/issues)




## Contents

- [Deploying DAG/Ingress Template](#deploying-dagingress-template)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Resources Provisioning](#resources-provisioning)
    - [Template Input Parameters](#template-input-parameters)
    - [Template Outputs](#template-outputs)
  - [Resource Creation Flow Chart](#resource-creation-flow-chart)



## Introduction

This solution uses an AWS CloudFormation template to launch a stack for provisioning DAG/Ingress related items. This template can be deployed as a standalone, however the main intention is to use as a module for provisioning DAG/Ingress related resources:


  
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
| createFailoverIngress | No | Creates Security Group rules to allow Config Sync and HA between peer BIG-IP instances. |
| environment | No | Environment Tag. |
| externalSubnetAz1 | No | Availability Zone 1 External Subnet ID. |
| externalSubnetAz2 | No | Availability Zone 2 External Subnet ID. |
| group | No | Group Tag. |
| internalSubnetAz1 | No | Availability Zone 1 Internal Subnet ID. |
| internalSubnetAz2 | No | Availability Zone 2 Internal Subnet ID. |
| numberPublicExternalIpAddresses | No | Number of external public IP addresses to create. Value must be minimum 0 and maximum 4. |
| numberPublicMgmtIpAddresses | No | Number of public management IP addresses to create. Value must be minimum 0 and maximum 4.  |
| owner | No | Application Tag. |
| provisionExternalBigipLoadBalancer | No | Flag to provision external Load Balancer |
| provisionInternalBigipLoadBalancer | No | Flag to provision internal Load Balancer |
| provisionPublicIp | No | Flag to provision Management and External Public IPs |
| restrictedSrcAddress | Yes |The IP address range used to SSH and access the management GUI on the EC2 instances. |
| restrictedSrcAddressApp | Yes | The IP address range that can be used to access web traffic (80/443) to the EC2. |
| restrictedSrcPort | Yes | The management port used for BIG-IP management GUI. |
| uniqueString | Yes | Unique String used when creating object names or Tags. |
| vpc | No | Provide VPC ID. |

### Template Outputs

| Name | Description | Required Resource | Type |
| --- | --- | --- | --- |
| stackName | DAG nested stack name. | DAG template deployment | String |
| externalElasticLoadBalancer | External Load Balancer ID. | None | String |
| externalElasticLoadBalancerDnsName | External Load Balancer DNS Name. | None | String |
| externalTargetGroupHttps |  External Target Group ID. | None | String |
| externalTargetGroupHttp |  External Target Group ID. | None | String |  
| internalElasticLoadBalancer | Internal Load Balancer ID. | None | String |
| internalElasticLoadBalancerDnsName | Internal Load Balancer DNS Name.  | None | String |
| internalTargetGroupHttps | Internal Target Group ID. | None | String |
| internalTargetGroupHttp | Internal Target Group ID. | None | String |
| bigIpManagementEipAddress01 | BIG-IP Management Public IP.  | None | String |
| bigIpManagementEipAllocationId01 | Allocation ID for Elastic IP for BIG-IP Management Interface. | None | String | 
| bigIpManagementEipAddress02 | BIG-IP Management Public IP.  | None | String |
| bigIpManagementEipAllocationId02 | Allocation ID for Elastic IP for BIG-IP Management Interface. | None | String | 
| bigIpManagementEipAddress03 | BIG-IP Management Public IP.  | None | String |
| bigIpManagementEipAllocationId03 | Allocation ID for Elastic IP for BIG-IP Management Interface. | None | String | 
| bigIpManagementEipAddress04 | BIG-IP Management Public IP.  | None | String |
| bigIpManagementEipAllocationId04 | Allocation ID for Elastic IP for BIG-IP Management Interface. | None | String | 
| bigIpExternalEipAddress00 | BIG-IP External Public IP.  | None | String |
| bigIpExternalEipAllocationId00 | Allocation ID for Elastic IP for BIG-IP External Interface. | None | String | 
| bigIpExternalEipAddress01 | BIG-IP External Public IP.  | None | String |
| bigIpExternalEipAllocationId01 | Allocation ID for Elastic IP for BIG-IP External Interface. | None | String | 
| bigIpExternalEipAddress02 | BIG-IP External Public IP.  | None | String |
| bigIpExternalEipAllocationId02 | Allocation ID for Elastic IP for BIG-IP External Interface. | None | String | 
| bigIpExternalEipAddress03 | BIG-IP External Public IP.  | None | String |
| bigIpExternalEipAllocationId03 | Allocation ID for Elastic IP for BIG-IP External Interface. | None | String | 
| bigIpExternalEipAddress04 | BIG-IP External Public IP.  | None | String |
| bigIpExternalEipAllocationId04 | Allocation ID for Elastic IP for BIG-IP External Interface. | None | String | 
| bigIpExternalSecurityGroup | BIG-IP Security Group ID. | None | String |
| appSecurityGroupId | Application Security Group ID. | None | String |  

## Resource Creation Flow Chart


![Resource Creation Flow Chart](../../../images/aws-dag-module.png)






