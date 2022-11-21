

# Enable a Network Security on a Subnet

## Overview

This workflow responds to the reccomendation **Subnets should be associated with a network security group** by creating a network security and associating it with the subnet. When a NSG is associated with a subnet, the ACL rules apply to all the VM instances and integrated services in that subnet, but don't apply to internal traffic inside the subnet. 

> This workflow will also remediate **Internet-facing virtual machines should be protected with network security groups** and **Non-internet-facing virtual machines should be protected with network security groups**

## Requirements

- Resource Group **Contributor** rights to deploy the ARM Template
- The Logic App uses a system-assigned Managed Identity. You will need to assign the **Network Contributor** to applicable subscriptions to create and assocaite network security groups. 

## Expected Impact
There is no expected impact that will occur on exisitng resources when the network security group is created and associated with an existing subnets. The nsg created will only have the [default network security group rules](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#default-security-rules). Please test appropriately. 

## Deployment

You can deploy the main template by clicking on the button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>


## Configuration Options

### Network Security Group Name
The logic app leverages the parameter **defaultNSGName** which is used as the nsg name during creation. By default this is set to "default-nsg" and appended with the subnet name during creation. 

``` 
default-nsg-<subnet name>
```

### Default Rules

By default the network security group created will only have the [default network security group rules](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview#default-security-rules). If desired you can modify the logic app to include deny or allow rules during creation. 

1. From the logic app > Log app designer select **Parameters**
2. Update the **securityRules** parameters with properly formmated json
    * See examples 
3. Click **Save**
