function Compare-UserToContact {
    <#
    .SYNOPSIS
    Compares a GAL user/contact with an existing personal contact.

    .DESCRIPTION
    Maps the personal contact into the same shape as the GAL object and
    returns which properties should be updated or skipped.

    .PARAMETER UserID
    User mailbox identifier used for logging and result metadata.

    .PARAMETER ExistingContactGAL
    User or contact object from Microsoft Graph/GAL.

    .PARAMETER Contact
    Existing personal contact from the user's mailbox.
    #>
    [CmdletBinding()]
    param(
        [string] $UserID,
        [PSCustomObject] $ExistingContactGAL,
        [PSCustomObject] $Contact
    )
    $AddressProperties = 'City', 'State', 'Street', 'PostalCode', 'Country'
    if ($Contact.PSObject.Properties.Name -contains 'MailNickName') {
        $TranslatedContact = $Contact
    } elseif ($Contact.PSObject.Properties.Name -contains 'Nickname') {
        # Translate existing contact in user's personal contacts to user object so it's identical to user object from GAL
        $TranslatedContact = [ordered] @{}
        foreach ($Property in $Script:MappingContactToUser.Keys) {
            if ($Property -eq 'Mail') {
                $TranslatedContact[$Property] = $Contact.EmailAddresses | ForEach-Object { $_.Address }
            } elseif ($Script:MappingContactToUser[$Property] -like "*.*") {
                $TranslatedContact[$Property] = $Contact.$($Script:MappingContactToUser[$Property].Split('.')[0]).$($Script:MappingContactToUser[$Property].Split('.')[1])
            } else {
                $TranslatedContact[$Property] = $Contact.$($Script:MappingContactToUser[$Property])
            }
        }
    } else {
        throw "Compare-UserToContact - Unknown user object $($ExistingContactGAL.PSObject.Properties.Name)"
    }

    $SkippedProperties = [System.Collections.Generic.List[string]]::new()
    $UpdateProperties = [System.Collections.Generic.List[string]]::new()
    foreach ($Property in $Script:MappingContactToUser.Keys) {
        if (-not ($ExistingContactGAL.PSObject.Properties.Name -contains $Property)) {
            continue
        }
        if ([string]::IsNullOrEmpty($ExistingContactGAL.$Property) -and [string]::IsNullOrEmpty($TranslatedContact.$Property)) {
            $SkippedProperties.Add($Property)
        } else {
            if ($ExistingContactGAL.$Property -ne $TranslatedContact.$Property) {
                Write-Verbose -Message "Compare-UserToContact - Property $($Property) for $($ExistingContactGAL.DisplayName) / $($ExistingContactGAL.Mail) different ($($ExistingContactGAL.$Property) vs $($Contact.$Property))"
                if ($Property -in $AddressProperties) {
                    # Update all address fields together to keep the address consistent.
                    foreach ($Address in $AddressProperties) {
                        if ($UpdateProperties -notcontains $Address) {
                            $UpdateProperties.Add($Address)
                        }
                    }
                } else {
                    $UpdateProperties.Add($Property)
                }

            } else {
                $SkippedProperties.Add($Property)
            }
        }
    }
    [PSCustomObject] @{
        UserId      = $UserId
        Action      = 'Update'
        DisplayName = $ExistingContactGAL.DisplayName
        Mail        = $ExistingContactGAL.Mail
        Update      = $UpdateProperties | Sort-Object -Unique
        Skip        = $SkippedProperties | Sort-Object -Unique
        Details     = ''
        Error       = ''
    }
}

