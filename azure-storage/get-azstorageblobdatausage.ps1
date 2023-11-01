
$storageAccounts = Get-AzStorageAccount

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

}

$storageAccounts  | Select StorageAccountName, ResourceGroupName, totalBlobCapacity30dayAvgGB, totalBlobCount30dayAvg, totalBlobIngress30dayAvgGB | ft -AutoSize

