function Sync-O365PersonalContactFilterGroup {
    <#
    .SYNOPSIS
    Provides a way to filter out users/contacts based on groups.

    .DESCRIPTION
    Provides a way to filter out users/contacts based on groups.
    Only users/contacts that are part of the group will be included/excluded.

    .PARAMETER Type
    Type of the filter. It can be 'Include' or 'Exclude'.

    .PARAMETER GroupID
    One or multiple GroupID's to filter out users/contacts. Keep in mind that it's not the name of the group, but the actual ID of the group.
    Due to performance reasons it's better to use GroupID instead of GroupName.

    .EXAMPLE
    Sync-O365PersonalContact -UserId 'przemyslaw.klys@test.pl' -Verbose -MemberTypes 'Contact', 'Member' -GuidPrefix 'O365Synchronizer' -WhatIf -PassThru {
        Sync-O365PersonalContactFilter -Type Include -Property 'CompanyName' -Value 'OtherCompany*','Evotec*' -Operator 'like' # filter out on CompanyName
        Sync-O365PersonalContactFilterGroup -Type Include -GroupID 'e7772951-4b0e-4f10-8f38-eae9b8f55962' # filter out on GroupID
    } | Format-Table

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [ValidateSet('Include', 'Exclude')][Parameter(Mandatory)][string] $Type,
        [Parameter(Mandatory)][string[]] $GroupID
    )
    $Filter = [ordered] @{
        FilterType = 'Group'
        Type       = $Type
        GroupID    = $GroupID
    }
    $Filter
}