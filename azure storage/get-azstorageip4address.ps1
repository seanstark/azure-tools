<#
    .DESCRIPTION
        This script will resolve storage account primary and secondary endpoints to ipv4 addresses.
        The script will inventory storage accounts across all subscriptions by default

    .PARAMETER Subscription
        The name or id of the subscription that the context should be set to. You can enter one or more strings separated by commas for multiple subscriptions

    .NOTES
        You can access the resolved ipv4 addresses via the below properties:
        
        PrimaryBlobDNS								SecondaryBlobDNS
        PrimaryBlobIP4Address						SecondaryBlobIP4Address
        PrimaryQueueDNS								SecondaryQueueDNS
        PrimaryQueueIP4Address						SecondaryQueueIP4Address
        PrimaryTableDNS								SecondaryTableDNS
        PrimaryTableIP4Address						SecondaryTableIP4Address
        PrimaryFileDNS								SecondaryFileDNS
        PrimaryFileIP4Address						SecondaryFileIP4Address
        PrimaryWebDNS								SecondaryWebDNS
        PrimaryWebIP4Address						SecondaryWebIP4Address
        PrimaryDfsDNS								SecondaryDfsDNS
        PrimaryDfsIP4Address						SecondaryDfsIP4Address
        PrimaryMicrosoftEndpointsDNS				SecondaryMicrosoftEndpointsDNS
        PrimaryMicrosoftEndpointsIP4Address			SecondaryMicrosoftEndpointsIP4Address
        PrimaryInternetEndpointsDNS					SecondaryInternetEndpointsDNS
        PrimaryInternetEndpointsIP4Address  		SecondaryInternetEndpointsIP4Address

        Aggregated list IPv4 Addresses are stored in:
        PrimaryIP4Addresses
        SecondaryIP4Addresses
    
    .EXAMPLE
        Get Storage Accounts for all subscriptions
        $storageAccountReport = .\get-azstorageip4address.ps1

    .EXAMPLE
        Get Storage Accounts for a single subscription
        $storageAccountReport = .\get-azstorageip4address.ps1 -Subscription 'production resources'

    .EXAMPLE
        Get Storage Accounts for multiple subscriptions
        $storageAccountReport = .\get-azstorageip4address.ps1 -Subscription 'production resources','dev resources'

    .EXAMPLE
        Search for an IP Address
        $ip = '20.150.71.134'
        $storageAccountReport | Where-Object {$ip -in $_.PrimaryIP4Addresses -or $ip -in $_.SecondaryIP4Addresses}

    .EXAMPLE
        Select all endpoint names and IPv4
        $storageAccountReport | Select StorageAccountName,SubscriptionName,ResourceGroupName,PrimaryIP4Addresses,SecondaryIP4Addresses,PrimaryBlobDNS,PrimaryBlobIP4Address,PrimaryQueueDNS,PrimaryQueueIP4Address,PrimaryTableDNS,PrimaryTableIP4Address,PrimaryFileDNS,PrimaryFileIP4Address,PrimaryWebDNS,PrimaryWebIP4Address,PrimaryDfsDNS,PrimaryDfsIP4Address,PrimaryMicrosoftEndpointsDNS,PrimaryMicrosoftEndpointsIP4Address,PrimaryInternetEndpointsDNS,PrimaryInternetEndpointsIP4Address,SecondaryBlobDNS,SecondaryBlobIP4Address,SecondaryQueueDNS,SecondaryQueueIP4Address,SecondaryTableDNS,SecondaryTableIP4Address,SecondaryFileDNS,SecondaryFileIP4Address,SecondaryWebDNS,SecondaryWebIP4Address,SecondaryDfsDNS,SecondaryDfsIP4Address,SecondaryMicrosoftEndpointsDNS,SecondaryMicrosoftEndpointsIP4Address,SecondaryInternetEndpointsDNS,SecondaryInternetEndpointsIP4Address

    .EXAMPLE
        Export to CSV
        $storageAccountReport | Select StorageAccountName,SubscriptionName,ResourceGroupName,PrimaryIP4Addresses,SecondaryIP4Addresses,PrimaryBlobDNS,PrimaryBlobIP4Address,PrimaryQueueDNS,PrimaryQueueIP4Address,PrimaryTableDNS,PrimaryTableIP4Address,PrimaryFileDNS,PrimaryFileIP4Address,PrimaryWebDNS,PrimaryWebIP4Address,PrimaryDfsDNS,PrimaryDfsIP4Address,PrimaryMicrosoftEndpointsDNS,PrimaryMicrosoftEndpointsIP4Address,PrimaryInternetEndpointsDNS,PrimaryInternetEndpointsIP4Address,SecondaryBlobDNS,SecondaryBlobIP4Address,SecondaryQueueDNS,SecondaryQueueIP4Address,SecondaryTableDNS,SecondaryTableIP4Address,SecondaryFileDNS,SecondaryFileIP4Address,SecondaryWebDNS,SecondaryWebIP4Address,SecondaryDfsDNS,SecondaryDfsIP4Address,SecondaryMicrosoftEndpointsDNS,SecondaryMicrosoftEndpointsIP4Address,SecondaryInternetEndpointsDNS,SecondaryInternetEndpointsIP4Address | Export-Csv storageaccountreport.csv -NoTypeInformation

#>

param(
    [Parameter(Mandatory=$false,ValueFromPipeline = $true)]
    [Alias('Id')]
    [string[]]$Subscription
)

#Required Modules
# Check for required modules
$requiredModules = 'Az.Accounts', 'Az.Storage'
$availableModules = Get-Module -ListAvailable -Name $requiredModules
$modulesToInstall = $requiredModules | where-object {$_ -notin $availableModules.Name}
ForEach ($module in $modulesToInstall){
    Write-Host "Installing Missing PowerShell Module: $module" -ForegroundColor Yellow
    Install-Module $module -force
}

#Load Latest Version 
ForEach ($module in $requiredModules){
    Remove-Module $module -Force -Confirm:$false -ErrorAction SilentlyContinue
    (Get-Module -Name $module -ListAvailable | Sort-Object -Property Version)[-1] | Import-Module
}

If(!(Get-AzContext)){
    Write-Host 'Connecting to Azure Subscription' -ForegroundColor Yellow
    Connect-AzAccount -Subscription $Subscription[0] -WarningAction SilentlyContinue | Out-Null
}

If(!($Subscription)){
    $Subscription = Get-AzSubscription -WarningAction SilentlyContinue
}

$allStorageAccounts = @()

Write-Host ('Starting Inventory on {0} Subscriptions'-f $subscription.count) -ForegroundColor Green

ForEach ($sub in $subscription){
    
    $context = Set-AzContext -Subscription $sub -WarningAction SilentlyContinue
 
    Write-Host ('Starting Inventory on the {0} Subscription'-f $context.Subscription.Name) -ForegroundColor Yellow

    $storageAccounts = Get-AzStorageAccount 

    Write-Host ('Found a total of {0} storage accounts in {1}'-f $storageAccounts.Count, $context.Subscription.Name) -ForegroundColor Cyan

    forEach ($storageAccount in $storageAccounts){

        Write-Host ('Getting information on the {0} Storage Account'-f $storageAccount.StorageAccountName) -ForegroundColor Cyan

        $primaryIP4Addresses = @()
        $secondaryIP4Addresses = @()

        ForEach ($endpoint in $($storageAccount.PrimaryEndpoints | ConvertTo-Xml).Objects.Object.Property){

            if ($endpoint.'#text'){
                $dnsObject = Resolve-DnsName ([System.Uri]$endpoint.'#text').Host
            }else{
                $dnsObject = @{
                    Name = @($null)
                    IP4Address = $null
                }
            }
        
            $storageAccount | Add-Member -MemberType NoteProperty -Name ('Primary{0}DNS' -f $endpoint.Name) -Value $dnsObject.Name[0] -Force -ErrorAction SilentlyContinue
            $storageAccount | Add-Member -MemberType NoteProperty -Name ('Primary{0}IP4Address' -f $endpoint.Name) -Value $dnsObject.IP4Address -Force -ErrorAction SilentlyContinue
            $primaryIP4Addresses += $dnsObject.IP4Address
        }
        
        
        ForEach ($endpoint in $($storageAccount.SecondaryEndpoints | ConvertTo-Xml).Objects.Object.Property){

            if ($endpoint.'#text'){
                $dnsObject = Resolve-DnsName ([System.Uri]$endpoint.'#text').Host
            }else{
                $dnsObject = @{
                    Name = @($null)
                    IP4Address = $null
                }
            }
        
            $storageAccount | Add-Member -MemberType NoteProperty -Name ('Secondary{0}DNS' -f $endpoint.Name) -Value $dnsObject.Name[0] -Force -ErrorAction SilentlyContinue
            $storageAccount | Add-Member -MemberType NoteProperty -Name ('Secondary{0}IP4Address' -f $endpoint.Name) -Value $dnsObject.IP4Address -Force -ErrorAction SilentlyContinue
            $secondaryIP4Addresses += $dnsObject.IP4Address
        }

        $storageAccount | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $context.Subscription.Name -Force
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'PrimaryIP4Addresses' -Value $primaryIP4Addresses -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'SecondaryIP4Addresses' -Value $secondaryIP4Addresses -Force -ErrorAction SilentlyContinue
    }

    $allStorageAccounts += $storageAccounts
}

Write-Host 'Script Completed' -ForegroundColor Green

$allStorageAccounts