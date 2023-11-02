# Get All Subscriptions
$subscriptions = Get-AzSubscription -WarningAction SilentlyContinue
$report = @()
ForEach ($subscription in $subscriptions){
    Set-AzContext -Subscription $subscription.Id | Out-Null
    Write-Host ('Getting All Storage Accounts in the {0} Subscription' -f $subscription.Name) -ForegroundColor Yellow

    $storageAccounts = Get-AzStorageAccount | Where Kind -like 'StorageV2' 
    Write-Host ('Found a Total of {0} storage accounts, getting ingress data volume...' -f $storageAccounts.Count) -ForegroundColor Yellow

    ForEach ($storageAccount in $storageAccounts){
        $totalBlobCapacity =  0
        $totalBlobCount = 0
        $totalBlobIngress = 0

        # Get Blob Capacity and Blob Count over the past 30 days per hour, blog ingress in bytes over the past 30 days per 5 minutes
        $blobCapacity = Get-AzMetric -ResourceId $($storageAccount.id + "/blobservices/default") -MetricName BlobCapacity -AggregationType Average -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -WarningAction SilentlyContinue
        $blobCount = Get-AzMetric -ResourceId $($storageAccount.id + "/blobservices/default") -MetricName BlobCount -AggregationType Average -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -WarningAction SilentlyContinue
        $blobIngress = Get-AzMetric -ResourceId $($storageAccount.id + "/blobservices/default") -MetricName Ingress -AggregationType Total -StartTime $((Get-Date).AddMonths(-1)) -EndTime $(Get-Date) -TimeGrain 00:05:00 -WarningAction SilentlyContinue

        # Get Total Average blobCapacity and blobCount over the past 30 days per hour
        $blobCapacity.Data.Average | % {$totalBlobCapacity += $_}
        $blobCount.Data.Average | % {$totalBlobCount += $_}
        $blobIngress.Data.Total | % {$totalBlobIngress += $_}
        
        $totalBlobCapacity30dayAvgGB = [math]::ceiling(($totalBlobCapacity / $blobCapacity.Data.Count) /1024/1024/1024)
        $totalBlobCount30dayAvg = [math]::ceiling($totalBlobCount / $blobCount.Data.Count)
        $totalBlobIngress30dayAvgGB = [math]::round([decimal]$totalBlobIngress/1024/1024/1024,6)

        $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalBlobCapacity30dayAvgGB' -Value $totalBlobCapacity30dayAvgGB -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalBlobCount30dayAvg' -Value $totalBlobCount30dayAvg -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'totalBlobIngress30dayAvgGB' -Value $totalBlobIngress30dayAvgGB -Force -ErrorAction SilentlyContinue
        $storageAccount | Add-Member -MemberType NoteProperty -Name 'Subscription' -Value $subscription.Name -Force -ErrorAction SilentlyContinue
    }

    $report += $storageAccounts | Where Kind -like 'StorageV2' | Select StorageAccountName, Subscription, ResourceGroupName, totalBlobCapacity30dayAvgGB, totalBlobCount30dayAvg, totalBlobIngress30dayAvgGB
}
