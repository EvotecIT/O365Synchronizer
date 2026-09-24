function Set-O365WrapperPersonalContact {
    <#
    .SYNOPSIS
    Updates a personal contact through Microsoft Graph.

    .DESCRIPTION
    Wraps Update-MgUserContact and cleans array inputs before sending.
    Remaining parameters map directly to Graph contact fields.

    .PARAMETER ContactId
    Contact identifier to update.

    .PARAMETER UserId
    User mailbox identifier.

    .PARAMETER AssistantName
    Assistant name for the contact.

    .PARAMETER Birthday
    Birthday of the contact.

    .PARAMETER BusinessStreet
    Business address street (aliases Street, StreetAddress).

    .PARAMETER BusinessCity
    Business address city (alias City).

    .PARAMETER BusinessState
    Business address state or province (alias State).

    .PARAMETER BusinessPostalCode
    Business address postal code (alias PostalCode).

    .PARAMETER BusinessCountryOrRegion
    Business address country or region (alias Country).

    .PARAMETER HomeStreet
    Home address street.

    .PARAMETER HomeCity
    Home address city.

    .PARAMETER HomeState
    Home address state or province.

    .PARAMETER HomePostalCode
    Home address postal code.

    .PARAMETER HomeCountryOrRegion
    Home address country or region.

    .PARAMETER OtherAddress
    Other address street.

    .PARAMETER OtherCity
    Other address city.

    .PARAMETER OtherState
    Other address state or province.

    .PARAMETER OtherPostalCode
    Other address postal code.

    .PARAMETER OtherCountryOrRegion
    Other address country or region.

    .PARAMETER BusinessHomePage
    Business home page URL.

    .PARAMETER BusinessPhones
    Business phone numbers.

    .PARAMETER Categories
    Categories assigned to the contact.

    .PARAMETER Children
    Children names.

    .PARAMETER CompanyName
    Company or organization name.

    .PARAMETER Department
    Department name.

    .PARAMETER DisplayName
    Display name.

    .PARAMETER EmailAddresses
    Email addresses (alias Mail).

    .PARAMETER FileAs
    FileAs value used to tag synchronized contacts.

    .PARAMETER Generation
    Name suffix or generation (for example Jr).

    .PARAMETER GivenName
    Given name.

    .PARAMETER HomePhones
    Home phone numbers.

    .PARAMETER ImAddresses
    Instant messaging addresses.

    .PARAMETER Initials
    Initials.

    .PARAMETER JobTitle
    Job title.

    .PARAMETER Manager
    Manager name.

    .PARAMETER MiddleName
    Middle name.

    .PARAMETER MobilePhone
    Mobile phone number.

    .PARAMETER NickName
    Nickname (alias MailNickname).

    .PARAMETER OfficeLocation
    Office location.

    .PARAMETER ParentFolderId
    Folder id when updating a contact in a named contact folder.

    .PARAMETER PersonalNotes
    Personal notes.

    .PARAMETER Profession
    Profession.

    .PARAMETER SpouseName
    Spouse name.

    .PARAMETER Surname
    Surname.

    .PARAMETER Title
    Title or honorific.

    .PARAMETER YomiCompanyName
    Phonetic company name.

    .PARAMETER YomiGivenName
    Phonetic given name.

    .PARAMETER YomiSurname
    Phonetic surname.
    #>
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

        [alias('HomePhone')][string[]]$HomePhones,
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

    $EmailAddressEntries = ConvertTo-CleanContactArray -Values $EmailAddresses -AsEmailAddress
    $BusinessPhonesClean = ConvertTo-CleanContactArray -Values $BusinessPhones
    $HomePhonesClean = ConvertTo-CleanContactArray -Values $HomePhones
    $ImAddressesClean = ConvertTo-CleanContactArray -Values $ImAddresses
    $ChildrenClean = ConvertTo-CleanContactArray -Values $Children
    $CategoriesClean = ConvertTo-CleanContactArray -Values $Categories

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
    $ClearPatch = [ordered] @{}
    $ScalarProperties = @(
        'AssistantName', 'BusinessHomePage', 'CompanyName', 'Department', 'DisplayName',
        'FileAs', 'Generation', 'GivenName', 'Initials', 'JobTitle', 'Manager',
        'MiddleName', 'MobilePhone', 'NickName', 'OfficeLocation', 'PersonalNotes',
        'Profession', 'SpouseName', 'Surname', 'Title', 'YomiCompanyName',
        'YomiGivenName', 'YomiSurname'
    )
    foreach ($Property in $ScalarProperties) {
        if ($PSBoundParameters.ContainsKey($Property) -and [string]::IsNullOrEmpty($PSBoundParameters[$Property])) {
            $GraphProperty = $Property.Substring(0, 1).ToLowerInvariant() + $Property.Substring(1)
            $ClearPatch[$GraphProperty] = $null
            $ContactSplat.Remove($Property)
        }
    }

    $ArrayProperties = [ordered] @{
        BusinessPhones = $BusinessPhonesClean
        Categories = $CategoriesClean
        Children = $ChildrenClean
        EmailAddresses = $EmailAddressEntries
        HomePhones = $HomePhonesClean
        ImAddresses = $ImAddressesClean
    }
    foreach ($Property in $ArrayProperties.Keys) {
        if ($PSBoundParameters.ContainsKey($Property) -and
            ($null -eq $ArrayProperties[$Property] -or @($ArrayProperties[$Property]).Count -eq 0)) {
            $GraphProperty = $Property.Substring(0, 1).ToLowerInvariant() + $Property.Substring(1)
            $ClearPatch[$GraphProperty] = @()
            $ContactSplat.Remove($Property)
        }
    }

    $BusinessAddressProperties = [ordered] @{
        BusinessStreet = 'street'
        BusinessCity = 'city'
        BusinessState = 'state'
        BusinessPostalCode = 'postalCode'
        BusinessCountryOrRegion = 'countryOrRegion'
    }
    $BusinessAddressNeedsClear = $false
    foreach ($Property in $BusinessAddressProperties.Keys) {
        if ($PSBoundParameters.ContainsKey($Property) -and [string]::IsNullOrEmpty($PSBoundParameters[$Property])) {
            $BusinessAddressNeedsClear = $true
            break
        }
    }
    if ($BusinessAddressNeedsClear) {
        foreach ($Property in $BusinessAddressProperties.Keys) {
            if (-not $PSBoundParameters.ContainsKey($Property)) {
                throw 'Clearing a business address field requires all business address fields.'
            }
        }
        $AddressPatch = [ordered] @{}
        foreach ($Property in $BusinessAddressProperties.Keys) {
            $Value = $PSBoundParameters[$Property]
            $AddressPatch[$BusinessAddressProperties[$Property]] = if ([string]::IsNullOrEmpty($Value)) { $null } else { $Value }
        }
        $ClearPatch['businessAddress'] = $AddressPatch
        $ContactSplat.Remove('BusinessAddress')
    }
    $ContactSplat.Remove('ParentFolderId')

    try {
        $RegularProperties = @($ContactSplat.Keys | Where-Object { $_ -notin 'ContactId', 'UserId', 'WhatIf', 'ErrorAction' })
        if ($RegularProperties.Count -gt 0) {
            if ([string]::IsNullOrEmpty($ParentFolderId)) {
                $null = Update-MgUserContact @contactSplat
            } else {
                $null = Update-MgUserContactFolderContact @contactSplat -ContactFolderId $ParentFolderId
            }
        }
        if ($ClearPatch.Count -gt 0 -and $PSCmdlet.ShouldProcess("$UserId / $ContactId", 'Clear personal contact fields')) {
            if ($PSBoundParameters.ContainsKey('DisplayName') -and -not $ClearPatch.Contains('displayName')) {
                $ClearPatch['displayName'] = $DisplayName
            }
            $EncodedUserId = [Uri]::EscapeDataString($UserId)
            $EncodedContactId = [Uri]::EscapeDataString($ContactId)
            if ([string]::IsNullOrEmpty($ParentFolderId)) {
                $ContactUri = "/v1.0/users/$EncodedUserId/contacts/$EncodedContactId"
            } else {
                $EncodedFolderId = [Uri]::EscapeDataString($ParentFolderId)
                $ContactUri = "/v1.0/users/$EncodedUserId/contactFolders/$EncodedFolderId/contacts/$EncodedContactId"
            }
            $Body = $ClearPatch | ConvertTo-Json -Depth 8 -Compress
            $null = Invoke-MgGraphRequest -Method PATCH -Uri $ContactUri -Body $Body -ContentType 'application/json' -ErrorAction Stop
        }
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
