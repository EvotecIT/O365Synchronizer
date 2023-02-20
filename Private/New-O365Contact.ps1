function New-O365Contact {
    [CmdletBinding()]
    param(
        [string] $UserId,
        [PSCustomObject] $User,
        [string] $GuidPrefix,
        [switch] $RequireEmailAddress
    )
    if ($RequireEmailAddress) {
        if (-not $User.Mail) {
            #Write-Verbose -Message "Skipping $($User.DisplayName) because they have no email address"
            continue
        }
    }

    Write-Color -Text "[+] ", "Creating ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Green, White, Green
    $newMgUserContactSplat = @{
        FileAs         = "$($GuidPrefix)$($User.Id)"
        UserId         = $UserId
        NickName       = $User.MailNickname
        DisplayName    = $User.DisplayName
        GivenName      = $User.GivenName
        Surname        = $User.Surname
        EmailAddresses = @(
            @{
                Address = $User.Mail;
                Name    = $User.MailNickname;
            }
        )
        MobilePhone    = $User.MobilePhone
        HomePhones     = $User.HomePhone
        BusinessPhones = $User.BusinessPhones
        CompanyName    = $User.CompanyName
    }
    Remove-EmptyValue -Hashtable $newMgUserContactSplat -Recursive

    try {
        $null = New-MgUserContact @newMgUserContactSplat -WhatIf:$WhatIfPreference -ErrorAction Stop
    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " / ", $User.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
    }

    [PSCustomObject] @{
        UserId      = $UserId
        Action      = 'New'
        DisplayName = $ExistingContact.DisplayName
        Mail        = $ExistingContact.Mail
        Skip        = ''
        Update      = $newMgUserContactSplat.Keys | Sort-Object
        Details     = ''
        Error       = $ErrorMessage
    }
}