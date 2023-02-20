function Sync-InternalO365PersonalContact {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $UserId,
        [ValidateSet('Member', 'Guest', 'Contact')][string[]] $MemberTypes,
        [switch] $RequireEmailAddress,
        [string] $GuidPrefix,
        [System.Collections.IDictionary] $ExistingUsers,
        [System.Collections.IDictionary] $ExistingContacts
    )
    $ListActions = [System.Collections.Generic.List[object]]::new()
    $ToPotentiallyRemove = [System.Collections.Generic.List[object]]::new()
    foreach ($UsersInternalID in $ExistingUsers.Keys) {
        $User = $ExistingUsers[$UsersInternalID]
        Write-Color -Text "[i] ", "Processing ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Cyan, White, Cyan

        $Entry = $User.Id
        $Contact = $ExistingContacts[$Entry]

        # lets check if user is a member or guest
        if ($User.Type -notin $MemberTypes) {
            Write-Color -Text "[i] ", "Skipping ", $User.DisplayName, " because they are not a ", $($MemberTypes -join ', ') -Color Yellow, White, DarkYellow, White, DarkYellow
            if ($Contact) {
                $ToPotentiallyRemove.Add($ExistingContacts[$Entry])
            }
            continue
        }

        if ($Contact) {
            $OutputObject = Compare-UserToContact -ExistingContact $User -Contact $Contact -UserID $UserID
            if ($OutputObject.Update.Count -gt 0) {
                Write-Color -Text "[i] ", "Updating ", $User.DisplayName, " / ", $User.Mail, " properties to update: ", $($OutputObject.Update -join ', '), " properties to skip: ", $($OutputObject.Skip -join ', ') -Color Yellow, White, Green, White, Green, White, Green, White, Cyan
                Set-O365Contact -UserID $UserId -User $User -Contact $Contact -Properties $OutputObject.Update
            }
        } else {
            $OutputObject = New-O365Contact -UserId $UserId -User $User -GuidPrefix $GuidPrefix -RequireEmailAddress:$RequireEmailAddress
        }
        $ListActions.Add($OutputObject)
    }
    foreach ($Contact in $ToPotentiallyRemove) {
        Write-Color -Text "[x] ", "Removing (filtered out) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
        try {
            Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
            $ErrorMessage = ''
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Color -Text "[!] ", "Failed to remove contact for ", $Contact.DisplayName, " / ", $Contact.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        }
        $OutputObject = [PSCustomObject] @{
            UserId      = $UserId
            Action      = 'Remove'
            DisplayName = $Contact.DisplayName
            Mail        = $Contact.Mail
            Skip        = ''
            Update      = ''
            Details     = 'Filtered out'
            Error       = $ErrorMessage
        }
        $ListActions.Add($OutputObject)
    }
    foreach ($ContactID in $ExistingContacts[$Entry].Keys) {
        $Contact = $ExistingContacts[$ContactID]
        $Entry = $Contact.FileAs
        if ($ExistingUsers[$Entry]) {

        } else {
            Write-Color -Text "[x] ", "Removing (not required) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
            try {
                Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
                $ErrorMessage = ''
            } catch {
                $ErrorMessage = $_.Exception.Message
                Write-Color -Text "[!] ", "Failed to remove contact for ", $Contact.DisplayName, " / ", $Contact.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
            }
            $OutputObject = [PSCustomObject] @{
                UserId      = $UserId
                Action      = 'Remove'
                DisplayName = $Contact.DisplayName
                Mail        = $Contact.Mail
                Skip        = ''
                Update      = ''
                Details     = 'Not required'
                Error       = $ErrorMessage
            }
            $ListActions.Add($OutputObject)
        }
    }
    $ListActions
}