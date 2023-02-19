function Compare-UserToContact {
    [CmdletBinding()]
    param(
        [PSCustomObject] $ExistingContact,
        [PSCustomObject] $Contact
    )
    $MappingContactToUser = [ordered] @{
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
    if ($Contact.PSObject.Properties.Name -contains 'MailNickName') {
        $TranslatedContact = $Contact
    } elseif ($Contact.PSObject.Properties.Name -contains 'Nickname') {
        $TranslatedContact = [ordered] @{}
        foreach ($Property in $MappingContactToUser.Keys) {
            if ($Property -eq 'Mail') {
                $TranslatedContact[$Property] = $Contact.EmailAddresses | ForEach-Object { $_.Address }
            } elseif ($MappingContactToUser[$Property] -like "*.*") {
                $TranslatedContact[$Property] = $Contact.$($MappingContactToUser[$Property].Split('.')[0]).$($MappingContactToUser[$Property].Split('.')[1])
            } else {
                $TranslatedContact[$Property] = $Contact.$($MappingContactToUser[$Property])
            }
        }
    } else {
        throw "Compare-UserToContact - Unknown user object $($ExistingContact.PSObject.Properties.Name)"
    }

    $SkippedProperties = [System.Collections.Generic.List[string]]::new()
    $UpdateProperties = [System.Collections.Generic.List[string]]::new()
    foreach ($Property in $MappingContactToUser.Keys) {
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
                $UpdateProperties.Add($Property)
            } else {
                $SkippedProperties.Add($Property)
            }
        }
    }
    [ordered] @{
        DisplayName = $ExistingContact.DisplayName
        Mail        = $ExistingContact.Mail
        Skip        = $SkippedProperties
        Update      = $UpdateProperties
    }
}

