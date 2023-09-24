function Set-O365OrgContact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.IDictionary] $CurrentContactsCache,
        [Object] $MailContact,
        [Object] $Contact,
        [Object] $Source,
        [Object] $SourceContact
    )
    Write-Color -Text "[i] ", "Checking ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress, " for updates" -Color Yellow, White, Cyan, White, Cyan
    if ($Source -and $SourceContact) {
        if (-not $MailContact) {
            $MailContact = $CurrentContactsCache[$Source.PrimarySmtpAddress].MailContact
        }
        $MismatchedMailContact = [ordered] @{}
        [Array] $MismatchedPropertiesMailContact = foreach ($Property in $Source.PSObject.Properties.Name) {
            if ($Source.$Property -ne $MailContact.$Property) {
                if ([string]::IsNullOrEmpty($Source.$Property) -and [string]::IsNullOrEmpty($MailContact.$Property) ) {

                } else {
                    # Property is not empty on both sides, and they are not equal
                    $Property
                    $MismatchedMailContact[$Property] = $Source.$Property
                }
            }
        }

        if (-not $Contact) {
            $Contact = $CurrentContactsCache[$Source.PrimarySmtpAddress].Contact
        }

        $MismatchedContact = [ordered] @{}
        [Array] $MismatchedPropertiesContact = foreach ($Property in $SourceContact.PSObject.Properties.Name) {
            if ($SourceContact.$Property -ne $Contact.$Property) {
                if ([string]::IsNullOrEmpty($SourceContact.$Property) -and [string]::IsNullOrEmpty($Contact.$Property) ) {

                } else {
                    # Property is not empty on both sides, and they are not equal
                    $Property
                    $MismatchedContact[$Property] = $SourceContact.$Property
                }
            }
        }
        if ($MismatchedPropertiesMailContact.Count -gt 0 -or $MismatchedPropertiesContact.Count -gt 0) {
            Write-Color -Text "[i] ", "Mismatched properties for ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress, " are: ", ($MismatchedPropertiesMailContact + $MismatchedPropertiesContact -join ', ') -Color Yellow, White, DarkCyan, White, Cyan

            if ($MismatchedPropertiesMailContact.Count -gt 0) {
                Write-Color -Text "[*] ", "Updating mail contact for ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress -Color Yellow, White, DarkCyan, White, Cyan
                try {
                    Set-MailContact -Identity $MailContact.Identity -WhatIf:$WhatIfPreference -ErrorAction Stop @MismatchedMailContact
                } catch {
                    Write-Color -Text "[e] ", "Failed to update mail contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
                }
            }
            if ($MismatchedPropertiesContact.Count -gt 0) {
                Write-Color -Text "[*] ", "Updating contact for ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress -Color Yellow, White, DarkCyan, White, Cyan
                try {
                    Set-Contact -Identity $MailContact.Identity -WhatIf:$WhatIfPreference -ErrorAction Stop @MismatchedContact
                } catch {
                    Write-Color -Text "[e] ", "Failed to update contact. Error: ", ($_.Exception.Message -replace ([Environment]::NewLine), " " )-Color Yellow, White, Red
                }
            }
        } else {
            #Write-Color -Text "[i] ", "No mismatched properties for ", $Source.DisplayName, " / ", $Source.PrimarySmtpAddress -Color Yellow, White, DarkCyan, White, Cyan
        }
    }
}