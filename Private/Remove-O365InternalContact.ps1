function Remove-O365InternalContact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.Generic.List[object]] $ToPotentiallyRemove,
        [System.Collections.IDictionary] $ExistingUsers,
        [System.Collections.IDictionary] $ExistingContacts,
        [string] $UserId

    )
    # foreach ($Contact in $ToPotentiallyRemove) {
    #     Write-Color -Text "[x] ", "Removing (filtered out) ", $Contact.DisplayName -Color Yellow, White, Red, White, Red
    #     try {
    #         Remove-MgUserContact -UserId $UserId -ContactId $Contact.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
    #         $ErrorMessage = ''
    #         if ($WhatIfPreference) {
    #             $Status = 'OK (WhatIf)'
    #         } else {
    #             $Status = 'OK'
    #         }
    #     } catch {
    #         $Status = 'Failed'
    #         $ErrorMessage = $_.Exception.Message
    #         Write-Color -Text "[!] ", "Failed to remove contact for ", $Contact.DisplayName, " / ", $Contact.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
    #     }
    #     $OutputObject = [PSCustomObject] @{
    #         UserId      = $UserId
    #         Action      = 'Remove'
    #         Status      = $Status
    #         DisplayName = $Contact.DisplayName
    #         Mail        = $Contact.Mail
    #         Skip        = ''
    #         Update      = ''
    #         Details     = 'Filtered out'
    #         Error       = $ErrorMessage
    #     }
    #     $OutputObject
    # }
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