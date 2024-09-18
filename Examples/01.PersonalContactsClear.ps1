Import-Module .\O365Synchronizer.psd1 -Force
$ClientID = '9e1b3c36'
$TenantID = 'ceb371f6'
$ClientSecret = 'nQF8Q'

$Credentials = [pscredential]::new($ClientID, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-MgGraph -ClientSecretCredential $Credentials -TenantId $TenantID -NoWelcome

# this is useful to clear current user contacts (if you have some)
# this will only delete synchronized ones (based on FileAs property that has to convert to GUID)
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -WhatIf

# this is useful to clear current user contacts (if you have some)
# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix)
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -WhatIf

# this will delete all contacts
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -All -WhatIf

# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix) from specific folder
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -FolderName 'O365' -WhatIf

# this will only delete synchronized ones (based on FileAs property that has to convert to GUID, with GUID prefix) from specific folder, including the folder
Clear-O365PersonalContact -Identity 'testAccount@evotec.pl' -GuidPrefix 'O365Synchronizer' -FolderName 'O365Sync' -FolderRemove -WhatIf