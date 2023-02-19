function Set-UserContact {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $ContactId,
        [string] $UserId,
        [string] $AssistantName,

        [DateTime] $Birthday,

        [alias('Street')][string] $BusinessStreet,
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
        [string[]] $EmailAddresses,

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
        [string] $NickName,
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
    Remove-EmptyValue -Hashtable $ContactSplat

    try {
        Update-MgUserContact @contactSplat
    } catch {
        Write-Color -Text "[!] ", "Failed to update contact for ", $ContactSplat.DisplayName, " / ", $ContactSplat.EmailAddresses, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
    }
}

<#
    -ContactId <String>
        key: id of contact

    -UserId <String>
        key: id of user

    -InputObject <IPersonalContactsIdentity>
        Identity Parameter
        To construct, please use Get-Help -Online and see NOTES section for INPUTOBJECT properties and create a hash table.

    -BodyParameter <IMicrosoftGraphContact>
        contact
        To construct, please use Get-Help -Online and see NOTES section for BODYPARAMETER properties and create a hash table.

    -AdditionalProperties <Hashtable>
        Additional Parameters

    -AssistantName <String>
        The name of the contact's assistant.

    -Birthday <DateTime>
        The contact's birthday.
        The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time.
        For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z

    -BusinessAddress <IMicrosoftGraphPhysicalAddress>
        physicalAddress
        To construct, please use Get-Help -Online and see NOTES section for BUSINESSADDRESS properties and create a hash table.

    -BusinessHomePage <String>
        The business home page of the contact.

    -BusinessPhones <String[]>
        The contact's business phone numbers.

    -Categories <String[]>
        The categories associated with the item

    -ChangeKey <String>
        Identifies the version of the item.
        Every time the item is changed, changeKey changes as well.
        This allows Exchange to apply changes to the correct version of the object.
        Read-only.

    -Children <String[]>
        The names of the contact's children.

    -CompanyName <String>
        The name of the contact's company.

    -CreatedDateTime <DateTime>
        The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time.
        For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z

    -Department <String>
        The contact's department.

    -DisplayName <String>
        The contact's display name.
        You can specify the display name in a create or update operation.
        Note that later updates to other properties may cause an automatically generated value to overwrite the displayName value you have specified.
        To preserve a pre-existing value, always include it as displayName in an update operation.

    -EmailAddresses <IMicrosoftGraphEmailAddress[]>
        The contact's email addresses.
        To construct, please use Get-Help -Online and see NOTES section for EMAILADDRESSES properties and create a hash table.

    -Extensions <IMicrosoftGraphExtension[]>
        The collection of open extensions defined for the contact.
        Read-only.
        Nullable.
        To construct, please use Get-Help -Online and see NOTES section for EXTENSIONS properties and create a hash table.

    -FileAs <String>
        The name the contact is filed under.

    -Generation <String>
        The contact's generation.

    -GivenName <String>
        The contact's given name.

    -HomeAddress <IMicrosoftGraphPhysicalAddress>
        physicalAddress
        To construct, please use Get-Help -Online and see NOTES section for HOMEADDRESS properties and create a hash table.

    -HomePhones <String[]>
        The contact's home phone numbers.

    -Id <String>
        The unique idenfier for an entity.
        Read-only.

    -ImAddresses <String[]>
        .

    -Initials <String>
        .

    -JobTitle <String>
        .

    -LastModifiedDateTime <DateTime>
        The Timestamp type represents date and time information using ISO 8601 format and is always in UTC time.
        For example, midnight UTC on Jan 1, 2014 is 2014-01-01T00:00:00Z

    -Manager <String>
        .

    -MiddleName <String>
        .

    -MobilePhone <String>
        .

    -MultiValueExtendedProperties <IMicrosoftGraphMultiValueLegacyExtendedProperty[]>
        The collection of multi-value extended properties defined for the contact.
        Read-only.
        Nullable.
        To construct, please use Get-Help -Online and see NOTES section for MULTIVALUEEXTENDEDPROPERTIES properties and create a hash table.

    -NickName <String>
        .

    -OfficeLocation <String>
        .

    -OtherAddress <IMicrosoftGraphPhysicalAddress>
        physicalAddress
        To construct, please use Get-Help -Online and see NOTES section for OTHERADDRESS properties and create a hash table.

    -ParentFolderId <String>
        .

    -PersonalNotes <String>
        .

    -Photo <IMicrosoftGraphProfilePhoto>
        profilePhoto
        To construct, please use Get-Help -Online and see NOTES section for PHOTO properties and create a hash table.

    -Profession <String>
        .

    -SingleValueExtendedProperties <IMicrosoftGraphSingleValueLegacyExtendedProperty[]>
        The collection of single-value extended properties defined for the contact.
        Read-only.
        Nullable.
        To construct, please use Get-Help -Online and see NOTES section for SINGLEVALUEEXTENDEDPROPERTIES properties and create a hash table.

    -SpouseName <String>
        .

    -Surname <String>
        .

    -Title <String>
        .

    -YomiCompanyName <String>
        .

    -YomiGivenName <String>
        .

    -YomiSurname <String>
        .

    -Break [<SwitchParameter>]
        Wait for .NET debugger to attach

    -HttpPipelineAppend <SendAsyncStep[]>
        SendAsync Pipeline Steps to be appended to the front of the pipeline

    -HttpPipelinePrepend <SendAsyncStep[]>
        SendAsync Pipeline Steps to be prepended to the front of the pipeline

    -PassThru [<SwitchParameter>]
        Returns true when the command succeeds

    -Proxy <Uri>
        The URI for the proxy server to use

    -ProxyCredential <PSCredential>
        Credentials for a proxy server to use for the remote call

    -ProxyUseDefaultCredentials [<SwitchParameter>]
        Use the default credentials for the proxy

    -WhatIf [<SwitchParameter>]

    -Confirm [<SwitchParameter>]

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

    -------------------------- EXAMPLE 1 --------------------------

    $params = @{
        HomeAddress = @{
                Street = "123 Some street"
                City = "Seattle"
                State = "WA"
                PostalCode = "98121"
        }
        Birthday = [System.DateTime]::Parse("1974-07-22")
    }
    # A UPN can also be used as -UserId.
    Update-MgUserContact -UserId $userId -ContactId $contactId -BodyParameter $params
#>