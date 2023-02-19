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
}