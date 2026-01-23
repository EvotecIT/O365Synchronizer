function Set-O365WrapperPersonalContact {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $ContactId,
        [string] $UserId,
        [string] $AssistantName,

        [DateTime] $Birthday,

        [alias('Street', 'StreetAddress')][string] $BusinessStreet,
        [alias('City')][string] $BusinessCity,
        [alias('State')][string] $BusinessState,
        [alias('PostalCode')][string] $BusinessPostalCode,
        [alias('Country')][string] $BusinessCountryOrRegion,

        [string] $HomeStreet,
        [string] $HomeCity,
        [string] $HomeState,
        [string] $HomePostalCode,
        [string] $HomeCountryOrRegion,

        [string] $OtherAddress,
        [string] $OtherCity,
        [string] $OtherState,
        [string] $OtherPostalCode,
        [string] $OtherCountryOrRegion,

        [string] $BusinessHomePage,
        [string[]] $BusinessPhones,
        [string[]] $Categories,
        [string[]] $Children,
        [string] $CompanyName,

        [string] $Department,
        [string] $DisplayName,
        [alias('Mail')][string[]] $EmailAddresses,

        [string] $FileAs,
        [string] $Generation,
        [string] $GivenName,

        [string[]]$HomePhones,
        [string[]] $ImAddresses,
        [string] $Initials,
        [string] $JobTitle,
        [string] $Manager,
        [string] $MiddleName,
        [string] $MobilePhone,
        [alias('MailNickname')][string] $NickName,
        [string] $OfficeLocation,

        [string] $ParentFolderId,
        [string] $PersonalNotes,
        #$Photo,
        [string] $Profession,
        [string] $SpouseName,
        [string] $Surname,
        [string] $Title,
        [string] $YomiCompanyName,
        [string] $YomiGivenName,
        [string] $YomiSurname
    )

    $EmailAddressesClean = @($EmailAddresses | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $EmailAddressEntries = @(
        foreach ($Email in $EmailAddressesClean) {
            @{
                Address = $Email
            }
        }
    )
    if ($EmailAddressEntries.Count -eq 0) {
        $EmailAddressEntries = $null
    }
    $BusinessPhonesClean = @($BusinessPhones | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $HomePhonesClean = @($HomePhones | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $ImAddressesClean = @($ImAddresses | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $ChildrenClean = @($Children | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $CategoriesClean = @($Categories | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    $ContactSplat = [ordered] @{
        ContactId        = $ContactId
        UserId           = $UserId
        AssistantName    = $AssistantName
        Birthday         = $Birthday
        BusinessAddress  = @{
            Street          = $BusinessStreet
            City            = $BusinessCity
            State           = $BusinessState
            PostalCode      = $BusinessPostalCode
            CountryOrRegion = $BusinessCountryOrRegion
        }
        BusinessHomePage = $BusinessHomePage
        BusinessPhones   = $BusinessPhonesClean
        Categories       = $CategoriesClean
        Children         = $ChildrenClean
        CompanyName      = $CompanyName
        Department       = $Department
        DisplayName      = $DisplayName
        EmailAddresses   = $EmailAddressEntries
        FileAs           = $FileAs
        Generation       = $Generation
        GivenName        = $GivenName
        HomeAddress      = @{
            Street          = $HomeStreet
            City            = $HomeCity
            State           = $HomeState
            PostalCode      = $HomePostalCode
            CountryOrRegion = $HomeCountryOrRegion
        }
        HomePhones       = $HomePhonesClean
        ImAddresses      = $ImAddressesClean
        Initials         = $Initials
        JobTitle         = $JobTitle
        Manager          = $Manager
        MiddleName       = $MiddleName
        MobilePhone      = $MobilePhone
        NickName         = $NickName
        OfficeLocation   = $OfficeLocation
        OtherAddress     = @{
            Street          = $OtherAddress
            City            = $OtherCity
            State           = $OtherState
            PostalCode      = $OtherPostalCode
            CountryOrRegion = $OtherCountryOrRegion
        }
        ParentFolderId   = $ParentFolderId
        PersonalNotes    = $PersonalNotes
        Profession       = $Profession
        SpouseName       = $SpouseName
        Surname          = $Surname
        Title            = $Title
        YomiCompanyName  = $YomiCompanyName
        YomiGivenName    = $YomiGivenName
        YomiSurname      = $YomiSurname
        WhatIf           = $WhatIfPreference
        ErrorAction      = 'Stop'
    }
    Remove-EmptyValue -Hashtable $ContactSplat -Recursive -Rerun 2
    if ($PSBoundParameters.ContainsKey('MobilePhone')) {
        # Preserve explicit clear when caller passes empty MobilePhone.
        if ([string]::IsNullOrEmpty($MobilePhone)) {
            $ContactSplat['MobilePhone'] = $null
        } else {
            $ContactSplat['MobilePhone'] = $MobilePhone
        }
    }

    try {
        $null = Update-MgUserContact @contactSplat
        [PSCustomObject] @{
            Success      = $true
            ErrorMessage = ''
        }
    } catch {
        $ErrorMessage = $_.Exception.Message
        Write-Color -Text "[!] ", "Failed to update contact for ", $ContactSplat.DisplayName, " / ", $ContactSplat.EmailAddresses, " because: ", $ErrorMessage -Color Yellow, White, Red, White, Red, White, Red
        [PSCustomObject] @{
            Success      = $false
            ErrorMessage = $ErrorMessage
        }
    }
}
