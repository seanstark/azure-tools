


param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId, 

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$Workspace,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$true,ParameterSetName = 'WindowsRegistry')]
    [Parameter(Mandatory=$true,ParameterSetName = 'Files')]
    [Parameter(Mandatory=$true,ParameterSetName = 'LinuxFiles')]
    [ValidateSet('WindowsRegistry','WindowsFiles','LinuxFiles')]
    [string]$Kind,
    
    [Parameter(Mandatory=$true)]
    [string]$ItemName,
    
    [Parameter(Mandatory=$false)]
    [string]$Group = 'Custom',
    
    [Parameter(Mandatory=$true,ParameterSetName = 'WindowsRegistry')]
    [string]$RegistryKey,

    [Parameter(Mandatory=$true,ParameterSetName = 'Files')]
    [string]$Path,

    [Parameter(Mandatory=$true,ParameterSetName = 'Files')]
    [Parameter(Mandatory=$true,ParameterSetName = 'LinuxFiles')]
    [ValidateSet('File','Directory')]
    [string]$PathType,

    [Parameter(Mandatory=$false,ParameterSetName = 'Files')]
    [switch]$UploadFileContent = $false,

    [Parameter(Mandatory=$false,ParameterSetName = 'LinuxFiles')]
     [Parameter(Mandatory=$false,ParameterSetName = 'Files')]
    [ValidateSet('Follow','Ignore','Manage')]
    [string]$Links = 'Follow',

    [Parameter(Mandatory=$false,ParameterSetName = 'LinuxFiles')]
     [Parameter(Mandatory=$false,ParameterSetName = 'Files')]
    [boolean]$UseSudo = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$Recursive = $false,

    [Parameter(Mandatory=$false)]
    [switch]$Enabled = $false

)

switch ($Kind){

    'WindowsRegistry' {$objectKind = 'ChangeTrackingDefaultRegistry'}
    'WindowsFiles' {$objectKind = 'ChangeTrackingCustomPath'}
    'LinuxFiles' {$objectKind = 'ChangeTrackingDefaultRegistry'}
}

$apiPath = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/microsoft.operationalinsights/workspaces/$Workspace/datasources/"

$apiVersion = '2015-11-01-preview'

$uri = ('{0}{1}?api-version={2}' -f $apiPath, $ItemName.ToLower(), $apiVersion)

$WindowsRegistrybody = [PSCustomObject]@{
	id = ('{0}{1}' -f $apiPath, $ItemName.ToLower())
	name = $ItemName.ToLower()
	etag = ''
	kind = 'ChangeTrackingDefaultRegistry'
	type = 'workspaces'
	location = $workspace
	properties = [PSCustomObject]@{
		enabled = $Enabled.ToString()
		groupTag = $Group
		keyName = $RegistryKey
		valueName = ''
		recurse = $Recursive.ToString()
	}
}

$WindowsFilesbody = [PSCustomObject]@{
	id = ('{0}{1}' -f $apiPath, $ItemName.ToLower())
	name = $ItemName.ToLower()
	etag = ''
	kind = 'ChangeTrackingCustomPath'
	type = 'workspaces'
	location = $workspace
	properties = [PSCustomObject]@{
		enabled = $Enabled.ToString()
		groupTag = $Group
		recurse = $Recursive.ToString()
        checksum = 'Md5'
        maxContentsReturnable = $(If($PathType -like 'Directory'){0}elseif($UploadFileContent){5000000}else{0})
        maxOutputSize = $(If($PathType -like 'Directory'){0}elseif($UploadFileContent){5000000}else{0})
        path = $Path
        pathType = $(If($PathType -like 'Directory'){'Folder'}else{$PathType})
	}
}

$LinuxFilesbody = [PSCustomObject]@{
	id = ('{0}{1}' -f $apiPath, $ItemName.ToLower())
	name = $ItemName.ToLower()
	etag = ''
	kind = 'ChangeTrackingLinuxPath'
	type = 'workspaces'
	location = $workspace
	properties = [PSCustomObject]@{
		enabled = $Enabled.ToString()
		groupTag = $Group
		recurse = $Recursive.ToString()
        checksum = 'Sha256'
        maxContentsReturnable = $(If($PathType -like 'Directory'){0}elseif($UploadFileContent){5000000}else{0})
        maxOutputSize = $(If($PathType -like 'Directory'){0}elseif($UploadFileContent){5000000}else{0})
        destinationPath = $Path
        links = $Links
        useSudo = $UseSudo.ToString()
        pathType = $PathType
	}
}

switch ($Kind){

    'WindowsRegistry' {$body = $WindowsRegistrybody}
    'WindowsFiles' {$body = $WindowsFilesbody}
    'LinuxFiles' {$body = $LinuxFilesbody}
}


Write-Host $($body | ConvertTo-Json) -ForegroundColor Green

Invoke-AzRestMethod -Path $uri -Payload $($body | ConvertTo-Json) -Method PUT
