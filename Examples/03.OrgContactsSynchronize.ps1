Import-Module .\O365Synchronizer.psd1 -Force

# Source tenant
$ClientID = '9e1b3c36'
$TenantID = 'ceb371f6'
$ClientSecret = 'NDE8Q'

$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

$UsersToSync = Get-MgUser | Select-Object -First 5

# Destination tenant
$ClientID = 'edc4302e'
Connect-ExchangeOnline -AppId $ClientID -CertificateThumbprint '2EC710' -Organization 'xxxxx.onmicrosoft.com'
Sync-O365Contact -SourceObjects $UsersToSync -Domains 'evotec.pl', 'gmail.com' -Verbose -WhatIf -LogPath 'C:\Temp\Logs\O365Synchronizer.log' -LogMaximum 5