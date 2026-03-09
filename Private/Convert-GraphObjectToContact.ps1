function Convert-GraphObjectToContact {
    <#
    .SYNOPSIS
    Converts a Graph object into Exchange contact shapes.

    .DESCRIPTION
    Builds PSCustomObject payloads for Contact and MailContact updates
    based on a Graph source object.

    .PARAMETER SourceObject
    Graph user/contact object to map.
    #>
    [cmdletbinding()]
    param(
        $SourceObject
    )

    $MappingMailContact = [ordered] @{
        DisplayName               = 'DisplayName'
        PrimarySmtpAddress        = 'Mail'
        CustomAttribute1          = 'CustomAttribute1'
        CustomAttribute2          = 'CustomAttribute2'
        ExtensionCustomAttribute1 = 'ExtensionCustomAttribute1'
        #HiddenFromAddressListsEnabled = 'HiddenFromAddressListsEnabled'
    }
    $MappingContact = [ordered] @{
        DisplayName         = 'DisplayName'
        WindowsEmailAddress = 'Mail'
        Title               = 'JobTitle'
        FirstName           = 'GivenName'
        LastName            = 'SurName'
        HomePhone           = 'HomePhone'
        MobilePhone         = 'MobilePhone'
        Phone               = 'BusinessPhones'
        CompanyName         = 'CompanyName'
        Department          = 'Department'
        Office              = 'Office'
        StreetAddress       = 'StreetAddress'
        City                = 'City'
        StateOrProvince     = 'StateOrProvince'
        PostalCode          = 'PostalCode'
        CountryOrRegion     = 'CountryOrRegion'
        #Fax                 = 'Fax'
    }

    $NewContact = [ordered] @{}
    foreach ($Property in $MappingContact.Keys) {
        $PropertyName = $MappingContact[$Property]
        if ($PropertyName -eq 'BusinessPhones') {
            $NewContact[$Property] = [string] $SourceObject.$PropertyName
        } else {
            $NewContact[$Property] = $SourceObject.$PropertyName
        }
    }
    $NewMailContact = [ordered] @{}
    foreach ($Property in $MappingMailContact.Keys) {
        $PropertyName = $MappingMailContact[$Property]
        #if ($PropertyName -eq 'BusinessPhones') {
        #    $NewMailContact[$Property] = [string] $SourceObject.$PropertyName
        # } else {
        $NewMailContact[$Property] = $SourceObject.$PropertyName
        # }
    }
    $Output = [ordered] @{
        Contact     = [PSCustomObject] $NewContact
        MailContact = [PSCustomObject] $NewMailContact
    }
    $Output
}
