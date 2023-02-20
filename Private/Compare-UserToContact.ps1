function Compare-UserToContact {
    [CmdletBinding()]
    param(
        [string] $UserID,
        [PSCustomObject] $ExistingContact,
        [PSCustomObject] $Contact
    )
    $Script:MappingContactToUser = [ordered] @{
        'MailNickname'   = 'NickName'
        'DisplayName'    = 'DisplayName'
        'GivenName'      = 'GivenName'
        'Surname'        = 'Surname'
        # special treatment for 'Mail' because it's an array
        'Mail'           = 'EmailAddresses.Address'
        'MobilePhone'    = 'MobilePhone'
        'HomePhone'      = 'HomePhone'
        'CompanyName'    = 'CompanyName'
        'BusinessPhones' = 'BusinessPhones'
        'JobTitle'       = 'JobTitle'
        'Country'        = 'BusinessAddress.CountryOrRegion'
        'City'           = 'BusinessAddress.City'
        'State'          = 'BusinessAddress.State'
        'Street'         = 'BusinessAddress.Street'
        'PostalCode'     = 'BusinessAddress.PostalCode'
    }
    $AddressProperties = 'City', 'State', 'Street', 'PostalCode', 'Country'
    if ($Contact.PSObject.Properties.Name -contains 'MailNickName') {
        $TranslatedContact = $Contact
    } elseif ($Contact.PSObject.Properties.Name -contains 'Nickname') {
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
        throw "Compare-UserToContact - Unknown user object $($ExistingContact.PSObject.Properties.Name)"
    }

    $SkippedProperties = [System.Collections.Generic.List[string]]::new()
    $UpdateProperties = [System.Collections.Generic.List[string]]::new()
    foreach ($Property in $Script:MappingContactToUser.Keys) {
        if ([string]::IsNullOrEmpty($ExistingContact.$Property) -and [string]::IsNullOrEmpty($TranslatedContact.$Property)) {
            $SkippedProperties.Add($Property)
        } else {
            # $TemporaryComparison = [ordered] @{
            #     Name         = $Property
            #     UserValue    = $ExistingContact.$Property
            #     ContactValue = $TranslatedContact.$Property
            # }
            # $TemporaryComparison | ConvertTo-Json | Write-Verbose

            if ($User.$Property -ne $TranslatedContact.$Property) {
                Write-Verbose -Message "Compare-UserToContact - Property $($Property) for $($ExistingContact.DisplayName) / $($ExistingContact.Mail) different ($($ExistingContact.$Property) vs $($Contact.$Property))"
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
        DisplayName = $ExistingContact.DisplayName
        Mail        = $ExistingContact.Mail
        Update      = $UpdateProperties | Sort-Object -Unique
        Skip        = $SkippedProperties | Sort-Object -Unique
        Details     = ''
        Error       = ''
    }
}

