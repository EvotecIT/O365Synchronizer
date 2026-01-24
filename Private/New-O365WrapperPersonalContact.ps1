function New-O365WrapperPersonalContact {
    <#
    .SYNOPSIS
    Creates a personal contact through Microsoft Graph.

    .DESCRIPTION
    Wraps New-MgUserContact/New-MgUserContactFolderContact and cleans
    array inputs before sending. Remaining parameters map directly to
    Graph contact fields.

    .PARAMETER UserId
    User mailbox identifier.

    .PARAMETER FileAs
    FileAs value used to tag synchronized contacts.

    .PARAMETER EmailAddresses
    Email addresses for the contact.

    .PARAMETER ContactFolderID
    Optional contact folder id.
    #>
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

    $EmailAddressEntries = ConvertTo-CleanContactArray -Values $EmailAddresses -AsEmailAddress
    $BusinessPhonesClean = ConvertTo-CleanContactArray -Values $BusinessPhones
    $HomePhonesClean = ConvertTo-CleanContactArray -Values $HomePhones
    $ImAddressesClean = ConvertTo-CleanContactArray -Values $ImAddresses
    $ChildrenClean = ConvertTo-CleanContactArray -Values $Children
    $CategoriesClean = ConvertTo-CleanContactArray -Values $Categories

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

    if ([string]::IsNullOrEmpty($ContactFolderID)) {
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
