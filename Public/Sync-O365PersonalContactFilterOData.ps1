function Sync-O365PersonalContactFilterOData {
    <#
    .SYNOPSIS
    Provides a way to prefilter users with Microsoft Graph OData.

    .DESCRIPTION
    Provides a way to prefilter users with Microsoft Graph OData.
    The filter is applied to Get-MgUser and affects only Member/Guest queries.

    .PARAMETER Filter
    OData filter string to apply to Get-MgUser.

    .PARAMETER ConsistencyLevel
    Consistency level used by Microsoft Graph for advanced queries.

    .PARAMETER CountVariable
    Count variable name for advanced queries.

    .PARAMETER PageSize
    Page size used by Microsoft Graph when paging results.

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Filter {
        Sync-O365PersonalContactFilterOData -Filter "onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTER'" -ConsistencyLevel eventual -CountVariable userCount -PageSize 999
    }

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'user@contoso.com' -MemberTypes 'Member' -Filter {
        Sync-O365PersonalContactFilterOData -Filter "startsWith(displayName,'Test')"
    }

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateScript( { -not [string]::IsNullOrWhiteSpace($_) } )][string] $Filter,
        [string] $ConsistencyLevel,
        [string] $CountVariable,
        [int] $PageSize
    )

    $FilterInformation = [ordered] @{
        FilterType       = 'OData'
        Filter           = $Filter
        ConsistencyLevel = $ConsistencyLevel
        CountVariable    = $CountVariable
        PageSize         = $PageSize
    }
    $FilterInformation
}
