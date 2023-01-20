function Compare-UserToContact {
    [CmdletBinding()]
    param(
        $User,
        $Contact
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
    )

    $MappingContactToUser = [ordered] @{
        'MailNickname'   = 'NickName'
        'DisplayName'    = 'DisplayName'
        'GivenName'      = 'GivenName'
        'Surname'        = 'Surname'
        'Mail'           = 'EmailAddresses'
        'MobilePhone'    = 'MobilePhone'
        'HomePhone'      = 'HomePhone'
        'BusinessPhones' = 'BusinessPhones'
    }
    $TranslatedContact = [ordered] @{}
    foreach ($Property in $MappingContactToUser.Keys) {
        $TranslatedContact[$Property] = $Contact.$($MappingContactToUser[$Property])
    }

    $SkippedProperties = [System.Collections.Generic.List[string]]::new()
    $UpdateProperties = [System.Collections.Generic.List[string]]::new()
    foreach ($Property in $Properties) {
        if ([string]::IsNullOrEmpty($User.$Property) -and [string]::IsNullOrEmpty($Contact.$Property)) {
            $SkippedProperties.Add($Property)
        } elseif ($User.$Property -ne $TranslatedContact.$Property) {
            Write-Verbose -Message "Compare-UserToContact - Property $($Property) for $($User.DisplayName) / $($User.Mail) different ($($User.$Property) vs $($Contact.$Property))"
            $UpdateProperties.Add($Property)
        } else {
            $SkippedProperties.Add($Property)
        }
    }
    @{
        Skip   = $SkippedProperties
        Update = $UpdateProperties
    }
}

