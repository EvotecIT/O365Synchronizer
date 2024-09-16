function Compare-UserToContact {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER UserID
    Identity of the user to synchronize contacts to. It can be UserID or UserPrincipalName

    .PARAMETER ExistingContactGAL
    User/Contact object from GAL

    .PARAMETER Contact
    Existing contact in user's personal contacts

    .EXAMPLE
    An example

    .NOTES
    General notes
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
        if ([string]::IsNullOrEmpty($ExistingContactGAL.$Property) -and [string]::IsNullOrEmpty($TranslatedContact.$Property)) {
            $SkippedProperties.Add($Property)
        } else {
            if ($ExistingContactGAL.$Property -ne $TranslatedContact.$Property) {
                Write-Verbose -Message "Compare-UserToContact - Property $($Property) for $($ExistingContactGAL.DisplayName) / $($ExistingContactGAL.Mail) different ($($ExistingContactGAL.$Property) vs $($Contact.$Property))"
                if ($Property -in $AddressProperties) {
                    foreach ($Address in $AddressProperties) {
                        if ($UpdatedProperties -notcontains $Address) {
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

