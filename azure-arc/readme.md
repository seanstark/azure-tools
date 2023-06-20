# Azure ARC Related Tools

## Logic App - arc-unhealthymachines
The arc-unhealthymachines logic app will report on Azure Arc Unhealthy machines using the Azure Resource Graph Query and the below KQL Query.

``` kql
resources
| where type =~ 'microsoft.hybridcompute/machines'
| extend computerName = properties.osProfile.computerName, lastStatusChange = properties.lastStatusChange, status = properties.status, os = properties.osType, cloudprovider = properties.detectedProperties.cloudprovider, machineFqdn = properties.machineFqdn, hostName = properties.hostName, dnsFqdn = properties.dnsFqdn, osSku = properties.osSku, errorDetails = properties.errorDetails, extensionServiceStatus = properties.serviceStatuses.extensionService.status, guestConfigurationServiceStatus = properties.serviceStatuses.guestConfigurationService.status, agentVersion = properties.agentVersion
| extend awsInstanceId = properties['detectedProperties']['AWS-instanceId']
| extend awsAccountId = properties['detectedProperties']['AWS-accountId']
| extend gcpinstanceId = properties['detectedProperties']['GCP-instanceId']
| extend gcpProject = properties['detectedProperties']['GCP-projectNumber']
| where status == 'Disconnected' or extensionServiceStatus !in ('active', 'running')  or guestConfigurationServiceStatus !in ('active', 'running')
| project hostName, machineFqdn, dnsFqdn, agentVersion, cloudprovider, subscriptionId, resourceGroup, status, lastStatusChange, os, osSku, extensionServiceStatus, guestConfigurationServiceStatus, errorDetails, awsInstanceId, awsAccountId, gcpinstanceId, gcpProject
```

### Deployment

You can deploy the main template by clicking on the button below:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fseanstark%2Fazure-tools%2Fmain%2Fazure-arc%2Farc-unhealthymachines.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>


1. After you have deployed the logic app assign the system managed identity the following roles
    - Reader
