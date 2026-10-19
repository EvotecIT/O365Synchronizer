function Complete-O365UserManagers {
    <#
    .SYNOPSIS
    Loads manager values for users selected by an advanced Graph filter.
    .DESCRIPTION
    Uses Graph batches of at most 20 manager reads so the filtered collection query
    does not combine advanced query parameters with manager expansion. Failed,
    incomplete or unreadable results stop synchronization before contact writes.
    A 404 from the manager relationship is the authoritative absence of a manager.
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
                url = '/users/' + [uri]::EscapeDataString($User.Id) + '/manager?$select=displayName,userPrincipalName'
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
            if ($Response.status -eq 404) {
                $Name = $null
            } elseif ($Response.status -eq 200) {
                $Name = Get-O365ManagerName -Manager $Response.body
                if ([string]::IsNullOrWhiteSpace($Name)) {
                    throw 'Graph returned an unreadable manager. Verify directory permissions before synchronizing.'
                }
            } else {
                throw "Manager read failed (HTTP $($Response.status))."
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
