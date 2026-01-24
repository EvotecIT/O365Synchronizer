function Get-O365PropertyValue {
    <#
    .SYNOPSIS
    Retrieves a property value from an object, supporting dotted paths.

    .DESCRIPTION
    Resolves nested properties such as
    OnPremisesExtensionAttributes.ExtensionAttribute5.

    .PARAMETER InputObject
    Object to read from.

    .PARAMETER PropertyPath
    Property name or dotted path to resolve.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $InputObject,
        [Parameter(Mandatory)][string] $PropertyPath
    )

    if ($PropertyPath -notlike '*.*') {
        return $InputObject.$PropertyPath
    }

    $Current = $InputObject
    foreach ($Segment in ($PropertyPath -split '\.')) {
        if ($null -eq $Current) {
            return $null
        }
        $Current = $Current.$Segment
    }
    $Current
}
