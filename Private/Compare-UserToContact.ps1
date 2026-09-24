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

    .PARAMETER NicknameSource
    Directory property used for the personal contact nickname. DisplayName is
    the default; MailNickname preserves the legacy behavior.
    #>
    [CmdletBinding()]
    param(
        [string] $UserID,
        [PSCustomObject] $ExistingContactGAL,
        [PSCustomObject] $Contact,
        [ValidateSet('DisplayName', 'MailNickname')][string] $NicknameSource = 'DisplayName'
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
        if ($Property -in 'BusinessPhones', 'HomePhone', 'Mail') {
            $SourceValues = ConvertTo-CleanContactArray -Values $ExistingContactGAL.$Property
            $ContactValues = ConvertTo-CleanContactArray -Values $TranslatedContact.$Property
            $SourceValues = if ($null -eq $SourceValues) { @() } else { @($SourceValues) }
            $ContactValues = if ($null -eq $ContactValues) { @() } else { @($ContactValues) }
            $Different = $SourceValues.Count -ne $ContactValues.Count
            for ($Index = 0; -not $Different -and $Index -lt $SourceValues.Count; $Index++) {
                $Different = $SourceValues[$Index] -ne $ContactValues[$Index]
            }
        } elseif ([string]::IsNullOrEmpty($ExistingContactGAL.$Property) -and [string]::IsNullOrEmpty($TranslatedContact.$Property)) {
            $SkippedProperties.Add($Property)
            continue
        } else {
            $Different = $ExistingContactGAL.$Property -ne $TranslatedContact.$Property
        }
        if ($Different) {
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

    $DesiredNickname = Resolve-O365PersonalContactNickname -SourceObject $ExistingContactGAL -NicknameSource $NicknameSource
    $ExistingNickname = if ($Contact.PSObject.Properties.Name -contains 'Nickname') {
        [string] $Contact.Nickname
    } elseif ($Contact.PSObject.Properties.Name -contains 'MailNickname') {
        [string] $Contact.MailNickname
    } else {
        ''
    }
    if ($DesiredNickname -ne $ExistingNickname) {
        $UpdateProperties.Add('NickName')
    } else {
        $SkippedProperties.Add('NickName')
    }

    [PSCustomObject] @{
        UserId      = $UserId
        Action      = 'Update'
        DisplayName = $ExistingContactGAL.DisplayName
        Mail        = $ExistingContactGAL.Mail
        # Force array output even when only a single property is present.
        Update      = @($UpdateProperties | Sort-Object -Unique)
        Skip        = @($SkippedProperties | Sort-Object -Unique)
        Details     = ''
        Error       = ''
    }
}

