function Set-O365InternalContact {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER UserID
    Identity of the user to synchronize contacts to. It can be UserID or UserPrincipalName.

    .PARAMETER User
    User/Contact object from GAL

    .PARAMETER FolderName

    .PARAMETER Contact
    Existing contact in user's personal contacts

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserID,
        [PSCustomObject] $User,
        [PSCustomObject] $Contact,
        [string] $FolderName
    )

    $OutputObject = Compare-UserToContact -ExistingContactGAL $User -Contact $Contact -UserID $UserID
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
            $PropertiesToUpdate[$Property] = $User.$Property
        }
        $StatusSet = Set-O365WrapperPersonalContact -UserId $UserID -ContactId $Contact.Id @PropertiesToUpdate -WhatIf:$WhatIfPreference
        if ($WhatIfPreference) {
            $Status = 'OK (WhatIf)'
        } elseif ($StatusSet -eq $true) {
            $Status = 'OK'
        } else {
            $Status = 'Failed'
        }
    } else {
        $Status = 'Not required'
    }

    $OutputObject = [PSCustomObject] @{
        UserId      = $UserId
        Action      = 'Update'
        Status      = $Status
        DisplayName = $User.DisplayName
        Mail        = $User.Mail
        Skip        = ''
        Update      = ''
        Details     = ''
        Error       = $ErrorMessage
    }
    $OutputObject
}