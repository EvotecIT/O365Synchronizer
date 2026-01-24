function Remove-O365InternalContact {
    <#
    .SYNOPSIS
    Removes personal contacts that are no longer required.

    .DESCRIPTION
    Compares existing personal contacts with current users and removes
    contacts that are no longer synchronized.

    .PARAMETER ToPotentiallyRemove
    Reserved list of contacts to remove (not currently used).

    .PARAMETER ExistingUsers
    Dictionary of current users keyed by id.

    .PARAMETER ExistingContacts
    Dictionary of existing personal contacts keyed by id.

    .PARAMETER UserId
    User mailbox identifier.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.Generic.List[object]] $ToPotentiallyRemove,
        [System.Collections.IDictionary] $ExistingUsers,
        [System.Collections.IDictionary] $ExistingContacts,
        [string] $UserId
    )
    foreach ($ContactID in $ExistingContacts.Keys) {
        $Contact = $ExistingContacts[$ContactID]
        $Entry = $Contact.FileAs
        if ($ExistingUsers[$Entry]) {

        } else {
            Write-Color -Text "[x] ", "Removing (not required) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
            try {
                Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
                if ($WhatIfPreference) {
                    $Status = 'OK (WhatIf)'
                } else {
                    $Status = 'OK'
                }
                $ErrorMessage = ''
            } catch {
                $Status = 'Failed'
                $ErrorMessage = $_.Exception.Message
                Write-Color -Text "[!] ", "Failed to remove contact for ", $Contact.DisplayName, " / ", $Contact.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
            }
            $OutputObject = [PSCustomObject] @{
                UserId      = $UserId
                Action      = 'Remove'
                Status      = $Status
                DisplayName = $Contact.DisplayName
                Mail        = $Contact.Mail
                Skip        = ''
                Update      = ''
                Details     = 'Not required'
                Error       = $ErrorMessage
            }
            $OutputObject
        }
    }
}
