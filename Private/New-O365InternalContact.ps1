function New-O365InternalContact {
    [CmdletBinding()]
    param(
        [string] $UserId,
        [PSCustomObject] $User,
        [string] $GuidPrefix,
        [switch] $RequireEmailAddress,
        [object] $FolderInformation
    )
    if ($RequireEmailAddress) {
        if (-not $User.Mail) {
            #Write-Verbose -Message "Skipping $($User.DisplayName) because they have no email address"
            return [PSCustomObject] @{
                UserId      = $UserId
                Action      = 'New'
                Status      = 'Skipped'
                DisplayName = $User.DisplayName
                Mail        = $User.Mail
                Skip        = 'RequireEmailAddress'
                Update      = ''
                Details     = 'Missing email address'
                Error       = ''
            }
        }
    }
    if ($User.Mail) {
        Write-Color -Text "[+] ", "Creating ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Green, White, Green
    } else {
        Write-Color -Text "[+] ", "Creating ", $User.DisplayName -Color Yellow, White, Green, White, Green
    }
    $PropertiesToUpdate = [ordered] @{}
    foreach ($Property in $Script:MappingContactToUser.Keys) {
        $PropertiesToUpdate[$Property] = $User.$Property
    }
    $ErrorMessage = ''
    try {
        $newO365WrapperPersonalContactSplat = @{
            UserId      = $UserID
            WhatIf      = $WhatIfPreference
            FileAs      = "$($GuidPrefix)$($User.Id)"
            ErrorAction = 'SilentlyContinue'
        }
        if ($FolderInformation) {
            $newO365WrapperPersonalContactSplat['ContactFolderID'] = $FolderInformation.Id
        }
        $StatusNew = New-O365WrapperPersonalContact @newO365WrapperPersonalContactSplat @PropertiesToUpdate
        $ErrorMessage = ''
    } catch {
        $ErrorMessage = $_.Exception.Message
        if ($User.Mail) {
            Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " / ", $User.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        } else {
            Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        }
    }
    if ($WhatIfPreference) {
        $Status = 'OK (WhatIf)'
    } elseif ($StatusNew -eq $true) {
        $Status = 'OK'
    } else {
        $Status = 'Failed'
    }
    [PSCustomObject] @{
        UserId      = $UserId
        Action      = 'New'
        Status      = $Status
        DisplayName = $User.DisplayName
        Mail        = $User.Mail
        Skip        = ''
        Update      = $PropertiesToUpdate.Keys | Sort-Object
        Details     = ''
        Error       = $ErrorMessage
    }
}
