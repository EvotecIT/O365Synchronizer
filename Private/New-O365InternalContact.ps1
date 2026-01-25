function New-O365InternalContact {
    <#
    .SYNOPSIS
    Creates a personal contact from a GAL user/contact.

    .DESCRIPTION
    Builds the contact payload and creates it in the user's mailbox.

    .PARAMETER UserId
    User mailbox identifier.

    .PARAMETER User
    User/contact object from Microsoft Graph.

    .PARAMETER GuidPrefix
    Optional prefix to mark synchronized contacts.

    .PARAMETER RequireEmailAddress
    When set, skips users without an email address.

    .PARAMETER FolderInformation
    Folder metadata for the target contact folder.

    .PARAMETER Category
    Categories assigned to synchronized personal contacts.
    #>
    [CmdletBinding()]
    param(
        [string] $UserId,
        [PSCustomObject] $User,
        [string] $GuidPrefix,
        [switch] $RequireEmailAddress,
        [object] $FolderInformation,
        [string[]] $Category
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
    if ($PSBoundParameters.ContainsKey('Category')) {
        $CategoriesClean = ConvertTo-CleanContactArray -Values $Category
        if ($null -ne $CategoriesClean) {
            $PropertiesToUpdate['Categories'] = $CategoriesClean
        }
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
