function Complete-O365UserManagers {
    <#
    .SYNOPSIS
    Loads manager values for users selected by an advanced Graph filter.
    .DESCRIPTION
    Uses Graph batches of at most 20 user reads so the filtered collection query
    does not combine advanced query parameters with manager expansion. Failed,
    incomplete or unreadable results stop synchronization before contact writes.
    A null manager is accepted as the authoritative absence of a manager.
    .PARAMETER Users
    Users returned by the filtered directory read.
    #>
    [CmdletBinding()]
    param([object[]] $Users)

    for ($Offset = 0; $Offset -lt $Users.Count; $Offset += 20) {
        $Pending = @{}
        $Requests = @(for ($Index = $Offset; $Index -lt [Math]::Min($Offset + 20, $Users.Count); $Index++) {
            $User = $Users[$Index]
            if ([string]::IsNullOrWhiteSpace($User.Id)) {
                throw 'Filtered user has no identity for its manager read.'
            }
            $RequestId = [string]($Index - $Offset + 1)
            $Pending[$RequestId] = $User
            @{
                id = $RequestId
                method = 'GET'
                url = '/users/' + [uri]::EscapeDataString($User.Id) + '?$select=id&$expand=manager($select=displayName,userPrincipalName)'
            }
        })
        $Body = @{ requests = $Requests } | ConvertTo-Json -Depth 8 -Compress
        $Batch = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/$batch' -Body $Body -ContentType 'application/json' -ErrorAction Stop
        foreach ($Response in $Batch.responses) {
            $ResponseId = [string]$Response.id
            if (-not $Pending.ContainsKey($ResponseId)) {
                throw 'Manager batch returned an unexpected or duplicate response identity.'
            }
            $User = $Pending[$ResponseId]
            if ($Response.status -ne 200 -or $Response.body.id -ne $User.Id) {
                throw "Manager read failed or returned a different user (HTTP $($Response.status))."
            }
            $HasManager = if ($Response.body -is [System.Collections.IDictionary]) {
                $Response.body.Contains('manager')
            } else {
                $Response.body.PSObject.Properties.Name -contains 'manager'
            }
            if (-not $HasManager) {
                throw 'Manager response is missing the requested relationship.'
            }
            $Manager = $Response.body.manager
            $Name = if ($null -ne $Manager) { Get-O365ManagerName -Manager $Manager } else { $null }
            if ($null -ne $Manager -and [string]::IsNullOrWhiteSpace($Name)) {
                throw 'Graph returned an unreadable manager. Verify directory permissions before synchronizing.'
            }
            $User | Add-Member -MemberType NoteProperty -Name Manager -Value $Name -Force
            $Pending.Remove($ResponseId)
        }
        if ($Pending.Count -gt 0) {
            throw 'Manager batch is incomplete.'
        }
    }
    $Users
}
