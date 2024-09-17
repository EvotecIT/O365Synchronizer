function New-O365WrapperPersonalContact {
    [cmdletBinding(SupportsShouldProcess)]
    param(
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

        [parameter(Mandatory)][string] $FileAs,
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

        [string] $ContactFolderID,
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

    $ContactSplat = [ordered] @{
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
        BusinessPhones   = $BusinessPhones
        Categories       = $Categories
        Children         = $Children
        CompanyName      = $CompanyName
        Department       = $Department
        DisplayName      = $DisplayName
        EmailAddresses   = @(
            foreach ($Email in $EmailAddresses) {
                @{
                    Address = $Email
                }
            }
        )
        Extensions       = $Extensions
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
        HomePhones       = $HomePhones
        ImAddresses      = $ImAddresses
        Initials         = $Initials
        JobTitle         = $JobTitle
        Manager          = $Manager
        MiddleName       = $MiddleName
        MobilePhone      = $MobilePhone
        NickName         = $NickName
        OfficeLocation   = $OfficeLocation
        OtherAddress     = @{
            Street          = $OtherStreet
            City            = $OtherCity
            State           = $OtherState
            PostalCode      = $OtherPostalCode
            CountryOrRegion = $OtherCountryOrRegion
        }
        ContactFolderID  = $ContactFolderID
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

    if ($null -eq $ContactFolderID) {
        try {
            $null = New-MgUserContact @contactSplat
            $true
        } catch {
            Write-Color -Text "[!] ", "Failed to create contact for ", $DisplayName, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
            $false
        }
    } else {
        try {
            $null = New-MgUserContactFolderContact @contactSplat
            $true
        } catch {
            Write-Color -Text "[!] ", "Failed to create contact for ", $DisplayName, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
            $false
        }
    }
}