Import-Module .\O365Synchronizer.psd1 -Force

$ClientID = '9e1b3c'
$TenantID = 'ceb371f6'
$ClientSecret = 'nQF8Q'

# connect to Microsoft Graph API
$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

# synchronize contacts for two users of two types (Member, Contact) using GUID prefix
Sync-O365PersonalContact -UserId 'test@evotec.pl', 'test1@evotec.pl' -Verbose -MemberTypes 'Member', 'Contact' -GuidPrefix 'O365Synchronizer' -WhatIf | Format-Table *