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

    .PARAMETER FolderName
    Optional folder name used for reporting.

    .PARAMETER Category
    Categories assigned to synchronized personal contacts.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserID,
        [PSCustomObject] $User,
        [PSCustomObject] $Contact,
        [string] $FolderName,
        [string[]] $Category
    )

    $OutputObject = Compare-UserToContact -ExistingContactGAL $User -Contact $Contact -UserID $UserID
    $CategoriesClean = $null
    if ($PSBoundParameters.ContainsKey('Category')) {
        $CategoriesClean = ConvertTo-CleanContactArray -Values $Category
        $RequestedCategories = @()
        if ($null -ne $CategoriesClean) {
            $RequestedCategories = $CategoriesClean | Sort-Object -Unique
        }
        $ExistingCategories = @()
        if ($Contact.PSObject.Properties.Name -contains 'Categories') {
            $ExistingCategories = ConvertTo-CleanContactArray -Values $Contact.Categories
            if ($null -ne $ExistingCategories) {
                $ExistingCategories = $ExistingCategories | Sort-Object -Unique
            } else {
                $ExistingCategories = @()
            }
        }
        if ($RequestedCategories.Count -ne $ExistingCategories.Count -or $null -ne (Compare-Object -ReferenceObject $RequestedCategories -DifferenceObject $ExistingCategories)) {
            if ($OutputObject.Update -notcontains 'Categories') {
                $OutputObject.Update += 'Categories'
            }
        } else {
            if ($OutputObject.Skip -notcontains 'Categories') {
                $OutputObject.Skip += 'Categories'
            }
        }
    }
    $ErrorMessage = ''
    if ($OutputObject.Update.Count -gt 0) {
        if ($User.Mail) {
            Write-Color -Text "[i] ", "Updating ", $User.DisplayName, " / ", $User.Mail, " properties to update: ", $($OutputObject.Update -join ', '), " properties to skip: ", $($OutputObject.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
        } else {
            Write-Color -Text "[i] ", "Updating ", $User.DisplayName, " properties to update: ", $($OutputObject.Update -join ', '), " properties to skip: ", $($OutputObject.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
        }
    }

    if ($OutputObject.Update.Count -gt 0) {
        $PropertiesToUpdate = [ordered] @{}
        foreach ($Property in $OutputObject.Update) {
            if ($Property -eq 'Categories') {
                $PropertiesToUpdate[$Property] = $CategoriesClean
            } else {
                $PropertiesToUpdate[$Property] = $User.$Property
            }
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
