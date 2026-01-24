function Get-O365PropertyValue {
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
