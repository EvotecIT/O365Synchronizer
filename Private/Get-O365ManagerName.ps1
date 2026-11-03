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
    } else {
        foreach ($Candidate in @($Manager.DisplayName, $Manager.UserPrincipalName,
            $Manager.AdditionalProperties.displayName, $Manager.AdditionalProperties.userPrincipalName)) {
            if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
                $ManagerName = $Candidate
                break
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
