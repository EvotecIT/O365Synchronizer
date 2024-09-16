function Initialize-DefaultValuesO365 {
    [cmdletBinding()]
    param(

    )

    $Script:PropertiesUsers = @(
        'DisplayName'
        'GivenName'
        'Surname'
        'Mail'
        'Nickname'
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
        'MobilePhone'
        'HomePhone'
        'BusinessPhones'
        'CompanyName'
        'JobTitle'
        'EmployeeId'
        'Country'
        'City'
        'State'
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
        'CompanyName'
        'JobTitle'
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