Import-Module .\O365Synchronizer.psd1 -Force

$ClientID = '9e1b3c'
$TenantID = 'ceb371f6'
$ClientSecret = 'nQF8Q'

# connect to Microsoft Graph API
$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

# synchronize contacts for two users of two types (Member, Contact) using GUID prefix
Sync-O365PersonalContact -UserId 'test@evotec.pl', 'test1@evotec.pl' -Verbose -MemberTypes 'Member', 'Contact' -GuidPrefix 'O365Synchronizer' -WhatIf | Format-Table *

# synchronize contacts for 1 user of two types (Member, Contact) using GUID prefix and filtering by company name
# this will only synchronize contacts that have CompanyName starting with 'Evotec' or 'Ziomek'
# this will also require contacts to be in a group by 'e7772951-4b0e-4f10-8f38-eae9b8f55962'
# this will also create a folder 'O365Sync' in user's personal contacts and put synchronized contacts there
# this will also return the results in a table
Sync-O365PersonalContact -UserId 'test@evotec.pl' -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' -PassThru {
    Sync-O365PersonalContactFilter -Type Include -Property 'CompanyName' -Value 'Evotec*','Ziomek*' -Operator 'like'
    Sync-O365PersonalContactFilterGroup -Type Include -GroupID 'e7772951-4b0e-4f10-8f38-eae9b8f55962'
} -FolderName 'O365Sync' | Format-Table