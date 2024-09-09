function Sync-O365PersonalContactFilter {
    <#
    .SYNOPSIS
    Provides a way to filter out users/contacts based on properties.

    .DESCRIPTION
    Provides a way to filter out users/contacts based on properties.
    Only users/contacts that match the filter will be included/excluded.

    .PARAMETER Type
    Type of the filter. It can be 'Include' or 'Exclude'.

    .PARAMETER Operator
    Operator to use. It can be 'Equal', 'NotEqual', 'LessThan', 'MoreThan', 'Like'.

    .PARAMETER Property
    Property to use for comparison. Keep in mind that it has to exists on the object.

    .PARAMETER Value
    Value to compare against. It can be single value or multiple values.

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
        [ValidateSet('Equal', 'NotEqual', 'LessThan', 'MoreThan', 'Like')][Parameter(Mandatory)][string] $Operator,
        [Parameter(Mandatory)][string] $Property,
        [Parameter()][Object] $Value
    )

    $Filter = [ordered] @{
        FilterType = 'Property'
        Type       = $Type
        Operator   = $Operator
        Property   = $Property
        Value      = $Value
    }
    $Filter
}