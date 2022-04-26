$put = .\new-fimitem.ps1 -SubscriptionId 'c94dffc7-2659-4750-a34e-a160f2a68c90' `
-ResourceGroup 'sentinel-prd' `
-Workspace 'sentinel-prd' `
-Kind WindowsRegistry `
-ItemName 'Test3' `
-RegistryKey 'HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\testno-rescu' `
-Recursive


$put = .\new-fimitem.ps1 -SubscriptionId 'c94dffc7-2659-4750-a34e-a160f2a68c90' `
-ResourceGroup 'sentinel-prd' `
-Workspace 'sentinel-prd' `
-Kind LinuxFiles `
-ItemName 'Test_Linux' `
-Path '/etc/txt.txt' `
-PathType File `
-Links Ignore `
-UseSudo $false



$put = .\new-fimitem.ps1 -SubscriptionId 'c94dffc7-2659-4750-a34e-a160f2a68c90' `
-ResourceGroup 'sentinel-prd' `
-Workspace 'sentinel-prd' `
-Kind WindowsFiles `
-ItemName 'Test_Windows' `
-Path 'C:\windows\' `
-PathType Directory 
