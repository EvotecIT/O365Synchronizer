function Set-O365InternalContact {
    <#
    .SYNOPSIS
    Updates an existing personal contact when changes are detected.

    .DESCRIPTION
    Compares the user/contact from GAL with the existing personal contact
    and applies only the necessary updates via Graph.

    .PARAMETER UserID
    User mailbox identifier used for updates and logging.

    .PARAMETER User
    User or contact object from Microsoft Graph/GAL.

    .PARAMETER Contact
    Existing personal contact from the user's mailbox.

    .PARAMETER FolderId
    Contact folder id when synchronizing a named folder.

    .PARAMETER Category
    Categories assigned to synchronized personal contacts.

    .PARAMETER SyncField
    Fields managed by synchronization. Unselected fields are preserved.

    .PARAMETER NicknameSource
    Directory property used for the personal contact nickname.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserID,
        [PSCustomObject] $User,
        [PSCustomObject] $Contact,
        [string] $FolderId,
        [string[]] $Category,
        [ValidateSet('DisplayName', 'MailNickname')][string] $NicknameSource = 'DisplayName',
        [string[]] $SyncField = @('All')
    )

    $Fields = @(Resolve-O365PersonalContactSyncFields -SyncField $SyncField)
    $OutputObject = Compare-UserToContact -ExistingContactGAL $User -Contact $Contact -UserID $UserID -NicknameSource $NicknameSource -SyncField $SyncField
    $CategoriesClean = $null
    if ($Fields -contains 'Categories' -and $PSBoundParameters.ContainsKey('Category')) {
        $CategoriesClean = ConvertTo-CleanContactArray -Values $Category
        $RequestedCategories = @()
        if ($null -ne $CategoriesClean) {
            $RequestedCategories = $CategoriesClean | Sort-Object -Unique
        }
        $ExistingCategories = @()
        if ($Contact.PSObject.Properties.Name -contains 'Categories') {
            $ExistingCategories = ConvertTo-CleanContactArray -Values $Contact.Categories -PreserveDuplicates
            if ($null -ne $ExistingCategories) {
                $ExistingCategories = $ExistingCategories | Sort-Object
            } else {
                $ExistingCategories = @()
            }
        }
        if ($RequestedCategories.Count -ne $ExistingCategories.Count -or $null -ne (Compare-Object -ReferenceObject $RequestedCategories -DifferenceObject $ExistingCategories)) {
            if ($OutputObject.Update -notcontains 'Categories') {
                $OutputObject.Update = @($OutputObject.Update) + 'Categories'
            }
        } else {
            if ($OutputObject.Skip -notcontains 'Categories') {
                $OutputObject.Skip = @($OutputObject.Skip) + 'Categories'
            }
        }
    }
    $ErrorMessage = ''
    if ($OutputObject.Update.Count -gt 0) {
        if ($User.Mail) {
            Write-O365Log -Text "[i] ", "Updating ", $User.DisplayName, " / ", $User.Mail, " properties to update: ", $($OutputObject.Update -join ', '), " properties to skip: ", $($OutputObject.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
        } else {
            Write-O365Log -Text "[i] ", "Updating ", $User.DisplayName, " properties to update: ", $($OutputObject.Update -join ', '), " properties to skip: ", $($OutputObject.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
        }
    }

    if ($OutputObject.Update.Count -gt 0) {
        $PropertiesToUpdate = [ordered] @{}
        foreach ($Property in $OutputObject.Update) {
            if ($Property -eq 'Categories') {
                $PropertiesToUpdate['Categories'] = $CategoriesClean
            } elseif ($Property -eq 'NickName') {
                $PropertiesToUpdate['NickName'] = Resolve-O365PersonalContactNickname -SourceObject $User -NicknameSource $NicknameSource
            } else {
                $PropName = [string]$Property
                $PropertiesToUpdate[$PropName] = $User.$Property
            }
        }
        if (-not $PropertiesToUpdate.Contains('DisplayName')) {
            # Graph can regenerate displayName when other contact properties change.
            if ($Fields -contains 'DisplayName' -and -not [string]::IsNullOrEmpty($User.DisplayName)) {
                $PropertiesToUpdate['DisplayName'] = $User.DisplayName
            } elseif ($Fields -notcontains 'DisplayName' -and $Contact.PSObject.Properties.Name -contains 'DisplayName') {
                $PropertiesToUpdate['DisplayName'] = $Contact.DisplayName
            } elseif ($PropertiesToUpdate.Contains('GivenName') -or $PropertiesToUpdate.Contains('Surname')) {
                throw 'The existing contact display name is required to preserve it during a name-only update.'
            }
        }
        if (-not [string]::IsNullOrEmpty($FolderId)) {
            $PropertiesToUpdate['ParentFolderId'] = $FolderId
        }
        $Result = Set-O365WrapperPersonalContact -UserId $UserID -ContactId $Contact.Id @PropertiesToUpdate -WhatIf:$WhatIfPreference
        if ($WhatIfPreference) {
            $Status = 'OK (WhatIf)'
        } elseif ($Result -and $Result.Success -eq $true) {
            $Status = 'OK'
        } else {
            $Status = 'Failed'
            if ($Result -and $Result.ErrorMessage) {
                $ErrorMessage = $Result.ErrorMessage
            }
        }
    } else {
        $Status = 'Not required'
    }

    $OutputObject | Add-Member -MemberType NoteProperty -Name 'Status' -Value $Status -Force
    $OutputObject | Add-Member -MemberType NoteProperty -Name 'Error' -Value $ErrorMessage -Force
    $OutputObject
}
