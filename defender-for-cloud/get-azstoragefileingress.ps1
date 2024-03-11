
# The script will get estimated ingress on Azure Files for supported V2 Storage Accounts with file containers across all subscriptions in a tenant based on the ingress metric, which is in bytes. 
# - The ingress metric used in this script is based on the last 30 days at a 5 minute interval
# - Overall this estimate is a ballpark and not to be expected as 100% accurate 

$requiredModules = 'Az.Accounts', 'Az.Storage', 'Az.Monitor'
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

# Get All Subscriptions
$subscriptions = Get-AzSubscription -WarningAction SilentlyContinue
$report = @()
ForEach ($subscription in $subscriptions){
    Set-AzContext -Subscription $subscription.Id | Out-Null
    Write-Host ('Getting All Storage Accounts in the {0} Subscription' -f $subscription.Name) -ForegroundColor Yellow

    $storageAccounts = Get-AzStorageAccount | Where Kind -like 'StorageV2' 
    Write-Host ('Found a Total of {0} storage accounts, getting ingress data volume in MB...' -f $storageAccounts.Count) -ForegroundColor Yellow

    ForEach ($storageAccount in $storageAccounts){
        $totalFileIngress30dayBytes = $null
        $totalFileIngress30dayMB = $null
        $totalFileIngress30dayGB = $null
        $fileIngress = $null
        $totalFileIngress = 0

        # Get blob ingress in bytes over the past 30 days per 5 minutes
        $fileIngress = Get-AzMetric -ResourceId $($storageAccount.id + "/fileservices/default") -MetricName Ingress -AggregationType Total -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -TimeGrain 00:05:00 -WarningAction SilentlyContinue

        # Get Total ingress bytes over the past 30 days
        $fileIngress.Data.Total | % {$totalBlobIngress += $_}
    
        $totalFileIngress30dayBytes = $totalBlobIngress
        $totalFileIngress30dayMB = [math]::round([decimal]$totalBlobIngress/1000/1000,6)
        $totalFileIngress30dayGB = [math]::round([decimal]$totalBlobIngress/1000/1000/1000,6)

        Write-Host ('    {0} totalFileIngress30dayBytes: {1}, totalFileIngress30dayMB:{2} totalFileIngress30dayGB: {3}' -f $storageAccount.StorageAccountName,  $totalFileIngress30dayBytes, $totalFileIngress30dayMB, $totalFileIngress30dayGB) -ForegroundColor Yellow

        $storageAccount | Add-Member -MemberType NoteProperty -Name 'Subscription' -Value $subscription.Name -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalFileIngress30dayBytes' -Value $totalFileIngress30dayBytes -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalFileIngress30dayMB' -Value $totalFileIngress30dayMB -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalFileIngress30dayGB' -Value $totalFileIngress30dayGB -Force -ErrorAction SilentlyContinue
    }

    $report += $storageAccounts | Select StorageAccountName, Subscription, ResourceGroupName, totalFileIngress30dayBytes, totalFileIngress30dayMB, totalFileIngress30dayGB
}

$report | Export-CSV -Path .\malwareScanningEstimates.csv -Force

Write-Host ('CSV file created with estimates: {0}\{1}' -f $(pwd).path, 'storageFileIngressEstimates.csv') -ForegroundColor Yellow
