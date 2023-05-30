function New-O365InternalContact {
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
    if ($User.Mail) {
        Write-Color -Text "[+] ", "Creating ", $User.DisplayName, " / ", $User.Mail -Color Yellow, White, Green, White, Green
    } else {
        Write-Color -Text "[+] ", "Creating ", $User.DisplayName -Color Yellow, White, Green, White, Green
    }
    # $newMgUserContactSplat = @{
    #     FileAs           = "$($GuidPrefix)$($User.Id)"
    #     UserId           = $UserId
    #     NickName         = $User.MailNickname
    #     DisplayName      = $User.DisplayName
    #     GivenName        = $User.GivenName
    #     Surname          = $User.Surname
    #     EmailAddresses   = @(
    #         @{
    #             Address = $User.Mail;
    #             Name    = $User.MailNickname;
    #         }
    #     )
    #     MobilePhone      = $User.MobilePhone
    #     HomePhones       = $User.HomePhone
    #     BusinessPhones   = $User.BusinessPhones
    #     CompanyName      = $User.CompanyName
    #     ContactId        = $ContactId
    #     AssistantName    = $AssistantName
    #     Birthday         = $Birthday
    #     BusinessAddress  = @{
    #         Street          = $BusinessStreet
    #         City            = $BusinessCity
    #         State           = $BusinessState
    #         PostalCode      = $BusinessPostalCode
    #         CountryOrRegion = $BusinessCountryOrRegion
    #     }
    #     BusinessHomePage = $BusinessHomePage
    #     Categories       = $Categories
    #     Children         = $Children
    #     Department       = $Department
    #     Extensions       = $Extensions
    #     Generation       = $Generation
    #     HomeAddress      = @{
    #         Street          = $HomeStreet
    #         City            = $HomeCity
    #         State           = $HomeState
    #         PostalCode      = $HomePostalCode
    #         CountryOrRegion = $HomeCountryOrRegion
    #     }
    #     ImAddresses      = $ImAddresses
    #     Initials         = $Initials
    #     JobTitle         = $JobTitle
    #     Manager          = $Manager
    #     MiddleName       = $MiddleName
    #     OfficeLocation   = $OfficeLocation
    #     OtherAddress     = @{
    #         Street          = $OtherStreet
    #         City            = $OtherCity
    #         State           = $OtherState
    #         PostalCode      = $OtherPostalCode
    #         CountryOrRegion = $OtherCountryOrRegion
    #     }
    #     ParentFolderId   = $ParentFolderId
    #     PersonalNotes    = $PersonalNotes
    #     Profession       = $Profession
    #     SpouseName       = $SpouseName
    #     Title            = $Title
    #     YomiCompanyName  = $YomiCompanyName
    #     YomiGivenName    = $YomiGivenName
    #     YomiSurname      = $YomiSurname
    # }
    # Remove-EmptyValue -Hashtable $newMgUserContactSplat -Recursive -Rerun 2

    # try {
    #     $null = New-MgUserContact @newMgUserContactSplat -WhatIf:$WhatIfPreference -ErrorAction Stop
    # } catch {
    #     $ErrorMessage = $_.Exception.Message
    #     Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " / ", $User.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
    # }

    $PropertiesToUpdate = [ordered] @{}
    foreach ($Property in $Script:MappingContactToUser.Keys) {
        $PropertiesToUpdate[$Property] = $User.$Property
    }
    try {
        $StatusNew = New-O365WrapperPersonalContact -UserId $UserID @PropertiesToUpdate -WhatIf:$WhatIfPreference -FileAs "$($GuidPrefix)$($User.Id)" -ErrorAction SilentlyContinue
        $ErrorMessage = ''
    } catch {
        $ErrorMessage = $_.Exception.Message
        if ($User.Mail) {
            Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " / ", $User.Mail, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        } else {
            Write-Color -Text "[!] ", "Failed to create contact for ", $User.DisplayName, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        }
    }
    if ($WhatIfPreference) {
        $Status = 'OK (WhatIf)'
    } elseif ($StatusNew -eq $true) {
        $Status = 'OK'
    } else {
        $Status = 'Failed'
    }
    [PSCustomObject] @{
        UserId      = $UserId
        Action      = 'New'
        Status      = $Status
        DisplayName = $User.DisplayName
        Mail        = $User.Mail
        Skip        = ''
        Update      = $newMgUserContactSplat.Keys | Sort-Object
        Details     = ''
        Error       = $ErrorMessage
    }
}