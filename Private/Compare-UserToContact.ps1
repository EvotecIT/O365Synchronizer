function Compare-UserToContact {
    [CmdletBinding()]
    param(
        [PSCustomObject] $ExistingContact,
        [PSCustomObject] $Contact
    )
    $Properties = @(
        'NickName'
        'DisplayName'
        'GivenName'
        'Surname'
        'EmailAddresses'
        'MobilePhone'
        'HomePhone'
        'BusinessPhones'
        'CompanyName'
        'JobTitle'
        'EmployeeId'
        'Country'
        'City'
        'State'
        'Street'
        'PostalCode'
    )

    $MappingContactToUser = [ordered] @{
        'MailNickname'   = 'NickName'
        'DisplayName'    = 'DisplayName'
        'GivenName'      = 'GivenName'
        'Surname'        = 'Surname'
        'Mail'           = 'EmailAddresses'
        'MobilePhone'    = 'MobilePhone'
        'HomePhone'      = 'HomePhone'
        'CompanyName'    = 'CompanyName'
        'BusinessPhones' = 'BusinessPhones'
        'JobTitle'       = 'JobTitle'
        'Country'        = 'Country'
        'City'           = 'City'
        'State'          = 'State'
        'Street'         = 'Street'
        'PostalCode'     = 'PostalCode'
        'EmployeeId'     = 'EmployeeId'
    }
    if ($Contact.PSObject.Properties.Name -contains 'MailNickName') {
        $TranslatedContact = $Contact
    } elseif ($Contact.PSObject.Properties.Name -contains 'Nickname') {
        $TranslatedContact = [ordered] @{}
        foreach ($Property in $MappingContactToUser.Keys) {
            $TranslatedContact[$Property] = $Contact.$($MappingContactToUser[$Property])
        }
    } else {
        throw "Compare-UserToContact - Unknown user object $($ExistingContact.PSObject.Properties.Name)"
    }

    $SkippedProperties = [System.Collections.Generic.List[string]]::new()
    $UpdateProperties = [System.Collections.Generic.List[string]]::new()
    foreach ($Property in $Properties) {
        if ([string]::IsNullOrEmpty($ExistingContact.$Property) -and [string]::IsNullOrEmpty($Contact.$Property)) {
            $SkippedProperties.Add($Property)
        } else {
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

