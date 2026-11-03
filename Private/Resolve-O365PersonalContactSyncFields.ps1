function Resolve-O365PersonalContactSyncFields {
    <#
    .SYNOPSIS
    Resolves the public field selection into the existing contact mapping.
    .DESCRIPTION
    All retains the default mapping. BusinessAddress manages the complete
    business address. Identity markers remain automatic. Empty selections and
    All combined with individual fields are rejected before synchronization.
    .PARAMETER SyncField
    Contact fields to manage.
    #>
    [CmdletBinding()]
    param(
        [string[]] $SyncField = @('All')
    )
    $Allowed = @('DisplayName', 'GivenName', 'Surname', 'Nickname', 'Mail', 'MobilePhone', 'HomePhone',
        'BusinessPhones', 'CompanyName', 'Department', 'JobTitle', 'Manager', 'BusinessAddress', 'Categories')
    if (-not $SyncField -or ($SyncField -contains 'All' -and $SyncField.Count -ne 1)) {
        throw 'Select All on its own, or at least one individual contact field.'
    }
    $Selection = if ($SyncField -contains 'All') { $Allowed } else { $SyncField }
    foreach ($Field in $Selection) {
        if ($Allowed -notcontains $Field) {
            throw "Unsupported contact field: $Field"
        }
        if ($Field -eq 'BusinessAddress') {
            'Country', 'City', 'State', 'Street', 'PostalCode'
        } else {
            $Field
        }
    }
}
