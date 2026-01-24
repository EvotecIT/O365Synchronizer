function Get-O365ManagerName {
    <#
    .SYNOPSIS
    Resolves a manager display name from Graph manager objects.

    .DESCRIPTION
    Accepts a manager string or Graph directory object and returns a
    trimmed display name (or UPN fallback) when available.

    .PARAMETER Manager
    Manager value to resolve.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $Manager
    )

    $ManagerName = $null
    if ($Manager -is [string]) {
        $ManagerName = $Manager
    } elseif ($Manager.PSObject.Properties.Name -contains 'DisplayName') {
        $ManagerName = $Manager.DisplayName
    } elseif ($Manager.PSObject.Properties.Name -contains 'AdditionalProperties') {
        $Additional = $Manager.AdditionalProperties
        if ($Additional) {
            if ($Additional.ContainsKey('displayName')) {
                $ManagerName = $Additional['displayName']
            } elseif ($Additional.ContainsKey('DisplayName')) {
                $ManagerName = $Additional['DisplayName']
            } elseif ($Additional.ContainsKey('userPrincipalName')) {
                $ManagerName = $Additional['userPrincipalName']
            } elseif ($Additional.ContainsKey('UserPrincipalName')) {
                $ManagerName = $Additional['UserPrincipalName']
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($ManagerName)) {
        return $null
    }

    $ManagerName = $ManagerName.Trim()
    if ([string]::IsNullOrWhiteSpace($ManagerName)) {
        return $null
    }

    $ManagerName
}
