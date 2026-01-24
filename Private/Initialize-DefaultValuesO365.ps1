function Initialize-DefaultValuesO365 {
    <#
    .SYNOPSIS
    Initializes script-level property lists and mappings.

    .DESCRIPTION
    Sets the user/contact property lists and contact-to-user mapping
    used during synchronization.
    #>
    [cmdletBinding()]
    param(

    )

    $Script:PropertiesUsers = @(
        'DisplayName'
        'GivenName'
        'Surname'
        'Mail'
        'OtherMails'
        'Nickname'
        'MailNickname'
        'MobilePhone'
        'HomePhone'
        'BusinessPhones'
        'UserPrincipalName'
        'Id',
        'UserType'
        'EmployeeType'
        'AccountEnabled'
        'CreatedDateTime'
        'AssignedLicenses'
        'MemberOf'
        'OnPremisesExtensionAttributes'
        'CompanyName'
        'JobTitle'
        'EmployeeId'
        'Country'
        'City'
        'State'
        'StreetAddress'
        'Street'
        'PostalCode'
    )

    $Script:PropertiesContacts = @(
        'DisplayName'
        'GivenName'
        'Surname'
        'Mail'
        'JobTitle'
        'MailNickname'
        #'Phones'
        'UserPrincipalName'
        'Id',
        'CompanyName'
        'OnPremisesSyncEnabled'
        'Addresses'
        'MemberOf'
        'MobilePhone'
        'Phones'
        'HomePhone'
        'BusinessPhones'
        'EmployeeId'
        'Country'
        'City'
        'State'
        'Street'
        'PostalCode'
    )

    $Script:MappingContactToUser = [ordered] @{
        'MailNickname'   = 'NickName'
        'DisplayName'    = 'DisplayName'
        'GivenName'      = 'GivenName'
        'Surname'        = 'Surname'
        # special treatment for 'Mail' because it's an array
        'Mail'           = 'EmailAddresses.Address'
        'MobilePhone'    = 'MobilePhone'
        'HomePhone'      = 'HomePhone'
        'CompanyName'    = 'CompanyName'
        'BusinessPhones' = 'BusinessPhones'
        'JobTitle'       = 'JobTitle'
        'Country'        = 'BusinessAddress.CountryOrRegion'
        'City'           = 'BusinessAddress.City'
        'State'          = 'BusinessAddress.State'
        'Street'         = 'BusinessAddress.Street'
        'PostalCode'     = 'BusinessAddress.PostalCode'
    }
}
